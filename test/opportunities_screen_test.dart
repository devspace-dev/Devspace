import 'package:cached_network_image/cached_network_image.dart';
import 'package:devspace/models/aura_summary_model.dart';
import 'package:devspace/models/event_access_model.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/screens/opportunities_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? get currentUserOrNull => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EventAccessModel _event({
  required String id,
  required String title,
  required String type,
  String? bannerUrl,
  int requiredAura = 0,
}) {
  return EventAccessModel(
    id: id,
    title: title,
    description: 'A short description for $title.',
    requiredAura: requiredAura,
    link: 'https://example.com/$id',
    type: type,
    unlocked: requiredAura == 0,
    locked: requiredAura > 0,
    bannerUrl: bannerUrl,
    date: '2026-10-20',
    location: 'Hybrid',
    organizer: 'Example Org',
  );
}

void main() {
  testWidgets(
    'opportunities screen uses designed banners instead of stock photos',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final events = [
        _event(id: 'h1', title: 'Smart Campus Hackathon', type: 'Hackathon'),
        _event(
          id: 'h2',
          title: 'Build Week',
          type: 'Hackathon',
          bannerUrl:
              'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800',
        ),
        _event(
          id: 'o1',
          title: 'Open Source Fellowship',
          type: 'Fellowship',
          requiredAura: 500,
        ),
      ];

      final engagement = EngagementProvider(
        auraSummaryLoader: () async => const AuraSummaryModel(
          userId: 'user-1',
          auraPoints: 120,
          level: 'Builder',
          currentStreak: 1,
          longestStreak: 1,
          lastChallengeCompletedOn: null,
          badges: [],
        ),
        eligibleEventsLoader: () async => events,
        dailyChallengeLoader: ({techStack}) async => null,
        weeklyFreeChallengeLoader: ({techStack}) async => [],
        refreshCurrentUser: () async {},
      );
      await engagement.fetchOverview();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<EngagementProvider>.value(value: engagement),
            ChangeNotifierProvider<AuthProvider>.value(
                value: _FakeAuthProvider()),
          ],
          child: const MaterialApp(home: OpportunitiesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Overflow / layout errors surface here as exceptions.
      expect(tester.takeException(), isNull);
      expect(find.text('Upcoming Hackathons'), findsOneWidget);
      expect(find.text('Smart Campus Hackathon'), findsWidgets);

      // Scroll far enough to build the locked card and the merged extras.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Stock photos (Unsplash) must never be fetched for cards.
      expect(find.byType(CachedNetworkImage), findsNothing);
    },
  );
}
