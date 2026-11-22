import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../models/roadmap_model.dart';
import '../providers/path_provider.dart';

/// Modal bottom sheet allowing a student to configure their starting level
/// and weekly study commitment before activating a roadmap.
class PathSetupSheet extends StatefulWidget {
  final Roadmap roadmap;
  final VoidCallback? onActivated;

  const PathSetupSheet({
    super.key,
    required this.roadmap,
    this.onActivated,
  });

  static Future<void> show(
    BuildContext context, {
    required Roadmap roadmap,
    VoidCallback? onActivated,
    PathProvider? provider,
  }) {
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
        child: PathSetupSheet(
          roadmap: roadmap,
          onActivated: onActivated,
        ),
      ),
    );
  }

  @override
  State<PathSetupSheet> createState() => _PathSetupSheetState();
}

class _PathSetupSheetState extends State<PathSetupSheet> {
  RoadmapLevel _selectedLevel = RoadmapLevel.beginner;
  int _weeklyHours = 6;
  bool _isSubmitting = false;

  int get _remainingHours => widget.roadmap.remainingHours(
        level: _selectedLevel,
        completedNodeIds: {},
      );

  int get _estimatedWeeks => widget.roadmap.estimatedWeeks(
        level: _selectedLevel,
        weeklyHours: _weeklyHours,
        completedNodeIds: {},
      );

  int get _skippedFoundationCount {
    if (_selectedLevel == RoadmapLevel.beginner) return 0;
    return widget.roadmap.foundationNodeIds.length;
  }

  Future<void> _activate() async {
    setState(() => _isSubmitting = true);
    final provider = context.read<PathProvider>();
    final success = await provider.selectRoadmap(
      roadmapId: widget.roadmap.id,
      level: _selectedLevel,
      weeklyHours: _weeklyHours,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onActivated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Could not activate roadmap. Please retry.',
              style: DsText.bodySm.copyWith(color: Ds.bone),
            ),
            backgroundColor: Ds.hot,
          ),
        );
      }
    }
  }

  Future<void> _saveForLater() async {
    final provider = context.read<PathProvider>();
    final success = await provider.saveRoadmap(widget.roadmap.id);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Saved to your roadmaps list!' : 'Could not save roadmap.',
            style: DsText.bodySm.copyWith(color: Ds.bone),
          ),
          backgroundColor: success ? Ds.mint : Ds.hot,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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

            // Header Tag & Title
            Row(
              children: [
                DsTag(
                  widget.roadmap.levelTag,
                  bg: Ds.border,
                  fg: Ds.aura,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Ds.muted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.roadmap.title.toUpperCase(),
              style: DsText.h2,
            ),
            const SizedBox(height: 6),
            Text(
              widget.roadmap.outcome,
              style: DsText.bodySm,
            ),
            const SizedBox(height: 20),

            // Section 1: Starting Level
            Text(
              '1. YOUR STARTING LEVEL'.toUpperCase(),
              style: DsText.number.copyWith(color: Ds.aura),
            ),
            const SizedBox(height: 10),
            Column(
              children: RoadmapLevel.values.map((lvl) {
                final isSelected = _selectedLevel == lvl;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedLevel = lvl),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Ds.surface : Ds.ink,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Ds.aura : Ds.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected ? Ds.aura : Ds.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lvl.label.toUpperCase(),
                                  style: DsText.label.copyWith(
                                    color: isSelected ? Ds.aura : Ds.bone,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lvl.description,
                                  style: DsText.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_skippedFoundationCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: Text(
                  '⚡ Skips $_skippedFoundationCount syntax primers to fast-track your route.',
                  style: DsText.caption.copyWith(color: Ds.mint),
                ),
              ),
            const SizedBox(height: 12),

            // Section 2: Weekly Commitment
            Text(
              '2. WEEKLY COMMITMENT'.toUpperCase(),
              style: DsText.number.copyWith(color: Ds.aura),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCommitmentPill(3, 'Casual\n3h / wk'),
                const SizedBox(width: 8),
                _buildCommitmentPill(6, 'Standard\n6h / wk'),
                const SizedBox(width: 8),
                _buildCommitmentPill(10, 'Hardcore\n10h / wk'),
              ],
            ),
            const SizedBox(height: 20),

            // Section 3: Live Finish Estimate Banner
            DsCard(
              padding: const EdgeInsets.all(16),
              borderColor: Ds.aura,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Ds.ink,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Ds.border),
                    ),
                    child: const Icon(Icons.timer_outlined, color: Ds.aura, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINISH IN ~$_estimatedWeeks WEEKS'.toUpperCase(),
                          style: DsText.label.copyWith(color: Ds.aura),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_remainingHours hours remaining at $_weeklyHours hrs/week',
                          style: DsText.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            DsButton(
              label: 'ACTIVATE THIS PATH',
              onPressed: _isSubmitting ? null : _activate,
              loading: _isSubmitting,
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _saveForLater,
                child: Text(
                  'SAVE FOR LATER',
                  style: DsText.caption.copyWith(color: Ds.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentPill(int hours, String label) {
    final isSelected = _weeklyHours == hours;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _weeklyHours = hours),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Ds.surface : Ds.ink,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Ds.aura : Ds.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: DsText.caption.copyWith(
                color: isSelected ? Ds.aura : Ds.bone,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
