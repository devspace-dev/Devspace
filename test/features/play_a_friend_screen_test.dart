import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/colors.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/screens/play_a_friend_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  UserModel makeUser({
    required String id,
    required String name,
    required String handle,
    required int aura,
    bool isFollowing = false,
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
      bio: '',
      college: 'JNU',
      githubHandle: handle,
      profileCompleted: true,
      isFollowing: isFollowing,
    );
  }

  testWidgets('PlayAFriendScreen shows everyone with followed friends first and searchable', (tester) async {
    final me = makeUser(id: 'me', name: 'Harshit', handle: 'harshit', aura: 790);
    final peer = makeUser(id: 'u2', name: 'Aarav', handle: 'aarav', aura: 900, isFollowing: false);
    final friend = makeUser(id: 'u1', name: 'Zara', handle: 'zara', aura: 100, isFollowing: true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(initialUser: me, listenToAuthChanges: false),
          ),
          ChangeNotifierProvider(
            create: (_) => UsersProvider(initialUsers: [me, peer, friend]),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const PlayAFriendScreen(
            category: 'Combat',
            mode: 'REFLEX MODE',
            color: Ds.hot,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Excludes self, shows both followed and non-followed builders
    expect(find.text('Harshit'), findsNothing);
    expect(find.text('Zara'), findsOneWidget);
    expect(find.text('Aarav'), findsOneWidget);
    expect(find.text('FRIEND'), findsOneWidget);

    // Followed friend appears above non-followed peer despite lower aura
    final zaraTop = tester.getTopLeft(find.text('Zara')).dy;
    final aaravTop = tester.getTopLeft(find.text('Aarav')).dy;
    expect(zaraTop, lessThan(aaravTop));

    // Search narrows by handle
    await tester.enterText(find.byType(TextField), '@aarav');
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    expect(find.text('Aarav'), findsOneWidget);
    expect(find.text('Zara'), findsNothing);
  });
}
