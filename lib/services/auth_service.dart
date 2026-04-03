import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'supabase_service.dart';
import 'analytics_service.dart';
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

  static const String _collegeDomain = 'mnit.ac.in';
  final SupabaseClient _supabase = Supabase.instance.client;
  final bool _enforceCollegeDomain = true;
  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  String _friendlySignUpError(AuthException e) {
    if (e is AuthApiException) {
      if (e.code == 'over_email_send_rate_limit') {
        return 'Supabase email confirmation is rate-limited right now. Wait about a minute before retrying, or disable "Confirm email" in Supabase for testing.';
      }

      if (e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already registered')) {
        return 'This email is already registered. If you already confirmed it, switch to Sign in.';
      }
    }

    return 'Sign-up failed: ${e.message}';
  }

  String _friendlySignInError(AuthException e) {
    if (e is AuthApiException &&
        (e.code == 'email_not_confirmed' ||
            e.message.toLowerCase().contains('email not confirmed'))) {
      return 'Confirm your email first, then sign in.';
    }

    return 'Sign-in failed: ${e.message}';
  }

  String? _friendlyDatabaseError(Object error) {
    if (error is PostgrestException && error.code == 'PGRST204') {
      return 'Supabase schema is incomplete. Run supabase/devspace_schema.sql in the Supabase SQL editor, then retry sign in.';
    }

    return null;
  }

  Future<void> init() async {
    // Check current session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = await _loadOrCreateProfile(session.user);
      _authStateController.add(_currentUser);
    }

    // Listen to auth changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (session != null) {
          _currentUser = await _loadOrCreateProfile(session.user);
          _authStateController.add(_currentUser);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _authStateController.add(null);
      }
    });
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

    while (await SupabaseService.instance.getUserByHandle(candidate) != null) {
      candidate = '${base}_$suffix';
      suffix += 1;
    }

    return candidate;
  }

  String _fallbackName(User user) {
    final metadata = user.userMetadata;
    final fullName = metadata?['full_name'] ?? metadata?['name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final email = user.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first.trim();
    }

    return 'DevSpace Student';
  }

  Future<UserModel?> _loadOrCreateProfile(User user) async {
    final existing = await SupabaseService.instance.getUserById(user.id);
    if (existing != null) return existing;

    final email = user.email ?? '';
    final name = _fallbackName(user);
    final handle = await _generateUniqueHandle(
      email.isNotEmpty ? email : user.id,
    );

    await SupabaseService.instance.createUser(
      id: user.id,
      name: name,
      email: email,
      handle: handle,
      avatar: _buildAvatar(name, email),
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

    return SupabaseService.instance.getUserById(user.id);
  }

  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (!_isAllowedEmail(email)) {
        return const AuthResult(
            error: 'Please use your @$_collegeDomain college email.');
      }

      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      final user = res.user;
      if (user == null) return const AuthResult(error: 'Sign-up failed.');

      if (res.session == null && user.emailConfirmedAt == null) {
        return const AuthResult(
          error:
              'Account created, but email confirmation is enabled for this Supabase project. For testing, disable "Confirm email" in Supabase Auth settings. Otherwise confirm the email, then sign in.',
        );
      }

      _currentUser = await _loadOrCreateProfile(user);
      _authStateController.add(_currentUser);

      AnalyticsService.instance.logSignUp('email');
      if (_currentUser != null) {
        AnalyticsService.instance.setUserIdentifier(_currentUser!.id);
      }

      return AuthResult(user: _currentUser);
    } on AuthException catch (e) {
      return AuthResult(error: _friendlySignUpError(e));
    } on PostgrestException catch (e) {
      return AuthResult(
        error: _friendlyDatabaseError(e) ?? 'Sign-up failed: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        error: _friendlyDatabaseError(e) ?? 'Sign-up failed: $e',
      );
    }
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) return const AuthResult(error: 'User not found.');

      _currentUser = await _loadOrCreateProfile(user);
      _authStateController.add(_currentUser);

      AnalyticsService.instance.logLogin('email');
      if (_currentUser != null) {
        AnalyticsService.instance.setUserIdentifier(_currentUser!.id);
      }

      return AuthResult(user: _currentUser);
    } on AuthException catch (e) {
      return AuthResult(error: _friendlySignInError(e));
    } on PostgrestException catch (e) {
      return AuthResult(
        error: _friendlyDatabaseError(e) ?? 'Sign-in failed: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        error: _friendlyDatabaseError(e) ?? 'Sign-in failed: $e',
      );
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return const AuthResult(error: 'Google sign-in cancelled.');

      if (!_isAllowedEmail(googleUser.email)) {
        await googleSignIn.signOut();
        return const AuthResult(
            error: 'Please use your @$_collegeDomain college email.');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        return const AuthResult(error: 'Google authentication failed.');
      }

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = res.user;
      if (user == null) return const AuthResult(error: 'Google sign-in failed.');

      _currentUser = await _loadOrCreateProfile(user);
      _authStateController.add(_currentUser);

      AnalyticsService.instance.logLogin('google');
      if (_currentUser != null) {
        AnalyticsService.instance.setUserIdentifier(_currentUser!.id);
      }

      return AuthResult(user: _currentUser);
    } on AuthException catch (e) {
      return AuthResult(error: _friendlySignInError(e));
    } catch (e) {
      return AuthResult(error: 'Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> refreshCurrentUser() async {
    final user = _currentUser;
    if (user == null) return;

    final refreshedUser = await SupabaseService.instance.getUserById(user.id);
    if (refreshedUser == null) return;

    _currentUser = refreshedUser;
    _authStateController.add(refreshedUser);
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
          await SupabaseService.instance.getUserByHandle(normalizedHandle);
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

      await SupabaseService.instance.updateUser(user.id, {
        'name': trimmedName,
        'handle': normalizedHandle,
        'role': role,
        'year': year,
        'branch': branch,
        'building': trimmedBuilding,
        'stack': stack,
        'bio': trimmedBio,
        'college': college,
        'github_handle': trimmedGithub,
        'profile_completed': true,
        'avatar': nextAvatar,
      });

      final refreshedUser = await SupabaseService.instance.getUserById(user.id);
      if (refreshedUser == null) {
        return const AuthResult(error: 'Failed to refresh updated profile.');
      }

      _currentUser = refreshedUser;
      _authStateController.add(refreshedUser);
      return AuthResult(user: refreshedUser);
    } catch (e) {
      return AuthResult(error: 'Profile update failed: $e');
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
