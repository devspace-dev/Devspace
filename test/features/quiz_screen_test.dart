import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/practice_provider.dart';
import 'package:devspace/features/quiz/screens/quiz_screen.dart';
import 'package:devspace/features/quiz/widgets/quiz_option_row.dart';
import 'package:devspace/features/quiz/widgets/shake_animation.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testUser = UserModel(
    id: 'test-user-id',
    name: 'Harshit Raj',
    handle: 'harshit',
    email: 'harshit@example.com',
    avatar: '',
    color: Colors.black,
    aura: 715,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'DevSpace',
    stack: const ['Flutter', 'Postgres'],
    followers: 10,
    following: 5,
    bio: 'Building things',
    college: 'Test College',
    githubHandle: 'harshit',
    profileCompleted: true,
    currentStreak: 7,
  );

  Widget createQuizApp({String lobby = 'ranked'}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: testUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: QuizScreen(lobby: lobby),
      ),
    );
  }

  testWidgets('QuizOptionRow renders in all 4 states without exception', (tester) async {
    for (final state in OptionState.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: QuizOptionRow(
              letter: 'A',
              text: 'Sample Option',
              state: state,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Sample Option'), findsOneWidget);
    }
  });

  testWidgets('ShakeAnimation wraps child and builds without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShakeAnimation(
            shake: true,
            child: Text('Shaking Target'),
          ),
        ),
      ),
    );

    expect(find.text('Shaking Target'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('QuizScreen renders question, lobby tags, and option rows', (tester) async {
    await tester.pumpWidget(createQuizApp(lobby: 'ranked'));
    await tester.pumpAndSettle();

    expect(find.text('HARD'), findsOneWidget);
    expect(find.byType(QuizOptionRow), findsWidgets);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Selecting an option reveals pinned bottom feedback panel', (tester) async {
    await tester.pumpWidget(createQuizApp(lobby: 'noob'));
    await tester.pumpAndSettle();

    // Tap first option row
    final firstOption = find.byType(QuizOptionRow).first;
    await tester.tap(firstOption);
    await tester.pumpAndSettle();

    // Bottom feedback panel should be visible with Continue button
    expect(find.text('CONTINUE'), findsOneWidget);

    // Tap Continue to advance to next question
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Q2 OF 8'), findsOneWidget);
  });
}
