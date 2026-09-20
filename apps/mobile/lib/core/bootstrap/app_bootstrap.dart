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
import '../../services/voice/wake_word_service.dart';
import '../native/nimmy_wake_word_platform.dart';
import '../config/app_config.dart';
import '../logging/nimmy_logger.dart';
import '../state/nimmy_controller.dart';

class AppBootstrap {
  AppBootstrap({
    required this.config,
    required this.controller,
    required this.voiceService,
    required this.permissionService,
    WakeWordService? wakeWordService,
    this.startupWarning,
  }) : wakeWordService =
           wakeWordService ??
           WakeWordService(platform: NimmyNativeWakeWordPlatform());

  final AppConfig config;
  final NimmyController controller;
  final VoiceService voiceService;
  final PermissionService permissionService;
  final WakeWordService wakeWordService;
  final String? startupWarning;

  static Future<AppBootstrap> create() async {
    NimmyLogger.info(
      'Starting Nimmy AppBootstrap...',
      category: LogCategory.system,
    );
    final config = AppConfig.fromEnvironment();
    NimmyRepository localRepository = HiveNimmyRepository();
    String? warning;
    try {
      await localRepository.initialize();
      NimmyLogger.info(
        'Local Hive repository initialized successfully',
        category: LogCategory.database,
      );
    } catch (e) {
      NimmyLogger.warn(
        'Local persistence unavailable, falling back to in-memory',
        category: LogCategory.database,
        error: e,
      );
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
          NimmyLogger.info(
            'Supabase cloud repository initialized',
            category: LogCategory.sync,
            context: {'userId': userId},
          );
        } else {
          warning ??=
              'Cloud is configured, but sign-in is required before sync.';
          NimmyLogger.info(
            'Supabase configured but user not signed in',
            category: LogCategory.sync,
          );
        }
      } catch (e) {
        warning ??= 'Cloud sync is unavailable. Nimmy is using local storage.';
        NimmyLogger.warn(
          'Cloud sync initialization failed',
          category: LogCategory.sync,
          error: e,
        );
      }
    } else {
      NimmyLogger.info(
        'App configured in local-only mode',
        category: LogCategory.system,
      );
    }

    ReminderScheduler scheduler = NativeReminderScheduler(
      configuredTimezone: config.defaultTimezone,
    );
    try {
      await scheduler.initialize();
      NimmyLogger.info(
        'Native reminder scheduler initialized',
        category: LogCategory.system,
      );
    } catch (e) {
      scheduler = NoopReminderScheduler();
      await scheduler.initialize();
      warning ??=
          'Notifications are unavailable. Reminders can still be saved locally.';
      NimmyLogger.warn(
        'Notification scheduler fallback to Noop',
        category: LogCategory.system,
        error: e,
      );
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

    NimmyLogger.info(
      'AppBootstrap complete',
      category: LogCategory.system,
      context: {
        'cloudConfigured': cloudConfigured,
        'hasWarning': warning != null,
      },
    );

    final wakeWordService = WakeWordService(
      platform: NimmyNativeWakeWordPlatform(),
    );
    await wakeWordService.initialize();

    return AppBootstrap(
      config: config,
      controller: controller,
      voiceService: VoiceService(),
      permissionService: PermissionService(),
      wakeWordService: wakeWordService,
      startupWarning: warning,
    );
  }
}
