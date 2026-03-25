import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/mock_users.dart';

class AuthProvider extends ChangeNotifier {
  UserModel _currentUser = kMe;

  UserModel get currentUser => _currentUser;

  void addAura(int points) {
    _currentUser = _currentUser.copyWith(aura: _currentUser.aura + points);
    notifyListeners();
  }

  void updateBuilding(String building) {
    _currentUser = UserModel(
      id: _currentUser.id, name: _currentUser.name,
      handle: _currentUser.handle, avatar: _currentUser.avatar,
      color: _currentUser.color, aura: _currentUser.aura,
      role: _currentUser.role, year: _currentUser.year,
      building: building, stack: _currentUser.stack,
      followers: _currentUser.followers, following: _currentUser.following,
      bio: _currentUser.bio, college: _currentUser.college,
    );
    notifyListeners();
  }
}
