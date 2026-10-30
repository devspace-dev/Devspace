import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../models/event_access_model.dart';
import '../../../models/post_model.dart';
import '../../../models/question_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/engagement_provider.dart';
import '../../../providers/posts_provider.dart';
import '../../../providers/questions_provider.dart';
import '../../../providers/users_provider.dart';
import '../../../screens/opportunity_detail_screen.dart';
import '../../../screens/notifications_screen.dart';
import '../../../screens/post_detail_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../screens/question_detail_screen.dart';
import '../../../widgets/compose_box.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _tabs = ['FEED', 'EVENTS', 'Q&A', 'PEOPLE'];
  String _peopleSearch = '';
  final Set<String> _selectedStacks = {};
  bool _showPastEvents = false;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PostsProvider>().fetchFeed();
      context.read<QuestionsProvider>().fetchQuestions();
      context.read<UsersProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuthProvider>().currentUserOrNull?.aura ?? 0;

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('COMMUNITY', style: DsText.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Ds.bone, size: 24),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AuraChip(aura),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
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
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
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
              _buildQnATab(),
              _buildPeopleTab(),
            ],
          ),

          // Floating yellow create button (56, radius 14, 5px edge) bottom-right
          Positioned(
            bottom: 24,
            right: 20,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: FEED
  // ---------------------------------------------------------------------------
  Widget _buildFeedTab() {
    final postsP = context.watch<PostsProvider>();
    if (postsP.isLoading && postsP.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Ds.aura));
    }
    if (postsP.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 48, color: Ds.muted),
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
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: postsP.posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = postsP.posts[index];
        return _buildPostCard(post);
      },
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

    return DsCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Ds.border,
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                  style: DsText.caption.copyWith(color: Ds.bone, fontWeight: FontWeight.bold),
                ),
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
          const SizedBox(height: 12),

          // Content capped at 4 lines with "Read more" in yellow
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
                      child: CircularProgressIndicator(color: Ds.aura, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Ds.surface,
                    height: 160,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, color: Ds.muted, size: 28),
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
                  final uid = context.read<AuthProvider>().currentUserOrNull?.id;
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
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                  );
                },
                radius: 24,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Ds.muted),
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
      return const Center(child: CircularProgressIndicator(color: Ds.aura));
    }
    if (allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_available_outlined, size: 48, color: Ds.muted),
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
      );
    }

    final upcoming = allEvents.where((e) => e.endDate == null || !_isPast(e.endDate!)).toList();
    final past = allEvents.where((e) => e.endDate != null && _isPast(e.endDate!)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No upcoming events.', style: DsText.bodySm),
            ),
          )
        else
          ...upcoming.map(_buildEventCard),

        if (past.isNotEmpty) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _showPastEvents = !_showPastEvents),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Ds.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Ds.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PAST EVENTS (${past.length})', style: DsText.label),
                  Icon(
                    _showPastEvents ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Ds.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_showPastEvents) ...[
            const SizedBox(height: 12),
            ...past.map(_buildEventCard),
          ],
        ],
      ],
    );
  }

  bool _isPast(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return false;
    return parsed.isBefore(DateTime.now());
  }

  Widget _buildEventCard(EventAccessModel event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        leftBar: event.unlocked ? Ds.mint : Ds.border,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OpportunityDetailScreen(opportunity: event)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DsTag(event.type.toUpperCase(), bg: Ds.border, fg: Ds.bone),
                if (event.requiredAura > 0)
                  DsTag('${event.requiredAura} AURA', bg: Ds.aura, fg: Ds.ink)
                else
                  const DsTag('FREE', bg: Ds.mint, fg: Ds.ink),
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
                  const Icon(Icons.location_on_outlined, size: 14, color: Ds.muted),
                  const SizedBox(width: 4),
                  Text(event.location!, style: DsText.caption),
                  const SizedBox(width: 12),
                ],
                if (event.date != null && event.date!.isNotEmpty) ...[
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Ds.muted),
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

  // ---------------------------------------------------------------------------
  // TAB 3: Q&A
  // ---------------------------------------------------------------------------
  Widget _buildQnATab() {
    final qP = context.watch<QuestionsProvider>();
    if (qP.isLoading && qP.questions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Ds.aura));
    }
    if (qP.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline_rounded, size: 48, color: Ds.muted),
              const SizedBox(height: 12),
              Text('No doubts asked yet.', style: DsText.h3),
              const SizedBox(height: 4),
              Text(
                'Ask questions, get help from peers, and earn Aura when your answers solve problems.',
                style: DsText.bodySm.copyWith(color: Ds.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: qP.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final q = qP.questions[index];
        return _buildQuestionCard(q);
      },
    );
  }

  Widget _buildQuestionCard(QuestionModel q) {
    return DsCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuestionDetailScreen(questionId: q.id)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (q.isSolved)
                const DsTag('SOLVED', bg: Ds.mint, fg: Ds.ink)
              else
                const DsTag('OPEN', bg: Ds.border, fg: Ds.bone),
              Text(_formatTimeAgo(q.createdAt), style: DsText.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.title, style: DsText.h3.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            q.body,
            style: DsText.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 16, color: Ds.aura),
              const SizedBox(width: 4),
              Text('${q.upvotesCount}', style: DsText.caption),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Ds.muted),
              const SizedBox(width: 4),
              Text('${q.repliesCount}', style: DsText.caption),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: PEOPLE
  // ---------------------------------------------------------------------------
  Widget _buildPeopleTab() {
    final usersP = context.watch<UsersProvider>();
    final allUsers = usersP.users;

    final filtered = allUsers.where((u) {
      if (_selectedStacks.isNotEmpty) {
        final matchesAny = _selectedStacks.any(
          (sel) => u.stack.any((s) => s.trim().toLowerCase() == sel.trim().toLowerCase()),
        );
        if (!matchesAny) return false;
      }
      if (_peopleSearch.isNotEmpty) {
        final q = _peopleSearch.toLowerCase().trim();
        final inName = u.name.toLowerCase().contains(q);
        final inHandle = u.handle.toLowerCase().contains(q);
        final inBranch = u.branch.toLowerCase().contains(q);
        final inStack = u.stack.any((s) => s.toLowerCase().contains(q));
        if (!inName && !inHandle && !inBranch && !inStack) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_selectedStacks.isNotEmpty) {
        final aCount = _selectedStacks.where(
          (sel) => a.stack.any((s) => s.trim().toLowerCase() == sel.trim().toLowerCase()),
        ).length;
        final bCount = _selectedStacks.where(
          (sel) => b.stack.any((s) => s.trim().toLowerCase() == sel.trim().toLowerCase()),
        ).length;
        if (aCount != bCount) return bCount.compareTo(aCount);
      }
      return b.aura.compareTo(a.aura);
    });

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Ds.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Ds.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Ds.muted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: DsText.bodySm.copyWith(color: Ds.bone),
                    decoration: InputDecoration(
                      hintText: 'Search builders by name, branch, or stack...',
                      hintStyle: DsText.bodySm.copyWith(color: Ds.muted),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _peopleSearch = val),
                  ),
                ),
                if (_peopleSearch.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _peopleSearch = ''),
                    child: const Icon(Icons.close_rounded, color: Ds.muted, size: 18),
                  ),
              ],
            ),
          ),
        ),

        // Multi-select Stack Chips Row
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _popularStacks.length + (_selectedStacks.isNotEmpty ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (_selectedStacks.isNotEmpty && index == 0) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedStacks.clear()),
                  child: DsTag(
                    'Clear (${_selectedStacks.length})',
                    bg: Ds.border,
                    fg: Ds.bone,
                  ),
                );
              }
              final stackIndex = _selectedStacks.isNotEmpty ? index - 1 : index;
              final stack = _popularStacks[stackIndex];
              final isSelected = _selectedStacks.contains(stack);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedStacks.remove(stack);
                    } else {
                      _selectedStacks.add(stack);
                    }
                  });
                },
                child: DsTag(
                  stack,
                  bg: isSelected ? Ds.aura : Ds.surface,
                  fg: isSelected ? Ds.ink : Ds.muted,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Users List
        Expanded(
          child: usersP.isLoading && allUsers.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Ds.aura))
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        _peopleSearch.isEmpty && _selectedStacks.isEmpty
                            ? 'No builders registered yet.'
                            : 'No builders found matching criteria.',
                        style: DsText.bodySm,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final u = filtered[index];
                        final rankTag = getRankTag(u.aura);
                        final tierColor = getTierColor(u.aura);

                        return DsCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(userId: u.id),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Ds.surface,
                                    child: Text(
                                      u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                                      style: DsText.h3.copyWith(color: Ds.bone, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                u.name,
                                                style: DsText.label,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            DsTag(rankTag, bg: tierColor, fg: Ds.ink),
                                          ],
                                        ),
                                        Text(
                                          '@${u.handle} · ${u.branch} ${u.year}',
                                          style: DsText.caption,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${u.aura}',
                                    style: DsText.number.copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                              if (u.stack.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: u.stack.map((tech) {
                                    final isMatched = _selectedStacks.any(
                                      (sel) => sel.trim().toLowerCase() == tech.trim().toLowerCase(),
                                    ) || (_peopleSearch.isNotEmpty && tech.toLowerCase().contains(_peopleSearch.toLowerCase().trim()));
                                    return DsTag(
                                      tech,
                                      bg: isMatched ? Ds.aura.withValues(alpha: 0.25) : const Color(0xFF1E2030),
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
    );
  }
}
