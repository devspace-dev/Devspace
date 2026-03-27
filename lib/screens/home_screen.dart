import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/story_reel.dart';
import '../widgets/compose_box.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postsP = context.watch<PostsProvider>();
    final posts = postsP.posts;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.bg2,
      onRefresh: postsP.refreshFeed,
      edgeOffset: topInset,
      child: CustomScrollView(
        slivers: [
          // Offset content by the full visible glass app bar height.
          // Do not reduce this to toolbar-only spacing or headers will clip.
          SliverToBoxAdapter(
            child: SizedBox(height: topInset),
          ),

          // Story reel
          const SliverToBoxAdapter(child: StoryReel()),

          // Compose box
          const SliverToBoxAdapter(child: ComposeBox()),

          // Trending tags horizontal strip
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: kTrendingTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Text(
                    kTrendingTags[i],
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.text2, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),

          if (postsP.feedError != null && posts.isNotEmpty)
            SliverToBoxAdapter(
              child: _InlineWarningBanner(
                message: postsP.feedError!,
                actionLabel: 'Retry',
                onAction: () {
                  postsP.refreshFeed();
                },
              ),
            ),

          // Posts feed
          if (postsP.isLoading && posts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AppLoadingState(
                title: 'Loading feed',
                message: 'Pulling in the latest builds from your campus.',
              ),
            )
          else if (postsP.feedError != null && posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppErrorState(
                title: 'Feed unavailable',
                message: postsP.feedError!,
                actionLabel: 'Retry',
                onAction: () {
                  postsP.refreshFeed();
                },
              ),
            )
          else if (posts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.rocket_launch_rounded,
                title: 'No posts yet',
                message:
                    'Be the first to share what you are building with other student developers.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => PostCard(post: posts[i]),
                childCount: posts.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _InlineWarningBanner extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlineWarningBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
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
              style: const TextStyle(
                color: AppColors.text2,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
