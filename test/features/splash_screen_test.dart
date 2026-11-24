import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/core/widgets/glitch.dart';
import 'package:devspace/core/widgets/segment_bar.dart';
import 'package:devspace/features/splash/screens/splash_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SplashScreen renders mascot, wordmark, tagline, and loading bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );

    // Initial render
    await tester.pump();

    // Verify mascot
    expect(find.byType(Glitch), findsOneWidget);

    // Verify wordmark
    expect(find.text('DEV'), findsOneWidget);
    expect(find.text('SPACE'), findsOneWidget);

    // Verify tagline
    expect(find.text('Student builders. One shared arena.'), findsOneWidget);

    // Verify loading bar and caption
    expect(find.byType(SegmentBar), findsOneWidget);
    expect(find.text('Loading your Aura...'), findsOneWidget);

    // Advance timer to verify loading progression without throwing
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Loading your Aura...'), findsOneWidget);
  });
}
