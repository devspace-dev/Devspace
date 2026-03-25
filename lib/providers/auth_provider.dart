import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/mongo_service.dart';

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

  UserModel get currentUser {
    final user = _currentUser ?? AuthService.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }
    return user;
  }

  void addAura(int points) {
    final updatedUser = currentUser.copyWith(aura: currentUser.aura + points);
    _currentUser = updatedUser;
    notifyListeners();
    unawaited(MongoService.instance.updateUser(
      updatedUser.id,
      {'aura': updatedUser.aura},
    ));
  }

  void updateBuilding(String building) {
    final updatedUser = currentUser.copyWith(building: building);
    _currentUser = updatedUser;
    notifyListeners();
    unawaited(MongoService.instance.updateUser(
      updatedUser.id,
      {'building': building},
    ));
  }

  Future<void> signOut() => AuthService.instance.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
