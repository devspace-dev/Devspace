import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../core/widgets/segment_bar.dart';
import '../../../data/badges_data.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/users_provider.dart';
import '../../../providers/messages_provider.dart';
import '../../../providers/practice_provider.dart';
import '../../../screens/chat_detail_screen.dart';
import '../../../screens/connections_screen.dart';
import '../../../screens/post_detail_screen.dart';
import '../../../screens/profile_setup_screen.dart';
import '../../../screens/saved_posts_screen.dart';
import '../../../screens/settings_screen.dart';
import '../../../services/supabase_service.dart';
import '../../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  static String getRankTag(int aura) {
    if (aura >= 5000) return '10x Dev';
    if (aura >= 1500) return 'SO Survivor';
    if (aura >= 500) return 'Bug Hunter';
    return 'Rookie';
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _targetUser;
  bool _isLoadingUser = false;

  int? _postsCount;
  int? _collegeRank;
  List<PostModel> _recentPosts = [];
  bool _isLoadingPosts = true;

  Set<String> _earnedBadgeKeys = {};
  Map<String, dynamic> _badgeProgress = {};
  Map<String, dynamic>? _nextBadge;

  bool _initializedTabState = false;
  bool _wasTabActive = true;
  int? _lastObservedAura;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _targetUser = null;
      _loadProfileData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTabActive = TickerMode.valuesOf(context).enabled;
    if (!_initializedTabState) {
      _initializedTabState = true;
      _wasTabActive = isTabActive;
    } else if (isTabActive && !_wasTabActive) {
      _wasTabActive = true;
      _loadProfileData();
    } else if (!isTabActive) {
      _wasTabActive = false;
    }

    final me = context.read<AuthProvider>().currentUserOrNull;
    if (_lastObservedAura != null &&
        me != null &&
        me.aura != _lastObservedAura) {
      _lastObservedAura = me.aura;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCollegeRank(me.id);
      });
    } else if (_lastObservedAura == null && me != null) {
      _lastObservedAura = me.aura;
    }
  }

  Future<void> _loadProfileData() async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    final isMe = widget.userId == null || widget.userId == me?.id;
    final targetId = widget.userId ?? me?.id;
    if (targetId == null) return;

    if (!isMe) {
      _fetchTargetUser(targetId);
    }

    await Future.wait([
      _loadBadges(targetId),
      _loadCollegeRank(targetId),
      _loadRecentPosts(targetId),
    ]);
  }

  Future<void> _fetchTargetUser(String userId) async {
    final usersP = context.read<UsersProvider>();
    final cached = usersP.getUserById(userId);
    if (cached != null) {
      if (mounted) setState(() => _targetUser = cached);
      return;
    }
    setState(() => _isLoadingUser = true);
    try {
      final fetched = await usersP.getUser(userId);
      if (mounted) {
        setState(() {
          _targetUser = fetched;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _loadBadges(String userId) async {
    try {
      final payload = await SupabaseService.instance.syncMyBadgesPayload(userId: userId);
      if (payload != null && mounted) {
        final earnedList = payload['earned_badge_keys'] as List? ?? [];
        final progressMap = payload['progress'] as Map<String, dynamic>? ?? {};
        final nextBadgeMap = payload['next_badge'] as Map<String, dynamic>?;

        setState(() {
          _earnedBadgeKeys = earnedList.map((e) => e.toString()).toSet();
          _badgeProgress = progressMap;
          _nextBadge = nextBadgeMap;
        });
      }
    } catch (e) {
      debugPrint('Error syncing badges on profile open: $e');
    }
  }

  Future<void> _loadCollegeRank(String userId) async {
    try {
      final rank = await SupabaseService.instance.getUserCollegeRank(userId);
      if (mounted) {
        setState(() {
          _collegeRank = rank;
        });
      }
    } catch (e) {
      debugPrint('Failed to load college rank: $e');
    }
  }

  Future<void> _loadRecentPosts(String userId) async {
    try {
      setState(() => _isLoadingPosts = true);
      final count = await SupabaseService.instance.getUserPostsCount(userId);
      final posts = await SupabaseService.instance.getUserPosts(userId, limit: 3);
      if (mounted) {
        setState(() {
          _postsCount = count;
          _recentPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load recent posts: $e');
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showAllBadgesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Ds.ink,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Ds.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ALL BADGES', style: DsText.h3),
                      Text('${_earnedBadgeKeys.length} of ${kCommunityBadges.length}', style: DsText.caption),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: kCommunityBadges.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final badge = kCommunityBadges[index];
                        final isEarned = _earnedBadgeKeys.contains(badge.key);
                        final progressItem = _badgeProgress[badge.key] as Map<String, dynamic>?;
                        final current = progressItem?['current'] ?? (isEarned ? 1 : 0);
                        final target = progressItem?['target'] ?? 1;

                        return DsCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isEarned ? badge.accentColor.withValues(alpha: 0.2) : Ds.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isEarned ? badge.accentColor : Ds.border,
                                    width: isEarned ? 2 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(badge.icon, style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(badge.name, style: DsText.label),
                                        if (isEarned) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.check_circle_rounded, size: 14, color: Ds.mint),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(badge.rule, style: DsText.caption),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEarned ? 'EARNED' : '$current/$target',
                                style: DsText.caption.copyWith(
                                  color: isEarned ? Ds.mint : Ds.muted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeTile(CommunityBadgeDefinition badge, bool isEarned) {
    final familyColor = badge.accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isEarned ? familyColor.withValues(alpha: 0.15) : Ds.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEarned ? familyColor : Ds.border,
          width: isEarned ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(badge.icon, style: const TextStyle(fontSize: 22)),
              if (isEarned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Ds.aura,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, size: 10, color: Ds.onAura),
                  ),
                )
              else
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Ds.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, size: 10, color: Ds.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: DsText.caption.copyWith(
              fontSize: 10,
              fontWeight: isEarned ? FontWeight.bold : FontWeight.w500,
              color: isEarned ? Ds.bone : Ds.muted,
            ),
          ),
          if (!isEarned) ...[
            const SizedBox(height: 2),
            Text(
              badge.rule,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: DsText.caption.copyWith(
                fontSize: 8,
                color: Ds.muted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authP = context.watch<AuthProvider>();
    final me = authP.currentUserOrNull;
    final isSelf = widget.userId == null || widget.userId == me?.id;
    final user = isSelf
        ? me
        : (_targetUser ?? (widget.userId != null ? context.watch<UsersProvider>().getUserById(widget.userId!) : null));

    if (!isSelf && _isLoadingUser && user == null) {
      return Scaffold(
        backgroundColor: Ds.ink,
        appBar: AppBar(
          backgroundColor: Ds.ink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Ds.bone),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: Ds.aura)),
      );
    }

    final practiceP = context.watch<PracticeProvider?>();

    final aura = user?.aura ?? 0;
    final rankTitle = ProfileScreen.getRankTag(aura);
    final streak = (user?.currentStreak ?? 0) > 0 ? user!.currentStreak : 0;
    final hasCollege = user != null && user.college.trim().isNotEmpty;
    final isUnranked = _collegeRank == null && hasCollege && aura <= 0;
    final collegeRankDisplay = _collegeRank != null
        ? '#$_collegeRank'
        : (isUnranked ? 'Unranked' : '-');
    final solvedCountDisplay = practiceP?.totalCompletedCount != null
        ? '${practiceP!.totalCompletedCount}'
        : '-';

    final String initial = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()[0].toUpperCase()
        : 'U';

    final stack = (user?.stack != null && user!.stack.isNotEmpty)
        ? user.stack
        : const ['Flutter', 'PostgreSQL', 'Dart'];

    final branchYearParts = [
      if (user?.branch != null && user!.branch.isNotEmpty) user.branch,
      if (user?.year != null && user!.year.isNotEmpty) user.year,
    ];
    final branchYear = branchYearParts.isNotEmpty ? branchYearParts.join(' ') : 'Engineering';

    final featuredBadges = kCommunityBadges.take(4).toList();

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isSelf
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Ds.bone),
                onPressed: () => Navigator.maybePop(context),
              ),
        title: Text(isSelf ? 'Profile' : '@${user?.handle ?? "dev"}', style: isSelf ? DsText.h2 : DsText.h3.copyWith(fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AuraChip(aura),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Ds.aura,
        backgroundColor: Ds.surface,
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Identity Row
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Ds.aura, width: 3),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: Ds.surface,
                    backgroundImage: (user != null && user.isImageAvatar && user.avatar.isNotEmpty)
                        ? CachedNetworkImageProvider(
                            StorageService.instance.resolvePublicUrl(user.avatar),
                          )
                        : null,
                    child: (user == null || !user.isImageAvatar || user.avatar.isEmpty)
                        ? Text(
                            (user != null && !user.isImageAvatar && user.avatar.isNotEmpty)
                                ? user.avatar
                                : initial,
                            style: DsText.h2.copyWith(color: Ds.bone),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(user?.name ?? 'Developer', style: DsText.h2)),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '@${user?.handle ?? "dev"} · $branchYear',
                  style: DsText.bodySm.copyWith(color: Ds.muted),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: DsTag(rankTitle, bg: Ds.aura, fg: Ds.onAura)),
              const SizedBox(height: 20),

              // 2. Counts Card (Followers | Following | Posts)
              DsCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    // Followers (tappable, 48dp min, semantics label)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: '${user?.followers ?? 0} Followers, tap to view followers list',
                        child: InkWell(
                          onTap: user != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ConnectionsScreen(
                                        user: user,
                                        type: ConnectionListType.followers,
                                      ),
                                    ),
                                  ).then((_) => _loadProfileData());
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('${user?.followers ?? 0}', style: DsText.number.copyWith(fontSize: 20)),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('FOLLOWERS', style: DsText.caption),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 32, color: Ds.border),
                    // Following (tappable, 48dp min, semantics label)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: '${user?.following ?? 0} Following, tap to view following list',
                        child: InkWell(
                          onTap: user != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ConnectionsScreen(
                                        user: user,
                                        type: ConnectionListType.following,
                                      ),
                                    ),
                                  ).then((_) => _loadProfileData());
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('${user?.following ?? 0}', style: DsText.number.copyWith(fontSize: 20)),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('FOLLOWING', style: DsText.caption),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 32, color: Ds.border),
                    // Posts (not tappable)
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _postsCount != null ? '$_postsCount' : '-',
                                style: DsText.number.copyWith(fontSize: 20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('POSTS', style: DsText.caption),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Action Buttons (Edit Profile for self; Follow & Message for others)
              if (isSelf) ...[
                DsButton(
                  label: 'Edit Profile',
                  kind: DsButtonKind.bone,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileSetupScreen(mode: ProfileSetupMode.edit),
                      ),
                    ).then((_) => _loadProfileData());
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: DsButton(
                        label: (user?.isFollowing ?? false) ? 'FOLLOWING' : 'FOLLOW',
                        kind: (user?.isFollowing ?? false) ? DsButtonKind.bone : DsButtonKind.aura,
                        loading: context.watch<UsersProvider>().isFollowUpdating(user?.id ?? ''),
                        onPressed: () async {
                          if (user == null || me == null) return;
                          HapticFeedback.mediumImpact();
                          await context.read<UsersProvider>().toggleFollow(me.id, user.id);
                          if (mounted) _loadProfileData();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DsButton(
                        label: 'MESSAGE',
                        kind: DsButtonKind.bone,
                        icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Ds.ink),
                        onPressed: () async {
                          if (user == null || me == null) return;
                          HapticFeedback.lightImpact();
                          final msgP = context.read<MessagesProvider>();
                          final conv = await msgP.getOrCreateConversation(user.id);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                conversation: conv,
                                otherUser: user,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // 4. Three Stat Cards (Day streak in coral, College rank in yellow, Solved in mint)
              Row(
                children: [
                  Expanded(
                    child: DsCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 20, color: Ds.hot),
                              const SizedBox(width: 4),
                              Text('$streak', style: DsText.number.copyWith(fontSize: 22, color: Ds.hot)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('DAY STREAK', style: DsText.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DsCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events_rounded, size: 20, color: Ds.aura),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  collegeRankDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: isUnranked
                                      ? DsText.label.copyWith(color: Ds.muted)
                                      : DsText.number.copyWith(fontSize: 22, color: Ds.aura),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('COLLEGE RANK', style: DsText.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DsCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 20, color: Ds.mint),
                              const SizedBox(width: 4),
                              Text(solvedCountDisplay, style: DsText.number.copyWith(fontSize: 22, color: Ds.mint)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('SOLVED', style: DsText.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Badges Section
              DsCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('BADGES', style: DsText.label),
                            const SizedBox(width: 8),
                            Text('${_earnedBadgeKeys.length} of ${kCommunityBadges.length}', style: DsText.caption),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showAllBadgesSheet(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'See all',
                              style: DsText.caption.copyWith(color: Ds.aura, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row of 4 badge tiles
                    Row(
                      children: featuredBadges.map((badge) {
                        final isEarned = _earnedBadgeKeys.contains(badge.key);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _buildBadgeTile(badge, isEarned),
                          ),
                        );
                      }).toList(),
                    ),
                    // "Next badge" card with SegmentBar
                    if (_nextBadge != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Ds.ink,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Ds.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up_rounded, size: 16, color: Ds.aura),
                                    const SizedBox(width: 6),
                                    Text(
                                      'NEXT: ${_nextBadge!['badge_name'] ?? ''}',
                                      style: DsText.label.copyWith(fontSize: 12, color: Ds.aura),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_nextBadge!['current'] ?? 0} / ${_nextBadge!['target'] ?? 1}',
                                  style: DsText.caption.copyWith(color: Ds.bone, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SegmentBar(
                              total: (_nextBadge!['target'] as num?)?.toInt() ?? 1,
                              current: (_nextBadge!['current'] as num?)?.toInt() ?? 0,
                              filledColor: Ds.mint,
                              emptyColor: Ds.border,
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. Stack Chips
              DsCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TECH STACK', style: DsText.label),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: stack.map((tech) => DsTag(tech, bg: Ds.border, fg: Ds.bone)).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 7. Recent Posts Section (up to 3 latest posts)
              DsCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RECENT POSTS', style: DsText.label),
                        if (_recentPosts.isNotEmpty)
                          Text('${_recentPosts.length} shown', style: DsText.caption),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingPosts)
                      Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: Ds.ink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(color: Ds.aura, strokeWidth: 2),
                      )
                    else if (_recentPosts.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Ds.ink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.edit_note_rounded, size: 36, color: Ds.muted),
                            const SizedBox(height: 8),
                            Text(
                              'Nothing here yet. Be the first to post.',
                              style: DsText.bodySm.copyWith(color: Ds.muted),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _recentPosts.map((post) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailScreen(post: post),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Ds.ink,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Ds.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'POST',
                                          style: DsText.caption.copyWith(color: Ds.aura, letterSpacing: 0.5),
                                        ),
                                        Text(_formatTimeAgo(post.createdAt), style: DsText.caption),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      post.content,
                                      style: DsText.bodySm,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxHeight: 140),
                                          child: CachedNetworkImage(
                                            imageUrl: post.imageUrl!,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 720,
                                            placeholder: (_, __) => Container(
                                              color: Ds.surface,
                                              height: 100,
                                              child: const Center(
                                                child: CircularProgressIndicator(color: Ds.aura, strokeWidth: 2),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 8. Settings & Actions Rows (Only for self)
              if (isSelf) ...[
                DsCard(
                  padding: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.bookmark_border_rounded, color: Ds.bone),
                          title: Text('Saved Posts', style: DsText.label),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Ds.muted),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Ds.border),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined, color: Ds.bone),
                          title: Text('Settings', style: DsText.label),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Ds.muted),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Ds.border),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Ds.hot),
                          title: Text('Sign Out', style: DsText.label.copyWith(color: Ds.hot)),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Ds.surface,
                                title: Text('SIGN OUT', style: DsText.h3),
                                content: Text('Are you sure you want to sign out?', style: DsText.body),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('CANCEL', style: DsText.button.copyWith(color: Ds.muted)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('SIGN OUT', style: DsText.button.copyWith(color: Ds.hot)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await authP.signOut();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
