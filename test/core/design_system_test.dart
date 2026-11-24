import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devspace/core/theme/colors.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/core/widgets/glitch.dart';
import 'package:devspace/core/widgets/ds_button.dart';
import 'package:devspace/core/widgets/ds_card.dart';
import 'package:devspace/core/widgets/ds_tag.dart';
import 'package:devspace/core/widgets/aura_chip.dart';
import 'package:devspace/core/widgets/segment_bar.dart';
import 'package:devspace/core/widgets/ds_nav_bar.dart';
import 'package:devspace/core/widgets/design_system_preview.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Glitch renders all 4 moods without throwing', (tester) async {
    for (final mood in GlitchMood.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Glitch(size: 64, mood: mood),
          ),
        ),
      );
      expect(find.byType(Glitch), findsOneWidget);
    }
  });

  testWidgets('DsButton renders, handles tap, and triggers callback', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: DsButton(
            label: 'Test Button',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('TEST BUTTON'), findsOneWidget);
    await tester.tap(find.byType(DsButton));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('DsCard renders with tier left bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: DsCard(
            leftBar: Ds.tierGold,
            child: Text('Ranked Lobby'),
          ),
        ),
      ),
    );

    expect(find.text('Ranked Lobby'), findsOneWidget);
  });

  testWidgets('DsTag, AuraChip, StreakChip and SegmentBar render accurately', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: Column(
            children: [
              DsTag('Ultra'),
              AuraChip(500),
              StreakChip(14),
              SegmentBar(total: 5, current: 3),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ULTRA'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.byType(SegmentBar), findsOneWidget);
  });

  testWidgets('DsNavBar renders all 5 items with active pill', (tester) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          bottomNavigationBar: DsNavBar(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Path'), findsOneWidget);
    expect(find.text('Ranks'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Ranks'));
    expect(selectedIndex, 2);
  });

  testWidgets('DesignSystemPreviewScreen renders gallery', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const DesignSystemPreviewScreen(),
      ),
    );

    expect(find.text('GLITCH DESIGN SYSTEM'), findsOneWidget);
    expect(find.text('MASCOT: GLITCH'), findsOneWidget);
    expect(find.text('CHUNKY BUTTONS'), findsOneWidget);
  });
}
