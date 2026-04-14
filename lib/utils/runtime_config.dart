import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    // Load .env file
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Warning: .env file not found or failed to load: $e');
    }

    final url = dotenv.env['SUPABASE_URL'] ?? 
                const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? 
                const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    return _instance = RuntimeConfig._(
      supabaseUrl: url,
      supabaseAnonKey: key,
    );
  }
}
