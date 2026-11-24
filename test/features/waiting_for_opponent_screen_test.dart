import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/screens/waiting_for_opponent_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  UserModel makeTestUser({
    required String id,
    required String name,
  }) {
    return UserModel(
      id: id,
      name: name,
      handle: name.toLowerCase(),
      email: '$name@example.com',
      avatar: '',
      color: Colors.blue,
      aura: 500,
      roles: const ['Student'],
      year: '2nd Year',
      branch: 'CSE',
      building: 'Block C',
      stack: const ['Flutter'],
      followers: 5,
      following: 5,
      bio: 'Ready to duel',
      college: 'Campus Tech',
      githubHandle: name.toLowerCase(),
      profileCompleted: true,
    );
  }

  testWidgets('WaitingForOpponentScreen renders opponent name, status, and cancel button', (tester) async {
    final opponent = makeTestUser(id: 'opp-1', name: 'Aarav');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: WaitingForOpponentScreen(
          requestId: 'test-req-123',
          opponent: opponent,
          category: 'Combat',
          mode: 'REFLEX',
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify opponent name and waiting indicator
    expect(find.text('Waiting for Aarav...'), findsOneWidget);
    expect(find.text('Challenge sent! Waiting for them to accept.'), findsOneWidget);
    expect(find.text('Cancel Request'), findsOneWidget);

    // Verify avatar fallback initial
    expect(find.text('A'), findsOneWidget);

    // Pump frames for animation without throwing
    await tester.pump(const Duration(milliseconds: 500));
  });
}
