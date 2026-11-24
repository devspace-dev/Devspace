import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/features/profile/screens/profile_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testUser = UserModel(
    id: 'u-self',
    name: 'Harshit Raj',
    handle: 'harshit',
    email: 'harshit@example.com',
    avatar: '',
    color: Colors.black,
    aura: 820,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'DevSpace',
    stack: const ['Flutter', 'PostgreSQL', 'Dart'],
    followers: 15,
    following: 10,
    bio: 'Student builder',
    college: 'IIIT Delhi',
    githubHandle: 'harshit',
    profileCompleted: true,
    currentStreak: 6,
  );

  Widget createProfileApp({UserModel? user, List<UserModel>? users}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: user ?? testUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: users ?? [user ?? testUser],
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const ProfileScreen(),
      ),
    );
  }

  testWidgets('ProfileScreen renders user info, rank tag, and 3 stat cards', (tester) async {
    await tester.pumpWidget(createProfileApp());
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Harshit Raj'), findsOneWidget);
    expect(find.textContaining('@harshit'), findsOneWidget);
    expect(find.text('BUG HUNTER'), findsOneWidget); // 820 aura -> Bug Hunter

    // Three stat cards
    expect(find.text('DAY STREAK'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('COLLEGE RANK'), findsOneWidget);
    expect(find.text('SOLVED'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders badges and tech stack chips', (tester) async {
    await tester.pumpWidget(createProfileApp());
    await tester.pumpAndSettle();

    expect(find.text('BADGES'), findsOneWidget);
    expect(find.text('First Practice Solve'), findsOneWidget);
    expect(find.text('Easy Cleared'), findsOneWidget);
    expect(find.text('Medium Cleared'), findsOneWidget);
    expect(find.text('Hard Cleared'), findsOneWidget);

    expect(find.text('TECH STACK'), findsOneWidget);
    expect(find.text('FLUTTER'), findsOneWidget);
    expect(find.text('POSTGRESQL'), findsOneWidget);
    expect(find.text('DART'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders Edit Profile button, Saved Posts, and Settings', (tester) async {
    await tester.pumpWidget(createProfileApp());
    await tester.pumpAndSettle();

    expect(find.text('EDIT PROFILE'), findsOneWidget);
    expect(find.text('Saved Posts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows Unranked in College Rank when aura is 0', (tester) async {
    final zeroAuraUser = UserModel(
      id: 'u-zero',
      name: 'New Student',
      handle: 'newstudent',
      email: 'new@example.com',
      avatar: '',
      color: Colors.black,
      aura: 0,
      roles: const ['Student'],
      year: '1st Year',
      branch: 'CSE',
      building: '',
      stack: const ['Dart'],
      followers: 0,
      following: 0,
      bio: '',
      college: 'Jaipur National University',
      githubHandle: '',
      profileCompleted: true,
      currentStreak: 0,
    );

    await tester.pumpWidget(createProfileApp(user: zeroAuraUser));
    await tester.pumpAndSettle();

    expect(find.text('COLLEGE RANK'), findsOneWidget);
    expect(find.text('Unranked'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders FOLLOW and MESSAGE when viewing peer profile', (tester) async {
    final peerUser = UserModel(
      id: 'u-peer',
      name: 'Peer Developer',
      handle: 'peerdev',
      email: 'peer@example.com',
      avatar: '',
      color: Colors.black,
      aura: 1200,
      roles: const ['Student'],
      year: '4th Year',
      branch: 'IT',
      building: '',
      stack: const ['Python', 'Django'],
      followers: 25,
      following: 5,
      bio: 'Open source lover',
      college: 'MNIT Jaipur',
      githubHandle: 'peerdev',
      profileCompleted: true,
      currentStreak: 12,
      isFollowing: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              initialUser: testUser,
              listenToAuthChanges: false,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => UsersProvider(
              initialUsers: [testUser, peerUser],
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const ProfileScreen(userId: 'u-peer'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('@peerdev'), findsOneWidget);
    expect(find.text('FOLLOW'), findsOneWidget);
    expect(find.text('MESSAGE'), findsOneWidget);
    // Peer should not see self-only settings or saved posts
    expect(find.text('Saved Posts'), findsNothing);
    expect(find.text('Sign Out'), findsNothing);
  });
}
