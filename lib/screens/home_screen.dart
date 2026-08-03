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

              // 2. Active Discussions Header
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
}
