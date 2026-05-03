import 'dart:async';

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class UsersProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  final Map<String, bool> _followUpdating = {};
  final Map<String, String?> _followErrors = {};
  StreamSubscription<List<UserModel>>? _usersSub;

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isFollowUpdating(String userId) => _followUpdating[userId] ?? false;
  String? followError(String userId) => _followErrors[userId];

  Future<void> fetchUsers() async {
    if (_usersSub != null) {
      await _usersSub!.cancel();
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    final completer = Completer<void>();
    late final StreamSubscription<List<UserModel>> subscription;

    void completeOnce() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    subscription = SupabaseService.instance.streamUsers().listen(
      (newList) async {
        try {
          final currentUser = AuthService.instance.currentUser;
          if (currentUser == null) {
            _users = newList;
          } else {
            final followingIds =
                await SupabaseService.instance.getFollowingIds(currentUser.id);
            _users = newList
                .map((user) => _mergeHydratedUser(user, followingIds))
                .toList();
          }
          _error = null;
        } catch (e) {
          _error = 'Failed to load developers: $e';
        } finally {
          _isLoading = false;
          notifyListeners();
          completeOnce();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _error = 'Failed to load developers: $error';
        _isLoading = false;
        notifyListeners();
        completeOnce();
      },
    );

    _usersSub = subscription;
    await completer.future;
  }

  Future<void> refreshUsers() => fetchUsers();

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUser(String id) async {
    final existing = getUserById(id);
    if (existing != null) return existing;
    return await SupabaseService.instance.getUserById(id);
  }

  Future<void> toggleFollow(String fromUid, String toUid) async {
    if (fromUid == toUid || _followUpdating[toUid] == true) return;

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
      _adjustCurrentUserFollowingCount(fromUid, !isFollowing);
    }
    _followUpdating[toUid] = true;
    _followErrors[toUid] = null;
    notifyListeners();

    try {
      if (isFollowing) {
        await SupabaseService.instance.unfollow(fromUid, toUid);
      } else {
        await SupabaseService.instance.follow(fromUid, toUid);
      }
      await _refreshFollowState(fromUid, toUid);
    } catch (e) {
      if (existing != null) {
        _users[userIndex] = existing;
        _adjustCurrentUserFollowingCount(fromUid, isFollowing);
      }
      _followErrors[toUid] = 'Failed to update follow: $e';
    } finally {
      _followUpdating[toUid] = false;
      notifyListeners();
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

  Future<List<UserModel>> followersFor(String userId) async {
    return _fetchConnectionUsers(
      userId,
      loadIds: SupabaseService.instance.getFollowerIds,
    );
  }

  Future<List<UserModel>> followingFor(String userId) async {
    return _fetchConnectionUsers(
      userId,
      loadIds: SupabaseService.instance.getFollowingIdList,
    );
  }

  List<UserModel> get leaderboard {
    final sorted = List<UserModel>.from(_users);
    sorted.sort((a, b) => b.aura.compareTo(a.aura));
    return sorted;
  }

  List<UserModel> collegeLeaderboard(String college) {
    if (college.isEmpty) return leaderboard;
    final filtered = _users.where((u) => u.college == college).toList();
    filtered.sort((a, b) => b.aura.compareTo(a.aura));
    return filtered;
  }

  UserModel _mergeHydratedUser(UserModel hydratedUser, Set<String> followingIds) {
    final existingUser = _findUser(hydratedUser.id);
    if (existingUser == null) {
      return hydratedUser.copyWith(
        isFollowing: followingIds.contains(hydratedUser.id),
      );
    }

    if (_followUpdating[hydratedUser.id] == true) {
      return hydratedUser.copyWith(
        isFollowing: existingUser.isFollowing,
        followers: existingUser.followers,
      );
    }

    return hydratedUser.copyWith(
      isFollowing: followingIds.contains(hydratedUser.id),
    );
  }

  void _adjustCurrentUserFollowingCount(String currentUserId, bool isFollowing) {
    final currentUserIndex =
        _users.indexWhere((user) => user.id == currentUserId);
    if (currentUserIndex == -1) return;

    final currentUser = _users[currentUserIndex];
    final nextFollowing = isFollowing
        ? currentUser.following + 1
        : (currentUser.following > 0 ? currentUser.following - 1 : 0);

    _users[currentUserIndex] = currentUser.copyWith(following: nextFollowing);
  }

  Future<void> _refreshFollowState(String currentUserId, String targetUserId) async {
    final followingIds =
        await SupabaseService.instance.getFollowingIds(currentUserId);
    final refreshedTargetUser =
        await SupabaseService.instance.getUserById(targetUserId);
    final refreshedCurrentUser =
        await SupabaseService.instance.getUserById(currentUserId);

    _users = _users.map((user) {
      if (user.id == targetUserId && refreshedTargetUser != null) {
        return refreshedTargetUser.copyWith(
          isFollowing: followingIds.contains(targetUserId),
        );
      }
      if (user.id == currentUserId && refreshedCurrentUser != null) {
        return refreshedCurrentUser.copyWith(isFollowing: false);
      }
      if (user.id == targetUserId) {
        return user.copyWith(isFollowing: followingIds.contains(targetUserId));
      }
      return user;
    }).toList();

    _followErrors[targetUserId] = null;
    await AuthService.instance.refreshCurrentUser();
  }

  UserModel? _findUser(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserModel>> _fetchConnectionUsers(
    String userId, {
    required Future<List<String>> Function(String userId) loadIds,
  }) async {
    final ids = await loadIds(userId);
    if (ids.isEmpty) return const [];

    final currentUser = AuthService.instance.currentUser;
    final knownUsersById = {
      for (final user in _users)
        user.id: user,
    };

    List<UserModel> loadedUsers;
    final missingIds = ids.where((id) => !knownUsersById.containsKey(id)).toList();

    if (missingIds.isEmpty) {
      loadedUsers = ids
          .map((id) => knownUsersById[id])
          .whereType<UserModel>()
          .toList();
    } else {
      loadedUsers = await SupabaseService.instance.getUsersByIds(ids);
    }

    if (currentUser == null) {
      return loadedUsers;
    }

    final followingIds = await SupabaseService.instance.getFollowingIds(currentUser.id);
    return loadedUsers
        .map(
          (user) => user.copyWith(
            isFollowing: user.id != currentUser.id && followingIds.contains(user.id),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
