import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/screens/connections_screen.dart';

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

  Widget createConnectionsApp({
    UserModel? user,
    ConnectionListType type = ConnectionListType.followers,
  }) {
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
            initialUsers: [user ?? testUser],
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: ConnectionsScreen(
          user: user ?? testUser,
          type: type,
        ),
      ),
    );
  }

  testWidgets('ConnectionsScreen renders mode switcher and back button', (tester) async {
    await tester.pumpWidget(createConnectionsApp());
    await tester.pump();

    // Mode tabs
    expect(find.text('Followers'), findsNWidgets(2)); // AppBar title + Tab title
    expect(find.text('Following'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('ConnectionsScreen in following mode renders Following title', (tester) async {
    await tester.pumpWidget(
      createConnectionsApp(type: ConnectionListType.following),
    );
    await tester.pump();

    expect(find.text('Following'), findsNWidgets(2)); // AppBar title + Tab title
    expect(find.text('Followers'), findsOneWidget);
  });
}
