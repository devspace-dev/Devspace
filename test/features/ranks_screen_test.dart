import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/features/ranks/screens/ranks_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  UserModel makeUser({
    required String id,
    required String name,
    required String handle,
    required int aura,
    String college = 'Apex University',
  }) {
    return UserModel(
      id: id,
      name: name,
      handle: handle,
      email: '$handle@example.com',
      avatar: '',
      color: Colors.black,
      aura: aura,
      roles: const ['Student'],
      year: '2nd Year',
      branch: 'CSE',
      building: 'Block A',
      stack: const ['Flutter'],
      followers: 5,
      following: 5,
      bio: 'Builder',
      college: college,
      githubHandle: handle,
      profileCompleted: true,
      currentStreak: 3,
    );
  }

  Widget createRanksApp({
    UserModel? currentUser,
    List<UserModel>? users,
    LeaderboardLoader? leaderboardLoader,
  }) {
    final me = currentUser ?? makeUser(id: 'me', name: 'Me Builder', handle: 'me', aura: 500);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: me,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: users ?? [],
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: RanksScreen(leaderboardLoader: leaderboardLoader),
      ),
    );
  }

  testWidgets('RanksScreen shows empty state when no users have aura', (tester) async {
    await tester.pumpWidget(createRanksApp(users: []));
    await tester.pumpAndSettle();

    expect(find.text('RANKS'), findsOneWidget);
    expect(find.text('Season just started.'), findsOneWidget);
    expect(find.text('Be the first on the board.'), findsOneWidget);
    expect(find.text('Unranked'), findsOneWidget);
    expect(find.text('0 AURA'), findsOneWidget);
  });

  testWidgets('RanksScreen shows Top 3 Podium, UTC reset banner, and ranks 4+ with tier tags', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final userList = [
      makeUser(id: 'u1', name: 'Alice Stark', handle: 'alice', aura: 3500),
      makeUser(id: 'u2', name: 'Bob Wayne', handle: 'bob', aura: 2200),
      makeUser(id: 'u3', name: 'Charlie Kent', handle: 'charlie', aura: 950),
      makeUser(id: 'u4', name: 'Dave Banner', handle: 'dave', aura: 600),
      makeUser(id: 'u5', name: 'Eve Parker', handle: 'eve', aura: 150),
    ];

    await tester.pumpWidget(createRanksApp(
      currentUser: userList[0],
      users: userList,
    ));
    await tester.pumpAndSettle();

    // Title & UTC reset banner (no fake rivalry text)
    expect(find.text('RANKS'), findsOneWidget);
    expect(find.text('Resets 1st of month · 05:30 IST (00:00 UTC)'), findsOneWidget);
    expect(find.textContaining('Apex Tech'), findsNothing);

    // Filter pills
    expect(find.text('MONTHLY'), findsOneWidget);
    expect(find.text('ALL TIME'), findsOneWidget);
    expect(find.text('COLLEGE'), findsOneWidget);

    // Top 3 Podium
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);

    // Ranks 4+
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('#5'), findsOneWidget);
    expect(find.text('Dave Banner'), findsOneWidget);
    expect(find.text('Eve Parker'), findsOneWidget);

    // Tier tags (DsTag uppercases text)
    expect(find.text('BUG HUNTER'), findsOneWidget); // 600 aura
    expect(find.text('ROOKIE'), findsOneWidget); // 150 aura

    // Pinned YOU bottom sheet for Alice (#1)
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('#1'), findsWidgets);
  });

  testWidgets('RanksScreen assigns shared competition ranks on ties and excludes 0-aura users', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final userList = [
      makeUser(id: 'u1', name: 'Alice', handle: 'alice', aura: 500),
      makeUser(id: 'u2', name: 'Bob', handle: 'bob', aura: 400),
      makeUser(id: 'u3', name: 'Charlie', handle: 'charlie', aura: 300),
      makeUser(id: 'u4', name: 'Hari', handle: 'hari', aura: 80),
      makeUser(id: 'u5', name: 'Sampark', handle: 'sampark', aura: 80),
      makeUser(id: 'u6', name: 'Rohit', handle: 'rohit', aura: 75),
      makeUser(id: 'u7', name: 'Zero User', handle: 'zero', aura: 0),
      makeUser(id: 'u8', name: 'Other Zero', handle: 'otherzero', aura: 0),
    ];

    await tester.pumpWidget(createRanksApp(
      currentUser: userList[6],
      users: userList,
    ));
    await tester.pumpAndSettle();

    expect(find.text('#4'), findsNWidgets(2)); // Hari and Sampark tie at #4
    expect(find.text('#5'), findsNothing);
    expect(find.text('#6'), findsOneWidget); // Rohit is #6
    expect(find.text('Other Zero'), findsNothing); // 0-aura filtered from board
    expect(find.text('Zero User'), findsOneWidget); // shown only in YOU bar
    expect(find.text('Unranked'), findsOneWidget);
    expect(find.text('0 AURA'), findsOneWidget);
  });

  testWidgets('RanksScreen preserves monthly board aura without overwriting with profile aura', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final meAllTime = makeUser(id: 'me', name: 'Harshit', handle: 'harshit', aura: 790);

    await tester.pumpWidget(createRanksApp(
      currentUser: meAllTime,
      leaderboardLoader: ({required isMonthly, college}) async => [
        makeUser(id: 'u1', name: 'Raja', handle: 'rexxon', aura: 120),
        makeUser(id: 'me', name: 'Harshit', handle: 'harshit', aura: 45),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('45 AURA'), findsOneWidget);
    expect(find.text('790 AURA'), findsNothing);
    expect(find.text('#2'), findsOneWidget);
  });

  testWidgets('RanksScreen shows retry button when remote load fails', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(createRanksApp(
      leaderboardLoader: ({required isMonthly, college}) async {
        attempts++;
        if (attempts == 1) {
          throw Exception('Network error');
        }
        return [makeUser(id: 'u1', name: 'Raja', handle: 'rexxon', aura: 100)];
      },
    ));
    await tester.pumpAndSettle();

    expect(find.text('RETRY'), findsOneWidget);
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(find.text('Raja'), findsOneWidget);
  });

  testWidgets('RanksScreen switches filter pill active states on tap', (tester) async {
    final userList = [
      makeUser(id: 'u1', name: 'Alice Stark', handle: 'alice', aura: 1000),
    ];

    await tester.pumpWidget(createRanksApp(
      currentUser: userList[0],
      users: userList,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ALL TIME'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('COLLEGE'));
    await tester.pumpAndSettle();

    expect(find.text('GLOBAL'), findsOneWidget);
  });

  testWidgets('RanksScreen renders profile pictures with CachedNetworkImage when avatar URL is present', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final userWithPhoto = makeUser(
      id: 'u-photo',
      name: 'Zara Photon',
      handle: 'zara',
      aura: 4000,
    ).copyWith(
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    );

    final user2 = makeUser(id: 'u2', name: 'Bob Wayne', handle: 'bob', aura: 2200);
    final user3 = makeUser(id: 'u3', name: 'Charlie Kent', handle: 'charlie', aura: 950);
    final user4 = makeUser(
      id: 'u4',
      name: 'Dave Banner',
      handle: 'dave',
      aura: 600,
    ).copyWith(
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    );

    final list = [userWithPhoto, user2, user3, user4];

    await tester.pumpWidget(createRanksApp(
      currentUser: userWithPhoto,
      users: list,
    ));
    await tester.pumpAndSettle();

    // Verify CachedNetworkImage widgets are present for userWithPhoto (podium + pinned YOU row) and user4 (row 4)
    expect(find.byType(CachedNetworkImage), findsWidgets);
  });
}
