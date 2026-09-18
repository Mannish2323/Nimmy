import 'package:supabase/supabase.dart';

import '../../services/ai/intent_parser.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/storage/hive_nimmy_repository.dart';
import '../../services/storage/in_memory_nimmy_repository.dart';
import '../../services/storage/nimmy_repository.dart';
import '../../services/storage/offline_first_nimmy_repository.dart';
import '../../services/storage/supabase_nimmy_repository.dart';
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
    NimmyRepository localRepository = HiveNimmyRepository();
    String? warning;
    try {
      await localRepository.initialize();
    } catch (_) {
      localRepository = InMemoryNimmyRepository();
      await localRepository.initialize();
      warning =
          'Local persistence is unavailable. Data will last for this session only.';
    }

    NimmyRepository repository = localRepository;
    var cloudConfigured = false;
    var userId = 'local-user';
    if (config.hasSupabaseConfiguration) {
      try {
        final client = SupabaseClient(
          config.supabaseUrl,
          config.supabaseAnonKey,
        );
        if (client.auth.currentUser != null) {
          final remote = SupabaseNimmyRepository(client);
          await remote.initialize();
          final offlineFirst = OfflineFirstNimmyRepository(
            local: localRepository,
            remote: remote,
          );
          await offlineFirst.synchronize();
          repository = offlineFirst;
          cloudConfigured = true;
          userId = remote.profileId;
        } else {
          warning ??=
              'Cloud is configured, but sign-in is required before sync.';
        }
      } catch (_) {
        warning ??= 'Cloud sync is unavailable. Nimmy is using local storage.';
      }
    }

    ReminderScheduler scheduler = NativeReminderScheduler(
      configuredTimezone: config.defaultTimezone,
    );
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
      userId: userId,
    );
    final controller = NimmyController(
      repository: repository,
      intentParser: parser,
      toolRegistry: toolRegistry,
      cloudConfigured: cloudConfigured,
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
