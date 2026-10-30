import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({UserModel? initialUser, bool listenToAuthChanges = true}) {
    _currentUser = initialUser;
    if (listenToAuthChanges) {
      try {
        _currentUser ??= AuthService.instance.currentUser;
        _authSub = AuthService.instance.authStateChanges.listen((user) {
          _currentUser = user;
          notifyListeners();
        });
      } catch (_) {
        // Safe fallback in test environments where Supabase is not initialized
      }
    }
  }

  UserModel? _currentUser;
  StreamSubscription<UserModel?>? _authSub;

  UserModel? get currentUserOrNull {
    if (_currentUser != null) return _currentUser;
    try {
      return AuthService.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  UserModel get currentUser {
    final user = currentUserOrNull;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }
    return user;
  }

  void updateLocalAura(int newAura) {
    final user = currentUserOrNull;
    if (user != null && user.aura != newAura) {
      _currentUser = user.copyWith(aura: newAura);
      notifyListeners();
    }
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
    final result = await AuthService.instance.updateCurrentUserProfile(
      name: name,
      handle: handle,
      roles: roles,
      year: year,
      branch: branch,
      building: building,
      stack: stack,
      college: college,
      bio: bio,
      githubHandle: githubHandle,
      avatar: avatar,
    );
    if (result.user != null) {
      _currentUser = result.user;
      notifyListeners();
    }
    return result;
  }

  Future<void> refreshUsers() async {
    await AuthService.instance.refreshCurrentUser();
    await SupabaseService.instance.getFollowingIds(currentUser.id);
    await SupabaseService.instance.getUserById(currentUser.id);
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
