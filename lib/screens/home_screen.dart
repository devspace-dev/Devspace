import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/app_state_widgets.dart';
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
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Offset content by the full visible glass app bar height.
          SliverToBoxAdapter(
            child: SizedBox(height: topInset + 10),
          ),

          // Compose box
          const SliverToBoxAdapter(child: ComposeBox()),

          // Trending tags horizontal strip
          SliverToBoxAdapter(
            child: Container(
              height: 54,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: kTrendingTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      kTrendingTags[i],
                      style: const TextStyle(
                        fontSize: 13, 
                        color: AppColors.text2, 
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ).animate().scale(delay: (i * 50).ms, duration: 400.ms, curve: Curves.elasticOut),
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
                title: 'Syncing Lab',
                message: 'Pulling in the latest builds from your campus.',
              ),
            )
          else if (postsP.feedError != null && posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppErrorState(
                title: 'Lab Offline',
                message: postsP.feedError!,
                actionLabel: 'Reconnect',
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
                title: 'Silence in the Lab',
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ).animate().shake();
  }
}
