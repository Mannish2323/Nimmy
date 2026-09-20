import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/core/theme/app_theme.dart';
import 'package:nimmy/widgets/error_view.dart';
import 'package:nimmy/widgets/loading_shimmer.dart';
import 'package:nimmy/widgets/nimmy_dialog.dart';
import 'package:nimmy/widgets/nimmy_snackbar.dart';

Widget _buildTestApp(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: NimmyTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('NimmyDialog', () {
    testWidgets('renders dialog title, message and buttons', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await NimmyDialog.showConfirmation(
                  context,
                  title: 'Delete Reminder',
                  message: 'Are you sure you want to delete this reminder?',
                  isDestructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Reminder'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this reminder?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Delete Reminder'), findsNothing);
    });

    testWidgets('cancel button returns false', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await NimmyDialog.showConfirmation(
                  context,
                  title: 'Discard draft?',
                  message: 'Your unsaved changes will be lost.',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });
  });

  group('NimmySnackbar', () {
    testWidgets('displays success message and action callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                NimmySnackbar.showSuccess(
                  context,
                  'Reminder scheduled for 9:00 AM',
                  actionLabel: 'UNDO',
                  onAction: () => actionTriggered = true,
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Animate in

      expect(find.text('Reminder scheduled for 9:00 AM'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
    });

    testWidgets('displays error snackbar with distinct styling', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                NimmySnackbar.showError(context, 'Failed to connect to AI engine');
              },
              child: const Text('Show Error'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Failed to connect to AI engine'), findsOneWidget);
    });
  });

  group('LoadingShimmer', () {
    testWidgets('renders animated shimmer when animations enabled', (tester) async {
      await tester.pumpWidget(_buildTestApp(LoadingShimmer.card(height: 100)));

      expect(find.byType(LoadingShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('renders static container when reduced motion is requested', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        LoadingShimmer.circle(size: 60),
        disableAnimations: true,
      ));

      expect(find.byType(LoadingShimmer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LoadingShimmer),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
    });
  });

  group('ErrorView', () {
    testWidgets('renders full error view with retry callback', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          ErrorView(
            title: 'Unable to Load Memories',
            message: 'Local storage experienced an unexpected read failure.',
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('Unable to Load Memories'), findsOneWidget);
      expect(find.text('Local storage experienced an unexpected read failure.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryPressed, isTrue);
    });

    testWidgets('renders compact error view inline', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const ErrorView(
            title: 'Sync Warning',
            message: 'Offline changes queued.',
            compact: true,
          ),
        ),
      );

      expect(find.text('Sync Warning'), findsOneWidget);
      expect(find.text('Offline changes queued.'), findsOneWidget);
    });
  });
}
