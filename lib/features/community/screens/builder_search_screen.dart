import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/users_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../services/storage_service.dart';

class BuilderSearchScreen extends StatefulWidget {
  const BuilderSearchScreen({super.key});

  @override
  State<BuilderSearchScreen> createState() => _BuilderSearchScreenState();
}

class _BuilderSearchScreenState extends State<BuilderSearchScreen> {
  static const int _pageSize = 30;
  static const List<String> _popularStacks = [
    'Flutter',
    'Dart',
    'React',
    'Next.js',
    'Node.js',
    'Python',
    'TypeScript',
    'Go',
    'Rust',
    'Java',
    'Kotlin',
    'C++',
    'PostgreSQL',
    'Docker',
    'AI/ML',
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  final Set<String> _selectedStacks = {};
  List<UserModel> _remoteResults = [];
  bool _hasFetchedRemote = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final usersP = context.read<UsersProvider>();
      if (usersP.users.isEmpty) {
        _runRemoteSearch(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  static String _getRankTag(int aura) {
    if (aura >= 5000) return '10x Dev';
    if (aura >= 1500) return 'SO Survivor';
    if (aura >= 500) return 'Bug Hunter';
    return 'Rookie';
  }

  static Color _getTierColor(int aura) {
    if (aura >= 5000) return Ds.tierGem;
    if (aura >= 1500) return Ds.tierGold;
    if (aura >= 500) return Ds.tierSilver;
    return Ds.tierBronze;
  }

  String? get _effectiveRemoteQuery {
    final trimmed = _query.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (_selectedStacks.isNotEmpty) return _selectedStacks.first;
    return null;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _runRemoteSearch(reset: false);
      }
    }
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _runRemoteSearch(reset: true);
    });
  }

  void _toggleStack(String stack) {
    setState(() {
      if (_selectedStacks.contains(stack)) {
        _selectedStacks.remove(stack);
      } else {
        _selectedStacks.add(stack);
      }
    });
    _debounce?.cancel();
    _runRemoteSearch(reset: true);
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedStacks.clear();
    });
    _runRemoteSearch(reset: true);
  }

  Future<void> _runRemoteSearch({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _hasMore = true;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    final offset = reset ? 0 : _remoteResults.length;
    try {
      final fetched = await context.read<UsersProvider>().searchDevelopers(
            query: _effectiveRemoteQuery,
            limit: _pageSize,
            offset: offset,
          );
      if (!mounted) return;
      setState(() {
        _hasFetchedRemote = true;
        if (reset) {
          _remoteResults = fetched;
        } else {
          final seen = _remoteResults.map((u) => u.id).toSet();
          _remoteResults = [
            ..._remoteResults,
            ...fetched.where((u) => !seen.contains(u.id)),
          ];
        }
        _hasMore = fetched.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Failed to search builders: $e';
      });
    }
  }

  List<UserModel> _filteredUsers(UsersProvider usersP) {
    final mergedById = <String, UserModel>{};
    for (final u in usersP.users) {
      mergedById[u.id] = u;
    }
    for (final u in _remoteResults) {
      mergedById[u.id] = usersP.getUserById(u.id) ?? u;
    }

    final candidates = (_hasFetchedRemote && _effectiveRemoteQuery != null)
        ? mergedById.values.toList()
        : mergedById.values.toList();

    final filtered = candidates.where((u) {
      if (_selectedStacks.isNotEmpty) {
        final matchesAnyStack = _selectedStacks.any(
          (sel) => u.stack.any(
            (s) => s.trim().toLowerCase() == sel.trim().toLowerCase(),
          ),
        );
        if (!matchesAnyStack) return false;
      }
      if (_query.trim().isNotEmpty && !UsersProvider.matchesQuery(u, _query)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_selectedStacks.isNotEmpty) {
        final aCount = _selectedStacks
            .where(
              (sel) => a.stack.any(
                (s) => s.trim().toLowerCase() == sel.trim().toLowerCase(),
              ),
            )
            .length;
        final bCount = _selectedStacks
            .where(
              (sel) => b.stack.any(
                (s) => s.trim().toLowerCase() == sel.trim().toLowerCase(),
              ),
            )
            .length;
        if (aCount != bCount) return bCount.compareTo(aCount);
      }
      return b.aura.compareTo(a.aura);
    });

    return filtered;
  }

  Future<void> _handleToggleFollow(UserModel target) async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null || me.id == target.id) return;

    final usersP = context.read<UsersProvider>();
    await usersP.toggleFollow(
      me.id,
      target.id,
      currentIsFollowing: target.isFollowing,
    );

    if (!mounted) return;
    final err = usersP.followError(target.id);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: DsText.caption.copyWith(color: Ds.bone)),
          backgroundColor: Ds.hot,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final usersP = context.watch<UsersProvider>();
    final filtered = _filteredUsers(usersP);
    final hasFilters = _query.trim().isNotEmpty || _selectedStacks.isNotEmpty;

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Ds.bone,
          ),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Ds.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Ds.border, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Ds.muted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: DsText.bodySm.copyWith(color: Ds.bone),
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _runRemoteSearch(reset: true),
                    decoration: InputDecoration(
                      hintText: 'Search builders by name, @handle or stack',
                      hintStyle: DsText.bodySm.copyWith(color: Ds.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Ds.muted,
                      size: 18,
                    ),
                    tooltip: 'Clear search',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Stack Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount:
                  _popularStacks.length + (_selectedStacks.isNotEmpty ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (_selectedStacks.isNotEmpty && index == 0) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStacks.clear());
                      _runRemoteSearch(reset: true);
                    },
                    child: DsTag(
                      'Clear (${_selectedStacks.length})',
                      bg: Ds.border,
                      fg: Ds.bone,
                    ),
                  );
                }
                final stackIndex =
                    _selectedStacks.isNotEmpty ? index - 1 : index;
                final stack = _popularStacks[stackIndex];
                final isSelected = _selectedStacks.contains(stack);
                return GestureDetector(
                  onTap: () => _toggleStack(stack),
                  child: DsTag(
                    stack,
                    bg: isSelected ? Ds.aura : Ds.surface,
                    fg: isSelected ? Ds.onAura : Ds.muted,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Ds.border),

          // Body
          Expanded(
            child: _buildBody(
              me: me,
              usersP: usersP,
              filtered: filtered,
              hasFilters: hasFilters,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required UserModel? me,
    required UsersProvider usersP,
    required List<UserModel> filtered,
    required bool hasFilters,
  }) {
    if ((_isLoading || (usersP.isLoading && usersP.users.isEmpty)) &&
        filtered.isEmpty) {
      return _buildSkeletonList();
    }

    if (_error != null && filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Ds.hot),
              const SizedBox(height: 16),
              Text('Unable to search builders', style: DsText.h3),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: DsText.bodySm.copyWith(color: Ds.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DsButton(
                label: 'Retry',
                kind: DsButtonKind.bone,
                onPressed: () => _runRemoteSearch(reset: true),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
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
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 32,
                  color: Ds.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasFilters ? 'No builders match your search' : 'No builders yet',
                style: DsText.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                hasFilters
                    ? 'Try another name, @handle, or tech stack.'
                    : 'Builders on campus will appear here.',
                style: DsText.bodySm.copyWith(color: Ds.muted),
                textAlign: TextAlign.center,
              ),
              if (hasFilters) ...[
                const SizedBox(height: 16),
                DsButton(
                  label: 'Clear filters',
                  kind: DsButtonKind.bone,
                  onPressed: _clearFilters,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Ds.aura,
      backgroundColor: Ds.surface,
      onRefresh: () => _runRemoteSearch(reset: true),
      child: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Ds.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Ds.hot),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Ds.hot,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: DsText.caption.copyWith(color: Ds.bone),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _runRemoteSearch(reset: true),
                    child: Text(
                      'Retry',
                      style: DsText.caption.copyWith(color: Ds.aura),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == filtered.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Ds.aura,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }

                final u = filtered[index];
                final liveUser = usersP.getUserById(u.id) ?? u;
                final isUpdating = usersP.isFollowUpdating(liveUser.id);
                final isSelf = me != null && me.id == liveUser.id;
                final rankTag = _getRankTag(liveUser.aura);
                final tierColor = _getTierColor(liveUser.aura);
                final academic = liveUser.academicLabel;
                final cleanQuery = _query
                    .trim()
                    .toLowerCase()
                    .replaceFirst(RegExp(r'^@+'), '');

                return DsCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: liveUser.id),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _BuilderAvatar(user: liveUser),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        liveUser.name,
                                        style: DsText.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    DsTag(rankTag, bg: tierColor, fg: Ds.ink),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${liveUser.handle}${academic.isNotEmpty ? ' · $academic' : ''}',
                                  style:
                                      DsText.caption.copyWith(color: Ds.muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isSelf) ...[
                            const SizedBox(width: 8),
                            _FollowActionButton(
                              userName: liveUser.name,
                              isFollowing: liveUser.isFollowing,
                              isUpdating: isUpdating,
                              onPressed: () => _handleToggleFollow(liveUser),
                            ),
                          ],
                        ],
                      ),
                      if (liveUser.stack.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: liveUser.stack.map((tech) {
                            final isMatched = _selectedStacks.any(
                                  (sel) =>
                                      sel.trim().toLowerCase() ==
                                      tech.trim().toLowerCase(),
                                ) ||
                                (cleanQuery.isNotEmpty &&
                                    tech.toLowerCase().contains(cleanQuery));
                            return DsTag(
                              tech,
                              bg: isMatched
                                  ? Ds.aura.withValues(alpha: 0.25)
                                  : Ds.border,
                              fg: isMatched ? Ds.aura : Ds.bone,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => DsCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Ds.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 130,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Ds.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Ds.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 78,
              height: 32,
              decoration: BoxDecoration(
                color: Ds.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderAvatar extends StatelessWidget {
  final UserModel user;

  const _BuilderAvatar({required this.user});

  String _resolveUrl(String avatar) {
    if (avatar.startsWith('http')) return avatar;
    try {
      return StorageService.instance.resolvePublicUrl(avatar);
    } catch (_) {
      return avatar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Ds.border, width: 1.5),
      ),
      child: ClipOval(
        child: user.isImageAvatar && user.avatar.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: _resolveUrl(user.avatar),
                fit: BoxFit.cover,
                memCacheWidth: 132,
                memCacheHeight: 132,
                placeholder: (_, __) => Container(color: Ds.ink),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    final initials = user.avatar.isNotEmpty && !user.isImageAvatar
        ? user.avatar
        : (user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U');
    return Container(
      color: Ds.ink,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: DsText.label.copyWith(color: Ds.bone),
      ),
    );
  }
}

class _FollowActionButton extends StatelessWidget {
  final String userName;
  final bool isFollowing;
  final bool isUpdating;
  final VoidCallback onPressed;

  const _FollowActionButton({
    required this.userName,
    required this.isFollowing,
    required this.isUpdating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
        width: 82,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(color: Ds.aura, strokeWidth: 2),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: isFollowing ? 'Unfollow $userName' : 'Follow $userName',
      child: isFollowing
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Ds.border),
                backgroundColor: Ds.ink,
                foregroundColor: Ds.bone,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(82, 36),
                tapTargetSize: MaterialTapTargetSize.padded,
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
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Ds.aura,
                foregroundColor: Ds.onAura,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(82, 36),
                tapTargetSize: MaterialTapTargetSize.padded,
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
    );
  }
}
