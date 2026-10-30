import 'package:flutter/material.dart';
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
        home: const RanksScreen(),
      ),
    );
  }

  testWidgets('RanksScreen shows empty state when no users have aura', (tester) async {
    await tester.pumpWidget(createRanksApp(users: []));
    await tester.pumpAndSettle();

    expect(find.text('RANKS'), findsOneWidget);
    expect(find.text('Season just started.'), findsOneWidget);
    expect(find.text('Be the first on the board.'), findsOneWidget);
  });

  testWidgets('RanksScreen shows Top 3 Podium and ranks 4+ with tier tags', (tester) async {
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

    // Title & Rivalry
    expect(find.text('RANKS'), findsOneWidget);
    expect(find.textContaining('Apex vs Apex Tech'), findsOneWidget);

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
}
