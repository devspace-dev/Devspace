import 'package:devspace/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen renders both auth methods', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onSuccess: _noop),
      ),
    );

    expect(find.text('DevSpace'), findsOneWidget);
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}

void _noop() {}
