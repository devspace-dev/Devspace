import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../models/roadmap_model.dart';
import '../providers/path_provider.dart';
import 'path_setup_sheet.dart';

/// Modal sheet to view and switch between saved roadmaps and active settings.
class PathSavedSheet extends StatelessWidget {
  const PathSavedSheet({super.key});

  static Future<void> show(BuildContext context, {PathProvider? provider}) {
    final effectiveProvider = provider ?? context.read<PathProvider>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Ds.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Ds.border, width: 2),
      ),
      builder: (_) => ChangeNotifierProvider<PathProvider>.value(
        value: effectiveProvider,
        child: const PathSavedSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PathProvider>();
    final active = provider.activeRoadmap;
    final saved = provider.savedSelections;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Ds.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Text(
                    'ROADMAP MANAGER'.toUpperCase(),
                    style: DsText.h3,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Ds.muted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Path Section
              Text(
                'CURRENT ACTIVE PATH'.toUpperCase(),
                style: DsText.number.copyWith(color: Ds.aura),
              ),
              const SizedBox(height: 8),
              if (active != null)
                DsCard(
                  borderColor: Ds.aura,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DsTag(active.levelTag, bg: Ds.ink, fg: Ds.aura),
                          const Spacer(),
                          Text(
                            '${provider.completedActiveCount} / ${provider.totalActiveCount} DONE',
                            style: DsText.caption.copyWith(color: Ds.mint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(active.title.toUpperCase(), style: DsText.h3),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.remainingHours}h remaining (~${provider.estimatedWeeks} weeks @ ${provider.currentWeeklyHours}h/wk)',
                        style: DsText.caption,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Ds.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                PathSetupSheet.show(context, roadmap: active);
                              },
                              child: Text(
                                'CHANGE COMMITMENT',
                                style: DsText.caption.copyWith(color: Ds.bone),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                DsCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No path is currently active. Pick one below or browse all paths.',
                    style: DsText.bodySm,
                  ),
                ),

              const SizedBox(height: 24),

              // Saved Paths Section
              Text(
                'SAVED FOR LATER'.toUpperCase(),
                style: DsText.number.copyWith(color: Ds.bone),
              ),
              const SizedBox(height: 8),

              if (saved.isEmpty)
                DsCard(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No saved roadmaps yet. Browse and save paths you want to explore later.',
                      style: DsText.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Column(
                  children: saved.map((selection) {
                    final roadmap = provider.allRoadmaps
                        .cast<Roadmap?>()
                        .firstWhere((r) => r?.id == selection.roadmapId,
                            orElse: () => null);
                    if (roadmap == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DsCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roadmap.title.toUpperCase(),
                                    style: DsText.label.copyWith(color: Ds.bone),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${roadmap.totalNodes} nodes • ${roadmap.totalHours}h total',
                                    style: DsText.caption,
                                  ),
                                ],
                              ),
                            ),
                            DsButton(
                              label: 'RESUME',
                              kind: DsButtonKind.aura,
                              height: 38,
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await provider.selectRoadmap(
                                  roadmapId: roadmap.id,
                                  level: selection.level,
                                  weeklyHours: selection.weeklyHours,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
