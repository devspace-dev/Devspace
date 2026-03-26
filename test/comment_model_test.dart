import 'package:devspace/models/comment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('comment model parses Supabase comment rows', () {
    final comment = CommentModel.fromJson({
      'id': 'comment-1',
      'post_id': 'post-1',
      'user_id': 'user-1',
      'content': 'This is solid work.',
      'created_at': '2026-03-25T12:30:00Z',
    });

    expect(comment.id, 'comment-1');
    expect(comment.postId, 'post-1');
    expect(comment.userId, 'user-1');
    expect(comment.text, 'This is solid work.');
    expect(comment.createdAt, DateTime.utc(2026, 3, 25, 12, 30).toLocal());
  });
}
