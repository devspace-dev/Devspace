import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../data/roadmap_directory.dart';
import '../models/roadmap_model.dart';
import '../providers/path_provider.dart';
import 'path_saved_sheet.dart';
import 'path_setup_sheet.dart';

/// Screen displayed when browsing and selecting a learning path.
class PathFindView extends StatefulWidget {
  final VoidCallback? onReturnToActive;

  const PathFindView({
    super.key,
    this.onReturnToActive,
  });

  @override
  State<PathFindView> createState() => _PathFindViewState();
}

class _PathFindViewState extends State<PathFindView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<PathProvider>();
    _searchCtrl.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openDirectoryUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PathProvider>();
    final active = provider.activeRoadmap;
    final filtered = provider.filteredRoadmaps;

    return Scaffold(
      backgroundColor: Ds.ink,
      body: SafeArea(
        child: RefreshIndicator(
          color: Ds.aura,
          backgroundColor: Ds.surface,
          onRefresh: () => provider.loadUserRoadmaps(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEVSPACE PATH', style: DsText.number.copyWith(color: Ds.aura)),
                        const SizedBox(height: 2),
                        Text('CHOOSE YOUR GOAL'.toUpperCase(), style: DsText.h2),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open_outlined, color: Ds.bone),
                    tooltip: 'Saved Roadmaps',
                    onPressed: () => PathSavedSheet.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select one primary roadmap to guide your learning route. You can switch or save anytime.',
                style: DsText.bodySm,
              ),
              const SizedBox(height: 16),

              // Active Path Quick Banner (if active)
              if (active != null) ...[
                DsCard(
                  borderColor: Ds.aura,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation, color: Ds.aura, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENTLY ACTIVE: ${active.title.toUpperCase()}',
                              style: DsText.caption.copyWith(
                                color: Ds.aura,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${provider.completedActiveCount} / ${provider.totalActiveCount} done • ~${provider.estimatedWeeks}w left',
                              style: DsText.caption,
                            ),
                          ],
                        ),
                      ),
                      if (widget.onReturnToActive != null)
                        TextButton(
                          onPressed: widget.onReturnToActive,
                          child: Text(
                            'VIEW ROUTE',
                            style: DsText.caption.copyWith(color: Ds.mint, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Ds.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Ds.border, width: 2),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: DsText.body.copyWith(color: Ds.bone),
                  cursorColor: Ds.aura,
                  onChanged: (q) => provider.setSearchQuery(q),
                  decoration: InputDecoration(
                    hintText: 'Search roadmaps (flutter, react, dsa, ml)...',
                    hintStyle: DsText.bodySm,
                    prefixIcon: const Icon(Icons.search, color: Ds.muted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Ds.muted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Error banner if any
              if (provider.errorMessage != null) ...[
                DsCard(
                  borderColor: Ds.hot,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Ds.hot, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: DsText.caption.copyWith(color: Ds.bone),
                        ),
                      ),
                      TextButton(
                        onPressed: () => provider.loadUserRoadmaps(),
                        child: Text('RETRY', style: DsText.caption.copyWith(color: Ds.hot)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Loading Skeleton State (Rule 11)
              if (provider.isLoading) ...[
                _buildLoadingSkeleton(),
                _buildLoadingSkeleton(),
              ] else if (filtered.isEmpty) ...[
                // Empty Search State (Rule 11)
                _buildEmptyState(provider),
              ] else ...[
                // Curated Paths Header
                Row(
                  children: [
                    Text(
                      'CURATED ENGINEERING PATHS'.toUpperCase(),
                      style: DsText.number.copyWith(color: Ds.aura),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Ds.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Ds.border),
                      ),
                      child: Text(
                        '${filtered.length}',
                        style: DsText.caption.copyWith(color: Ds.bone, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Curated Roadmaps List
                for (final roadmap in filtered) ...[
                  _buildCuratedPathCard(roadmap, active?.id == roadmap.id),
                  const SizedBox(height: 14),
                ],

                // External Directory Section (Only when not searching)
                if (_searchCtrl.text.trim().isEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'ROADMAP.SH DIRECTORY'.toUpperCase(),
                    style: DsText.number.copyWith(color: Ds.bone),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Additional open-source technology roadmaps powered by roadmap.sh',
                    style: DsText.caption,
                  ),
                  const SizedBox(height: 12),
                  _buildDirectoryGrid(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuratedPathCard(Roadmap roadmap, bool isActive) {
    return DsCard(
      borderColor: isActive ? Ds.aura : Ds.border,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsTag(roadmap.levelTag, bg: Ds.ink, fg: isActive ? Ds.aura : Ds.bone),
              const Spacer(),
              if (isActive)
                const DsTag('ACTIVE ROUTE', bg: Ds.mintPanel, fg: Ds.mint)
              else
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Ds.muted, size: 20),
                  tooltip: 'Save for later',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final provider = context.read<PathProvider>();
                    final ok = await provider.saveRoadmap(roadmap.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok ? 'Saved ${roadmap.title} to your roadmaps!' : 'Could not save roadmap.',
                            style: DsText.bodySm.copyWith(color: Ds.bone),
                          ),
                          backgroundColor: ok ? Ds.mint : Ds.hot,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(roadmap.title.toUpperCase(), style: DsText.h3),
          const SizedBox(height: 4),
          Text(roadmap.outcome, style: DsText.bodySm),
          const SizedBox(height: 14),

          // Stats Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              DsTag('${roadmap.stages.length} STAGES', bg: Ds.ink, fg: Ds.bone),
              DsTag('${roadmap.totalNodes} NODES', bg: Ds.ink, fg: Ds.bone),
              DsTag('${roadmap.totalHours} HOURS', bg: Ds.ink, fg: Ds.aura),
            ],
          ),
          const SizedBox(height: 16),

          // Action Button
          DsButton(
            label: isActive ? 'CONTINUE ROUTE' : 'START THIS PATH',
            kind: isActive ? DsButtonKind.mint : DsButtonKind.aura,
            height: 46,
            onPressed: () {
              if (isActive && widget.onReturnToActive != null) {
                widget.onReturnToActive!();
              } else {
                PathSetupSheet.show(
                  context,
                  roadmap: roadmap,
                  onActivated: widget.onReturnToActive,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PathProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off, color: Ds.muted, size: 48),
            const SizedBox(height: 12),
            Text('NO ROADMAPS FOUND', style: DsText.h3),
            const SizedBox(height: 6),
            Text(
              'No curated roadmaps matched "${provider.searchQuery}".',
              style: DsText.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DsButton(
              label: 'CLEAR SEARCH',
              kind: DsButtonKind.bone,
              height: 40,
              onPressed: () {
                _searchCtrl.clear();
                provider.setSearchQuery('');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Ds.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Ds.border, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 80, height: 16, color: Ds.ink),
            const SizedBox(height: 14),
            Container(width: 200, height: 24, color: Ds.ink),
            const SizedBox(height: 10),
            Container(width: double.infinity, height: 14, color: Ds.ink),
            const Spacer(),
            Container(width: double.infinity, height: 42, color: Ds.ink),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kRoadmapDirectory.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, idx) {
        final entry = kRoadmapDirectory[idx];
        return InkWell(
          onTap: () => _openDirectoryUrl(entry.url),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Ds.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Ds.border),
            ),
            child: Row(
              children: [
                Icon(entry.icon, color: entry.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.title,
                    style: DsText.caption.copyWith(color: Ds.bone, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
