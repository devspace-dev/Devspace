import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
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
  
  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  Future<void> init() async {
    // Check current session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = await SupabaseService.instance.getUserById(session.user.id);
      _authStateController.add(_currentUser);
    }

    // Listen to auth changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (session != null) {
          _currentUser = await SupabaseService.instance.getUserById(session.user.id);
          _authStateController.add(_currentUser);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _authStateController.add(null);
      }
    });
  }

  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (!email.toLowerCase().endsWith('@$_collegeDomain')) {
        return AuthResult(
            error: 'Please use your @$_collegeDomain college email.');
      }

      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      final user = res.user;
      if (user == null) return const AuthResult(error: 'Sign-up failed.');

      final handle = email.split('@').first.replaceAll('.', '_').toLowerCase();
      
      // Create user profile in public.users table
      await SupabaseService.instance.createUser(
        id: user.id,
        name: name,
        email: email,
        handle: handle,
        college: 'MNIT Jaipur',
      );

      _currentUser = await SupabaseService.instance.getUserById(user.id);
      _authStateController.add(_currentUser);

      return AuthResult(user: _currentUser);
    } catch (e) {
      return AuthResult(error: 'Sign-up failed: $e');
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

      _currentUser = await SupabaseService.instance.getUserById(user.id);
      _authStateController.add(_currentUser);

      return AuthResult(user: _currentUser);
    } catch (e) {
      return AuthResult(error: 'Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
