import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    String? url;
    String? key;

    // 1. Try loading from .env.local.json asset
    try {
      final content = await rootBundle.loadString('.env.local.json');
      final json = jsonDecode(content) as Map<String, dynamic>;
      url = json['SUPABASE_URL'] as String?;
      key = json['SUPABASE_ANON_KEY'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('Note: .env.local.json asset not found or empty: $e');
    }

    // 2. Try loading from .env file (handled by flutter_dotenv using rootBundle)
    if (url == null || key == null || url.isEmpty || key.isEmpty) {
      try {
        await dotenv.load(fileName: ".env");
        url = (url == null || url.isEmpty) ? dotenv.env['SUPABASE_URL'] : url;
        key = (key == null || key.isEmpty) ? dotenv.env['SUPABASE_ANON_KEY'] : key;
      } catch (e) {
        if (kDebugMode) debugPrint('Warning: .env file not found or failed to load: $e');
      }
    }

    // 3. Try from environment variables (--dart-define)
    url ??= const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    key ??= const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    return _instance = RuntimeConfig._(
      supabaseUrl: url,
      supabaseAnonKey: key,
    );
  }
}
