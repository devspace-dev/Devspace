import 'package:flutter_test/flutter_test.dart';
import 'package:devspace/data/badges_data.dart';

void main() {
  group('Community Badges Data Model', () {
    test('contains all 11 defined badges', () {
      expect(kCommunityBadges.length, 11);
    });

    test('all badges have unique keys and non-empty metadata', () {
      final keys = <String>{};
      for (final badge in kCommunityBadges) {
        expect(keys.contains(badge.key), isFalse, reason: 'Duplicate badge key: ${badge.key}');
        keys.add(badge.key);
        expect(badge.name.isNotEmpty, isTrue);
        expect(badge.icon.isNotEmpty, isTrue);
        expect(badge.description.isNotEmpty, isTrue);
        expect(badge.rule.isNotEmpty, isTrue);
      }
    });

    test('expected badge keys are present', () {
      final keys = kCommunityBadges.map((b) => b.key).toSet();
      expect(keys.contains('first_practice_solve'), isTrue);
      expect(keys.contains('practice_easy_cleared'), isTrue);
      expect(keys.contains('practice_medium_cleared'), isTrue);
      expect(keys.contains('practice_hard_cleared'), isTrue);
      expect(keys.contains('practice_ultra_cleared'), isTrue);
      expect(keys.contains('streak_3_days'), isTrue);
      expect(keys.contains('streak_7_days'), isTrue);
      expect(keys.contains('first_duel_win'), isTrue);
      expect(keys.contains('duel_winner_x10'), isTrue);
      expect(keys.contains('first_post'), isTrue);
      expect(keys.contains('connector_x10'), isTrue);
    });
  });
}
