import 'dart:async';

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

typedef UsersPageLoader = Future<List<UserModel>> Function({
  int limit,
  int offset,
  String? query,
});
typedef FollowToggleAction = Future<void> Function(String fromUid, String toUid);
typedef CurrentUserIdResolver = String? Function();

class UsersProvider extends ChangeNotifier {
  UsersProvider({
    List<UserModel>? initialUsers,
    UsersPageLoader? usersPageLoader,
    FollowToggleAction? followAction,
    FollowToggleAction? unfollowAction,
    CurrentUserIdResolver? currentUserIdResolver,
  })  : _usersPageLoader = usersPageLoader ?? _defaultUsersPageLoader,
        _followAction = followAction,
        _unfollowAction = unfollowAction,
        _currentUserIdResolver =
            currentUserIdResolver ?? _defaultCurrentUserIdResolver {
    if (initialUsers != null) {
      _users = List.from(initialUsers);
    }
    try {
      _authSub = AuthService.instance.authStateChanges.listen((user) {
        if (user != null) {
          updateUserInList(user);
        }
      });
    } catch (_) {
      // Safe fallback in test environments where Supabase is not initialized
    }
  }

  static Future<List<UserModel>> _defaultUsersPageLoader({
    int limit = 20,
    int offset = 0,
    String? query,
  }) {
    return SupabaseService.instance.getUsers(
      limit: limit,
      offset: offset,
      query: query,
    );
  }

