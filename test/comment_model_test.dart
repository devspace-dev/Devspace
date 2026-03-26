import 'package:devspace/models/comment_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() {
  test('comment model parses Mongo comment documents', () {
    final comment = CommentModel.fromJson({
      '_id': ObjectId.fromHexString('65a123456789abcdef123456'),
      'postId': ObjectId.fromHexString('65a123456789abcdef123457'),
      'uid': ObjectId.fromHexString('65a123456789abcdef123458'),
      'text': 'This is solid work.',
      'createdAt': DateTime.utc(2026, 3, 25, 12, 30),
    });

    expect(comment.id, '65a123456789abcdef123456');
    expect(comment.postId, '65a123456789abcdef123457');
    expect(comment.userId, '65a123456789abcdef123458');
    expect(comment.text, 'This is solid work.');
    expect(comment.createdAt, DateTime.utc(2026, 3, 25, 12, 30).toLocal());
  });
}
