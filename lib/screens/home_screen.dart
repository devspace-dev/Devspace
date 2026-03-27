import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return RefreshIndicator.adaptive(
      color: AppColors.primary,
      onRefresh: postsP.refreshFeed,
      edgeOffset: topInset,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topInset),
          ),

          const SliverToBoxAdapter(child: ComposeBox()),

          SliverToBoxAdapter(
            child: Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: kTrendingTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, i) => Text(
                  kTrendingTags[i],
                  style: const TextStyle(
                    fontSize: 14, 
                    color: AppColors.text3, 
                    fontWeight: FontWeight.w600,
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

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
