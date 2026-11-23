import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/features/play/screens/play_screen.dart';
import 'package:devspace/features/profile/screens/profile_screen.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/features/tour/widgets/first_quests_card.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:devspace/providers/practice_provider.dart';
import 'package:devspace/providers/theme_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/features/path/providers/path_provider.dart';
import 'package:devspace/features/path/screens/path_screen.dart';
import 'package:devspace/features/path/models/roadmap_model.dart';
import 'package:devspace/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TourAnchorRegistry.instance.clear();
  });

  final testUser = UserModel(
    id: 'test-overflow-user',
    name: 'Long Name Builder Student Extraordinaire',
    handle: 'verylonghandlename123',
    email: 'builder@example.com',
    avatar: '',
    color: Colors.blue,
    aura: 500,
    roles: const ['Student'],
    year: '4th Year',
    branch: 'Computer Science and Engineering',
    building: 'Block C Complex',
    stack: const ['Flutter', 'PostgreSQL', 'TypeScript', 'Docker'],
    followers: 1240,
    following: 890,
    bio: 'Testing overflow under 200% text scale on 360dp screens',
    college: 'International Institute of Information Technology',
    githubHandle: 'verylonghandlename123',
    profileCompleted: true,
    currentStreak: 14,
  );

  Widget wrapWith200PercentScale({
    required Widget child,
    Size screenSize = const Size(360, 640),
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: const TextScaler.linear(2.0),
      ),
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Overflow Immunity: 200% Font Scale on 360dp Screen', () {
    testWidgets('PlayScreen renders without RenderFlex overflow', (tester) async {
      final auth = AuthProvider(initialUser: testUser, listenToAuthChanges: false);
      final engagement = EngagementProvider();
      final controller = TourController();

      FlutterErrorDetails? caughtError;
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
      };

      try {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<EngagementProvider>.value(value: engagement),
              ChangeNotifierProvider<TourController>.value(value: controller),
            ],
            child: wrapWith200PercentScale(child: const PlayScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(caughtError, isNull, reason: 'PlayScreen overflowed at 200% font scale');
        expect(find.text('QUEUE UP'), findsOneWidget);
        expect(find.text('FIRST QUESTS'), findsOneWidget);
      } finally {
        FlutterError.onError = prevHandler;
      }
    });

    testWidgets('ProfileScreen renders without RenderFlex overflow', (tester) async {
      final auth = AuthProvider(initialUser: testUser, listenToAuthChanges: false);
      final users = UsersProvider();

      FlutterErrorDetails? caughtError;
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
      };

      try {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<UsersProvider>.value(value: users),
            ],
            child: wrapWith200PercentScale(child: const ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(caughtError, isNull, reason: 'ProfileScreen overflowed at 200% font scale');
        expect(find.text('FOLLOWERS'), findsOneWidget);
        expect(find.text('FOLLOWING'), findsOneWidget);
      } finally {
        FlutterError.onError = prevHandler;
      }
    });

    testWidgets('FirstQuestsCard renders without RenderFlex overflow', (tester) async {
      final auth = AuthProvider(initialUser: testUser, listenToAuthChanges: false);
      final controller = TourController();

      FlutterErrorDetails? caughtError;
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
      };

      try {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<TourController>.value(value: controller),
            ],
            child: wrapWith200PercentScale(
              child: const SingleChildScrollView(
                child: FirstQuestsCard(showBadgeQuest: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(caughtError, isNull, reason: 'FirstQuestsCard overflowed at 200% font scale');
        expect(find.text('FIRST QUESTS'), findsOneWidget);
      } finally {
        FlutterError.onError = prevHandler;
      }
    });

    testWidgets('SettingsScreen renders without RenderFlex overflow', (tester) async {
      final auth = AuthProvider(initialUser: testUser, listenToAuthChanges: false);
      final controller = TourController();
      final theme = ThemeProvider();

      FlutterErrorDetails? caughtError;
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
      };

      try {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<TourController>.value(value: controller),
              ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ],
            child: wrapWith200PercentScale(child: const SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(caughtError, isNull, reason: 'SettingsScreen overflowed at 200% font scale');
      } finally {
        FlutterError.onError = prevHandler;
      }
    });

    testWidgets('PathScreen with PathActiveView renders without RenderFlex overflow at 200% font scale', (tester) async {
      final auth = AuthProvider(initialUser: testUser, listenToAuthChanges: false);
      final fakeSelections = [
        UserRoadmapSelection(
          id: 'sel_1',
          userId: 'test-overflow-user',
          roadmapId: 'flutter',
          status: 'active',
          level: RoadmapLevel.beginner,
          weeklyHours: 6,
          startedAt: DateTime(2026, 11, 20),
          updatedAt: DateTime(2026, 11, 20),
        ),
      ];
      final pathProvider = PathProvider(
        currentUserIdGetter: () => 'test-overflow-user',
        userRoadmapsLoader: (userId) async => fakeSelections,
        roadmapProgressLoader: (userId, roadmapId) async => {'fl_dart_basics'},
      );
      await pathProvider.loadUserRoadmaps();

      FlutterErrorDetails? caughtError;
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
      };

      try {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<PathProvider>.value(value: pathProvider),
            ],
            child: wrapWith200PercentScale(child: const PathScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(caughtError, isNull, reason: 'PathScreen overflowed at 200% font scale on 360dp');
        expect(find.text('FLUTTER APP DEVELOPER'), findsOneWidget);
        expect(find.text('ALL PATHS'), findsOneWidget);
      } finally {
        FlutterError.onError = prevHandler;
      }
    });
  });
}
