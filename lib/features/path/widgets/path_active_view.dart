import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../core/widgets/segment_bar.dart';
import '../models/roadmap_model.dart';
import '../providers/path_provider.dart';
import 'path_map_canvas.dart';
import 'path_node_detail_sheet.dart';
import 'path_saved_sheet.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Ds.ink,
        border: Border(bottom: BorderSide(color: Ds.border, width: 1)),
      ),
      child: Row(
        children: [
          // Browse all button
          IconButton(
            icon: const Icon(Icons.explore_outlined, color: Ds.bone),
            tooltip: 'Browse all roadmaps',
            onPressed: widget.onBrowseAll,
          ),
          const SizedBox(width: 4),

          // Title & Level Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    DsTag(widget.roadmap.levelTag, bg: Ds.surface, fg: Ds.aura),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.currentWeeklyHours}H/WK',
                      style: DsText.caption.copyWith(color: Ds.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.roadmap.title.toUpperCase(),
                  style: DsText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // View Mode Switcher (List / Map)
          Container(
            decoration: BoxDecoration(
              color: Ds.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Ds.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeIcon(Icons.view_list, PathViewMode.list),
                _buildModeIcon(Icons.alt_route, PathViewMode.map),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Roadmaps Manager Sheet
          IconButton(
            icon: const Icon(Icons.folder_open_outlined, color: Ds.bone),
            tooltip: 'Saved Roadmaps',
            onPressed: () => PathSavedSheet.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(IconData icon, PathViewMode mode) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isSelected ? Ds.aura : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Ds.onAura : Ds.muted,
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
        // One Clear Next Step Card
        _buildNextStepCard(nextStep, provider),
        const SizedBox(height: 16),

        // Progress Summary & Milestone Marker
        _buildProgressCard(provider, doneActive, totalActive),
        const SizedBox(height: 24),

        // Section Title: Stages Breakdown
        Text(
          'YOUR LEARNING ROUTE'.toUpperCase(),
          style: DsText.number.copyWith(color: Ds.aura),
        ),
        const SizedBox(height: 12),

        // Stages and Nodes
        for (final stage in widget.roadmap.stages) ...[
          _buildStageSection(stage, completed, level, nextStep),
          const SizedBox(height: 18),
        ],
      ],
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

  Widget _buildProgressCard(PathProvider provider, int done, int total) {
    final pct = provider.progressPercent;
    final pctInt = (pct * 100).toInt();

    return DsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ROUTE PROGRESS', style: DsText.number.copyWith(color: Ds.bone)),
              const Spacer(),
              Text(
                '$pctInt% COMPLETED',
                style: DsText.number.copyWith(color: Ds.mint),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Segment Bar
          SegmentBar(
            total: total > 0 ? total : 1,
            current: done,
            height: 10,
            filledColor: Ds.mint,
            emptyColor: Ds.border,
          ),
          const SizedBox(height: 12),

          // Milestone Checkpoint Markers (Visual markers in v1 per specs)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMilestonePill('25%', pct >= 0.25),
              _buildMilestonePill('50%', pct >= 0.50),
              _buildMilestonePill('100%', pct >= 1.0),
            ],
          ),
          const SizedBox(height: 14),

          // Stats Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done of $total nodes done',
                style: DsText.caption,
              ),
              Text(
                '${provider.remainingHours}h remaining (~${provider.estimatedWeeks}w)',
                style: DsText.caption.copyWith(color: Ds.aura),
              ),
            ],
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
                  leading: _buildNodeStatusIcon(isDone, isNext, isSkipped),
                  title: Text(
                    node.title.toUpperCase(),
                    style: DsText.label.copyWith(
                      color: isDone
                          ? Ds.mint
                          : isNext
                              ? Ds.aura
                              : isSkipped
                                  ? Ds.muted
                                  : Ds.bone,
                    ),
                  ),
                  subtitle: Text(
                    isSkipped
                        ? 'Skipped based on your starting level'
                        : '${node.estimatedHours} hours • ${node.subtopics.length} subtopics',
                    style: DsText.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Ds.muted, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNodeStatusIcon(bool isDone, bool isNext, bool isSkipped) {
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
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Ds.ink,
      child: Icon(Icons.radio_button_unchecked, color: Ds.border, size: 16),
    );
  }
}
