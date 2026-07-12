import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';
import '../widgets/post_shimmer.dart';
import '../widgets/compose_box.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _activeSubTab = 0; // 0: For You, 1: Following, 2: Projects
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshFeed() async {
    final postsP = context.read<PostsProvider>();
    await postsP.refreshFeed();
    if (mounted) {
      final userIds = postsP.posts.map((p) => p.userId).toList();
      await context.read<UsersProvider>().fetchAndCacheUsers(userIds);
    }
  }

  Future<void> _loadMoreFeed() async {
    final postsP = context.read<PostsProvider>();
    await postsP.loadMoreFeed();
    if (mounted) {
      final userIds = postsP.posts.map((p) => p.userId).toList();
      await context.read<UsersProvider>().fetchAndCacheUsers(userIds);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreFeed();
    }
  }

  void scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _refreshFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authP = context.watch<AuthProvider>();
    final user = authP.currentUserOrNull;
    final name = user?.name ?? 'Builder';

    final postsP = context.watch<PostsProvider>();
    final posts = postsP.posts;

    // Filter posts for subtabs
    List filteredPosts = posts;
    if (_activeSubTab == 2) {
      // Filter project-related updates (contain github links or keyword project)
      filteredPosts = posts
          .where((p) =>
              p.content.toLowerCase().contains('github') ||
              p.content.toLowerCase().contains('project') ||
              p.content.toLowerCase().contains('build'))
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          color: AppColors.primary,
          onRefresh: () async {
            await authP.refreshUsers();
            await _refreshFeed();
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 0. Greeting Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Evening,',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.text3For(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$name 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          color: AppColors.textFor(context),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 1. Sub-tabs segment
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildSubTab(0, 'For You'),
                      const SizedBox(width: 8),
                      _buildSubTab(1, 'Following'),
                      const SizedBox(width: 8),
                      _buildSubTab(2, 'Projects'),
                    ],
                  ),
                ),
              ),

              // 2. For You shows resources first
              if (_activeSubTab == 0) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text(
                      'Resources for you',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildResourceCard(
                          context,
                          roadmap: _learningRoadmaps[0],
                          isDark: isDark,
                        ),
                        _buildResourceCard(
                          context,
                          roadmap: _learningRoadmaps[1],
                          isDark: isDark,
                        ),
                        _buildResourceCard(
                          context,
                          roadmap: _learningRoadmaps[2],
                          isDark: isDark,
                        ),
                        _buildResourceCard(
                          context,
                          roadmap: _learningRoadmaps[3],
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 3. Active Discussions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Discussions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ComposeBox.showCreatePostSheet(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Discussions feed list
              if (postsP.isLoading && filteredPosts.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const PostShimmer(),
                    childCount: 4,
                  ),
                )
              else if (filteredPosts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 44,
                            color: AppColors.text3For(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No active discussions',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text2For(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: PostCard(post: filteredPosts[idx]),
                      );
                    },
                    childCount: filteredPosts.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTab(int index, String label) {
    final active = _activeSubTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeSubTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF1F3F5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppColors.primary : AppColors.text2For(context),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context, {
    required LearningRoadmap roadmap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LearningRoadmapScreen(roadmap: roadmap),
          ),
        );
      },
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg2Dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.8),
          ),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: roadmap.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(roadmap.icon, color: roadmap.color, size: 16),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.text4For(context),
                  size: 16,
                ),
              ],
            ),
            const Spacer(),
            Text(
              roadmap.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textFor(context),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              roadmap.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.text3For(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LearningRoadmapScreen extends StatelessWidget {
  final LearningRoadmap roadmap;

  const LearningRoadmapScreen({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _RoadmapProgressCard(roadmap: roadmap, isDark: isDark),
              ),
            ),
            SliverList.builder(
              itemCount: roadmap.levels.length,
              itemBuilder: (context, index) {
                final level = roadmap.levels[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    index == 0 ? 6 : 0,
                    20,
                    index == roadmap.levels.length - 1 ? 100 : 14,
                  ),
                  child: _RoadmapLevelCard(
                    roadmap: roadmap,
                    level: level,
                    levelNumber: index + 1,
                    isLast: index == roadmap.levels.length - 1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.bg2For(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderFor(context)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textFor(context),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(roadmap.icon, color: roadmap.color, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Resource Quest',
                        style: GoogleFonts.plusJakartaSans(
                          color: roadmap.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  roadmap.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textFor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  roadmap.description,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.text3For(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapProgressCard extends StatelessWidget {
  final LearningRoadmap roadmap;
  final bool isDark;

  const _RoadmapProgressCard({
    required this.roadmap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roadmap.color.withValues(alpha: isDark ? 0.22 : 0.16),
            AppColors.bg2For(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roadmap.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: roadmap.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: roadmap.color,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${roadmap.levels.length} levels - ${roadmap.totalMaterials} materials',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textFor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.28,
                    minHeight: 7,
                    backgroundColor: AppColors.borderFor(context),
                    valueColor: AlwaysStoppedAnimation<Color>(roadmap.color),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Complete levels, post your learnings, and earn aura.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.text3For(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapLevelCard extends StatelessWidget {
  final LearningRoadmap roadmap;
  final RoadmapLevel level;
  final int levelNumber;
  final bool isLast;

  const _RoadmapLevelCard({
    required this.roadmap,
    required this.level,
    required this.levelNumber,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final completed = levelNumber == 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: completed ? roadmap.color : AppColors.bg2For(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed
                      ? roadmap.color
                      : roadmap.color.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                completed ? Icons.check_rounded : Icons.flag_rounded,
                color: completed ? Colors.white : roadmap.color,
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 210,
                color: roadmap.color.withValues(alpha: 0.18),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.bg2For(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Level $levelNumber',
                      style: GoogleFonts.plusJakartaSans(
                        color: roadmap.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    _AuraRewardChip(
                      reward: '+${level.auraReward} aura',
                      color: roadmap.color,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  level.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textFor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  level.goal,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.text3For(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                ...level.materials.map(
                  (material) => _MaterialRow(
                    material: material,
                    color: roadmap.color,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: roadmap.color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Quest: ${level.quest}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.text2For(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final RoadmapMaterial material;
  final Color color;

  const _MaterialRow({
    required this.material,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(material.icon, color: color, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  material.detail,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.text3For(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraRewardChip extends StatelessWidget {
  final String reward;
  final Color color;

  const _AuraRewardChip({
    required this.reward,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        reward,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LearningRoadmap {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<RoadmapLevel> levels;

  const LearningRoadmap({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.levels,
  });

  int get totalMaterials =>
      levels.fold(0, (sum, level) => sum + level.materials.length);
}

class RoadmapLevel {
  final String title;
  final String goal;
  final String quest;
  final int auraReward;
  final List<RoadmapMaterial> materials;

  const RoadmapLevel({
    required this.title,
    required this.goal,
    required this.quest,
    required this.auraReward,
    required this.materials,
  });
}

class RoadmapMaterial {
  final String title;
  final String detail;
  final IconData icon;

  const RoadmapMaterial({
    required this.title,
    required this.detail,
    required this.icon,
  });
}

const List<LearningRoadmap> _learningRoadmaps = [
  LearningRoadmap(
    title: 'Top 10 DSA Problems',
    subtitle: 'Practice path with levels',
    description: 'A short DSA quest for interviews and coding rounds.',
    icon: Icons.storage_rounded,
    color: Colors.blue,
    levels: [
      RoadmapLevel(
        title: 'Array Starter',
        goal: 'Build confidence with the patterns used in most easy rounds.',
        quest:
            'Solve Two Sum and Best Time to Buy/Sell Stock, then post one trick you learned.',
        auraReward: 20,
        materials: [
          RoadmapMaterial(
            title: 'Two Sum',
            detail: 'Hash map lookup, complements, and one-pass thinking.',
            icon: Icons.functions_rounded,
          ),
          RoadmapMaterial(
            title: 'Best Time to Buy/Sell Stock',
            detail: 'Track minimum price and maximum profit in one scan.',
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Pointers & Windows',
        goal: 'Learn to reduce nested loops into clean linear scans.',
        quest:
            'Solve Valid Palindrome, Container With Most Water, and Longest Substring Without Repeating Characters.',
        auraReward: 35,
        materials: [
          RoadmapMaterial(
            title: 'Two Pointer Notes',
            detail:
                'When a sorted or boundary-based problem can shrink inward.',
            icon: Icons.compare_arrows_rounded,
          ),
          RoadmapMaterial(
            title: 'Sliding Window Notes',
            detail:
                'Use a moving range for longest, shortest, and count problems.',
            icon: Icons.view_week_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Core Interview Set',
        goal: 'Cover the patterns that frequently decide shortlists.',
        quest:
            'Finish Merge Intervals, Binary Search, Valid Parentheses, Number of Islands, and Climbing Stairs.',
        auraReward: 50,
        materials: [
          RoadmapMaterial(
            title: 'Intervals + Search',
            detail:
                'Sort intervals first, and write binary search from a template.',
            icon: Icons.timeline_rounded,
          ),
          RoadmapMaterial(
            title: 'Stack, Graph, DP',
            detail:
                'Use stack for matching, DFS/BFS for grids, and recurrence for DP.',
            icon: Icons.account_tree_rounded,
          ),
        ],
      ),
    ],
  ),
  LearningRoadmap(
    title: 'System Design Roadmap',
    subtitle: 'Scale beginner architectures',
    description: 'Move from app features to reliable, scalable systems.',
    icon: Icons.alt_route_rounded,
    color: Colors.green,
    levels: [
      RoadmapLevel(
        title: 'Web App Basics',
        goal:
            'Understand what happens between phone, server, database, and storage.',
        quest: 'Draw the architecture of DevSpace feed loading in four boxes.',
        auraReward: 20,
        materials: [
          RoadmapMaterial(
            title: 'Client Server Model',
            detail: 'Requests, responses, auth tokens, and API boundaries.',
            icon: Icons.http_rounded,
          ),
          RoadmapMaterial(
            title: 'Database Basics',
            detail: 'Tables, indexes, constraints, and why reads need shape.',
            icon: Icons.table_chart_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Reliability Layer',
        goal:
            'Design features that keep working when traffic or failures increase.',
        quest:
            'Explain caching, pagination, and rate limiting using the feed as an example.',
        auraReward: 35,
        materials: [
          RoadmapMaterial(
            title: 'Caching',
            detail:
                'Use cache for repeated reads and avoid stale critical writes.',
            icon: Icons.cached_rounded,
          ),
          RoadmapMaterial(
            title: 'Queues',
            detail:
                'Move slow jobs like notifications away from user requests.',
            icon: Icons.low_priority_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Design Practice',
        goal: 'Practice end-to-end designs for student app features.',
        quest:
            'Design a Q&A feed with votes, solved answers, and abuse limits.',
        auraReward: 50,
        materials: [
          RoadmapMaterial(
            title: 'Feed Design',
            detail: 'Ranking, fan-out, pagination, and freshness tradeoffs.',
            icon: Icons.dynamic_feed_rounded,
          ),
          RoadmapMaterial(
            title: 'Metrics',
            detail: 'Track latency, error rate, and feature-specific health.',
            icon: Icons.monitor_heart_rounded,
          ),
        ],
      ),
    ],
  ),
  LearningRoadmap(
    title: 'Git & GitHub Workflows',
    subtitle: 'Collaborative builder guide',
    description: 'A practical workflow for projects, teams, and open source.',
    icon: Icons.commit_rounded,
    color: Colors.purple,
    levels: [
      RoadmapLevel(
        title: 'Git Control',
        goal: 'Use Git without losing work or depending on random commands.',
        quest:
            'Create a branch, make two commits, and write clear commit messages.',
        auraReward: 20,
        materials: [
          RoadmapMaterial(
            title: 'Core Commands',
            detail: 'status, add, commit, branch, checkout, pull, and push.',
            icon: Icons.terminal_rounded,
          ),
          RoadmapMaterial(
            title: 'Commit Hygiene',
            detail: 'Small commits with messages that explain the change.',
            icon: Icons.edit_note_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Pull Request Flow',
        goal: 'Work with reviews and avoid breaking the main branch.',
        quest:
            'Open a PR with summary, screenshots if UI changed, and test notes.',
        auraReward: 35,
        materials: [
          RoadmapMaterial(
            title: 'PR Checklist',
            detail: 'What changed, why it changed, how it was tested.',
            icon: Icons.fact_check_rounded,
          ),
          RoadmapMaterial(
            title: 'Merge Conflicts',
            detail: 'Read the file, keep the intended code, then test again.',
            icon: Icons.merge_type_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Team Workflow',
        goal: 'Make GitHub useful for college teams and project launches.',
        quest:
            'Set up issues, labels, README tasks, and one release checklist.',
        auraReward: 50,
        materials: [
          RoadmapMaterial(
            title: 'Issues & Labels',
            detail: 'Split bugs, features, and polish tasks clearly.',
            icon: Icons.label_rounded,
          ),
          RoadmapMaterial(
            title: 'Release Notes',
            detail: 'Summarize user-facing changes and known issues.',
            icon: Icons.new_releases_rounded,
          ),
        ],
      ),
    ],
  ),
  LearningRoadmap(
    title: 'Build Open Source',
    subtitle: 'First contributions guide',
    description:
        'Learn how to contribute without guessing or spamming maintainers.',
    icon: Icons.rocket_launch_rounded,
    color: Colors.orange,
    levels: [
      RoadmapLevel(
        title: 'Find Your First Issue',
        goal: 'Pick contribution work that is small and actually useful.',
        quest:
            'Find one docs bug or small UI issue and describe the fix before coding.',
        auraReward: 20,
        materials: [
          RoadmapMaterial(
            title: 'Repo Reading',
            detail:
                'Read README, setup steps, issue history, and contribution guide.',
            icon: Icons.menu_book_rounded,
          ),
          RoadmapMaterial(
            title: 'Good First Issues',
            detail:
                'Prefer scoped fixes over large rewrites for your first PR.',
            icon: Icons.search_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Make a Clean PR',
        goal: 'Ship a contribution maintainers can review quickly.',
        quest: 'Submit one focused PR with screenshots or logs where relevant.',
        auraReward: 35,
        materials: [
          RoadmapMaterial(
            title: 'Local Setup',
            detail: 'Run the project, reproduce the issue, and test your fix.',
            icon: Icons.build_circle_rounded,
          ),
          RoadmapMaterial(
            title: 'PR Description',
            detail:
                'Include problem, solution, and verification in plain language.',
            icon: Icons.description_rounded,
          ),
        ],
      ),
      RoadmapLevel(
        title: 'Become Reliable',
        goal: 'Build identity through useful repeated contributions.',
        quest:
            'Follow up on review comments and write a learning post in DevSpace.',
        auraReward: 50,
        materials: [
          RoadmapMaterial(
            title: 'Review Replies',
            detail:
                'Respond clearly, update code, and avoid defensive replies.',
            icon: Icons.rate_review_rounded,
          ),
          RoadmapMaterial(
            title: 'Contribution Log',
            detail:
                'Track what you changed and what you learned for your profile.',
            icon: Icons.workspace_premium_rounded,
          ),
        ],
      ),
    ],
  ),
];
