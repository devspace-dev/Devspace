import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _currentUser = AuthService.instance.currentUser;
    _authSub = AuthService.instance.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  UserModel? _currentUser;
  StreamSubscription<UserModel?>? _authSub;

  UserModel? get currentUserOrNull =>
      _currentUser ?? AuthService.instance.currentUser;

  UserModel get currentUser {
    final user = currentUserOrNull;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }
    return user;
  }

  void addAura(int points) {
    final updatedUser = currentUser.copyWith(aura: currentUser.aura + points);
    _currentUser = updatedUser;
    notifyListeners();
    unawaited(SupabaseService.instance.updateUser(
      updatedUser.id,
      {'aura': updatedUser.aura},
    ));
  }

  void updateBuilding(String building) {
    final updatedUser = currentUser.copyWith(building: building);
    _currentUser = updatedUser;
    notifyListeners();
    unawaited(SupabaseService.instance.updateUser(
      updatedUser.id,
      {'building': building},
    ));
  }

  Future<AuthResult> updateProfile({
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
    return AuthService.instance.updateCurrentUserProfile(
      name: name,
      handle: handle,
      role: role,
      year: year,
      branch: branch,
      building: building,
      stack: stack,
      college: college,
      bio: bio,
      githubHandle: githubHandle,
      avatar: avatar,
    );
  }

  Future<void> signOut() => AuthService.instance.signOut();

  Future<AuthResult> sendPasswordResetEmail(String email) =>
      AuthService.instance.sendPasswordResetEmail(email);

  Future<void> deleteAccount() async {
    await SupabaseService.instance.deleteAccount();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
