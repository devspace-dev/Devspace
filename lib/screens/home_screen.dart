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
              child: AppInlineError(
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
              child: _WelcomeCard(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    return RepaintBoundary(
                      child: PostCard(post: posts[i]),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            ),
          if (postsP.isLoadingMore)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const PostShimmer(),
                childCount: 2,
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



class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bg2For(context),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.borderFor(context)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to DevSpace',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textFor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The feed is quiet right now. Start the conversation by sharing what you are building or learning today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.text2For(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bg3For(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Earn your first 10 Aura points by posting your first builder update.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text2For(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
