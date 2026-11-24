class RuntimeConfig {
  RuntimeConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.googleWebClientId = '',
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;

  static RuntimeConfig? _instance;

  static RuntimeConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('RuntimeConfig has not been initialized yet.');
    }
    return config;
  }

  static Future<RuntimeConfig> load() async {
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const key = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    const googleClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );

    return _instance = RuntimeConfig._(
      supabaseUrl: url.trim(),
      supabaseAnonKey: key.trim(),
      googleWebClientId: googleClientId.trim(),
    );
  }
}
