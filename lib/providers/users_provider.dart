import 'dart:async';

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class UsersProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;
  StreamSubscription<List<UserModel>>? _usersSub;

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    if (_usersSub != null) {
      await _usersSub!.cancel();
    }
    _isLoading = true;
    notifyListeners();
    _usersSub = SupabaseService.instance.streamUsers().listen((newList) async {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        _users = newList;
      } else {
        final followingIds =
            await SupabaseService.instance.getFollowingIds(currentUser.id);
        _users = newList
            .map(
              (user) => user.copyWith(
                isFollowing: followingIds.contains(user.id),
              ),
            )
            .toList();
      }
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
    final userIndex = _users.indexWhere((user) => user.id == toUid);
    final existing = userIndex == -1 ? null : _users[userIndex];
    final isFollowing = existing?.isFollowing ?? false;

    if (existing != null) {
      _users[userIndex] = existing.copyWith(
        isFollowing: !isFollowing,
        followers: !isFollowing
            ? existing.followers + 1
            : (existing.followers > 0 ? existing.followers - 1 : 0),
      );
      notifyListeners();
    }

    try {
      if (isFollowing) {
        await SupabaseService.instance.unfollow(fromUid, toUid);
      } else {
        await SupabaseService.instance.follow(fromUid, toUid);
      }
    } catch (_) {
      if (existing != null) {
        _users[userIndex] = existing;
        notifyListeners();
      }
    }
  }

  List<UserModel> search(String query) {
    if (query.isEmpty) return _users;
    final q = query.toLowerCase();
    return _users.where((u) =>
      u.name.toLowerCase().contains(q) ||
      u.handle.toLowerCase().contains(q) ||
      u.branch.toLowerCase().contains(q) ||
      u.building.toLowerCase().contains(q) ||
      u.role.toLowerCase().contains(q) ||
      u.stack.any((s) => s.toLowerCase().contains(q))
    ).toList();
  }

  List<UserModel> filterByBranch(String branch) {
    if (branch == 'All') return _users;
    return _users.where((u) => u.branch == branch).toList();
  }

  List<UserModel> get leaderboard {
    final sorted = List<UserModel>.from(_users);
    sorted.sort((a, b) => b.aura.compareTo(a.aura));
    return sorted;
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
