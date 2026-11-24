import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/ds_tag.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../features/profile/screens/profile_screen.dart';

enum ConnectionListType { followers, following }

class ConnectionsScreen extends StatefulWidget {
  final UserModel user;
  final ConnectionListType type;

  const ConnectionsScreen({
    super.key,
    required this.user,
    required this.type,
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  static const int _pageSize = 30;

  late ConnectionListType _activeType;
  final ScrollController _scrollController = ScrollController();

  List<UserModel> _users = [];
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  final Set<String> _togglingUserIds = {};
  late int _followersCount;
  late int _followingCount;

  static String _getRankTag(int aura) {
    if (aura >= 5000) return '10x Dev';
    if (aura >= 1500) return 'SO Survivor';
    if (aura >= 500) return 'Bug Hunter';
    return 'Rookie';
  }

  @override
  void initState() {
    super.initState();
    _activeType = widget.type;
    _followersCount = widget.user.followers;
    _followingCount = widget.user.following;

    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoadingInitial) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
      _hasMore = true;
      _users = [];
    });

    final currentViewerId = context.read<AuthProvider>().currentUserOrNull?.id;

    try {
      final fetched = await SupabaseService.instance.getConnectionUsersPaginated(
        targetUserId: widget.user.id,
        isFollowers: _activeType == ConnectionListType.followers,
        currentViewerId: currentViewerId,
        limit: _pageSize,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _users = fetched;
          _isLoadingInitial = false;
          _hasMore = fetched.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final currentViewerId = context.read<AuthProvider>().currentUserOrNull?.id;

    try {
      final fetched = await SupabaseService.instance.getConnectionUsersPaginated(
        targetUserId: widget.user.id,
        isFollowers: _activeType == ConnectionListType.followers,
        currentViewerId: currentViewerId,
        limit: _pageSize,
        offset: _users.length,
      );

      if (mounted) {
        setState(() {
          _users.addAll(fetched);
          _isLoadingMore = false;
          _hasMore = fetched.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _handleToggleFollow(UserModel user) async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null || me.id == user.id) return;
    if (_togglingUserIds.contains(user.id)) return;

    setState(() {
      _togglingUserIds.add(user.id);
    });

    final wasFollowing = user.isFollowing;
    final newFollowing = !wasFollowing;

    // Optimistically update list row
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      setState(() {
        _users[index] = user.copyWith(
          isFollowing: newFollowing,
          followers: newFollowing
              ? user.followers + 1
              : (user.followers > 0 ? user.followers - 1 : 0),
        );
      });
    }

    try {
      await context.read<UsersProvider>().toggleFollow(
        me.id,
        user.id,
        currentIsFollowing: wasFollowing,
      );

      // Keep counts in sync
      if (widget.user.id == me.id && _activeType == ConnectionListType.following) {
        setState(() {
          _followingCount = newFollowing
              ? _followingCount + 1
              : (_followingCount > 0 ? _followingCount - 1 : 0);
        });
      }
    } catch (e) {
      if (index != -1 && mounted) {
        setState(() {
          _users[index] = user.copyWith(isFollowing: wasFollowing);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow: $e', style: DsText.caption),
            backgroundColor: Ds.hot,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _togglingUserIds.remove(user.id);
        });
      }
    }
  }

  Future<void> _syncUserFollowStatus(String userId) async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null) return;
    try {
      final followingIds = await SupabaseService.instance.getFollowingIds(me.id);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1 && mounted) {
        setState(() {
          _users[index] = _users[index].copyWith(
            isFollowing: followingIds.contains(userId),
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final title = _activeType == ConnectionListType.followers ? 'Followers' : 'Following';

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Ds.bone),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(title, style: DsText.h3),
      ),
      body: Column(
        children: [
          // Top Segment / Mode Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Ds.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Ds.border),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    title: 'Followers',
                    count: _followersCount,
                    isSelected: _activeType == ConnectionListType.followers,
                    onTap: () {
                      if (_activeType != ConnectionListType.followers) {
                        setState(() => _activeType = ConnectionListType.followers);
                        _loadInitial();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    title: 'Following',
                    count: _followingCount,
                    isSelected: _activeType == ConnectionListType.following,
                    onTap: () {
                      if (_activeType != ConnectionListType.following) {
                        setState(() => _activeType = ConnectionListType.following);
                        _loadInitial();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content List
          Expanded(
            child: _buildBody(me),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(UserModel? me) {
    if (_isLoadingInitial) {
      return _buildSkeletonList();
    }

    if (_errorMessage != null && _users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Ds.hot),
              const SizedBox(height: 16),
              Text('Unable to load network', style: DsText.h3),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: DsText.bodySm.copyWith(color: Ds.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DsButton(
                label: 'Retry',
                kind: DsButtonKind.bone,
                onPressed: _loadInitial,
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      final isFollowers = _activeType == ConnectionListType.followers;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Ds.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Ds.border),
                ),
                child: Icon(
                  isFollowers ? Icons.people_outline_rounded : Icons.person_search_rounded,
                  size: 32,
                  color: Ds.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFollowers ? 'No followers yet' : 'Not following anyone yet',
                style: DsText.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isFollowers
                    ? 'When developers follow this profile, they will appear here.'
                    : 'Developers followed by this profile will appear here.',
                style: DsText.bodySm.copyWith(color: Ds.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      color: Ds.aura,
      backgroundColor: Ds.surface,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _users.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1, color: Ds.border),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Ds.aura, strokeWidth: 2),
                ),
              ),
            );
          }

          final user = _users[index];
          return _ConnectionUserRow(
            user: user,
            isCurrentUser: me?.id == user.id,
            isToggling: _togglingUserIds.contains(user.id),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: user.id),
                ),
              ).then((_) {
                _syncUserFollowStatus(user.id);
              });
            },
            onToggleFollow: () => _handleToggleFollow(user),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Ds.border),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Ds.surface,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Ds.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Ds.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 76,
              height: 30,
              decoration: BoxDecoration(
                color: Ds.surface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Ds.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: DsText.caption.copyWith(
                color: isSelected ? Ds.bone : Ds.muted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Ds.border : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: DsText.caption.copyWith(
                  color: isSelected ? Ds.aura : Ds.muted,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionUserRow extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final bool isToggling;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;

  const _ConnectionUserRow({
    required this.user,
    required this.isCurrentUser,
    required this.isToggling,
    required this.onTap,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final rankTag = _ConnectionsScreenState._getRankTag(user.aura);
    final academic = user.academicLabel;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 44px Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Ds.border, width: 1.5),
              ),
              child: ClipOval(
                child: user.isImageAvatar && user.avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: StorageService.instance.resolvePublicUrl(user.avatar),
                        fit: BoxFit.cover,
                        memCacheWidth: 132,
                        memCacheHeight: 132,
                        placeholder: (_, __) => Container(color: Ds.surface),
                        errorWidget: (_, __, ___) => _fallbackAvatar(),
                      )
                    : _fallbackAvatar(),
              ),
            ),
            const SizedBox(width: 12),

            // Name, Handle, Rank Tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: DsText.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      DsTag(rankTag, bg: Ds.aura, fg: Ds.onAura),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${user.handle}${academic.isNotEmpty ? " · $academic" : ""}',
                    style: DsText.caption.copyWith(color: Ds.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Follow / Following Action Button
            if (!isCurrentUser)
              isToggling
                  ? const SizedBox(
                      width: 82,
                      height: 32,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Ds.aura, strokeWidth: 2),
                        ),
                      ),
                    )
                  : user.isFollowing
                      ? OutlinedButton(
                          onPressed: onToggleFollow,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Ds.border),
                            backgroundColor: Ds.surface,
                            foregroundColor: Ds.bone,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(82, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Following',
                            style: DsText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Ds.bone,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: onToggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Ds.aura,
                            foregroundColor: Ds.onAura,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(82, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Follow',
                            style: DsText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Ds.onAura,
                            ),
                          ),
                        ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    final initials = user.avatar.isNotEmpty && !user.isImageAvatar
        ? user.avatar
        : (user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U');
    return Container(
      color: Ds.surface,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: DsText.label.copyWith(color: Ds.bone),
      ),
    );
  }
}
