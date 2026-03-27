import 'package:devspace/models/question_model.dart';
import 'package:devspace/models/question_reply_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('question model parses Supabase rows', () {
    final question = QuestionModel.fromJson({
      'id': 'question-1',
      'user_id': 'user-1',
      'title': 'How should I structure feature flags in Flutter?',
      'body': 'I want remote config without making the app messy.',
      'tags': ['flutter', 'architecture'],
      'upvotes_count': 7,
      'replies_count': 3,
      'solved_reply_id': 'reply-9',
      'created_at': '2026-03-27T10:30:00Z',
    });

    expect(question.id, 'question-1');
    expect(question.userId, 'user-1');
    expect(question.tags, ['flutter', 'architecture']);
    expect(question.upvotesCount, 7);
    expect(question.repliesCount, 3);
    expect(question.solvedReplyId, 'reply-9');
    expect(question.isSolved, isTrue);
    expect(question.createdAt, DateTime.utc(2026, 3, 27, 10, 30).toLocal());
  });

  test('question reply model parses Supabase rows', () {
    final reply = QuestionReplyModel.fromJson({
      'id': 'reply-1',
      'question_id': 'question-1',
      'user_id': 'user-2',
      'content': 'Keep the flags in one service and expose typed getters.',
      'created_at': '2026-03-27T12:00:00Z',
    });

    expect(reply.id, 'reply-1');
    expect(reply.questionId, 'question-1');
    expect(reply.userId, 'user-2');
    expect(reply.content, 'Keep the flags in one service and expose typed getters.');
    expect(reply.createdAt, DateTime.utc(2026, 3, 27, 12, 0).toLocal());
  });
}
