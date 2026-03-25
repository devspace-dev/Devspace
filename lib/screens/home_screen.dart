import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/story_reel.dart';
import '../widgets/compose_box.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostsProvider>().posts;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.bg2,
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 800)),
      child: CustomScrollView(
        slivers: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    kTrendingTags[i],
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),

          // Posts feed
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
