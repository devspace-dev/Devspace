import 'dart:io';

import 'package:devspace/models/post_model.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('post validation blocks empty submit with no image', () {
    expect(PostsProvider.canCreatePost(''), isFalse);
    expect(PostsProvider.canCreatePost('   '), isFalse);
  });

  test('post validation allows text-only and image-only posts', () {
    expect(PostsProvider.canCreatePost('Build update'), isTrue);
    expect(
      PostsProvider.canCreatePost(
        '',
        imageFile: File('test/fixtures/fake-image.png'),
      ),
      isTrue,
    );
  });

  test('fetchFeed loads the first page and hydrates reaction state', () async {
    final provider = PostsProvider(
      postsPageLoader: ({
        required int limit,
        required int offset,
      }) async {
        expect(limit, 20);
        expect(offset, 0);
        return [
          _post(id: 'post-1'),
          _post(id: 'post-2'),
        ];
      },
      currentUserResolver: () => _user(),
      likedPostIdsLoader: (_) async => {'post-1'},
      bookmarkedPostIdsLoader: (_) async => {'post-2'},
    );

    await provider.fetchFeed();

    expect(provider.isLoading, isFalse);
    expect(provider.feedError, isNull);
    expect(provider.hasMore, isFalse);
    expect(provider.posts, hasLength(2));
    expect(provider.posts[0].isLiked, isTrue);
    expect(provider.posts[0].isBookmarked, isFalse);
    expect(provider.posts[1].isLiked, isFalse);
    expect(provider.posts[1].isBookmarked, isTrue);
  });

  test('loadMoreFeed appends unique posts and preserves pagination state', () async {
    final requestedOffsets = <int>[];
    final provider = PostsProvider(
      postsPageLoader: ({
        required int limit,
        required int offset,
      }) async {
        requestedOffsets.add(offset);
        if (offset == 0) {
          return List.generate(20, (index) => _post(id: 'post-$index'));
        }
        return [
          _post(id: 'post-19'),
          _post(id: 'post-20'),
          _post(id: 'post-21'),
        ];
      },
      currentUserResolver: () => null,
    );

    await provider.fetchFeed();
    await provider.loadMoreFeed();

    expect(requestedOffsets, [0, 20]);
    expect(provider.isLoadingMore, isFalse);
    expect(provider.feedError, isNull);
    expect(provider.hasMore, isFalse);
    expect(provider.posts, hasLength(22));
    expect(provider.posts.map((post) => post.id).toSet(), hasLength(22));
  });
}

PostModel _post({required String id}) {
  return PostModel(
    id: id,
    userId: 'user-1',
    content: 'Build update for $id',
    tags: const ['flutter'],
    createdAt: DateTime.utc(2026, 3, 28),
  );
}

UserModel _user() {
  return UserModel(
    id: 'user-1',
    name: 'Test User',
    handle: 'test_user',
    email: 'test@example.com',
    avatar: 'TU',
    color: const Color(0xFF123456),
    aura: 0,
    role: 'Student',
    year: '3rd Year',
    branch: 'CSE',
    building: 'Lab 1',
    stack: const ['Flutter'],
    followers: 0,
    following: 0,
    bio: '',
    college: 'DevSpace College',
    githubHandle: '',
    profileCompleted: true,
  );
}
