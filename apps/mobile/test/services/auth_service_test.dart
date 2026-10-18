import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/services/auth/auth_service.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }
}

void main() {
  group('AuthService', () {
    late _FakeSecureStorage fakeStorage;
    late AuthService authService;

    setUp(() {
      fakeStorage = _FakeSecureStorage();
      authService = AuthService(
        client: null,
        secureStorage: fakeStorage,
      );
    });

    test('initializes with unauthenticated local profile when client is null', () async {
      await authService.initialize();

      expect(authService.state, isA<AuthUnauthenticated>());
      expect(authService.isAuthenticated, isFalse);
      expect(authService.isCloudAvailable, isFalse);
      expect(authService.currentUser.id, 'local-user');
      expect(authService.currentUser.isCloudAuthenticated, isFalse);
    });

    test('refuses sign-in with explicit error when cloud is unconfigured', () async {
      await authService.initialize();

      expect(
        () => authService.signIn(email: 'user@example.com', password: 'password123'),
        throwsA(isA<StateError>()),
      );
      expect(authService.state, isA<AuthUnauthenticated>());
    });

    test('refuses sign-up with explicit error when cloud is unconfigured', () async {
      await authService.initialize();

      expect(
        () => authService.signUp(email: 'new@example.com', password: 'password123'),
        throwsA(isA<StateError>()),
      );
      expect(authService.state, isA<AuthUnauthenticated>());
    });

    test('refuses password reset with explicit error when cloud is unconfigured', () async {
      await authService.initialize();

      expect(
        () => authService.resetPassword(email: 'user@example.com'),
        throwsA(isA<StateError>()),
      );
    });

    test('signs out cleanly, clears tokens, and reverts to local state', () async {
      await fakeStorage.write(key: 'nimmy_auth_token', value: 'secret-token-123');
      await fakeStorage.write(key: 'nimmy_auth_refresh_token', value: 'refresh-token-456');

      await authService.signOut();

      expect(authService.state, isA<AuthUnauthenticated>());
      expect(authService.isAuthenticated, isFalse);
      expect(await fakeStorage.read(key: 'nimmy_auth_token'), isNull);
      expect(await fakeStorage.read(key: 'nimmy_auth_refresh_token'), isNull);
    });

    test('refuses account deletion when not authenticated', () async {
      await authService.initialize();

      expect(
        () => authService.deleteAccount(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
