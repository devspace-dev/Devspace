import 'package:devspace/screens/login_screen.dart';
import 'package:devspace/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen renders both auth methods', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(onSuccess: _noop),
      ),
    );

    expect(find.text('DevSpace'), findsOneWidget);
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  test('user model splits legacy academic text into year and branch', () {
    final user = UserModel.fromJson({
      'id': 'user-1',
      'name': 'Mohammad',
      'email': 'm@example.com',
      'handle': 'mohammad',
      'avatar': '',
      'color': const Color(0xFF0E0F12).toARGB32(),
      'aura': 12,
      'role': 'Student',
      'year': '3rd Year · CSE',
      'building': 'Low-latency campus tools',
      'stack': ['Flutter'],
      'followers': 0,
      'following': 0,
      'bio': '',
      'college': 'Jaipur National University',
      'profile_completed': true,
    });

    expect(user.year, '3rd Year');
    expect(user.branch, 'CSE');
    expect(user.profileCompleted, isTrue);
  });
}

void _noop() {}
