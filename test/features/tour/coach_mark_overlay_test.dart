import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devspace/core/widgets/ds_button.dart';
import 'package:devspace/features/tour/widgets/coach_mark_overlay.dart';

void main() {
  testWidgets('CoachMarkOverlay renders spotlight and tooltip on 360dp narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var primaryTapped = false;
    var dismissTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoachMarkOverlay(
            targetRect: const Rect.fromLTWH(20, 100, 120, 48),
            title: 'Test Spotlight',
            body: 'Highlighting the active element cleanly.',
            primaryButtonLabel: 'Next',
            onPrimaryPressed: () => primaryTapped = true,
            secondaryButtonLabel: 'Skip',
            onSecondaryPressed: () => dismissTapped = true,
            onDismiss: () => dismissTapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TEST SPOTLIGHT'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    expect(primaryTapped, isTrue);

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(dismissTapped, isTrue);
  });

  testWidgets('CoachMarkOverlay supports 200% font scaling without RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2.0), // 200% font scale
          ),
          child: Scaffold(
            body: CoachMarkOverlay(
              targetRect: const Rect.fromLTWH(40, 120, 150, 50),
              title: 'Accessibility Test with 200% font scaling',
              body: 'This is a long body description ensuring no horizontal or vertical overflow occurs.',
              onPrimaryPressed: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // No exceptions or overflow errors thrown
    expect(find.byType(DsButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CoachMarkOverlay renders stepPill and fires onTargetTap on hole press', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var targetTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoachMarkOverlay(
            targetRect: const Rect.fromLTWH(50, 150, 100, 50),
            title: 'Spotlight Tap Test',
            body: 'Verify tapping the spotlighted hole invokes onTargetTap.',
            stepPill: 'STEP 2 OF 5',
            primaryButtonLabel: 'NEXT',
            onPrimaryPressed: () {},
            onTargetTap: () => targetTapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('STEP 2 OF 5'), findsOneWidget);
    expect(find.text('SPOTLIGHT TAP TEST'), findsOneWidget);

    // Tap in center of the targetRect (100, 175)
    await tester.tapAt(const Offset(100, 175));
    await tester.pump();

    expect(targetTapped, isTrue);
  });
}
