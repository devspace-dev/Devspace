import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    // CRITICAL: Return the full session JSON string, not just the token.
    // This allows Supabase to recover the refresh_token and maintain the session.
    return await _storage.read(key: 'supabase_session');
  }

  @override
  Future<bool> hasAccessToken() async {
    final data = await _storage.read(key: 'supabase_session');
    return data != null;
  }

  @override
  Future<void> persistSession(String session) async {
    await _storage.write(key: 'supabase_session', value: session);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: 'supabase_session');
  }
}
