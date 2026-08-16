import 'package:devspace/models/badge_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BadgeModel & Aura Progress', () {
    test('getBadge returns default Aura badge', () {
      expect(getBadge(0).name, 'Aura');
      expect(getBadge(150).name, 'Aura');
      expect(getBadge(1000).name, 'Aura');
    });

    test('getNextBadge returns null for flat aura model', () {
      expect(getNextBadge(0), isNull);
      expect(getNextBadge(100), isNull);
    });

    test('getAuraProgress returns 1.0 for flat aura model', () {
      expect(getAuraProgress(0), 1.0);
      expect(getAuraProgress(500), 1.0);
    });
  });
}
