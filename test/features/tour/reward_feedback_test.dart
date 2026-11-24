import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/services/reward_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RewardFeedback.resetForTest();
  });

  group('RewardFeedback tests', () {
    test('defaults to enabled and persists toggling', () async {
      expect(await RewardFeedback.isHapticsEnabled(), isTrue);

      await RewardFeedback.setHapticsEnabled(false);
      expect(await RewardFeedback.isHapticsEnabled(), isFalse);

      await RewardFeedback.setHapticsEnabled(true);
      expect(await RewardFeedback.isHapticsEnabled(), isTrue);
    });

    test('plays all reward kinds cleanly when enabled without throwing', () async {
      await RewardFeedback.setHapticsEnabled(true);

      for (final kind in RewardKind.values) {
        expect(() async => await RewardFeedback.play(kind), returnsNormally);
      }
    });

    test('skips playing when haptics are disabled', () async {
      await RewardFeedback.setHapticsEnabled(false);
      expect(() async => await RewardFeedback.play(RewardKind.practice), returnsNormally);
    });
  });
}
