import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/core/theme/app_theme.dart';
import 'package:nimmy/features/auth/auth_screen.dart';
import 'package:nimmy/services/auth/auth_service.dart';
import 'package:provider/provider.dart';

Widget _buildAuthScreen({AuthService? authService}) {
  return MaterialApp(
    theme: NimmyTheme.darkTheme,
    home: ChangeNotifierProvider<AuthService>.value(
      value: authService ?? AuthService(client: null),
      child: const AuthScreen(),
    ),
  );
}

void main() {
  group('AuthScreen Widget Tests', () {
    testWidgets('renders brand hero, input fields, and tab toggles', (tester) async {
      await tester.pumpWidget(_buildAuthScreen());
      await tester.pumpAndSettle();

      expect(find.text('Nimmy OS Account'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Continue in Local-Only Mode'), findsOneWidget);
    });

    testWidgets('switches to Create Account and shows Full Name input', (tester) async {
      await tester.pumpWidget(_buildAuthScreen());
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsNothing);

      // Tap Create Account tab
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Forgot password?'), findsNothing);
    });

    testWidgets('shows validation errors on empty submission', (tester) async {
      await tester.pumpWidget(_buildAuthScreen());
      await tester.pumpAndSettle();

      // Tap Sign In button inside the form (the GlowButton)
      final signInButton = find.widgetWithText(GestureDetector, 'Sign In').last;
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Email address is required.'), findsOneWidget);
    });

    testWidgets('shows validation error on short password', (tester) async {
      await tester.pumpWidget(_buildAuthScreen());
      await tester.pumpAndSettle();

      // Enter valid email but short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '123',
      );

      final signInButton = find.widgetWithText(GestureDetector, 'Sign In').last;
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });
  });
}
