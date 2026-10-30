import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/core/widgets/glitch.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/features/path/screens/path_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testUser = UserModel(
    id: 'u-1',
    name: 'Harshit Raj',
    handle: 'harshit',
    email: 'harshit@example.com',
    avatar: '',
    color: Colors.black,
    aura: 650,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'DevSpace',
    stack: const ['Flutter', 'PostgreSQL'],
    followers: 10,
    following: 5,
    bio: 'Student builder',
    college: 'IIIT Delhi',
    githubHandle: 'harshit',
    profileCompleted: true,
    currentStreak: 4,
  );

  Widget createPathApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: testUser,
            listenToAuthChanges: false,
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const PathScreen(),
      ),
    );
  }

  testWidgets('PathScreen renders title, track chips, and segmented progress', (tester) async {
    await tester.pumpWidget(createPathApp());
    await tester.pumpAndSettle();

    expect(find.text('PATH'), findsOneWidget);
    expect(find.text('FLUTTER & DART'), findsOneWidget);
    expect(find.text('WEB FRONTEND'), findsOneWidget);
    expect(find.text('BACKEND ENGINEERING'), findsOneWidget);

    expect(find.text('0 of 6 NODES'), findsOneWidget);
  });

  testWidgets('PathScreen renders active node with Glitch companion and bottom card', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createPathApp());
    await tester.pumpAndSettle();

    // Glitch companion stands next to the active node
    expect(find.byType(Glitch), findsOneWidget);

    // Default active node is Dart & Type System
    expect(find.text('IN PROGRESS'), findsWidgets);
    expect(find.text('Dart & Type System'), findsWidgets);
  });

  testWidgets('Tapping bottom card opens modal detail sheet with verified resources and project', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createPathApp());
    await tester.pumpAndSettle();

    // Tap the bottom preview card
    await tester.tap(find.byKey(const ValueKey('selected_node_preview_card')));
    await tester.pumpAndSettle();

    // Detail sheet content
    expect(find.text('WHY IT MATTERS'), findsOneWidget);
    expect(find.text('CORE CONCEPTS'), findsOneWidget);
    expect(find.text('HANDS-ON PROJECT'), findsOneWidget);
    expect(find.text('VERIFIED RESOURCES'), findsOneWidget);
    expect(find.text('MARK AS COMPLETED'), findsOneWidget);

    // Tap Mark As Completed
    await tester.tap(find.text('MARK AS COMPLETED'));
    await tester.pumpAndSettle();

    // Bottom sheet should now show MARK INCOMPLETE
    expect(find.text('MARK INCOMPLETE'), findsOneWidget);
  });

  testWidgets('PathScreen switches track when tapping Backend track chip', (tester) async {
    await tester.pumpWidget(createPathApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('BACKEND ENGINEERING'));
    await tester.pumpAndSettle();

    // Should now show backend first node
    expect(find.text('HTTP, REST & Networking'), findsWidgets);
  });

  testWidgets('PathScreen search button opens roadmap.sh directory modal', (tester) async {
    await tester.pumpWidget(createPathApp());
    await tester.pumpAndSettle();

    // Tap search icon button in AppBar
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(find.text('SEARCH ROADMAPS'), findsOneWidget);
    expect(find.text('ROADMAP.SH'), findsOneWidget);
    expect(find.text('INTERACTIVE MIND MAP TRACKS'), findsOneWidget);
    expect(find.text('ROADMAP.SH CURATED GUIDES'), findsOneWidget);
  });
}
