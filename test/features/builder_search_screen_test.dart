import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/features/community/screens/builder_search_screen.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/users_provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final selfUser = UserModel(
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
    stack: const ['Flutter', 'PostgreSQL'],
    followers: 15,
    following: 10,
    bio: 'Student builder',
    college: 'IIIT Delhi',
    githubHandle: 'harshit',
    profileCompleted: true,
    currentStreak: 6,
  );

  final aliceUser = UserModel(
    id: 'u-alice',
    name: 'Alice Verma',
    handle: 'alice_dev',
    email: 'alice@example.com',
    avatar: '',
    color: Colors.black,
    aura: 1650,
    roles: const ['Student'],
    year: '2nd Year',
    branch: 'ECE',
    building: 'CompilerKit',
    stack: const ['Rust', 'PostgreSQL'],
    followers: 42,
    following: 12,
    bio: 'Systems engineer',
    college: 'IIIT Delhi',
    githubHandle: 'alice',
    profileCompleted: true,
    isFollowing: false,
  );

  final bobUser = UserModel(
    id: 'u-bob',
    name: 'Bob Kumar',
    handle: 'bob_builds',
    email: 'bob@example.com',
    avatar: '',
    color: Colors.black,
    aura: 400,
    roles: const ['Student'],
    year: '1st Year',
    branch: 'IT',
    building: 'CampusMap',
    stack: const ['React', 'TypeScript'],
    followers: 8,
    following: 5,
    bio: 'Web dev',
    college: 'IIIT Delhi',
    githubHandle: 'bob',
    profileCompleted: true,
    isFollowing: true,
  );

  Widget createSearchApp({
    List<UserModel>? initialUsers,
    UsersPageLoader? usersPageLoader,
    FollowToggleAction? followAction,
    FollowToggleAction? unfollowAction,
  }) {
    final users = initialUsers ?? [selfUser, aliceUser, bobUser];
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: selfUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: users,
            usersPageLoader: usersPageLoader ??
                ({int limit = 20, int offset = 0, String? query}) async {
                  if (query == null || query.trim().isEmpty) return users;
                  return users
                      .where((u) => UsersProvider.matchesQuery(u, query))
                      .toList();
                },
            followAction: followAction ?? (_, __) async {},
            unfollowAction: unfollowAction ?? (_, __) async {},
            currentUserIdResolver: () => selfUser.id,
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const BuilderSearchScreen(),
      ),
    );
  }

  testWidgets(
      'BuilderSearchScreen filters case-insensitively by name, @handle, and stack',
      (tester) async {
    await tester.pumpWidget(createSearchApp());
    await tester.pumpAndSettle();

    expect(find.text('Harshit Raj'), findsOneWidget);
    expect(find.text('Alice Verma'), findsOneWidget);
    expect(find.text('Bob Kumar'), findsOneWidget);

    // Case-insensitive @handle search
    await tester.enterText(find.byType(TextField), '@ALICE');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Alice Verma'), findsOneWidget);
    expect(find.text('Bob Kumar'), findsNothing);
    expect(find.text('Harshit Raj'), findsNothing);

    // Clear and search by lowercase stack
    await tester.enterText(find.byType(TextField), 'typescript');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Bob Kumar'), findsOneWidget);
    expect(find.text('Alice Verma'), findsNothing);
  });

  testWidgets('BuilderSearchScreen supports stack chip filtering and Follow toggle',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var followedId = '';
    await tester.pumpWidget(
      createSearchApp(
        followAction: (from, to) async {
          followedId = to;
        },
      ),
    );
    await tester.pumpAndSettle();

    // Tap Rust chip in top filter bar -> only Alice matches
    final rustChip = find.descendant(
      of: find.byType(ListView).first,
      matching: find.text('RUST'),
    );
    await tester.ensureVisible(rustChip);
    await tester.tap(rustChip);
    await tester.pumpAndSettle();

    expect(find.text('Alice Verma'), findsOneWidget);
    expect(find.text('Bob Kumar'), findsNothing);

    // Alice shows Follow button; tapping toggles to Following
    expect(find.text('Follow'), findsOneWidget);
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();

    expect(followedId, 'u-alice');
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('BuilderSearchScreen shows error with retry when remote search fails and list is empty',
      (tester) async {
    await tester.pumpWidget(
      createSearchApp(
        initialUsers: const [],
        usersPageLoader: ({int limit = 20, int offset = 0, String? query}) async {
          throw Exception('Search failed');
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to search builders'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
  });
}
