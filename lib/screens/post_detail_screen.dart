import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
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
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Ds.bone),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('POST', style: DsText.h3.copyWith(color: Ds.bone, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: author != null
              ? PostCard(post: post)
              : FutureBuilder<UserModel?>(
                  future: context.read<UsersProvider>().getUser(post.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: CircularProgressIndicator(color: Ds.aura),
                        ),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return PostCard(post: post);
                    }
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'User not found',
                          style: DsText.body.copyWith(color: Ds.muted),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
