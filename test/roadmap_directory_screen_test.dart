import 'package:devspace/data/roadmap_directory.dart';
import 'package:devspace/screens/roadmap_directory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('roadmap directory renders and search filters the list',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoadmapDirectoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Roadmaps'), findsOneWidget);
    // Every entry is a real roadmap.sh link, not reproduced content.
    expect(kRoadmapDirectory, isNotEmpty);
    for (final entry in kRoadmapDirectory) {
      expect(entry.url, startsWith('https://roadmap.sh/'));
    }

    await tester.enterText(find.byType(TextField), 'react');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('React'), findsOneWidget);
    expect(find.text('React Native'), findsOneWidget);
    expect(find.text('Docker'), findsNothing);

    // Clearing the search restores the full (long) list.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Frontend'), findsOneWidget);
  });

  testWidgets('category filter narrows results', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoadmapDirectoryScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(RoadmapCategory.beginners));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Frontend Beginner'), findsOneWidget);
    expect(find.text('React'), findsNothing);
  });

  testWidgets('empty results show the empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoadmapDirectoryScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField), 'zzz-not-a-real-roadmap-zzz');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No roadmaps found'), findsOneWidget);
  });
}
