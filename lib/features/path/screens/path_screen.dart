import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../core/widgets/glitch.dart';
import '../../../core/widgets/segment_bar.dart';
import '../../../data/roadmap_directory.dart';
import '../../../data/roadmaps_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/supabase_service.dart';

class PathScreen extends StatefulWidget {
  const PathScreen({super.key});

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  int _selectedTrackIndex = 0;
  String? _selectedNodeId;
  final Set<String> _completedNodeIds = {};

  RoadmapTrack get _currentTrack =>
      kRoadmapTracks[_selectedTrackIndex.clamp(0, kRoadmapTracks.length - 1)];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final trackId = _currentTrack.id;
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('roadmap_completed_$trackId') ?? [];

    if (mounted) {
      setState(() {
        _completedNodeIds.addAll(cached);
      });
    }

    try {
      final remoteCompleted =
          await SupabaseService.instance.getUserRoadmapProgress(trackId);
      if (mounted && remoteCompleted.isNotEmpty) {
        setState(() {
          _completedNodeIds.addAll(remoteCompleted);
        });
        await prefs.setStringList(
            'roadmap_completed_$trackId', _completedNodeIds.toList());
      }
    } catch (_) {
      // Offline fallback to local cache
    }
  }

  Future<void> _toggleNodeCompletion(RoadmapNode node, bool isCompleted) async {
    final trackId = _currentTrack.id;
    setState(() {
      if (isCompleted) {
        _completedNodeIds.add(node.id);
      } else {
        _completedNodeIds.remove(node.id);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'roadmap_completed_$trackId', _completedNodeIds.toList());

    try {
      await SupabaseService.instance.setRoadmapNodeCompleted(
        trackId,
        node.id,
        isCompleted,
      );
    } catch (_) {
      // Persisted locally, will retry on next sync
    }
  }

  bool _isNodeUnlocked(RoadmapNode node) {
    if (node.prerequisites.isEmpty) return true;
    return node.prerequisites.every((prereqId) => _completedNodeIds.contains(prereqId));
  }

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuthProvider>().currentUserOrNull?.aura ?? 0;
    final track = _currentTrack;
    final nodes = track.nodes;

    final selectedNode = nodes.firstWhere(
      (n) => n.id == _selectedNodeId,
      orElse: () => nodes.firstWhere(
        (n) => !_completedNodeIds.contains(n.id) && _isNodeUnlocked(n),
        orElse: () => nodes.first,
      ),
    );

    final completedCount = nodes.where((n) => _completedNodeIds.contains(n.id)).length;
    final isSelectedDone = _completedNodeIds.contains(selectedNode.id);
    final isSelectedUnlocked = _isNodeUnlocked(selectedNode);

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('PATH', style: DsText.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Ds.bone, size: 24),
            tooltip: 'Search roadmaps (roadmap.sh)',
            onPressed: () => _openRoadmapSearchModal(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AuraChip(aura),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Horizontally Scrollable Track Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kRoadmapTracks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final t = kRoadmapTracks[index];
                  final active = index == _selectedTrackIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTrackIndex = index;
                        _selectedNodeId = null;
                        _completedNodeIds.clear();
                      });
                      _loadProgress();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? Ds.aura : Ds.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? Ds.auraEdge : Ds.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        t.title.toUpperCase(),
                        style: DsText.caption.copyWith(
                          color: active ? Ds.onAura : Ds.bone,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Track Summary & Segmented Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    track.subtitle,
                    style: DsText.bodySm.copyWith(color: Ds.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedCount of ${nodes.length} NODES',
                  style: DsText.number.copyWith(fontSize: 13, color: Ds.aura),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentBar(
              total: nodes.isEmpty ? 1 : nodes.length,
              current: completedCount,
            ),
          ),
          const SizedBox(height: 12),

          // 3. Interactive Mind Map Canvas (Pan & Zoom)
          Expanded(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 2.2,
              boundaryMargin: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Column(
                    children: [
                      for (int i = 0; i < nodes.length; i++) ...[
                        _buildNodeItem(
                          node: nodes[i],
                          index: i,
                          isSelected: nodes[i].id == selectedNode.id,
                          isDone: _completedNodeIds.contains(nodes[i].id),
                          isUnlocked: _isNodeUnlocked(nodes[i]),
                          isLast: i == nodes.length - 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom Selected Node Preview Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: DsCard(
              key: const ValueKey('selected_node_preview_card'),
              onTap: () => _openNodeDetailSheet(context, selectedNode),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelectedDone
                          ? Ds.mint
                          : (isSelectedUnlocked ? Ds.aura : Ds.surface),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelectedDone
                            ? Ds.mintEdge
                            : (isSelectedUnlocked ? Ds.auraEdge : Ds.border),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSelectedDone
                          ? Icons.check_rounded
                          : (isSelectedUnlocked
                              ? Icons.bolt_rounded
                              : Icons.lock_outline_rounded),
                      color: isSelectedDone
                          ? Ds.ink
                          : (isSelectedUnlocked ? Ds.onAura : Ds.muted),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isSelectedDone)
                              const DsTag('COMPLETED', bg: Ds.mint, fg: Ds.ink)
                            else if (isSelectedUnlocked)
                              const DsTag('IN PROGRESS', bg: Ds.aura, fg: Ds.ink)
                            else
                              const DsTag('LOCKED', bg: Ds.border, fg: Ds.muted),
                            const SizedBox(width: 8),
                            Text(selectedNode.estimatedHours, style: DsText.caption),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedNode.title,
                          style: DsText.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Ds.muted, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem({
    required RoadmapNode node,
    required int index,
    required bool isSelected,
    required bool isDone,
    required bool isUnlocked,
    required bool isLast,
  }) {
    // Dynamic zig-zag horizontal offset
    final double xOffset = (index % 2 == 1) ? 36.0 : -36.0;

    return Column(
      children: [
        Transform.translate(
          offset: Offset(xOffset, 0),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedNodeId = node.id);
              _openNodeDetailSheet(context, node);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glitch companion stands next to active node if unlocked and not done
                if (isUnlocked && !isDone) ...[
                  const Glitch(size: 48, mood: GlitchMood.idle),
                  const SizedBox(width: 10),
                ],

                // Node Circle
                Container(
                  width: isUnlocked && !isDone ? 68 : 58,
                  height: isUnlocked && !isDone ? 68 : 58,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Ds.mint
                        : (isUnlocked ? Ds.aura : Ds.surface),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Ds.bone
                          : (isDone
                              ? Ds.mintEdge
                              : (isUnlocked ? Ds.auraEdge : Ds.border)),
                      width: isSelected ? 3.5 : 2.5,
                    ),
                    boxShadow: isUnlocked && !isDone
                        ? [
                            BoxShadow(
                              color: Ds.aura.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_rounded
                        : (isUnlocked ? Icons.bolt_rounded : Icons.lock_rounded),
                    size: isUnlocked && !isDone ? 34 : 26,
                    color: isDone
                        ? Ds.ink
                        : (isUnlocked ? Ds.onAura : Ds.muted),
                  ),
                ),

                const SizedBox(width: 12),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: DsText.caption.copyWith(
                            color: isDone || isUnlocked ? Ds.bone : Ds.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          node.estimatedHours,
                          style: DsText.caption.copyWith(
                            color: Ds.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Connecting rail to next node
        if (!isLast) ...[
          Container(
            width: 3,
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDone ? Ds.mint : Ds.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }


  void _openRoadmapSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Ds.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Ds.border, width: 1.5),
      ),
      builder: (ctx) => _RoadmapSearchSheet(
        onSelectInteractiveTrack: (trackIndex) {
          Navigator.pop(ctx);
          setState(() {
            _selectedTrackIndex = trackIndex;
            _selectedNodeId = null;
            _completedNodeIds.clear();
          });
          _loadProgress();
        },
      ),
    );
  }

  void _openNodeDetailSheet(BuildContext context, RoadmapNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Ds.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Ds.border, width: 1.5),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final modalDone = _completedNodeIds.contains(node.id);
            final modalUnlocked = _isNodeUnlocked(node);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
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
                      const SizedBox(height: 18),

                      // Tags
                      Row(
                        children: [
                          DsTag(_currentTrack.stackLabel),
                          const SizedBox(width: 8),
                          if (modalDone)
                            const DsTag('COMPLETED', bg: Ds.mint, fg: Ds.ink)
                          else if (modalUnlocked)
                            const DsTag('IN PROGRESS', bg: Ds.aura, fg: Ds.ink)
                          else
                            const DsTag('LOCKED', bg: Ds.border, fg: Ds.muted),
                          const Spacer(),
                          Text(node.estimatedHours, style: DsText.caption),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Node Title
                      Text(node.title.toUpperCase(), style: DsText.h2),
                      const SizedBox(height: 12),

                      // Overview
                      Text(node.description, style: DsText.body),
                      const SizedBox(height: 20),

                      // Why It Matters
                      Text('WHY IT MATTERS', style: DsText.label),
                      const SizedBox(height: 6),
                      Text(node.whyItMatters, style: DsText.bodySm),
                      const SizedBox(height: 20),

                      // Sub-topics
                      Text('CORE CONCEPTS', style: DsText.label),
                      const SizedBox(height: 8),
                      for (final topic in node.subTopics) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Ds.aura, fontSize: 16)),
                              Expanded(child: Text(topic, style: DsText.bodySm)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Practice Project Idea
                      Text('HANDS-ON PROJECT', style: DsText.label),
                      const SizedBox(height: 8),
                      DsCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: Ds.aura, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                node.practiceProjectIdea,
                                style: DsText.bodySm.copyWith(color: Ds.bone),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Verified Resources
                      if (node.resources.isNotEmpty) ...[
                        Text('VERIFIED RESOURCES', style: DsText.label),
                        const SizedBox(height: 8),
                        for (final res in node.resources) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DsCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              onTap: res.url != null
                                  ? () async {
                                      final uri = Uri.parse(res.url!);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.inAppWebView);
                                      }
                                    }
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    res.url != null ? Icons.link_rounded : Icons.menu_book_rounded,
                                    color: Ds.aura,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(res.title, style: DsText.label.copyWith(fontSize: 13)),
                                        Text(res.type, style: DsText.caption),
                                      ],
                                    ),
                                  ),
                                  if (res.url != null)
                                    const Icon(Icons.open_in_new_rounded, color: Ds.muted, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],

                      // Toggle Button (0 Aura Awarded)
                      if (modalUnlocked) ...[
                        DsButton(
                          label: modalDone ? 'MARK INCOMPLETE' : 'MARK AS COMPLETED',
                          kind: modalDone ? DsButtonKind.bone : DsButtonKind.mint,
                          onPressed: () async {
                            final newStatus = !modalDone;
                            await _toggleNodeCompletion(node, newStatus);
                            setModalState(() {});
                            if (mounted) setState(() {});
                          },
                        ),
                      ] else ...[
                        const DsButton(
                          label: 'COMPLETE PREREQUISITES FIRST',
                          kind: DsButtonKind.bone,
                          onPressed: null,
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RoadmapSearchSheet extends StatefulWidget {
  final ValueChanged<int> onSelectInteractiveTrack;

  const _RoadmapSearchSheet({
    required this.onSelectInteractiveTrack,
  });

  @override
  State<_RoadmapSearchSheet> createState() => _RoadmapSearchSheetState();
}

class _RoadmapSearchSheetState extends State<_RoadmapSearchSheet> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', ...RoadmapCategory.all];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanQuery = _query.trim().toLowerCase();

    // Match interactive tracks
    final List<(int, RoadmapTrack)> matchedInteractive = [];
    for (int i = 0; i < kRoadmapTracks.length; i++) {
      final t = kRoadmapTracks[i];
      if (_selectedCategory == 'All' || _selectedCategory == RoadmapCategory.roleBased) {
        if (cleanQuery.isEmpty ||
            t.title.toLowerCase().contains(cleanQuery) ||
            t.stackLabel.toLowerCase().contains(cleanQuery) ||
            t.subtitle.toLowerCase().contains(cleanQuery)) {
          matchedInteractive.add((i, t));
        }
      }
    }

    // Match roadmap.sh entries
    final matchedDirectory = kRoadmapDirectory.where((entry) {
      final matchesCat = _selectedCategory == 'All' || entry.category == _selectedCategory;
      final matchesQ = cleanQuery.isEmpty ||
          entry.title.toLowerCase().contains(cleanQuery) ||
          entry.slug.toLowerCase().contains(cleanQuery);
      return matchesCat && matchesQ;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SEARCH ROADMAPS', style: DsText.h3),
                  const DsTag('ROADMAP.SH', bg: Ds.aura, fg: Ds.ink),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '90+ developer paths curated by roadmap.sh. Tap an interactive path to jump straight in.',
                style: DsText.caption,
              ),
              const SizedBox(height: 14),

              // Search Box
              Container(
                decoration: BoxDecoration(
                  color: Ds.ink,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Ds.border, width: 1.5),
                ),
                child: TextField(
                  controller: _queryController,
                  style: DsText.body,
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'Search stack (e.g. Flutter, DevOps, React)...',
                    hintStyle: DsText.bodySm.copyWith(color: Ds.muted),
                    prefixIcon: const Icon(Icons.search_rounded, color: Ds.muted, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Ds.muted, size: 18),
                            onPressed: () {
                              _queryController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category Pills
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSel = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? Ds.bone : Ds.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSel ? Ds.bone : Ds.border,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          cat.toUpperCase(),
                          style: DsText.caption.copyWith(
                            color: isSel ? Ds.ink : Ds.bone,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Results List
              Expanded(
                child: (matchedInteractive.isEmpty && matchedDirectory.isEmpty)
                    ? Center(
                        child: Text(
                          'No roadmaps match "$_query".',
                          style: DsText.caption,
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        children: [
                          if (matchedInteractive.isNotEmpty) ...[
                            Text('INTERACTIVE MIND MAP TRACKS', style: DsText.label),
                            const SizedBox(height: 8),
                            for (final (idx, track) in matchedInteractive) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: DsCard(
                                  leftBar: Ds.aura,
                                  onTap: () => widget.onSelectInteractiveTrack(idx),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.route_rounded, color: Ds.aura, size: 22),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(track.title, style: DsText.label),
                                            Text(
                                              '${track.nodes.length} Interactive Nodes · In-App Canvas',
                                              style: DsText.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const DsTag('CANVAS', bg: Ds.aura, fg: Ds.ink),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],

                          if (matchedDirectory.isNotEmpty) ...[
                            Text('ROADMAP.SH CURATED GUIDES', style: DsText.label),
                            const SizedBox(height: 8),
                            for (final entry in matchedDirectory) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: DsCard(
                                  onTap: () async {
                                    final uri = Uri.parse(entry.url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.inAppWebView);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Ds.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Ds.border, width: 1.5),
                                        ),
                                        child: Icon(entry.icon, color: entry.color, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(entry.title, style: DsText.label),
                                            Text(
                                              entry.category,
                                              style: DsText.caption.copyWith(color: Ds.muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.open_in_new_rounded, color: Ds.muted, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
