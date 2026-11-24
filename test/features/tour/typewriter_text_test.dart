import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devspace/features/tour/widgets/typewriter_text.dart';

void main() {
  testWidgets('TypewriterText types characters incrementally', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TypewriterText(
            text: 'Hello DevSpace',
            charDuration: Duration(milliseconds: 25),
          ),
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.byType(TypewriterText), findsOneWidget);

    // After 100ms, about 4 characters are typed
    await tester.pump(const Duration(milliseconds: 100));
    final finder = find.byType(Text);
    expect(finder, findsOneWidget);
    final textWidget = tester.widget<Text>(finder);
    expect(textWidget.data!.length, inInclusiveRange(3, 6));

    // Finish typing
    await tester.pumpAndSettle();
    final finalTextWidget = tester.widget<Text>(finder);
    expect(finalTextWidget.data, 'Hello DevSpace');
  });

  testWidgets('Tapping TypewriterText completes text reveal immediately', (tester) async {
    var completedCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TypewriterText(
            text: 'Instant Reveal Test',
            charDuration: const Duration(milliseconds: 50),
            onComplete: () => completedCalled = true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    // Tap to finish instantly
    await tester.tap(find.byType(TypewriterText));
    await tester.pump();

    final textWidget = tester.widget<Text>(find.byType(Text));
    expect(textWidget.data, 'Instant Reveal Test');
    expect(completedCalled, isTrue);
  });

  testWidgets('Semantics exposes the full label immediately for accessibility', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TypewriterText(
            text: 'Accessibility First',
            charDuration: Duration(milliseconds: 100),
          ),
        ),
      ),
    );

    await tester.pump();
    // Screen reader sees full label right away
    expect(
      find.bySemanticsLabel('Accessibility First'),
      findsOneWidget,
    );
  });
}
