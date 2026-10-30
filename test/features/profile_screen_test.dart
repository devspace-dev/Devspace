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

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('Harshit Raj'), findsOneWidget);
    expect(find.text('@harshit'), findsOneWidget);
    expect(find.text('BUG HUNTER'), findsOneWidget); // 820 aura -> Bug Hunter

    // Three stat cards
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('COLLEGE RANK'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('SOLVED'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders badges and tech stack chips', (tester) async {
    await tester.pumpWidget(createProfileApp());
    await tester.pumpAndSettle();

    expect(find.text('BADGES'), findsOneWidget);
    expect(find.text('First Build'), findsOneWidget);
    expect(find.text('Week Fire'), findsOneWidget);
    expect(find.text('Century'), findsOneWidget);
    expect(find.text('Veteran'), findsOneWidget);
    expect(find.text('10x Dev'), findsOneWidget);

    expect(find.text('TECH STACK'), findsOneWidget);
    expect(find.text('FLUTTER'), findsOneWidget);
    expect(find.text('POSTGRESQL'), findsOneWidget);
    expect(find.text('DART'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders Edit Profile button, Saved Posts, and Theme settings', (tester) async {
    await tester.pumpWidget(createProfileApp());
    await tester.pumpAndSettle();

    expect(find.text('EDIT PROFILE'), findsOneWidget);
    expect(find.text('Saved Posts'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Dark (v1)'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
