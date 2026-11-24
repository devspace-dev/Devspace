import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../models/roadmap_model.dart';
import '../providers/path_provider.dart';

/// Deep detail modal sheet for a specific roadmap node.
///
/// Contains:
/// - Why it matters (engineering context)
/// - Subtopics checklist
/// - Practice project idea
/// - Verified official resources (Rule 9)
/// - "Practice this" button that navigates cleanly to `/quiz/:lobby`
/// - Optimistic complete/uncomplete toggle with rollback
class PathNodeDetailSheet extends StatefulWidget {
  final String roadmapId;
  final RoadmapNode node;
  final String stageTitle;

  const PathNodeDetailSheet({
    super.key,
    required this.roadmapId,
    required this.node,
    required this.stageTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String roadmapId,
    required RoadmapNode node,
    required String stageTitle,
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
        child: PathNodeDetailSheet(
          roadmapId: roadmapId,
          node: node,
          stageTitle: stageTitle,
        ),
      ),
    );
  }

  @override
  State<PathNodeDetailSheet> createState() => _PathNodeDetailSheetState();
}

class _PathNodeDetailSheetState extends State<PathNodeDetailSheet> {
  bool _isToggling = false;

  Future<void> _toggleCompletion() async {
    setState(() => _isToggling = true);
    final provider = context.read<PathProvider>();
    final ok = await provider.toggleNodeCompletion(
      roadmapId: widget.roadmapId,
      nodeId: widget.node.id,
    );

    if (mounted) {
      setState(() => _isToggling = false);
      if (!ok && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage!,
              style: DsText.bodySm.copyWith(color: Ds.bone),
            ),
            backgroundColor: Ds.hot,
          ),
        );
      }
    }
  }

  Future<void> _openResource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open documentation link.',
              style: DsText.bodySm.copyWith(color: Ds.bone),
            ),
            backgroundColor: Ds.hot,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PathProvider>();
    final isCompleted = provider.completedNodeIds.contains(widget.node.id);
    final isUnlocked = provider.isNodeUnlocked(widget.node);
    final uncompletedPrereqs = provider.getUncompletedPrerequisites(widget.node);
    final lobby = widget.node.practiceTier;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),

            // Top action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.stageTitle.toUpperCase(),
                      style: DsText.caption.copyWith(color: Ds.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Ds.muted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Ds.border, height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Node Title & Tags
                    Text(
                      widget.node.title.toUpperCase(),
                      style: DsText.h2,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        DsTag('${widget.node.estimatedHours} HOURS', bg: Ds.ink, fg: Ds.aura),
                        if (widget.node.isFoundation)
                          const DsTag('FOUNDATION', bg: Ds.ink, fg: Ds.mint),
                        if (lobby != null)
                          DsTag('${lobby.toUpperCase()} TIER', bg: Ds.ink, fg: Ds.bone),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section: Why this matters
                    Text(
                      'WHY THIS MATTERS'.toUpperCase(),
                      style: DsText.number.copyWith(color: Ds.aura),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.node.why,
                      style: DsText.body,
                    ),
                    const SizedBox(height: 20),

                    // Section: Key Subtopics Checklist
                    Text(
                      'KEY TOPICS TO MASTER'.toUpperCase(),
                      style: DsText.number.copyWith(color: Ds.aura),
                    ),
                    const SizedBox(height: 8),
                    DsCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.node.subtopics.map((topic) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Ds.mint,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    topic,
                                    style: DsText.bodySm.copyWith(color: Ds.bone),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Practical Project
                    Text(
                      'PRACTICE PROJECT IDEA'.toUpperCase(),
                      style: DsText.number.copyWith(color: Ds.aura),
                    ),
                    const SizedBox(height: 8),
                    DsCard(
                      borderColor: Ds.aura,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.code, color: Ds.aura, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.node.projectIdea,
                              style: DsText.bodySm.copyWith(color: Ds.bone),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Official Resources (Rule 9)
                    Text(
                      'OFFICIAL DOCUMENTATION'.toUpperCase(),
                      style: DsText.number.copyWith(color: Ds.aura),
                    ),
                    const SizedBox(height: 8),
                    if (widget.node.resources.isEmpty)
                      DsCard(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Self-contained guide: Master the subtopics and complete the practice project above using official language/framework docs.',
                          style: DsText.caption,
                        ),
                      )
                    else
                      Column(
                        children: widget.node.resources.map((res) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => _openResource(res.url),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Ds.ink,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Ds.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.open_in_new, color: Ds.aura, size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            res.title,
                                            style: DsText.label.copyWith(color: Ds.bone),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${res.sourceDomain} • ${res.type}',
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
                  ],
                ),
              ),
            ),

            // Bottom Sticky Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Ds.surface,
                border: Border(top: BorderSide(color: Ds.border, width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Practice This Button (if practiceTier exists)
                  if (lobby != null) ...[
                    DsButton(
                      label: 'PRACTICE THIS (${lobby.toUpperCase()})',
                      kind: DsButtonKind.bone,
                      icon: const Icon(Icons.bolt, color: Ds.onAura, size: 20),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/quiz/$lobby');
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Prerequisite Lock Banner
                  if (!isUnlocked && !isCompleted) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Ds.ink,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Ds.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: Ds.aura, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              uncompletedPrereqs.isNotEmpty
                                  ? 'Complete "${uncompletedPrereqs.map((p) => p.title).join(', ')}" first to unlock.'
                                  : 'Complete previous topics first to unlock.',
                              style: DsText.caption.copyWith(color: Ds.bone),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mark Complete Toggle Button
                  if (!isUnlocked && !isCompleted)
                    const DsButton(
                      label: 'TOPIC LOCKED',
                      kind: DsButtonKind.bone,
                      icon: Icon(Icons.lock_outline, color: Ds.muted, size: 18),
                      onPressed: null,
                    )
                  else
                    DsButton(
                      label: isCompleted ? 'COMPLETED ✓' : 'MARK AS COMPLETED',
                      kind: isCompleted ? DsButtonKind.mint : DsButtonKind.aura,
                      loading: _isToggling,
                      onPressed: _isToggling ? null : _toggleCompletion,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
