import 'package:devspace/models/event_access_model.dart';
import 'package:devspace/screens/opportunity_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EventAccessModel _makeEvent({
  required String id,
  required String title,
  required String type,
  String? link,
}) {
  return EventAccessModel(
    id: id,
    title: title,
    description: 'Description for $title.',
    requiredAura: 0,
    link: link ?? 'https://example.com/$id',
    type: type,
    unlocked: true,
    locked: false,
    date: '2026-12-01',
    location: 'Remote',
    organizer: 'DevSpace Club',
  );
}

void main() {
  testWidgets('OpportunityDetailScreen uses bottomNavigationBar with bounded button and disabled state', (tester) async {
    final eventWithLink = _makeEvent(
      id: 'e1',
      title: 'DevSpace Hackathon',
      type: 'Hackathon',
      link: 'https://example.com/hack',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OpportunityDetailScreen(opportunity: eventWithLink),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNotNull);
    expect(scaffold.bottomSheet, isNull);

    expect(find.text('REGISTER NOW'), findsOneWidget);

    final buttonSize = tester.getSize(find.text('REGISTER NOW'));
    expect(buttonSize.height, lessThan(60));

    // Test with missing link
    final eventNoLink = _makeEvent(
      id: 'e2',
      title: 'Closed Workshop',
      type: 'Workshop',
      link: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OpportunityDetailScreen(opportunity: eventNoLink),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('REGISTRATION CLOSED'), findsOneWidget);
  });
}
