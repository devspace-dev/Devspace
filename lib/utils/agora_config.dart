import 'package:flutter_dotenv/flutter_dotenv.dart';

class AgoraConfig {
  static String get appId =>
      dotenv.env['AGORA_APP_ID'] ??
      const String.fromEnvironment('AGORA_APP_ID', defaultValue: '');
}