  static String? _defaultCurrentUserIdResolver() {
    try {
      return AuthService.instance.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  final UsersPageLoader _usersPageLoader;
  final FollowToggleAction? _followAction;
  final FollowToggleAction? _unfollowAction;
  final CurrentUserIdResolver _currentUserIdResolver;
  StreamSubscription<UserModel?>? _authSub;
  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  final Map<String, bool> _followUpdating = {};
  final Map<String, String?> _followErrors = {};
  static const int _pageSize = 20;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool isFollowUpdating(String userId) => _followUpdating[userId] ?? false;
  String? followError(String userId) => _followErrors[userId];

  void updateUserInList(UserModel updatedUser) {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
    }
  }

  Future<void> fetchUsers({String? query}) async {
    if (!SupabaseService.instance.isSupabaseReady &&
        _usersPageLoader == _defaultUsersPageLoader &&
        _users.isNotEmpty &&
        (query == null || query.isEmpty)) {
      return;
    }
    _isLoading = true;
    _error = null;
    _hasMore = true;
    notifyListeners();

    try {
      final page = await _usersPageLoader(
        limit: _pageSize,
        offset: 0,
        query: query,
      );

      _users = await _hydrateUsers(page);
      _hasMore = page.length >= _pageSize;
      _error = null;
    } catch (e) {
      _error = 'Failed to load developers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsers() => fetchUsers();

  Future<void> loadMoreUsers({String? query}) async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final page = await _usersPageLoader(
        limit: _pageSize,
        offset: _users.length,
        query: query,
      );

      if (page.isEmpty) {
        _hasMore = false;
        return;
      }

      final hydratedPage = await _hydrateUsers(page);
      final existingIds = _users.map((u) => u.id).toSet();
      _users = [
        ..._users,
        ...hydratedPage.where((u) => !existingIds.contains(u.id)),
      ];
      _hasMore = page.length >= _pageSize;
      _error = null;
    } catch (e) {
      _error = 'Failed to load more developers: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Searches developers without overwriting the shared cached directory used by Feed.
  Future<List<UserModel>> searchDevelopers({
    String? query,
    int limit = 30,
    int offset = 0,
  }) async {
    final page = await _usersPageLoader(
      limit: limit,
      offset: offset,
      query: query,
    );
    final hydrated = await _hydrateUsers(page);
    if (hydrated.isNotEmpty) {
      final byId = {for (final u in _users) u.id: u};
      var changed = false;
      for (final user in hydrated) {
        if (!byId.containsKey(user.id)) {
          _users.add(user);
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    }
    return hydrated;
  }

  Future<List<UserModel>> _hydrateUsers(List<UserModel> users) async {
    final currentUserId = _currentUserIdResolver();
    if (currentUserId == null || currentUserId.isEmpty) return users;

    try {
      final followingIds =
          await SupabaseService.instance.getFollowingIds(currentUserId);
      return users
          .map((user) => _mergeHydratedUser(user, followingIds))
          .toList();
    } catch (_) {
      return users;
    }
  }

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
    final fetched = await SupabaseService.instance.getUserById(id);
    if (fetched != null && getUserById(id) == null) {
      _users.add(fetched);
      notifyListeners();
    }
    return fetched;
  }

  Future<void> fetchAndCacheUsers(List<String> ids) async {
    final uniqueIds = ids.toSet().toList();
    if (uniqueIds.isEmpty) return;
    
    final missingIds = uniqueIds.where((id) => getUserById(id) == null).toList();
    if (missingIds.isEmpty) return;

    try {
      final fetchedUsers = await SupabaseService.instance.getUsersByIds(missingIds);
      if (fetchedUsers.isNotEmpty) {
        final hydrated = await _hydrateUsers(fetchedUsers);
        
        final existingIds = _users.map((u) => u.id).toSet();
        final newUsers = hydrated.where((u) => !existingIds.contains(u.id)).toList();
        
        if (newUsers.isNotEmpty) {
          _users.addAll(newUsers);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to batch fetch users: $e');
    }
  }

  Future<void> toggleFollow(String fromUid, String toUid, {bool? currentIsFollowing}) async {
    if (fromUid == toUid || _followUpdating[toUid] == true) return;

    final userIndex = _users.indexWhere((user) => user.id == toUid);
    final existing = userIndex == -1 ? null : _users[userIndex];
    final isFollowing = currentIsFollowing ?? existing?.isFollowing ?? false;

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
        final unfollow = _unfollowAction ?? SupabaseService.instance.unfollow;
        await unfollow(fromUid, toUid);
      } else {
        final follow = _followAction ?? SupabaseService.instance.follow;
        await follow(fromUid, toUid);
      }
      if (_followAction == null && _unfollowAction == null) {
        await _refreshFollowState(fromUid, toUid);
      }
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

  static bool matchesQuery(UserModel u, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    final cleanQ =
        trimmed.startsWith('@') ? trimmed.substring(1).trim() : trimmed;
    if (cleanQ.isEmpty) return true;
    return u.name.toLowerCase().contains(cleanQ) ||
        u.handle.toLowerCase().contains(cleanQ) ||
        u.branch.toLowerCase().contains(cleanQ) ||
        u.building.toLowerCase().contains(cleanQ) ||
        u.role.toLowerCase().contains(cleanQ) ||
        u.stack.any((s) => s.toLowerCase().contains(cleanQ));
  }

  List<UserModel> search(String query) {
    if (query.trim().isEmpty) return _users;
    return _users.where((u) => matchesQuery(u, query)).toList();
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

    var targetFound = false;
    _users = _users.map((user) {
      if (user.id == targetUserId && refreshedTargetUser != null) {
        targetFound = true;
        return refreshedTargetUser.copyWith(
          isFollowing: followingIds.contains(targetUserId),
        );
      }
      if (user.id == currentUserId && refreshedCurrentUser != null) {
        return refreshedCurrentUser.copyWith(isFollowing: false);
      }
      if (user.id == targetUserId) {
        targetFound = true;
        return user.copyWith(isFollowing: followingIds.contains(targetUserId));
      }
      return user;
    }).toList();

    if (!targetFound && refreshedTargetUser != null) {
      _users.add(refreshedTargetUser.copyWith(
        isFollowing: followingIds.contains(targetUserId),
      ));
    }

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
}
