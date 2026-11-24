import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../data/curated_hackathons.dart';
import '../../../models/event_access_model.dart';
import '../../../models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/engagement_provider.dart';
import '../../../providers/messages_provider.dart';
import '../../../providers/posts_provider.dart';
import '../../../providers/users_provider.dart';
import '../../../screens/messages_screen.dart';
import '../../../screens/opportunity_detail_screen.dart';
import '../../../screens/post_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../services/storage_service.dart';
import '../../../utils/hackathon_region.dart';
import '../../../widgets/compose_box.dart';
import '../../tour/models/tour_step.dart';
import '../../tour/widgets/tour_anchor.dart';
import 'builder_search_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _feedScrollController = ScrollController();
  final List<String> _tabs = ['FEED', 'EVENTS'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _feedScrollController.addListener(_onFeedScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PostsProvider>().fetchFeed();
      context.read<UsersProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onFeedScroll() {
    if (!_feedScrollController.hasClients) return;
    if (_feedScrollController.position.pixels >=
        _feedScrollController.position.maxScrollExtent - 250) {
      context.read<PostsProvider>().loadMoreFeed();
    }
  }

  static String getRankTag(int aura) {
    if (aura >= 5000) return '10x Dev';
    if (aura >= 1500) return 'SO Survivor';
    if (aura >= 500) return 'Bug Hunter';
    return 'Rookie';
  }

  static Color getTierColor(int aura) {
    if (aura >= 5000) return Ds.tierGem;
    if (aura >= 1500) return Ds.tierGold;
    if (aura >= 500) return Ds.tierSilver;
    return Ds.tierBronze;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _resolveUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    try {
      return StorageService.instance.resolvePublicUrl(raw);
    } catch (_) {
      return raw;
    }
  }

  void _openInbox() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const MessagesScreen()),
    );
  }

  void _openBuilderSearch() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const BuilderSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuthProvider>().currentUserOrNull?.aura ?? 0;
    final unreadMessages =
        context.watch<MessagesProvider?>()?.totalUnreadCount ?? 0;
    final inboxSemanticsLabel = unreadMessages == 1
        ? 'Inbox, 1 unread message'
        : 'Inbox, $unreadMessages unread messages';

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Community', style: DsText.h2),
        actions: [
          Semantics(
            button: true,
            label: inboxSemanticsLabel,
            child: InkResponse(
              onTap: _openInbox,
              radius: 24,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Ds.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Ds.border, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: Ds.bone,
                      size: 20,
                    ),
                    if (unreadMessages > 0)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Ds.hot,
                            shape: BoxShape.circle,
                            border: Border.all(color: Ds.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 16),
            child: AuraChip(aura),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            MediaQuery.textScalerOf(context).scale(48).clamp(48.0, 68.0),
          ),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Ds.border, width: 2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Ds.aura,
              indicatorWeight: 3,
              labelColor: Ds.bone,
              unselectedLabelColor: Ds.muted,
              labelStyle: DsText.caption.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: DsText.caption,
              tabs: _tabs.map((t) {
                final tabChild = Text(t, maxLines: 1, overflow: TextOverflow.ellipsis);
                if (t == 'EVENTS') {
                  return Tab(
                    child: TourAnchor(
                      id: TourAnchorId.eventsTab,
                      child: tabChild,
                    ),
                  );
                }
                return Tab(child: tabChild);
              }).toList(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildFeedTab(),
              _buildEventsTab(),
            ],
          ),

          // Floating yellow create button (56, radius 14, 5px edge) bottom-right
          Positioned(
            bottom: 24,
            right: 20,
            child: TourAnchor(
              id: TourAnchorId.createPostButton,
              child: Semantics(
                button: true,
                label: 'Create post',
                child: GestureDetector(
                  onTap: () => ComposeBox.showCreatePostSheet(context),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Ds.aura,
                      borderRadius: BorderRadius.circular(14),
                      border: const Border(
                        bottom: BorderSide(color: Ds.auraEdge, width: 5),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Ds.onAura, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: FEED
  // ---------------------------------------------------------------------------
  Widget _buildFeedTab() {
    final postsP = context.watch<PostsProvider>();

    return Column(
      children: [
        // Builder Search Trigger Bar under tabs on Feed
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Semantics(
            button: true,
            label: 'Search builders by name, @handle or stack',
            child: GestureDetector(
              onTap: _openBuilderSearch,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Ds.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Ds.border, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Ds.muted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search builders by name, @handle or stack',
                        style: DsText.bodySm.copyWith(color: Ds.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildFeedContent(postsP),
        ),
      ],
    );
  }

  Widget _buildFeedContent(PostsProvider postsP) {
    if (postsP.isLoading && postsP.posts.isEmpty) {
      return _buildFeedSkeletons();
    }

    if (postsP.feedError != null && postsP.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Ds.hot),
              const SizedBox(height: 12),
              Text('Unable to load feed', style: DsText.h3),
              const SizedBox(height: 6),
              Text(
                postsP.feedError!,
                style: DsText.bodySm.copyWith(color: Ds.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DsButton(
                label: 'Retry',
                kind: DsButtonKind.bone,
                onPressed: postsP.fetchFeed,
              ),
            ],
          ),
        ),
      );
    }

    if (postsP.posts.isEmpty) {
      return RefreshIndicator(
        color: Ds.aura,
        backgroundColor: Ds.surface,
        onRefresh: postsP.refreshFeed,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 48,
                        color: Ds.muted,
                      ),
                      const SizedBox(height: 12),
                      Text('Nothing here yet.', style: DsText.h3),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to post a project update or doubt.',
                        style: DsText.bodySm.copyWith(color: Ds.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Ds.aura,
      backgroundColor: Ds.surface,
      onRefresh: postsP.refreshFeed,
      child: ListView.separated(
        controller: _feedScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: postsP.posts.length + (postsP.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == postsP.posts.length) {
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
          final post = postsP.posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildFeedSkeletons() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Ds.border,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Ds.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Ds.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Ds.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                color: Ds.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final author = context.watch<UsersProvider>().getUserById(post.userId);
    final authorName = author?.name ?? 'Developer';
    final authorHandle = author?.handle ?? 'dev';
    final authorAura = author?.aura ?? 0;
    final rankTag = getRankTag(authorAura);
    final tierColor = getTierColor(authorAura);
    final isLong = post.content.length > 160;
    final hasImageAvatar =
        author != null && author.isImageAvatar && author.avatar.isNotEmpty;

    return DsCard(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header Row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: post.userId),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Ds.border,
                  backgroundImage: hasImageAvatar
                      ? CachedNetworkImageProvider(_resolveUrl(author.avatar))
                      : null,
                  child: !hasImageAvatar
                      ? Text(
                          (author != null &&
                                  !author.isImageAvatar &&
                                  author.avatar.isNotEmpty)
                              ? author.avatar
                              : (authorName.isNotEmpty
                                  ? authorName[0].toUpperCase()
                                  : 'U'),
                          style: DsText.caption.copyWith(
                            color: Ds.bone,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              authorName,
                              style: DsText.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          DsTag(rankTag, bg: tierColor, fg: Ds.ink),
                        ],
                      ),
                      Text(
                        '@$authorHandle · ${_formatTimeAgo(post.createdAt)}',
                        style: DsText.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Content capped at 4 lines with "Read more" in yellow
          if (post.content.isNotEmpty)
            Text(
              post.content,
              style: DsText.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          if (isLong) ...[
            const SizedBox(height: 4),
            Text(
              'Read more',
              style: DsText.caption.copyWith(
                color: Ds.aura,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 180, maxHeight: 420),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 1080,
                  placeholder: (_, __) => Container(
                    color: Ds.surface,
                    height: 220,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Ds.aura,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Ds.surface,
                    height: 160,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Ds.muted,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Action row with 48dp touch targets
          Row(
            children: [
              InkResponse(
                onTap: () {
                  final uid =
                      context.read<AuthProvider>().currentUserOrNull?.id;
                  if (uid != null) {
                    context.read<PostsProvider>().toggleLike(post.id, uid);
                  }
                },
                radius: 24,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: post.isLiked ? Ds.hot : Ds.muted,
                      ),
                      const SizedBox(width: 6),
                      Text('${post.likes}', style: DsText.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              InkResponse(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: post),
                    ),
                  );
                },
                radius: 24,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: Ds.muted,
                      ),
                      const SizedBox(width: 6),
                      Text('${post.comments}', style: DsText.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: EVENTS
  // ---------------------------------------------------------------------------
  Widget _buildEventsTab() {
    final engagement = context.watch<EngagementProvider>();
    final allEvents = engagement.events;

    if (engagement.isLoading && allEvents.isEmpty) {
      return _buildEventsSkeletons();
    }

    if (engagement.error != null && allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Ds.hot),
              const SizedBox(height: 12),
              Text('Unable to load events', style: DsText.h3),
              const SizedBox(height: 6),
              Text(
                engagement.error!,
                style: DsText.bodySm.copyWith(color: Ds.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DsButton(
                label: 'Retry',
                kind: DsButtonKind.bone,
                onPressed: () =>
                    engagement.fetchOverview(forceChallengeRefresh: true),
              ),
            ],
          ),
        ),
      );
    }

    if (allEvents.isEmpty) {
      return RefreshIndicator(
        color: Ds.aura,
        backgroundColor: Ds.surface,
        onRefresh: () =>
            engagement.fetchOverview(forceChallengeRefresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: Ds.muted,
                      ),
                      const SizedBox(height: 12),
                      Text('No upcoming events right now.', style: DsText.h3),
                      const SizedBox(height: 4),
                      Text(
                        'Hackathons and fellowship programs will appear here.',
                        style: DsText.bodySm.copyWith(color: Ds.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final combinedEvents = <EventAccessModel>[];
    final existingTitles = <String>{};

    for (final e in allEvents) {
      if (!isNonIndianHackathon(e)) {
        combinedEvents.add(e);
        existingTitles.add(e.title.toLowerCase().trim());
      }
    }

    for (final curated in kCuratedIndianHackathons) {
      if (!existingTitles.contains(curated.title.toLowerCase().trim())) {
        combinedEvents.add(curated);
      }
    }

    final activeEvents = combinedEvents.where((e) => !_isExpired(e)).toList();

    // Sort active events: nearest deadline ascending, then title
    activeEvents.sort((a, b) {
      final dateA = _getEventDate(a);
      final dateB = _getEventDate(b);
      if (dateA != null && dateB != null) {
        return dateA.compareTo(dateB);
      }
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      return a.title.compareTo(b.title);
    });

    return RefreshIndicator(
      color: Ds.aura,
      backgroundColor: Ds.surface,
      onRefresh: () =>
          engagement.fetchOverview(forceChallengeRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          if (activeEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No upcoming events.', style: DsText.bodySm),
              ),
            )
          else
            ...activeEvents.map(_buildEventCard),
        ],
      ),
    );
  }

  Widget _buildEventsSkeletons() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 72,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Ds.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 64,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Ds.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 18,
              decoration: BoxDecoration(
                color: Ds.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 12,
              decoration: BoxDecoration(
                color: Ds.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseHumanDate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // 1. Direct ISO / SQL timestamp parse (e.g. 2026-12-05T23:59:59Z, 2026-11-28 00:00:00+00)
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso.toLocal();

    final lower = trimmed.toLowerCase();
    // 2. Explicit terminal keywords using word boundary \b
    final isExplicitClosed = RegExp(r'\b(ended|concluded|expired)\b').hasMatch(lower) ||
        RegExp(r'\bregistration\s+closed\b').hasMatch(lower);
    if (isExplicitClosed) {
      return DateTime(2020, 1, 1);
    }

    // 3. For date ranges ("Nov 15 - Dec 05, 2026", "Jul 21 to Oct 31, 2026"), target deadline at the END
    final rangeParts = trimmed.split(RegExp(r'[-–]|(?:\bto\b)'));
    final targetStr = rangeParts.isNotEmpty ? rangeParts.last.trim() : trimmed;

    // Strip times ("10:00 AM", "11AM") so hours don't clash with day numbers
    final withoutTime = targetStr.replaceAll(
      RegExp(r'\b\d{1,2}(?::\d{2})?\s*(?:am|pm)\b', caseSensitive: false),
      '',
    );

    // Extract year: target segment -> full text -> current year
    int year = DateTime.now().year;
    final yearMatch = RegExp(r'\b(202[0-9])\b').firstMatch(targetStr) ??
        RegExp(r'\b(202[0-9])\b').firstMatch(trimmed);
    if (yearMatch != null) {
      final y = int.tryParse(yearMatch.group(1)!);
      if (y != null) year = y;
    }

    // Extract month using word boundaries \b to prevent matching "smart", "summary", etc.
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    int month = 12;
    final monthMatch = RegExp(
      r'\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b',
      caseSensitive: false,
    ).firstMatch(withoutTime) ?? RegExp(
      r'\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (monthMatch != null) {
      final key = monthMatch.group(1)!.substring(0, 3).toLowerCase();
      month = months[key] ?? 12;
    }

    // Extract day: find day number (1-31)
    int day = 28;
    final dayMatches = RegExp(r'\b([0-2]?[0-9]|3[0-1])\b').allMatches(withoutTime);
    for (final m in dayMatches) {
      final val = int.tryParse(m.group(1)!);
      if (val != null && val >= 1 && val <= 31 && val != year) {
        day = val;
      }
    }

    return DateTime(year, month, day, 23, 59, 59);
  }

  DateTime? _getEventDate(EventAccessModel e) {
    if (e.endDate != null && e.endDate!.trim().isNotEmpty) {
      final parsed = _parseHumanDate(e.endDate!);
      if (parsed != null) return parsed;
    }
    if (e.date != null && e.date!.trim().isNotEmpty) {
      final parsed = _parseHumanDate(e.date!);
      if (parsed != null) return parsed;
    }
    return null;
  }

  bool _isExpired(EventAccessModel e) {
    final lowerTitle = e.title.toLowerCase();
    if (RegExp(r'\b(ended|concluded|expired)\b').hasMatch(lowerTitle)) {
      return true;
    }

    final date = _getEventDate(e);
    if (date != null) {
      final now = DateTime.now();
      return date.isBefore(now);
    }

    // TBA / unparsed date events remain visible
    return false;
  }

  Widget _buildEventCard(EventAccessModel event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        leftBar: event.unlocked ? Ds.mint : Ds.border,
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => OpportunityDetailScreen(opportunity: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DsTag(event.type.toUpperCase(), bg: Ds.border, fg: Ds.bone),
              ],
            ),
            const SizedBox(height: 10),
            Text(event.title, style: DsText.h3.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            if (event.organizer != null && event.organizer!.isNotEmpty)
              Text(event.organizer!, style: DsText.caption),
            const SizedBox(height: 6),
            Row(
              children: [
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Ds.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(event.location!, style: DsText.caption),
                  const SizedBox(width: 12),
                ],
                if (event.date != null && event.date!.isNotEmpty) ...[
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Ds.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(event.date!, style: DsText.caption),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
