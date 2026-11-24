import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/path_provider.dart';
import '../widgets/path_active_view.dart';
import '../widgets/path_find_view.dart';

/// Redesigned Path screen for DevSpace.
///
/// Features:
/// - Single active roadmap per student (persisted in `public.user_roadmaps`)
/// - Dynamic routing: Shows [PathActiveView] if a path is active, or [PathFindView] to explore
/// - Seamless toggle back and forth between active route and directory
/// - 60fps optimistic node completion with automatic error rollback
class PathScreen extends StatefulWidget {
  const PathScreen({super.key});

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  bool _browsingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PathProvider>().loadUserRoadmaps();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PathProvider>();
    final activeRoadmap = provider.activeRoadmap;

    if (activeRoadmap != null && !_browsingAll) {
      return PathActiveView(
        roadmap: activeRoadmap,
        onBrowseAll: () => setState(() => _browsingAll = true),
      );
    }

    return PathFindView(
      onReturnToActive: activeRoadmap != null
          ? () => setState(() => _browsingAll = false)
          : null,
    );
  }
}
