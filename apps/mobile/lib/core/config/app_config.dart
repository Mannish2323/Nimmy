class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.aiBaseUrl,
    required this.defaultTimezone,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      aiBaseUrl: String.fromEnvironment(
        'NIMMY_AI_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000',
      ),
      defaultTimezone: String.fromEnvironment(
        'NIMMY_TIMEZONE',
        defaultValue: 'UTC',
      ),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String aiBaseUrl;
  final String defaultTimezone;

  bool get hasSupabaseConfiguration =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
