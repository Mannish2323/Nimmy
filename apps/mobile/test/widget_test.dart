import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/core/bootstrap/app_bootstrap.dart';
import 'package:nimmy/core/config/app_config.dart';
import 'package:nimmy/core/state/nimmy_controller.dart';
import 'package:nimmy/main.dart';
import 'package:nimmy/services/ai/intent_parser.dart';
import 'package:nimmy/services/notifications/notification_service.dart';
import 'package:nimmy/services/permissions/permission_service.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';
import 'package:nimmy/services/tools/tool_registry.dart';
import 'package:nimmy/services/voice/voice_service.dart';

void main() {
  testWidgets('opens the real Nimmy command center', (tester) async {
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
    final bootstrap = AppBootstrap(
      config: const AppConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        aiBaseUrl: 'http://localhost:8000',
        defaultTimezone: 'Asia/Kolkata',
      ),
      controller: controller,
      voiceService: VoiceService(),
      permissionService: PermissionService(),
    );

    await tester.pumpWidget(NimmyApp(bootstrap: bootstrap));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hey, I’m Nimmy.'), findsOneWidget);
    expect(find.text('Talk to Nimmy'), findsOneWidget);
    expect(find.text('LOCAL MODE'), findsOneWidget);
  });
}
