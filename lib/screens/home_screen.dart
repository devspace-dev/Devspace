import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/posts_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/compose_box.dart';
import '../widgets/engagement_overview.dart';
import '../widgets/post_card.dart';

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
          const SliverToBoxAdapter(child: _HomeIntro()),
          const SliverToBoxAdapter(child: ComposeBox()),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: EngagementOverview()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: _TrendingTags(tags: kTrendingTags),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                children: [
                  Text(
                    'Latest from builders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textFor(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${posts.length} posts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text3For(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (postsP.feedError != null && posts.isNotEmpty)
            SliverToBoxAdapter(
              child: _InlineWarningBanner(
                message: postsP.feedError!,
                onRetry: postsP.refreshFeed,
              ),
            ),
          if (postsP.isLoading && posts.isEmpty)
            const SliverFillRemaining(
              child: AppLoadingState(
                title: 'Loading',
                message: 'Fetching the latest updates...',
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
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => PostCard(post: posts[i]),
                childCount: posts.length,
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

class _HomeIntro extends StatelessWidget {
  const _HomeIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus builder feed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: AppColors.textFor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track projects, ask doubts, and stay visible to other student builders without the noise.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.text3For(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingTags extends StatelessWidget {
  final List<String> tags;

  const _TrendingTags({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending topics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textFor(context),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgFor(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderFor(context)),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2For(context),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
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
