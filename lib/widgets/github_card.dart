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
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 18, color: AppColors.text3),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'GitHub · ${widget.githubHandle}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.text2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (data.stats != null) ...[
                      _StatChip(
                          icon: Icons.star_outline_rounded,
                          label: '${data.stats!['public_repos'] ?? 0}'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),

              // Recent commits
              if (data.commits.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text('RECENT COMMITS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                          color: AppColors.text4, letterSpacing: 1.0)),
                ),
                ...data.commits.take(2).map((c) => _CommitRow(commit: c)),
              ],

              // Top repos
              if (data.repos.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text('TOP REPOSITORIES',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                          color: AppColors.text4, letterSpacing: 1.0)),
                ),
                ...data.repos.take(2).map((r) => _RepoRow(repo: r)),
              ],

              const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  '${commit.repo.split('/').last} · ${timeago.format(commit.date, locale: 'en_short')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.text3),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
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
                      style: const TextStyle(fontSize: 12, color: AppColors.text3),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              const Icon(Icons.star_outline_rounded, size: 14, color: AppColors.text3),
              const SizedBox(width: 4),
              Text('${repo.stars}',
                  style: const TextStyle(fontSize: 12, color: AppColors.text3)),
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
        Icon(icon, size: 14, color: AppColors.text3),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
      ],
    );
  }
}

class _GitHubSkeleton extends StatelessWidget {
  const _GitHubSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
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
