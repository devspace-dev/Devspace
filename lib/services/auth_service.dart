import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'supabase_service.dart';
import 'analytics_service.dart';
import '../models/user_model.dart';

class AuthResult {
  final UserModel? user;
  final String? error;
  final String? message;
  final bool pendingEmailConfirmation;

  bool get success => user != null && error == null;

  const AuthResult({
    this.user,
    this.error,
    this.message,
    this.pendingEmailConfirmation = false,
  });
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const String _collegeDomain = 'mnit.ac.in';
  final SupabaseClient _supabase = Supabase.instance.client;
  final bool _enforceCollegeDomain = false;
  bool _googleSignInInitialized = false;
  UserModel? _currentUser;
  StreamSubscription? _profileSub;
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

  String _friendlyGoogleError(Object error) {
    if (error is GoogleSignInException) {
      final details = '${error.code} ${error.description ?? ''}'.toLowerCase();
      if (details.contains('requestedscopes cannot be null or empty')) {
        return 'Google sign-in hit a local app bug while requesting tokens. Update to the latest app build and try again.';
      }
      if (details.contains('canceled')) {
        return 'Google sign-in was canceled.';
      }
    }

    if (error is PlatformException) {
      final details = '${error.code} ${error.message ?? ''}'.toLowerCase();
      if (details.contains('sign_in_failed') ||
          details.contains('developer_error') ||
          details.contains('10')) {
        return 'Google sign-in is not configured correctly yet. Verify Firebase/Google OAuth setup for this app package, add the Android SHA-1, enable Google in Supabase Auth, and only add --dart-define=GOOGLE_WEB_CLIENT_ID=... if you need an explicit web client ID override.';
      }
    }

    return 'Google sign-in failed: $error';
  }

  String _friendlyPhoneError(AuthException e) {
    if (e is AuthApiException) {
      final message = e.message.toLowerCase();
      if (message.contains('invalid phone')) {
        return 'Enter a valid phone number with country code, for example +919876543210.';
      }
      if (message.contains('otp') || message.contains('token')) {
        return 'The OTP is invalid or expired. Request a new code and try again.';
      }
      if (e.code == 'over_sms_send_rate_limit' ||
          message.contains('rate limit')) {
        return 'Too many OTP requests. Wait a minute before trying again.';
      }
    }

    return 'Phone login failed: ${e.message}';
  }

  String? _friendlyDatabaseError(Object error) {
    if (error is PostgrestException) {
      if (error.code == 'PGRST204') {
        return 'Supabase schema is incomplete. Run supabase/devspace_schema.sql in the Supabase SQL editor, then retry sign in.';
      }

      if (error.code == '42501') {
        return 'Supabase access policy blocked profile creation. Re-run supabase/devspace_schema.sql so the users table policies match the app.';
      }

      if (error.code == '23505' &&
          (error.message.contains('users_email_key') ||
              error.message.toLowerCase().contains('duplicate key value'))) {
        return 'That email already has an account. Sign in with the method you used before for this email, or delete the old account before using Google sign-in.';
      }

      if (error.message.contains('users_handle_length')) {
        return 'Handle must be between 3 and 25 characters.';
      }
    }

    return null;
  }

