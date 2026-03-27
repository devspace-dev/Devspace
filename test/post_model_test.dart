import 'package:devspace/models/post_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('post model parses quote post rows', () {
    final post = PostModel.fromJson({
      'id': 'post-2',
      'user_id': 'user-2',
      'content': 'My take on this build',
      'tags': ['flutter'],
      'image_url': '',
      'quote_post_id': 'post-1',
      'likes_count': 4,
      'comments_count': 2,
      'reposts_count': 3,
      'created_at': '2026-03-27T08:00:00Z',
    });

    expect(post.id, 'post-2');
    expect(post.userId, 'user-2');
    expect(post.quotePostId, 'post-1');
    expect(post.reposts, 3);
    expect(post.createdAt, DateTime.utc(2026, 3, 27, 8, 0).toLocal());
  });
}
