import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text.dart';
import 'glitch.dart';
import 'ds_button.dart';
import 'ds_card.dart';
import 'ds_tag.dart';
import 'aura_chip.dart';
import 'segment_bar.dart';

class DesignSystemPreviewScreen extends StatefulWidget {
  const DesignSystemPreviewScreen({super.key});

  @override
  State<DesignSystemPreviewScreen> createState() => _DesignSystemPreviewScreenState();
}

class _DesignSystemPreviewScreenState extends State<DesignSystemPreviewScreen> {
  int _progress = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        title: Text('GLITCH DESIGN SYSTEM', style: DsText.h3),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: AuraChip(715)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MASCOT: GLITCH', style: DsText.h2),
            const SizedBox(height: 12),
            const DsCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Glitch(size: 60, mood: GlitchMood.idle),
                      SizedBox(height: 4),
                      DsTag('idle'),
                    ],
                  ),
                  Column(
                    children: [
                      Glitch(size: 60, mood: GlitchMood.win),
                      SizedBox(height: 4),
                      DsTag('win'),
                    ],
                  ),
                  Column(
                    children: [
                      Glitch(size: 60, mood: GlitchMood.lose),
                      SizedBox(height: 4),
                      DsTag('lose'),
                    ],
                  ),
                  Column(
                    children: [
                      Glitch(size: 60, mood: GlitchMood.hype),
                      SizedBox(height: 4),
                      DsTag('hype'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('CHUNKY BUTTONS', style: DsText.h2),
            const SizedBox(height: 12),
            DsButton(
              label: 'Claim 50 Aura (Primary)',
              kind: DsButtonKind.aura,
              onPressed: () {
                setState(() => _progress = (_progress % 8) + 1);
              },
            ),
            const SizedBox(height: 12),
            DsButton(
              label: 'Continue (Success / Mint)',
              kind: DsButtonKind.mint,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            DsButton(
              label: 'Secondary (Bone)',
              kind: DsButtonKind.bone,
              onPressed: () {},
            ),
            const SizedBox(height: 24),
            Text('TIER CARDS & TAGS', style: DsText.h2),
            const SizedBox(height: 12),
            DsCard(
              leftBar: Ds.tierBronze,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DsTag('EASY', bg: Ds.tierBronze, fg: Ds.ink),
                        const SizedBox(height: 6),
                        Text('NOOB LOBBY', style: DsText.h3),
                      ],
                    ),
                  ),
                  Text('+100', style: DsText.number.copyWith(fontSize: 22)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DsCard(
              leftBar: Ds.tierGem,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DsTag('ULTRA', bg: Ds.tierGem, fg: Ds.ink),
                        const SizedBox(height: 6),
                        Text('FINAL CIRCLE', style: DsText.h3),
                      ],
                    ),
                  ),
                  Text('+400', style: DsText.number.copyWith(fontSize: 22)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('PROGRESS & CHIPS', style: DsText.h2),
            const SizedBox(height: 12),
            SegmentBar(total: 8, current: _progress),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                AuraChip(1250),
                StreakChip(7),
                DsTag('Rookie'),
                DsTag('Bug Hunter'),
                DsTag('10x Dev'),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
