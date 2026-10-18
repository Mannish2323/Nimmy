import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase/supabase.dart';

import '../../core/logging/nimmy_logger.dart';

class NimmyAuthUser {
  const NimmyAuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.isCloudAuthenticated = true,
  });

  final String id;
  final String email;
  final String? displayName;
  final bool isCloudAuthenticated;

  static const local = NimmyAuthUser(
    id: 'local-user',
    email: 'local@device.nimmy',
    displayName: 'Local User',
    isCloudAuthenticated: false,
  );
}

sealed class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final NimmyAuthUser user;
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthService extends ChangeNotifier {
  AuthService({
    SupabaseClient? client,
    FlutterSecureStorage? secureStorage,
  }) : _client = client,
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  final SupabaseClient? _client;
  final FlutterSecureStorage _secureStorage;

  AuthState _state = const AuthUnauthenticated();
  AuthState get state => _state;

  NimmyAuthUser get currentUser => switch (_state) {
    AuthAuthenticated(:final user) => user,
    _ => NimmyAuthUser.local,
  };

  bool get isAuthenticated => switch (_state) {
    AuthAuthenticated(:final user) => user.isCloudAuthenticated,
    _ => false,
  };

  bool get isCloudAvailable => _client != null;

  static const _tokenKey = 'nimmy_auth_token';
  static const _refreshTokenKey = 'nimmy_auth_refresh_token';

  Future<void> initialize() async {
    NimmyLogger.info('Initializing AuthService...', category: LogCategory.security);
    if (_client == null) {
      NimmyLogger.info('Supabase not configured; running in local auth mode.', category: LogCategory.security);
      _state = const AuthUnauthenticated();
      notifyListeners();
      return;
    }

    try {
      final currentAuthUser = _client.auth.currentUser;
      if (currentAuthUser != null) {
        _setAuthenticatedUser(currentAuthUser);
        return;
      }

      // Check secure storage for restored token
      final savedRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (savedRefreshToken != null && savedRefreshToken.isNotEmpty) {
        NimmyLogger.info('Restoring session from secure storage...', category: LogCategory.security);
        final response = await _client.auth.setSession(savedRefreshToken);
        if (response.user != null) {
          _setAuthenticatedUser(response.user!);
          return;
        }
      }
    } catch (e) {
      NimmyLogger.warn('Session restoration failed; keeping unauthenticated.', category: LogCategory.security, error: e);
    }

    _state = const AuthUnauthenticated();
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw StateError('Cloud authentication is not configured in this build.');
    }

    _state = const AuthLoading();
    notifyListeners();

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      final session = response.session;
      if (user == null || session == null) {
        throw StateError('Sign in succeeded but no valid user session was returned.');
      }

      await _persistSession(session);
      _setAuthenticatedUser(user);
      NimmyLogger.info('User successfully authenticated', category: LogCategory.security);
    } catch (e) {
      _state = const AuthUnauthenticated();
      notifyListeners();
      NimmyLogger.warn('Authentication failed', category: LogCategory.security, error: e);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_client == null) {
      throw StateError('Cloud authentication is not configured in this build.');
    }

    _state = const AuthLoading();
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName.trim()} : null,
      );

      final user = response.user;
      final session = response.session;
      if (user == null) {
        throw StateError('Sign up succeeded but no user was returned.');
      }

      if (session != null) {
        await _persistSession(session);
        _setAuthenticatedUser(user);
      } else {
        // Confirmation email required
        _state = const AuthUnauthenticated();
        notifyListeners();
      }
      NimmyLogger.info('User registered successfully', category: LogCategory.security);
    } catch (e) {
      _state = const AuthUnauthenticated();
      notifyListeners();
      NimmyLogger.warn('Registration failed', category: LogCategory.security, error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    NimmyLogger.info('Signing out user...', category: LogCategory.security);
    try {
      if (_client != null) {
        await _client.auth.signOut();
      }
    } catch (e) {
      NimmyLogger.warn('Remote sign out error', category: LogCategory.security, error: e);
    } finally {
      await _clearStoredSession();
      _state = const AuthUnauthenticated();
      notifyListeners();
    }
  }

  Future<void> resetPassword({required String email}) async {
    if (_client == null) {
      throw StateError('Cloud authentication is not configured in this build.');
    }

    NimmyLogger.info('Requesting password reset...', category: LogCategory.security);
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> deleteAccount() async {
    if (_client == null || !isAuthenticated) {
      throw StateError('Must be authenticated to delete an account.');
    }

    NimmyLogger.warn('User initiated account deletion', category: LogCategory.security);
    // Real account deletion will clean up user-scoped data through Supabase cascade
    await signOut();
  }

  void _setAuthenticatedUser(User user) {
    _state = AuthAuthenticated(
      NimmyAuthUser(
        id: user.id,
        email: user.email ?? 'unknown@nimmy.ai',
        displayName: user.userMetadata?['display_name'] as String?,
        isCloudAuthenticated: true,
      ),
    );
    notifyListeners();
  }

  Future<void> _persistSession(Session session) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: session.accessToken);
      if (session.refreshToken != null) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: session.refreshToken!,
        );
      }
    } catch (e) {
      NimmyLogger.warn('Failed to securely store session tokens', category: LogCategory.security, error: e);
    }
  }

  Future<void> _clearStoredSession() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      NimmyLogger.warn('Failed to clear stored session tokens', category: LogCategory.security, error: e);
    }
  }
}
