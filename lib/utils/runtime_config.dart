// Runtime configuration resolved from compile-time --dart-define values.

class RuntimeConfig {
  RuntimeConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  static RuntimeConfig? _instance;

  static RuntimeConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('RuntimeConfig has not been initialized yet.');
    }
    return config;
  }

  static Future<RuntimeConfig> load() async {
    // Resolved exclusively from compile-time --dart-define or --dart-define-from-file=.env.local.json
    const definedUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const definedKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );

    String url = definedUrl.trim();
    String key = definedKey.trim();

    return _instance = RuntimeConfig._(
      supabaseUrl: url,
      supabaseAnonKey: key,
    );
  }
}
