import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../models/roadmap_model.dart';
import '../providers/path_provider.dart';
import 'path_map_canvas.dart';
import 'path_node_detail_sheet.dart';
import 'path_saved_sheet.dart';
import 'path_setup_sheet.dart';

enum PathViewMode { list, map }

/// View rendered when a student has an active roadmap.
class PathActiveView extends StatefulWidget {
  final Roadmap roadmap;
  final VoidCallback onBrowseAll;

  const PathActiveView({
    super.key,
    required this.roadmap,
    required this.onBrowseAll,
  });

  @override
  State<PathActiveView> createState() => _PathActiveViewState();
}

class _PathActiveViewState extends State<PathActiveView> {
  PathViewMode _viewMode = PathViewMode.list;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PathProvider>();
    final completed = provider.completedNodeIds;
    final level = provider.currentLevel;
    final nextStep = provider.nextRecommendedStep;

    return Scaffold(
      backgroundColor: Ds.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(provider),

            // Main Content Area
            Expanded(
              child: _viewMode == PathViewMode.map
                  ? PathMapCanvas(roadmap: widget.roadmap)
                  : _buildListView(provider, completed, level, nextStep),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PathProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Ds.ink,
        border: Border(bottom: BorderSide(color: Ds.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Labeled "ALL PATHS" button with back icon
          InkWell(
            onTap: widget.onBrowseAll,
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: 'Browse all roadmaps',
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Ds.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Ds.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_ios_new, size: 12, color: Ds.aura),
                    const SizedBox(width: 8),
                    Text(
                      'ALL PATHS',
                      style: DsText.caption.copyWith(
                        color: Ds.bone,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Controls: View Switcher (List / Map) + Saved Roadmaps
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: Ds.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Ds.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeIcon(Icons.view_list, PathViewMode.list, 'List'),
                    _buildModeIcon(Icons.alt_route, PathViewMode.map, 'Map'),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Roadmaps Manager Sheet
              InkWell(
                onTap: () => PathSavedSheet.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: const EdgeInsets.all(7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Ds.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Ds.border),
                  ),
                  child: const Icon(
                    Icons.folder_open_outlined,
                    color: Ds.bone,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(IconData icon, PathViewMode mode, String label) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Ds.aura : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Ds.onAura : Ds.muted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: DsText.caption.copyWith(
                color: isSelected ? Ds.onAura : Ds.muted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    PathProvider provider,
    Set<String> completed,
    RoadmapLevel level,
    RoadmapNode? nextStep,
  ) {
    final totalActive = provider.totalActiveCount;
    final doneActive = provider.completedActiveCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Roadmap Identity Header (Spacious, full title with no truncation)
        _buildRoadmapHeader(provider),
        const SizedBox(height: 12),

        // 2. Slim Progress Bar (Option B style: compact, responsive)
        _buildSlimProgressBar(provider, doneActive, totalActive),
        const SizedBox(height: 16),

        // 3. One Clear Next Step Card (Option A style)
        _buildNextStepCard(nextStep, provider),
        const SizedBox(height: 24),

        // 4. Section Title: Stages Breakdown
        Text(
          'YOUR LEARNING ROUTE'.toUpperCase(),
          style: DsText.number.copyWith(color: Ds.aura),
        ),
        const SizedBox(height: 12),

        // 5. Stages and Nodes
        for (final stage in widget.roadmap.stages) ...[
          _buildStageSection(stage, completed, level, nextStep),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _buildRoadmapHeader(PathProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags Row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            DsTag(widget.roadmap.levelTag, bg: Ds.surface, fg: Ds.aura),
            DsTag('${provider.currentWeeklyHours}H / WEEK', bg: Ds.surface, fg: Ds.bone),
            DsTag('~${provider.estimatedWeeks}W LEFT', bg: Ds.surface, fg: Ds.mint),
          ],
        ),
        const SizedBox(height: 8),

        // Full Title (Anton H2 - wraps naturally if long, never truncated)
        Text(
          widget.roadmap.title.toUpperCase(),
          style: DsText.h2,
        ),
        const SizedBox(height: 4),

        // Outcome summary & quick settings link
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.roadmap.outcome,
                style: DsText.bodySm.copyWith(color: Ds.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => PathSetupSheet.show(context, roadmap: widget.roadmap),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune, size: 14, color: Ds.aura),
                    const SizedBox(width: 4),
                    Text(
                      'SETTINGS',
                      style: DsText.caption.copyWith(
                        color: Ds.aura,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlimProgressBar(PathProvider provider, int done, int total) {
    final pct = provider.progressPercent;
    final pctInt = (pct * 100).toInt();

    return DsCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Done count badge
              Flexible(
                child: Text(
                  '$done / $total DONE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DsText.caption.copyWith(
                    color: Ds.mint,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Progress Bar
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: Ds.ink,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(color: Ds.mint),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Percentage & Remaining Hours
              Flexible(
                child: Text(
                  '$pctInt% • ${provider.remainingHours}H LEFT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: DsText.caption.copyWith(
                    color: Ds.aura,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Milestone Checkpoint Markers (Clean, scrollable row for small screens & large fonts)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMilestonePill('25% Milestone', pct >= 0.25),
                const SizedBox(width: 8),
                _buildMilestonePill('50% Milestone', pct >= 0.50),
                const SizedBox(width: 8),
                _buildMilestonePill('100% Complete', pct >= 1.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard(RoadmapNode? nextStep, PathProvider provider) {
    if (nextStep == null) {
      return DsCard(
        borderColor: Ds.mint,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.celebration, color: Ds.mint, size: 36),
            const SizedBox(height: 8),
            Text('PATH COMPLETED!'.toUpperCase(), style: DsText.h3.copyWith(color: Ds.mint)),
            const SizedBox(height: 4),
            Text(
              'You have mastered all milestones for ${widget.roadmap.title}. Explore another path!',
              style: DsText.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            DsButton(
              label: 'EXPLORE ANOTHER PATH',
              kind: DsButtonKind.mint,
              height: 44,
              onPressed: widget.onBrowseAll,
            ),
          ],
        ),
      );
    }

    // Find stage for nextStep
    String stageName = 'Current Stage';
    for (final s in widget.roadmap.stages) {
      if (s.nodes.any((n) => n.id == nextStep.id)) {
        stageName = s.title;
        break;
      }
    }

    return DsCard(
      borderColor: Ds.aura,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsTag('NEXT STEP', bg: Ds.ink, fg: Ds.aura),
              const Spacer(),
              Text(
                '~${nextStep.estimatedHours} HOURS',
                style: DsText.caption.copyWith(color: Ds.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(nextStep.title.toUpperCase(), style: DsText.h3),
          const SizedBox(height: 4),
          Text(
            nextStep.why,
            style: DsText.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          DsButton(
            label: 'CONTINUE LEARNING',
            icon: const Icon(Icons.play_arrow, color: Ds.onAura, size: 20),
            height: 46,
            onPressed: () {
              PathNodeDetailSheet.show(
                context,
                roadmapId: widget.roadmap.id,
                node: nextStep,
                stageTitle: stageName,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonePill(String label, bool reached) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: reached ? Ds.mintPanel : Ds.ink,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: reached ? Ds.mint : Ds.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reached ? Icons.check : Icons.lock_outline,
            size: 12,
            color: reached ? Ds.mint : Ds.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: DsText.caption.copyWith(
              color: reached ? Ds.mint : Ds.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageSection(
    RoadmapStage stage,
    Set<String> completed,
    RoadmapLevel level,
    RoadmapNode? nextStep,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Ds.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Ds.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Ds.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Ds.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title.toUpperCase(),
                  style: DsText.number.copyWith(color: Ds.aura),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.description,
                  style: DsText.caption,
                ),
              ],
            ),
          ),

          // Nodes in Stage
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stage.nodes.length,
            separatorBuilder: (_, __) => const Divider(color: Ds.border, height: 1),
            itemBuilder: (context, idx) {
              final node = stage.nodes[idx];
              final isDone = completed.contains(node.id);
              final isSkipped = node.isSkippedForLevel(level);
              final isNext = nextStep?.id == node.id;
              final isUnlocked = widget.roadmap.isNodeUnlocked(
                node: node,
                level: level,
                completedNodeIds: completed,
              );

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () {
                    PathNodeDetailSheet.show(
                      context,
                      roadmapId: widget.roadmap.id,
                      node: node,
                      stageTitle: stage.title,
                    );
                  },
                  leading: _buildNodeStatusIcon(isDone, isNext, isSkipped, isUnlocked),
                  title: Text(
                    node.title.toUpperCase(),
                    style: DsText.label.copyWith(
                      color: isDone
                          ? Ds.mint
                          : isNext
                              ? Ds.aura
                              : (isSkipped || !isUnlocked)
                                  ? Ds.muted
                                  : Ds.bone,
                    ),
                  ),
                  subtitle: Text(
                    isSkipped
                        ? 'Skipped based on your starting level'
                        : !isUnlocked
                            ? '${node.estimatedHours} hours • Locked'
                            : '${node.estimatedHours} hours • ${node.subtopics.length} subtopics',
                    style: DsText.caption,
                  ),
                  trailing: Icon(
                    !isUnlocked ? Icons.lock_outline : Icons.chevron_right,
                    color: Ds.muted,
                    size: !isUnlocked ? 16 : 18,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNodeStatusIcon(bool isDone, bool isNext, bool isSkipped, bool isUnlocked) {
    if (isDone) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Ds.mintPanel,
        child: Icon(Icons.check, color: Ds.mint, size: 16),
      );
    }
    if (isNext) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Ds.ink,
        child: Icon(Icons.play_arrow, color: Ds.aura, size: 18),
      );
    }
    if (isSkipped) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Ds.ink,
        child: Icon(Icons.fast_forward, color: Ds.muted, size: 16),
      );
    }
    if (!isUnlocked) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Ds.ink,
        child: Icon(Icons.lock_outline, color: Ds.muted, size: 15),
      );
    }
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Ds.ink,
      child: Icon(Icons.radio_button_unchecked, color: Ds.border, size: 16),
    );
  }
}
