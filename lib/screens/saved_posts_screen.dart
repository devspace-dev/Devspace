import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/post_card.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().currentUser.id;
      context.read<PostsProvider>().fetchBookmarkedPosts(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser.id;
    final postsProvider = context.watch<PostsProvider>();
    final savedPosts = postsProvider.savedPosts;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.bgFor(context),
        elevation: 0,
        title: Text(
          'Saved posts',
          style: TextStyle(
            color: AppColors.textFor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (postsProvider.isSavedPostsLoading && savedPosts.isEmpty) {
            return const AppLoadingState(
              title: 'Loading saved posts',
              message: 'Fetching the posts you bookmarked.',
            );
          }

          if (postsProvider.savedPostsError != null && savedPosts.isEmpty) {
            return AppErrorState(
              title: 'Saved posts unavailable',
              message: postsProvider.savedPostsError!,
              actionLabel: 'Retry',
              onAction: () {
                postsProvider.fetchBookmarkedPosts(userId, force: true);
              },
            );
          }

          if (savedPosts.isEmpty) {
            return const AppEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'No saved posts yet',
              message: 'Save posts to revisit them later.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => postsProvider.fetchBookmarkedPosts(
              userId,
              force: true,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) {
                return PostCard(post: savedPosts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
