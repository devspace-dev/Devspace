import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/widgets/ds_button.dart';
import 'package:devspace/models/daily_challenge_model.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/screens/daily_challenge_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testUser = UserModel(
    id: 'user-daily-1',
    name: 'Dev Tester',
    handle: 'devtester',
    email: 'tester@example.com',
    avatar: '',
    color: Colors.blue,
    aura: 500,
    roles: const ['Student'],
    year: '2nd Year',
    branch: 'CSE',
    building: 'Block A',
    stack: const ['Flutter', 'Python'],
    followers: 1,
    following: 1,
    bio: '',
    college: 'Campus',
    githubHandle: 'devtester',
    profileCompleted: true,
  );

  DailyChallengeModel makeChallenge({
    required String question,
    bool completed = false,
    bool wasSolved = false,
  }) {
    return DailyChallengeModel(
      assignmentId: 'assign-1',
      challengeId: 'chall-1',
      assignedDate: DateTime.now(),
      selectedTechStack: 'Python',
      completed: completed,
      completedAt: completed ? DateTime.now() : null,
      title: 'Python Scope',
      description: 'Understanding function scope in Python.',
      difficulty: 'Medium',
      techStack: 'Python',
      pointsReward: 20,
      missionType: 'mcq',
      question: question,
      options: const ['Option A', 'Option B', 'Option C'],
      link: '',
      isCorrect: wasSolved,
    );
  }

  Widget createDailyScreenApp({
    required DailyChallengeModel challenge,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: testUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EngagementProvider(
            initialDailyChallenge: challenge,
            dailyChallengeLoader: ({techStack}) async => challenge,
          ),
        ),
      ],
      child: const MaterialApp(
        home: DailyChallengeScreen(),
      ),
    );
  }

  testWidgets('DailyChallengeScreen renders prose question wrapping naturally with no horizontal scroll', (tester) async {
    final challenge = makeChallenge(
      question: 'What is the return type of the bool function in Python when evaluating an empty list?',
    );

    await tester.pumpWidget(createDailyScreenApp(challenge: challenge));
    await tester.pumpAndSettle();

    expect(find.text('DAILY MISSION'), findsOneWidget);
    expect(find.text('What is the return type of the bool function in Python when evaluating an empty list?'), findsOneWidget);

    // Verify prose is NOT inside a horizontal scroll view
    final horizontalScrolls = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(horizontalScrolls, findsNothing);

    // Verify sticky submit button is placed in bottomNavigationBar
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNotNull);
    expect(find.text('CONFIRM SUBMISSION'), findsOneWidget);

    // Initially disabled because no option is chosen
    final button = tester.widget<DsButton>(find.byType(DsButton));
    expect(button.onPressed, isNull);

    // Select Option A
    await tester.tap(find.text('Option A'));
    await tester.pump();

    // Button should now be active
    final activeBtn = tester.widget<DsButton>(find.byType(DsButton));
    expect(activeBtn.onPressed, isNotNull);
  });

  testWidgets('DailyChallengeScreen renders code block inside dedicated horizontal scroll box while prose wraps', (tester) async {
    const questionWithCode = '''What will be the output of the following function call?
```python
def calc(a, b):
    return a * b + 42
print(calc(2, 3))
```
Choose the matching output from the choices below.''';

    final challenge = makeChallenge(question: questionWithCode);

    await tester.pumpWidget(createDailyScreenApp(challenge: challenge));
    await tester.pumpAndSettle();

    expect(find.text('What will be the output of the following function call?'), findsOneWidget);
    expect(find.text('Choose the matching output from the choices below.'), findsOneWidget);

    // The code block should have its own horizontal scroll view
    final horizontalScrolls = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(horizontalScrolls, findsOneWidget);
  });
}
