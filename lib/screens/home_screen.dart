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
          const SliverToBoxAdapter(child: ComposeBox()),
          const SliverToBoxAdapter(child: EngagementOverview()),
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: AppColors.borderFor(context), width: 0.5)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: kTrendingTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => Center(
                  child: Text(
                    kTrendingTags[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text3For(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (postsP.isLoading && posts.isEmpty)
            const SliverFillRemaining(
              child: AppLoadingState(
                title: 'Loading',
                message: 'Fetching the latest updates...',
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
