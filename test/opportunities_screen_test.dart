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

String _daysFromNow(int days) => DateTime.now()
    .add(Duration(days: days))
    .toIso8601String()
    .substring(0, 10);

EventAccessModel _event({
  required String id,
  required String title,
  required String type,
  String? bannerUrl,
  int requiredAura = 0,
  String? date,
  String? link,
}) {
  return EventAccessModel(
    id: id,
    title: title,
    description: 'A short description for $title.',
    requiredAura: requiredAura,
    link: link ?? 'https://example.com/$id',
    type: type,
    unlocked: requiredAura == 0,
    locked: requiredAura > 0,
    bannerUrl: bannerUrl,
    date: date ?? _daysFromNow(30),
    location: 'Hybrid',
    organizer: 'Example Org',
  );
}

Future<void> _pumpScreen(WidgetTester tester, List<EventAccessModel> events) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

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
        ChangeNotifierProvider<AuthProvider>.value(value: _FakeAuthProvider()),
      ],
      child: const MaterialApp(home: OpportunitiesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'opportunities screen uses designed banners instead of stock photos',
    (tester) async {
      await _pumpScreen(tester, [
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
      ]);

      // Overflow / layout errors surface here as exceptions.
      expect(tester.takeException(), isNull);
      expect(find.text('Upcoming Hackathons'), findsOneWidget);
      expect(find.text('Smart Campus Hackathon'), findsWidgets);

      // Scroll far enough to build the locked card too.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Stock photos (Unsplash) must never be fetched for cards.
      expect(find.byType(CachedNetworkImage), findsNothing);
    },
  );

  testWidgets('no built-in fake opportunities or hackathons are shown',
      (tester) async {
    await _pumpScreen(tester, const []);

    expect(tester.takeException(), isNull);
    expect(find.text('No opportunities found'), findsOneWidget);
    expect(find.text('Upcoming Hackathons'), findsNothing);
    expect(find.text('Microsoft Learn Student Ambassadors'), findsNothing);
    expect(find.text('Hack India 2025'), findsNothing);
  });

  testWidgets('past hackathons are not listed as upcoming', (tester) async {
    await _pumpScreen(tester, [
      _event(
        id: 'old',
        title: 'Last Year Hackathon',
        type: 'Hackathon',
        date: _daysFromNow(-40),
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Upcoming Hackathons'), findsNothing);
  });

  testWidgets('international (Devpost) hackathons are hidden', (tester) async {
    await _pumpScreen(tester, [
      _event(
        id: 'in',
        title: 'Bengaluru Build Day',
        type: 'Hackathon',
        link: 'https://bengaluru-build-day.devfolio.co',
      ),
      _event(
        id: 'intl',
        title: 'Global Online Jam',
        type: 'Hackathon',
        link: 'https://global-online-jam.devpost.com/',
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Bengaluru Build Day'), findsWidgets);
    expect(find.text('Global Online Jam'), findsNothing);
    expect(find.text('1 opportunity'), findsOneWidget);
  });

  testWidgets('shows a result count and See all opens the Hackathons filter',
      (tester) async {
    await _pumpScreen(tester, [
      _event(id: 'h1', title: 'Campus Hack', type: 'Hackathon'),
      _event(id: 'i1', title: 'Backend Internship', type: 'Internship'),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('2 opportunities'), findsOneWidget);
    expect(find.text('Backend Internship'), findsOneWidget);

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('1 opportunity'), findsOneWidget);
    expect(find.text('Backend Internship'), findsNothing);
    // Already on the Hackathons filter, so the link is no longer offered.
    expect(find.text('See all'), findsNothing);
  });
}
