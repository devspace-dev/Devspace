import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SECURITY: Using flutter_secure_storage ensures that auth tokens are stored 
// in a secure enclave (KeyChain on iOS, KeyStore on Android) rather than 
// plaintext SharedPreferences.
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    return null; // Not explicitly used for session storage in this way
  }

  @override
  Future<bool> hasAccessToken() async {
    return false; // Not explicitly used for session storage in this way
  }

  @override
  Future<void> persistSession(String session) async {
    await _storage.write(key: 'supabase_session', value: session);
  }

  @override
  Future<void> removeSession() async {
    await _storage.delete(key: 'supabase_session');
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: 'supabase_session');
  }

  @override
  Future<String?> session() async {
    return _storage.read(key: 'supabase_session');
  }
}
