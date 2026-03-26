import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class UsersProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    SupabaseService.instance.streamUsers().listen((newList) {
      _users = newList;
      _isLoading = false;
      notifyListeners();
    });
  }

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleFollow(String fromUid, String toUid) async {
    final following = await SupabaseService.instance.isFollowing(fromUid, toUid);
    if (following) {
      await SupabaseService.instance.unfollow(fromUid, toUid);
    } else {
      await SupabaseService.instance.follow(fromUid, toUid);
    }
  }

  List<UserModel> search(String query) {
    if (query.isEmpty) return _users;
    final q = query.toLowerCase();
    return _users
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.handle.toLowerCase().contains(q) ||
            u.building.toLowerCase().contains(q) ||
            u.stack.any((s) => s.toLowerCase().contains(q)))
        .toList();
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
