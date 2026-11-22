import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_tag.dart';
import '../models/roadmap_model.dart';
import '../providers/path_provider.dart';
import 'path_node_detail_sheet.dart';

/// Interactive Canvas Map view for a roadmap using [InteractiveViewer] and [CustomPaint].
class PathMapCanvas extends StatelessWidget {
  final Roadmap roadmap;

  const PathMapCanvas({
    super.key,
    required this.roadmap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PathProvider>();
    final completed = provider.completedNodeIds;
    final level = provider.currentLevel;
    final nextStep = provider.nextRecommendedStep;

    // Calculate canvas size based on number of stages and nodes
    final stages = roadmap.stages;
    final totalStages = stages.length;
    const stageWidth = 280.0;
    const stageSpacing = 40.0;
    const nodeHeight = 110.0;
    const nodeSpacing = 24.0;

    int maxNodesInStage = 1;
    for (final s in stages) {
      if (s.nodes.length > maxNodesInStage) {
        maxNodesInStage = s.nodes.length;
      }
    }

    final canvasWidth = (totalStages * (stageWidth + stageSpacing)) + 100.0;
    final canvasHeight = (maxNodesInStage * (nodeHeight + nodeSpacing)) + 160.0;

    return Container(
      color: Ds.ink,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(120),
        minScale: 0.5,
        maxScale: 2.5,
        constrained: false,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: Stack(
            children: [
              // Grid background dots
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridBackgroundPainter(),
                ),
              ),

              // Stages and Nodes
              for (int sIdx = 0; sIdx < stages.length; sIdx++) ...[
                // Stage Header
                Positioned(
                  left: 50.0 + (sIdx * (stageWidth + stageSpacing)),
                  top: 30,
                  width: stageWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Ds.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Ds.border, width: 2),
                    ),
                    child: Text(
                      stages[sIdx].title.toUpperCase(),
                      style: DsText.number.copyWith(color: Ds.aura),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Stage Nodes
                for (int nIdx = 0; nIdx < stages[sIdx].nodes.length; nIdx++) ...[
                  () {
                    final node = stages[sIdx].nodes[nIdx];
                    final isDone = completed.contains(node.id);
                    final isSkipped = node.isSkippedForLevel(level);
                    final isNext = nextStep?.id == node.id;

                    final nodeLeft = 50.0 + (sIdx * (stageWidth + stageSpacing));
                    final nodeTop = 85.0 + (nIdx * (nodeHeight + nodeSpacing));

                    Color borderColor = Ds.border;
                    Color titleColor = Ds.bone;
                    if (isDone) {
                      borderColor = Ds.mint;
                      titleColor = Ds.mint;
                    } else if (isNext) {
                      borderColor = Ds.aura;
                      titleColor = Ds.aura;
                    } else if (isSkipped) {
                      borderColor = Ds.border.withOpacity(0.5);
                      titleColor = Ds.muted;
                    }

                    return Positioned(
                      left: nodeLeft,
                      top: nodeTop,
                      width: stageWidth,
                      height: nodeHeight,
                      child: InkWell(
                        onTap: () {
                          PathNodeDetailSheet.show(
                            context,
                            roadmapId: roadmap.id,
                            node: node,
                            stageTitle: stages[sIdx].title,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Ds.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: isNext || isDone ? 2 : 1,
                            ),
                            boxShadow: isNext
                                ? [
                                    BoxShadow(
                                      color: Ds.aura.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isDone)
                                    const Icon(Icons.check_circle, color: Ds.mint, size: 18)
                                  else if (isNext)
                                    const Icon(Icons.play_circle_fill, color: Ds.aura, size: 18)
                                  else if (isSkipped)
                                    const Icon(Icons.fast_forward, color: Ds.muted, size: 18)
                                  else
                                    const Icon(Icons.radio_button_unchecked, color: Ds.muted, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      node.title.toUpperCase(),
                                      style: DsText.label.copyWith(color: titleColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                node.why,
                                style: DsText.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  DsTag('${node.estimatedHours}H', bg: Ds.ink, fg: Ds.bone),
                                  const SizedBox(width: 6),
                                  if (node.practiceTier != null)
                                    DsTag(node.practiceTier!.toUpperCase(), bg: Ds.ink, fg: Ds.aura),
                                  const Spacer(),
                                  if (isNext)
                                    Text(
                                      'NEXT STEP'.toUpperCase(),
                                      style: DsText.caption.copyWith(
                                        color: Ds.aura,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Ds.border.withOpacity(0.4)
      ..strokeWidth = 1.0;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
