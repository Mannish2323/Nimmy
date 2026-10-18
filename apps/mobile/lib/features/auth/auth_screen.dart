import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/nimmy_dialog.dart';
import '../../widgets/nimmy_snackbar.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    if (!authService.isCloudAvailable) {
      NimmySnackbar.showWarning(
        context,
        'Cloud authentication is not configured in this build. Continuing in local-only mode.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        );
        if (mounted) {
          NimmySnackbar.showSuccess(
            context,
            'Account created! Welcome to Nimmy.',
          );
          context.pop();
        }
      } else {
        await authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          NimmySnackbar.showSuccess(
            context,
            'Signed in successfully. Cloud sync is active.',
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        NimmySnackbar.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text);
    final confirmed = await NimmyDialog.showConfirmation(
      context,
      title: 'Reset Password',
      message: 'Enter your email address to receive a secure password recovery link.',
      confirmLabel: 'Send Link',
      cancelLabel: 'Cancel',
      isDestructive: false,
    );

    if (confirmed == true && mounted) {
      final email = emailCtrl.text.trim();
      if (email.isEmpty) {
        NimmySnackbar.showWarning(context, 'Please enter a valid email address.');
        return;
      }

      final authService = context.read<AuthService>();
      try {
        await authService.resetPassword(email: email);
        if (mounted) {
          NimmySnackbar.showSuccess(
            context,
            'Password reset link sent. Check your inbox.',
          );
        }
      } catch (e) {
        if (mounted) {
          NimmySnackbar.showError(
            context,
            'Could not send reset link: ${e.toString()}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: NimmySpacing.lg,
            vertical: NimmySpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand Hero Header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NimmyColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: NimmyColors.purple.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: NimmySpacing.md),
              Center(
                child: Text(
                  'Nimmy OS Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: NimmySpacing.xs),
              Center(
                child: Text(
                  _isSignUp
                      ? 'Create your account to enable end-to-end cloud sync'
                      : 'Sign in to access your synchronized memories & tasks',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NimmyColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: NimmySpacing.xl),

              // Segmented Tab Control
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: NimmyColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NimmyColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? NimmyColors.purple : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: !_isSignUp ? Colors.white : NimmyColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignUp ? NimmyColors.purple : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isSignUp ? Colors.white : NimmyColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NimmySpacing.lg),

              // Auth Form Card
              GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: NimmySpacing.md),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email address is required.';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: NimmySpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      if (!_isSignUp) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: NimmySpacing.md),
                      ],
                      const SizedBox(height: NimmySpacing.md),
                      GlowButton(
                        label: _isLoading
                            ? 'Please wait...'
                            : (_isSignUp ? 'Create Account' : 'Sign In'),
                        icon: _isSignUp
                            ? Icons.person_add_rounded
                            : Icons.login_rounded,
                        onPressed: _isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: NimmySpacing.lg),

              // Local Offline Option
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.phonelink_setup_rounded, size: 18),
                  label: const Text('Continue in Local-Only Mode'),
                  style: TextButton.styleFrom(
                    foregroundColor: NimmyColors.textSecondary,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
