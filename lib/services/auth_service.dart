import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mongo_service.dart';
import '../models/user_model.dart';

class AuthResult {
  final UserModel? user;
  final String? error;
  bool get success => user != null && error == null;
  const AuthResult({this.user, this.error});
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const String _collegeDomain = 'mnit.ac.in'; // customize
  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('auth_uid');
    if (uid != null) {
      _currentUser = await MongoService.instance.getUserById(uid);
      _authStateController.add(_currentUser);
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (!email.toLowerCase().endsWith('@$_collegeDomain')) {
        return AuthResult(error: 'Please use your @$_collegeDomain college email.');
      }

      final existing = await MongoService.instance.getUserByEmail(email);
      if (existing != null) {
        return const AuthResult(error: 'Email already in use.');
      }

      final handle = email.split('@').first.replaceAll('.', '_').toLowerCase();
      final passwordHash = _hashPassword(password);

      final user = await MongoService.instance.createUser(
        name: name,
        email: email,
        passwordHash: passwordHash,
        handle: handle,
        college: 'MNIT Jaipur',
      );

      _currentUser = user;
      _authStateController.add(user);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', user.id);

      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: 'Sign-up failed: $e');
    }
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final passwordHash = _hashPassword(password);
      final isValid = await MongoService.instance.verifyPassword(email, passwordHash);
      if (!isValid) {
        return const AuthResult(error: 'Invalid email or password.');
      }

      final user = await MongoService.instance.getUserByEmail(email);
      if (user == null) {
        return const AuthResult(error: 'User not found.');
      }

      _currentUser = user;
      _authStateController.add(user);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', user.id);

      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: 'Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_uid');
  }

  void dispose() {
    _authStateController.close();
  }
}
