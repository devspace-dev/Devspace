import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/screens/settings_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  UserModel makeTestUser({
    required String id,
    required String name,
    required String handle,
    required int aura,
    bool isFounder = false,
  }) {
    return UserModel(
      id: id,
      name: name,
      handle: handle,
      email: '$handle@example.com',
      avatar: '',
      color: Colors.blue,
      aura: aura,
      roles: isFounder ? const ['Founder'] : const ['Student'],
      year: '3rd Year',
      branch: 'CSE',
      building: 'DevHub',
      stack: const ['Flutter', 'Postgres'],
      followers: 12,
      following: 8,
      bio: 'Building campus apps',
      college: 'Tech University',
      githubHandle: handle,
      profileCompleted: true,
    );
  }

  Widget createSettingsApp({required UserModel user}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: user,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => TourController()),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const SettingsScreen(),
      ),
    );
  }

  testWidgets('SettingsScreen renders account card, metrics and settings sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 7200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = makeTestUser(id: 'u1', name: 'Harshit Raj', handle: 'harshit', aura: 750);

    await tester.pumpWidget(createSettingsApp(user: user));
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('SETTINGS'), findsOneWidget);

    // Verify Account Card info
    expect(find.text('Harshit Raj'), findsOneWidget);
    expect(find.text('@harshit'), findsOneWidget);
    expect(find.text('harshit@example.com'), findsOneWidget);

    // Verify 3-column analytics card
    expect(find.text('POSTS'), findsOneWidget);
    expect(find.text('LIKES'), findsOneWidget);
    expect(find.text('AURA'), findsOneWidget);
    expect(find.text('750'), findsOneWidget);

    // Verify settings sections and tiles
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Saved posts'), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
    expect(find.text('Replay tour'), findsOneWidget);
    expect(find.text('Terms & Privacy'), findsOneWidget);
    expect(find.text('About DevSpace'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
  });

  testWidgets('Tapping Sign Out displays confirmation dialog and cancel dismisses it', (tester) async {
    tester.view.physicalSize = const Size(1080, 7200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = makeTestUser(id: 'u1', name: 'Harshit Raj', handle: 'harshit', aura: 750);

    await tester.pumpWidget(createSettingsApp(user: user));
    await tester.pumpAndSettle();

    // Scroll to sign out button and tap it
    final signOutFinder = find.text('SIGN OUT');
    await tester.tap(signOutFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('SIGN OUT?'), findsOneWidget);
    expect(find.text('You will return to the login screen on this device.'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('SIGN OUT?'), findsNothing);
  });

  testWidgets('Tapping Delete account displays danger warning dialog and cancel dismisses it', (tester) async {
    tester.view.physicalSize = const Size(1080, 7200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = makeTestUser(id: 'u1', name: 'Harshit Raj', handle: 'harshit', aura: 750);

    await tester.pumpWidget(createSettingsApp(user: user));
    await tester.pumpAndSettle();

    // Tap Delete Account
    final deleteTileFinder = find.text('Delete account');
    await tester.tap(deleteTileFinder);
    await tester.pumpAndSettle();

    // Verify danger confirmation dialog
    expect(find.text('DELETE ACCOUNT?'), findsOneWidget);
    expect(find.textContaining('This action is permanent'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('DELETE ACCOUNT?'), findsNothing);
  });

  testWidgets('Tapping About DevSpace displays info dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 7200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = makeTestUser(id: 'u1', name: 'Harshit Raj', handle: 'harshit', aura: 750);

    await tester.pumpWidget(createSettingsApp(user: user));
    await tester.pumpAndSettle();

    // Tap About DevSpace
    final aboutFinder = find.text('About DevSpace');
    await tester.tap(aboutFinder);
    await tester.pumpAndSettle();

    // Verify About dialog contents
    expect(find.text('ABOUT DEVSPACE'), findsOneWidget);
    expect(find.textContaining('student developers'), findsOneWidget);
    expect(find.text('CLOSE'), findsOneWidget);

    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();
    expect(find.text('ABOUT DEVSPACE'), findsNothing);
  });
}
