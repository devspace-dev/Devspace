import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/mock_users.dart';

class UsersProvider extends ChangeNotifier {
  final List<UserModel> _users = List.from(kUsers);

  List<UserModel> get users => List.unmodifiable(_users);

  UserModel? getUserById(int id) {
    if (id == kMe.id) return kMe;
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  void toggleFollow(int userId) {
    final i = _users.indexWhere((u) => u.id == userId);
    if (i < 0) return;
    final u = _users[i];
    _users[i] = u.copyWith(
      isFollowing: !u.isFollowing,
      followers: u.isFollowing ? u.followers - 1 : u.followers + 1,
    );
    notifyListeners();
  }

  List<UserModel> search(String query) {
    if (query.isEmpty) return _users;
    final q = query.toLowerCase();
    return _users.where((u) =>
      u.name.toLowerCase().contains(q) ||
      u.handle.toLowerCase().contains(q) ||
      u.building.toLowerCase().contains(q) ||
      u.stack.any((s) => s.toLowerCase().contains(q))
    ).toList();
  }

  List<UserModel> filterByBranch(String branch) {
    if (branch == 'All') return _users;
    return _users.where((u) => u.year.contains(branch)).toList();
  }

  List<UserModel> get leaderboard {
    final sorted = List<UserModel>.from(_users);
    sorted.sort((a, b) => b.aura.compareTo(a.aura));
    return sorted;
  }
}
