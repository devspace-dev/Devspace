import 'dart:io';

import 'package:devspace/providers/posts_provider.dart';
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
}
