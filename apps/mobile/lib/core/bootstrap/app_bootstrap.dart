import '../../services/ai/intent_parser.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/storage/hive_nimmy_repository.dart';
import '../../services/storage/in_memory_nimmy_repository.dart';
import '../../services/storage/nimmy_repository.dart';
import '../../services/tools/tool_registry.dart';
import '../../services/voice/voice_service.dart';
import '../config/app_config.dart';
import '../state/nimmy_controller.dart';

class AppBootstrap {
  const AppBootstrap({
    required this.config,
    required this.controller,
    required this.voiceService,
    required this.permissionService,
    this.startupWarning,
  });

  final AppConfig config;
  final NimmyController controller;
  final VoiceService voiceService;
  final PermissionService permissionService;
  final String? startupWarning;

  static Future<AppBootstrap> create() async {
    final config = AppConfig.fromEnvironment();
    NimmyRepository repository = HiveNimmyRepository();
    String? warning;
    try {
      await repository.initialize();
    } catch (_) {
      repository = InMemoryNimmyRepository();
      await repository.initialize();
      warning = 'Local persistence is unavailable. Data will last for this session only.';
    }

    ReminderScheduler scheduler = LocalNotificationService();
    try {
      await scheduler.initialize();
    } catch (_) {
      scheduler = NoopReminderScheduler();
      await scheduler.initialize();
      warning ??=
          'Notifications are unavailable. Reminders can still be saved locally.';
    }

    final timezone = scheduler.timezone == 'UTC'
        ? config.defaultTimezone
        : scheduler.timezone;
    final parser = NimmyIntentParser(timezone: timezone);
    final toolRegistry = ToolRegistry(
      repository: repository,
      reminderScheduler: scheduler,
    );
    final controller = NimmyController(
      repository: repository,
      intentParser: parser,
      toolRegistry: toolRegistry,
      cloudConfigured: false,
    );
    await controller.initialize();

    return AppBootstrap(
      config: config,
      controller: controller,
      voiceService: VoiceService(),
      permissionService: PermissionService(),
      startupWarning: warning,
    );
  }
}
