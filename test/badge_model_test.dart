import 'package:devspace/models/badge_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BadgeModel & Aura Progress', () {
    test('getBadge returns correct badge for aura points', () {
      expect(getBadge(0).name, 'Seed');
      expect(getBadge(149).name, 'Seed');
      expect(getBadge(150).name, 'Sprout');
      expect(getBadge(999).name, 'Sprout');
      expect(getBadge(1000).name, 'Spark');
      expect(getBadge(1999).name, 'Spark');
      expect(getBadge(2000).name, 'Flame');
      expect(getBadge(3000).name, 'Voltage');
      expect(getBadge(5000).name, 'Nova');
      expect(getBadge(1000000).name, 'Nova');
    });

    test('getNextBadge returns correct next level', () {
      expect(getNextBadge(0)?.name, 'Sprout');
      expect(getNextBadge(149)?.name, 'Sprout');
      expect(getNextBadge(150)?.name, 'Spark');
      expect(getNextBadge(999)?.name, 'Spark');
      expect(getNextBadge(4999)?.name, 'Nova');
      expect(getNextBadge(5000), isNull);
    });

    test('getAuraProgress calculates percentage within current tier', () {
      // Seed tier: 0 to 149 (150 points total range)
      expect(getAuraProgress(0), 0.0);
      expect(getAuraProgress(75), closeTo(0.5, 0.01));
      
      // Sprout tier: 150 to 999 (850 points total range)
      expect(getAuraProgress(150), 0.0);
      expect(getAuraProgress(150 + 425), closeTo(0.5, 0.01));
      
      // Nova tier (Max)
      expect(getAuraProgress(5000), 1.0);
      expect(getAuraProgress(10000), 1.0);
    });
  });
}
