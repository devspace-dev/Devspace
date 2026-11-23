import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devspace/core/theme/colors.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/screens/duel_result_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  UserModel makeUser({required String id, required String name}) {
    return UserModel(
      id: id,
      name: name,
      handle: name.toLowerCase(),
      email: '$name@example.com',
      avatar: '',
      color: Colors.blue,
      aura: 100,
      roles: const ['Student'],
      year: '3rd Year',
      branch: 'CSE',
      building: 'Block B',
      stack: const ['Flutter'],
      followers: 1,
      following: 1,
      bio: '',
      college: 'Campus',
      githubHandle: name.toLowerCase(),
      profileCompleted: true,
    );
  }

  Widget buildTestWidget({
    required UserModel me,
    required UserModel opponent,
    Future<String> Function({
      required String senderId,
      required String receiverId,
      required String category,
      required String mode,
    })? onSendDuelRequest,
    Widget Function(String requestId)? waitingScreenBuilder,
    double fontScale = 1.0,
    Size size = const Size(360, 640),
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(fontScale),
      ),
      child: MaterialApp(
        home: DuelResultScreen(
          me: me,
          opponent: opponent,
          myScore: 45,
          opponentScore: 30,
          mode: 'REFLEX',
          category: 'Combat',
          myQuestionsAnswered: 3,
          opponentQuestionsAnswered: 2,
          myAccuracy: 1.0,
          opponentAccuracy: 0.67,
          onSendDuelRequest: onSendDuelRequest,
          waitingScreenBuilder: waitingScreenBuilder,
        ),
      ),
    );
  }

  testWidgets('DuelResultScreen renders REMATCH and NEW DUEL with touch target >= 48dp', (tester) async {
    final me = makeUser(id: 'u1', name: 'DevOne');
    final opp = makeUser(id: 'u2', name: 'DevTwo');

    await tester.pumpWidget(buildTestWidget(me: me, opponent: opp));
    await tester.pumpAndSettle();

    final rematchFinder = find.widgetWithText(ElevatedButton, 'REMATCH');
    final newDuelFinder = find.widgetWithText(ElevatedButton, 'NEW DUEL');

    expect(rematchFinder, findsWidgets);
    expect(newDuelFinder, findsWidgets);

    // Verify touch target height >= 48dp on the overview card buttons
    final firstRematch = tester.getSize(rematchFinder.first);
    final firstNewDuel = tester.getSize(newDuelFinder.first);
    expect(firstRematch.height, greaterThanOrEqualTo(48.0));
    expect(firstNewDuel.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('Tapping REMATCH triggers request and opens waiting screen', (tester) async {
    final me = makeUser(id: 'u1', name: 'DevOne');
    final opp = makeUser(id: 'u2', name: 'DevTwo');
    String? sentSenderId;
    String? sentReceiverId;
    String? sentCategory;
    String? sentMode;

    await tester.pumpWidget(
      buildTestWidget(
        me: me,
        opponent: opp,
        onSendDuelRequest: ({
          required senderId,
          required receiverId,
          required category,
          required mode,
        }) async {
          sentSenderId = senderId;
          sentReceiverId = receiverId;
          sentCategory = category;
          sentMode = mode;
          return 'req_123';
        },
        waitingScreenBuilder: (reqId) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: Text('WAITING FOR $reqId'),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Tap REMATCH
    await tester.tap(find.widgetWithText(ElevatedButton, 'REMATCH').first);
    await tester.pumpAndSettle();

    expect(sentSenderId, 'u1');
    expect(sentReceiverId, 'u2');
    expect(sentCategory, 'Combat');
    expect(sentMode, 'REFLEX');
    expect(find.text('WAITING FOR req_123'), findsOneWidget);
  });

  testWidgets('Returning from waiting screen triggers 10s cooldown and disables button', (tester) async {
    final me = makeUser(id: 'u1', name: 'DevOne');
    final opp = makeUser(id: 'u2', name: 'DevTwo');

    await tester.pumpWidget(
      buildTestWidget(
        me: me,
        opponent: opp,
        onSendDuelRequest: ({
          required senderId,
          required receiverId,
          required category,
          required mode,
        }) async {
          return 'req_456';
        },
        waitingScreenBuilder: (reqId) {
          return Scaffold(
            body: Center(
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('DECLINED OR TIMED OUT'),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Tap REMATCH -> enters waiting screen
    await tester.tap(find.widgetWithText(ElevatedButton, 'REMATCH').first);
    await tester.pumpAndSettle();

    expect(find.text('DECLINED OR TIMED OUT'), findsOneWidget);

    // Opponent declines or times out -> pops back to DuelResultScreen
    await tester.tap(find.text('DECLINED OR TIMED OUT'));
    await tester.pumpAndSettle();

    // Cooldown is active: 10 seconds remaining
    expect(find.text('REMATCH (10s)'), findsWidgets);

    // Button should be disabled during cooldown
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'REMATCH (10s)').first,
    );
    expect(button.onPressed, isNull);

    // Advance 5 seconds
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('REMATCH (5s)'), findsWidgets);

    // Advance remaining 5 seconds
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    // Button is re-enabled with original label
    expect(find.text('REMATCH'), findsWidgets);
    final reenabledButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'REMATCH').first,
    );
    expect(reenabledButton.onPressed, isNotNull);
  });

  testWidgets('DuelResultScreen is immune to overflow at 360dp width and 200% font scale', (tester) async {
    final me = makeUser(id: 'u1', name: 'DevOne');
    final opp = makeUser(id: 'u2', name: 'DevTwo');

    await tester.pumpWidget(
      buildTestWidget(
        me: me,
        opponent: opp,
        size: const Size(360, 640),
        fontScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();

    // Expect no Flutter errors or overflow exceptions
    expect(tester.takeException(), isNull);
    expect(find.text('REMATCH'), findsWidgets);
    expect(find.text('NEW DUEL'), findsWidgets);
  });
}
