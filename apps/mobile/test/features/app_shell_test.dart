import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/core/bootstrap/app_bootstrap.dart';
import 'package:nimmy/core/config/app_config.dart';
import 'package:nimmy/core/router/app_router.dart';
import 'package:nimmy/core/state/nimmy_controller.dart';
import 'package:nimmy/main.dart';
import 'package:nimmy/models/wake_word.dart';
import 'package:nimmy/services/ai/intent_parser.dart';
import 'package:nimmy/services/auth/auth_service.dart';
import 'package:nimmy/services/notifications/notification_service.dart';
import 'package:nimmy/services/permissions/permission_service.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';
import 'package:nimmy/services/tools/tool_registry.dart';
import 'package:nimmy/services/voice/voice_service.dart';
import 'package:nimmy/services/voice/wake_word_platform.dart';
import 'package:nimmy/services/voice/wake_word_service.dart';

class _FakeWakeWordPlatform implements WakeWordPlatform {
  final eventsController = StreamController<WakeWordEvent>.broadcast();

  @override
  Stream<WakeWordEvent> get events => eventsController.stream;

  @override
  Future<WakeWordCapabilities> capabilities() async => const WakeWordCapabilities(
        supported: true,
        local: true,
        serviceRunning: false,
        status: WakeWordStatus.stopped,
        microphonePermission: true,
        notificationPermission: true,
        modelInstalled: true,
        featureModelsInstalled: true,
        missingAssets: [],
        phrases: ['Hey Nimmy', 'Nimmy'],
        requiresVisibleNotification: true,
        canAutoStartAfterBoot: false,
      );

  @override
  Future<WakeWordOperationResult> start({double threshold = 0.5}) async =>
      const WakeWordOperationResult(
        success: true,
        status: WakeWordStatus.active,
      );

  @override
  Future<WakeWordOperationResult> stop() async =>
      const WakeWordOperationResult(
        success: true,
        status: WakeWordStatus.stopped,
      );

  @override
  Future<WakeWordOperationResult> pause({required String reason}) async =>
      const WakeWordOperationResult(
        success: true,
        status: WakeWordStatus.paused,
      );

  @override
  Future<WakeWordOperationResult> resume() async =>
      const WakeWordOperationResult(
        success: true,
        status: WakeWordStatus.active,
      );

  Future<void> dispose() => eventsController.close();
}

Future<AppBootstrap> _createTestBootstrap() async {
  final repository = InMemoryNimmyRepository();
  await repository.initialize();
  final scheduler = NoopReminderScheduler();
  final parser = NimmyIntentParser(timezone: 'Asia/Kolkata');
  final registry = ToolRegistry(
    repository: repository,
    reminderScheduler: scheduler,
  );
  final controller = NimmyController(
    repository: repository,
    intentParser: parser,
    toolRegistry: registry,
  );
  await controller.initialize();
  return AppBootstrap(
    config: const AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      aiBaseUrl: 'http://localhost:8000',
      defaultTimezone: 'Asia/Kolkata',
    ),
    controller: controller,
    authService: AuthService(client: null),
    voiceService: VoiceService(),
    permissionService: PermissionService(),
    wakeWordService: WakeWordService(platform: _FakeWakeWordPlatform()),
  );
}

void main() {
  group('AppShell Navigation & Destinations', () {
    testWidgets('renders all destinations and navigates through tabs and voice modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ensure router starts at /home
      NimmyRouter.router.go('/home');

      final bootstrap = await _createTestBootstrap();
      await tester.pumpWidget(NimmyApp(bootstrap: bootstrap));
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify bottom bar destinations and center orb button
      expect(find.widgetWithText(InkResponse, 'Home'), findsOneWidget);
      expect(find.widgetWithText(InkResponse, 'Tasks'), findsOneWidget);
      expect(find.widgetWithText(InkResponse, 'Calendar'), findsOneWidget);
      expect(find.widgetWithText(InkResponse, 'Memory'), findsOneWidget);
      expect(find.widgetWithText(InkResponse, 'More'), findsOneWidget);
      expect(find.byKey(const Key('shell_orb_button')), findsOneWidget);
      expect(find.text('Hey, I’m Nimmy.'), findsOneWidget);

      // 2. Navigate to Tasks
      await tester.tap(find.widgetWithText(InkResponse, 'Tasks'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Productivity'), findsOneWidget);

      // 3. Navigate to Calendar
      await tester.tap(find.widgetWithText(InkResponse, 'Calendar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Calendar & Agenda'), findsOneWidget);

      // 4. Navigate to Memory
      await tester.tap(find.widgetWithText(InkResponse, 'Memory'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('What Nimmy remembers—only with your approval.'), findsOneWidget);

      // 5. Navigate to More
      await tester.tap(find.widgetWithText(InkResponse, 'More'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Powerful tools, kept out of your way.'), findsOneWidget);

      // 6. Navigate back to Home
      await tester.tap(find.widgetWithText(InkResponse, 'Home'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hey, I’m Nimmy.'), findsOneWidget);

      // 7. Center Orb opens Voice modal
      await tester.tap(find.byKey(const Key('shell_orb_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byTooltip('Close'), findsOneWidget);

      // 8. Close voice modal
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Hey, I’m Nimmy.'), findsOneWidget);

      // 9. Rapid tab switching resilience without exceptions
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.widgetWithText(InkResponse, 'Tasks'));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(find.widgetWithText(InkResponse, 'Calendar'));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(find.widgetWithText(InkResponse, 'Memory'));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(find.widgetWithText(InkResponse, 'Home'));
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hey, I’m Nimmy.'), findsOneWidget);
    });
  });
}
