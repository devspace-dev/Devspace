import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../providers/posts_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/post_shimmer.dart';
import '../widgets/compose_box.dart';
import 'opportunities_screen.dart';
import 'people_screen.dart';

class ExploreScreen extends StatefulWidget {
  final int initialIndex;
  const ExploreScreen({super.key, this.initialIndex = 0});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Custom sliding segment control for Hub, Opportunities, Developers
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bg2Dark : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderFor(context).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.text3For(context),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Hub'),
                  Tab(text: 'Opportunities'),
                  Tab(text: 'Developers'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  HubTabView(),
                  OpportunitiesScreen(),
                  PeopleScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HubTabView extends StatefulWidget {
  const HubTabView({super.key});

  @override
  State<HubTabView> createState() => _HubTabViewState();
}

class _HubTabViewState extends State<HubTabView> {
  int _activeSubTab = 0; // 0: For You, 1: Following, 2: Projects
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostsProvider>().refreshFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      context.read<PostsProvider>().loadMoreFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsP = context.watch<PostsProvider>();
    final posts = postsP.posts;

    // Filter posts for subtabs
    List filteredPosts = posts;
    if (_activeSubTab == 2) {
      // Filter project-related updates (contain github links or keyword project)
      filteredPosts = posts.where((p) => p.content.toLowerCase().contains('github') || p.content.toLowerCase().contains('project') || p.content.toLowerCase().contains('build')).toList();
    }

    return RefreshIndicator.adaptive(
      color: AppColors.primary,
      onRefresh: () async {
        await postsP.refreshFeed();
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Sub-tabs segment
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

          // For You shows resources first
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
                      title: 'Top 10 DSA Problems',
                      subtitle: 'Master these in 2025',
                      icon: Icons.storage_rounded,
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    _buildResourceCard(
                      context,
                      title: 'System Design Roadmap',
                      subtitle: 'Scale beginner architectures',
                      icon: Icons.alt_route_rounded,
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    _buildResourceCard(
                      context,
                      title: 'Git & GitHub Workflows',
                      subtitle: 'Collaborative builder guide',
                      icon: Icons.commit_rounded,
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                    _buildResourceCard(
                      context,
                      title: 'Build Open Source',
                      subtitle: 'First contributions guide',
                      icon: Icons.rocket_launch_rounded,
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Active Discussions Header
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

          // Discussions feed list
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
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
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: AppColors.text4For(context), size: 16),
            ],
          ),
          const Spacer(),
          Text(
            title,
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
            subtitle,
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
    );
  }
}
