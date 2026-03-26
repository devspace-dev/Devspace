import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/github_service.dart';
import '../theme/app_colors.dart';

class GitHubCard extends StatefulWidget {
  final String githubHandle;
  const GitHubCard({super.key, required this.githubHandle});

  @override
  State<GitHubCard> createState() => _GitHubCardState();
}

class _GitHubCardState extends State<GitHubCard> {
  late Future<_GitHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GitHubData> _load() async {
    final svc = GitHubService.instance;
    final results = await Future.wait([
      svc.getRepos(widget.githubHandle),
      svc.getRecentCommits(widget.githubHandle),
      svc.getUserStats(widget.githubHandle),
    ]);
    return _GitHubData(
      repos:   results[0] as List<GitHubRepo>,
      commits: results[1] as List<GitHubCommit>,
      stats:   results[2] as Map<String, dynamic>?,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.githubHandle.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<_GitHubData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _GitHubSkeleton();
        }
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();

        final data = snap.data!;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.text.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text('⌥',
                            style: TextStyle(fontSize: 13, color: AppColors.text2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@${widget.githubHandle}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: AppColors.text),
                    ),
                    const Spacer(),
                    if (data.stats != null) ...[
                      _StatChip(
                          icon: Icons.star_rounded,
                          label: '${data.stats!['public_repos'] ?? 0} repos'),
                      const SizedBox(width: 8),
                      _StatChip(
                          icon: Icons.people_outline_rounded,
                          label: '${data.stats!['followers'] ?? 0}'),
                    ],
                  ],
                ),
              ),

              // Recent commits
              if (data.commits.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Text('Recent commits',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.text3, letterSpacing: 0.5)),
                ),
                ...data.commits.take(3).map((c) => _CommitRow(commit: c)),
              ],

              // Top repos
              if (data.repos.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Text('Top repositories',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.text3, letterSpacing: 0.5)),
                ),
                ...data.repos.take(3).map((r) => _RepoRow(repo: r)),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CommitRow extends StatelessWidget {
  final GitHubCommit commit;
  const _CommitRow({required this.commit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.message,
                  style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${commit.repo.split('/').last} · ${timeago.format(commit.date)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.text3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoRow extends StatelessWidget {
  final GitHubRepo repo;
  const _RepoRow({required this.repo});

  @override
  Widget build(BuildContext context) {
    final langColors = {
      'Dart': const Color(0xFF00B4AB),
      'JavaScript': const Color(0xFFF1E05A),
      'TypeScript': const Color(0xFF3178C6),
      'Python': const Color(0xFF3572A5),
      'Go': const Color(0xFF00ADD8),
      'Rust': const Color(0xFFDEA584),
      'Swift': const Color(0xFFFA7343),
      'Kotlin': const Color(0xFF7F52FF),
    };
    final langColor = langColors[repo.language] ?? AppColors.text3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, size: 16, color: AppColors.text3),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(repo.name,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                    overflow: TextOverflow.ellipsis),
                if (repo.description.isNotEmpty)
                  Text(repo.description,
                      style: const TextStyle(fontSize: 11, color: AppColors.text3),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: langColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(repo.language,
                  style: const TextStyle(fontSize: 11, color: AppColors.text3)),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, size: 13, color: AppColors.text3),
              const SizedBox(width: 2),
              Text('${repo.stars}',
                  style: const TextStyle(fontSize: 11, color: AppColors.text3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.text3),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
      ],
    );
  }
}

class _GitHubSkeleton extends StatelessWidget {
  const _GitHubSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2)),
      ),
    );
  }
}

class _GitHubData {
  final List<GitHubRepo> repos;
  final List<GitHubCommit> commits;
  final Map<String, dynamic>? stats;
  const _GitHubData({required this.repos, required this.commits, this.stats});
}