  Future<void> init() async {
    final completer = Completer<void>();
    bool firstEventFired = false;

    // Initialize Google Sign In (v7+)
    try {
      const webClientId =
          String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
      if (webClientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      } else {
        await GoogleSignIn.instance.initialize();
      }
      _googleSignInInitialized = true;
    } catch (e) {
      debugPrint('Google Sign In initialization failed: $e');
    }

    // 1. Listen to auth changes first so we catch the initial load
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.initialSession) {
        if (session != null) {
          try {
            _currentUser = await _loadOrCreateProfile(session.user);
          } catch (e) {
            debugPrint('Failed to load profile on auth change: $e');
          }
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _unsubscribeFromProfileChanges();
      }

      if (_currentUser != null) {
        _subscribeToProfileChanges(_currentUser!.id);
      }
      _authStateController.add(_currentUser);

      // Signal that initialization is complete after the first event
      if (!firstEventFired) {
        firstEventFired = true;
        if (!completer.isCompleted) completer.complete();
      }
    });

    // 2. Synchronous check for immediate session if already available
    final initialSession = _supabase.auth.currentSession;
    if (initialSession != null) {
      try {
        _currentUser = await _loadOrCreateProfile(initialSession.user);
        _authStateController.add(_currentUser);
      } catch (e) {
        debugPrint('Failed to load profile for initial session: $e');
      }
      if (!completer.isCompleted) {
        firstEventFired = true;
        completer.complete();
      }
    }

    // 3. Safety timeout if no auth event fires (e.g., no session)
    Future.delayed(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
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
      final initials =
          parts.take(2).map((part) => part[0].toUpperCase()).join();
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
    var base = _sanitizeHandleSeed(email.split('@').first);
    if (base.length < 3) {
      base = '${base}_ds';
    }
    if (base.length > 20) {
      base = base.substring(0, 20);
    }
    // Remove any trailing underscores that might result from truncation
    base = base.replaceAll(RegExp(r'_+$'), '');
    if (base.length < 3) {
      base = base.padRight(3, '0');
    }

    var candidate = base;
    var suffix = 1;

    while (await SupabaseService.instance.getUserByHandle(candidate) != null) {
      final suffixStr = '_$suffix';
      final maxBaseLength = 25 - suffixStr.length;
      var currentBase = base;
      if (currentBase.length > maxBaseLength) {
        currentBase = currentBase.substring(0, maxBaseLength).replaceAll(RegExp(r'_+$'), '');
        if (currentBase.length < 3) {
          currentBase = currentBase.padRight(3, '0');
        }
      }
      candidate = '$currentBase$suffixStr';
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

    final phone = user.phone ?? '';
    if (phone.isNotEmpty) {
      return 'DevSpace Student';
    }

    return 'DevSpace Student';
  }

  Future<UserModel?> _loadOrCreateProfile(User user) async {
    final existing = await SupabaseService.instance.getUserById(user.id);
    if (existing != null) return existing;

    final email = user.email ?? user.phone ?? '';
    if (email.isNotEmpty) {
      final existingByEmail = await SupabaseService.instance.getUserByEmail(
        email,
      );
      if (existingByEmail != null) {
        if (existingByEmail.id == user.id) {
          return existingByEmail;
        }

        throw PostgrestException(
          message:
              'A profile with this email already exists under a different auth account (users_email_key).',
          code: '23505',
        );
      }
    }

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
      roles: const ['Student'],
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
          message:
              'Account created. Check your email to confirm the account, then sign in. If you are testing only, you can disable "Confirm email" in Supabase Auth settings.',
          pendingEmailConfirmation: true,
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
      final googleSignIn = GoogleSignIn.instance;

      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await googleSignIn.authenticate();

      if (!_isAllowedEmail(googleUser.email)) {
        await googleSignIn.signOut();
        return const AuthResult(
            error: 'Please use your @$_collegeDomain college email.');
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      String? accessToken;
      try {
        final scopes = ['email', 'profile'];
        final authorization =
            await googleUser.authorizationClient.authorizationForScopes(scopes) ??
                await googleUser.authorizationClient.authorizeScopes(scopes);
        accessToken = authorization.accessToken;
      } catch (e) {
        debugPrint('Failed to get Google access token: $e');
      }

      if (idToken == null || idToken.isEmpty) {
        return const AuthResult(error: 'Google authentication failed.');
      }

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = res.user;
      if (user == null) {
        return const AuthResult(error: 'Google sign-in failed.');
      }

      _currentUser = await _loadOrCreateProfile(user);
      _authStateController.add(_currentUser);

      AnalyticsService.instance.logLogin('google');
      if (_currentUser != null) {
        AnalyticsService.instance.setUserIdentifier(_currentUser!.id);
      }

      return AuthResult(user: _currentUser);
    } on AuthException catch (e) {
      return AuthResult(error: _friendlySignInError(e));
    } on PostgrestException catch (e) {
      return AuthResult(
        error:
            _friendlyDatabaseError(e) ?? 'Google sign-in failed: ${e.message}',
      );
    } catch (e) {
      return AuthResult(error: _friendlyGoogleError(e));
    }
  }

  Future<AuthResult> sendPhoneOtp(String phone) async {
    try {
      final normalizedPhone = phone.trim();
      if (normalizedPhone.isEmpty || !normalizedPhone.startsWith('+')) {
        return const AuthResult(
          error: 'Enter phone number with country code, for example +919876543210.',
        );
      }

      await _supabase.auth.signInWithOtp(phone: normalizedPhone);
      return const AuthResult(message: 'OTP sent to your phone.');
    } on AuthException catch (e) {
      return AuthResult(error: _friendlyPhoneError(e));
    } catch (e) {
      return AuthResult(error: 'Failed to send OTP: $e');
    }
  }

  Future<AuthResult> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final normalizedPhone = phone.trim();
      final normalizedOtp = otp.trim();
      if (normalizedPhone.isEmpty || normalizedOtp.length < 4) {
        return const AuthResult(error: 'Enter the OTP sent to your phone.');
      }

      final AuthResponse res = await _supabase.auth.verifyOTP(
        phone: normalizedPhone,
        token: normalizedOtp,
        type: OtpType.sms,
      );

      final user = res.user;
      if (user == null) {
        return const AuthResult(error: 'Phone verification failed.');
      }

      _currentUser = await _loadOrCreateProfile(user);
      _authStateController.add(_currentUser);

      AnalyticsService.instance.logLogin('phone');
      if (_currentUser != null) {
        AnalyticsService.instance.setUserIdentifier(_currentUser!.id);
      }

      return AuthResult(user: _currentUser);
    } on AuthException catch (e) {
      return AuthResult(error: _friendlyPhoneError(e));
    } on PostgrestException catch (e) {
      return AuthResult(
        error:
            _friendlyDatabaseError(e) ?? 'Phone login failed: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        error: _friendlyDatabaseError(e) ?? 'Phone login failed: $e',
      );
    }
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return const AuthResult(message: 'Password reset email sent.');
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: 'Failed to send reset email: $e');
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleSignInInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint('Google Sign Out failed: $e');
    }
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
    required List<String> roles,
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
      if (normalizedHandle.length < 3 || normalizedHandle.length > 25) {
        return const AuthResult(error: 'Handle must be between 3 and 25 characters.');
      }
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
        'role': roles,
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

      // Sync GitHub aura if handle changed or is new
      if (trimmedGithub.isNotEmpty && (user.githubHandle != trimmedGithub)) {
        unawaited(SupabaseService.instance.syncGitHubAura(user.id, trimmedGithub));
      }

      // Synchronize identity metadata with Supabase Auth user record
      try {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'display_name': trimmedName,
              'avatar_url': nextAvatar,
            },
          ),
        );
      } catch (e) {
        debugPrint('Auth identity sync notice: $e');
      }

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

  void _subscribeToProfileChanges(String uid) {
    if (_profileSub != null) return;

    _profileSub = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .listen((data) {
          if (data.isNotEmpty) {
            _currentUser = UserModel.fromJson(data.first);
            _authStateController.add(_currentUser);
          }
        });
  }

  void _unsubscribeFromProfileChanges() {
    _profileSub?.cancel();
    _profileSub = null;
  }

  void dispose() {
    _unsubscribeFromProfileChanges();
    _authStateController.close();
  }
}
