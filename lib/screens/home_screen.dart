import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/posts_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/compose_box.dart';
import '../widgets/engagement_overview.dart';
import '../widgets/post_card.dart';
import '../widgets/post_shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
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
    final postsP = context.watch<PostsProvider>();
    final posts = postsP.posts;

    return RefreshIndicator.adaptive(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          postsP.refreshFeed(),
          context.read<EngagementProvider>().fetchOverview(),
        ]);
      },
      edgeOffset: 0,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverToBoxAdapter(child: ComposeBox()),
          const SliverToBoxAdapter(child: EngagementOverview()),
          if (postsP.feedError != null && posts.isNotEmpty)
            SliverToBoxAdapter(
              child: _InlineWarningBanner(
                message: postsP.feedError!,
                onRetry: postsP.refreshFeed,
              ),
            ),
          if (postsP.isLoading && posts.isEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const PostShimmer(),
                childCount: 5,
              ),
            )
          else if (postsP.feedError != null && posts.isEmpty)
            SliverFillRemaining(
              child: AppErrorState(
                title: 'Feed unavailable',
                message: postsP.feedError!,
                actionLabel: 'Retry',
                onAction: postsP.refreshFeed,
              ),
            )
          else if (posts.isEmpty)
            const SliverFillRemaining(
              child: AppEmptyState(
                icon: Icons.auto_awesome_rounded,
                title: 'No Posts',
                message: 'Be the first to share an update.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => PostCard(post: posts[i])
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (i % 5 * 100).ms)
                      .moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                  childCount: posts.length,
                ),
              ),
            ),
          if (postsP.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            )
          else if (!postsP.hasMore && posts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'You are caught up.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text3For(context),
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _InlineWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineWarningBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.text2For(context),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
