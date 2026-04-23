import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  final UserModel? author;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Post'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: author != null
              ? PostCard(post: post)
              : FutureBuilder<UserModel?>(
                  future: context.read<UsersProvider>().getUser(post.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return PostCard(post: post);
                    }
                    return const Center(child: Text('User not found'));
                  },
                ),
        ),
      ),
    );
  }
}
