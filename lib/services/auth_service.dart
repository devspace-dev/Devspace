import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  static const bool _enforceCollegeDomain = false;

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('auth_uid');
    if (uid != null) {
      _currentUser = await MongoService.instance.getUserById(uid);
      if (_currentUser == null) {
        await prefs.remove('auth_uid');
      }
    }
    _authStateController.add(_currentUser);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  bool _isAllowedEmail(String email) {
    if (!_enforceCollegeDomain) return true;
    return email.toLowerCase().endsWith('@$_collegeDomain');
  }

  String _buildAvatar(String name, String email) {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      final parts = trimmedName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
      if (initials.isNotEmpty) return initials;
    }

    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'DS';
    final cleaned = localPart.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.isEmpty) return 'DS';
    return cleaned.substring(0, cleaned.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _sanitizeHandleSeed(String value) {
    final sanitized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? 'devspace_user' : sanitized;
  }

  bool _looksLikeImageReference(String avatar) {
    return avatar.startsWith('http') ||
        avatar.contains('/') ||
        avatar.startsWith('data:');
  }

  Future<String> _generateUniqueHandle(String email) async {
    final base = _sanitizeHandleSeed(email.split('@').first);
    var candidate = base;
    var suffix = 1;

    while (await MongoService.instance.getUserByHandle(candidate) != null) {
      candidate = '${base}_$suffix';
      suffix += 1;
    }

    return candidate;
  }

  Future<void> _persistSession(UserModel user) async {
    _currentUser = user;
    _authStateController.add(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_uid', user.id);
  }

  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      if (!_isAllowedEmail(normalizedEmail)) {
        return AuthResult(error: 'Please use your @$_collegeDomain college email.');
      }

      final existing = await MongoService.instance.getUserByEmail(normalizedEmail);
      if (existing != null) {
        return const AuthResult(error: 'Email already in use.');
      }

      final handle = await _generateUniqueHandle(normalizedEmail);
      final passwordHash = _hashPassword(password);

      final user = await MongoService.instance.createUser(
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: passwordHash,
        handle: handle,
        avatar: _buildAvatar(name, normalizedEmail),
        role: 'Student',
        year: '',
        branch: '',
        building: '',
        stack: const [],
        bio: '',
        college: 'Jaipur National University',
        githubHandle: '',
        profileCompleted: false,
      );

      await _persistSession(user);
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
      final normalizedEmail = email.trim().toLowerCase();
      final passwordHash = _hashPassword(password);
      final isValid = await MongoService.instance.verifyPassword(
        normalizedEmail,
        passwordHash,
      );
      if (!isValid) {
        return const AuthResult(error: 'Invalid email or password.');
      }

      final user = await MongoService.instance.getUserByEmail(normalizedEmail);
      if (user == null) {
        return const AuthResult(error: 'User not found.');
      }

      await _persistSession(user);
      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: 'Sign-in failed: $e');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const AuthResult(error: 'Google sign-in was cancelled.');
      }

      final email = account.email.trim().toLowerCase();
      if (!_isAllowedEmail(email)) {
        await _googleSignIn.signOut();
        return AuthResult(error: 'Please use your @$_collegeDomain college email.');
      }

      var user = await MongoService.instance.getUserByEmail(email);
      user ??= await MongoService.instance.createUser(
        name: (account.displayName?.trim().isNotEmpty ?? false)
            ? account.displayName!.trim()
            : email.split('@').first,
        email: email,
        handle: await _generateUniqueHandle(email),
        avatar: _buildAvatar(account.displayName ?? '', email),
        role: 'Student',
        year: '',
        branch: '',
        building: '',
        stack: const [],
        bio: '',
        college: 'Jaipur National University',
        githubHandle: '',
        profileCompleted: false,
      );

      await _persistSession(user);
      return AuthResult(user: user);
    } catch (e) {
      return AuthResult(error: 'Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore local Google session cleanup failures.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_uid');
  }

  Future<AuthResult> updateCurrentUserProfile({
    required String name,
    required String handle,
    required String role,
    required String year,
    required String branch,
    required String building,
    required List<String> stack,
    required String college,
    String bio = '',
    String githubHandle = '',
    String? avatar,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const AuthResult(error: 'No authenticated user.');
    }

    try {
      final normalizedHandle = _sanitizeHandleSeed(handle);
      final existingHandleUser =
          await MongoService.instance.getUserByHandle(normalizedHandle);
      if (existingHandleUser != null && existingHandleUser.id != user.id) {
        return const AuthResult(error: 'That handle is already taken.');
      }

      final trimmedName = name.trim();
      final trimmedBuilding = building.trim();
      final trimmedBio = bio.trim();
      final trimmedGithub = githubHandle.trim();
      final nextAvatar = (avatar != null && avatar.trim().isNotEmpty)
          ? avatar.trim()
          : (_looksLikeImageReference(user.avatar)
              ? user.avatar
              : _buildAvatar(trimmedName, user.email));

      await MongoService.instance.updateUser(user.id, {
        'name': trimmedName,
        'handle': normalizedHandle,
        'role': role,
        'year': year,
        'branch': branch,
        'building': trimmedBuilding,
        'stack': stack,
        'bio': trimmedBio,
        'college': college,
        'githubHandle': trimmedGithub,
        'profileCompleted': true,
        'avatar': nextAvatar,
      });

      final refreshedUser = await MongoService.instance.getUserById(user.id);
      if (refreshedUser == null) {
        return const AuthResult(error: 'Failed to refresh updated profile.');
      }

      await _persistSession(refreshedUser);
      return AuthResult(user: refreshedUser);
    } catch (e) {
      return AuthResult(error: 'Profile update failed: $e');
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
