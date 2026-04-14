import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/github_service.dart';
import '../theme/app_colors.dart';
import 'skeleton_loaders.dart';

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
        final totalStars = data.repos.fold<int>(0, (sum, r) => sum + r.stars);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bg2,
                AppColors.bg2.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/25/25231.png',
                        width: 18,
                        height: 18,
                        color: AppColors.text,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.code_rounded,
                          size: 18,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GitHub Developer Stats',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'github.com/${widget.githubHandle}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.border, height: 1),

              // Stats Grid
              if (data.stats != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.library_books_rounded,
                        label: 'Repos',
                        value: '${data.stats!['public_repos'] ?? 0}',
                      ),
                      _StatItem(
                        icon: Icons.star_rounded,
                        label: 'Stars',
                        value: '$totalStars',
                      ),
                      _StatItem(
                        icon: Icons.people_alt_rounded,
                        label: 'Followers',
                        value: '${data.stats!['followers'] ?? 0}',
                      ),
                      _StatItem(
                        icon: Icons.person_add_rounded,
                        label: 'Following',
                        value: '${data.stats!['following'] ?? 0}',
                      ),
                    ],
                  ),
                ),

              // Latest contribution
              if (data.commits.isNotEmpty) ...[
                const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'LATEST PUSH · ${timeago.format(data.commits.first.date, locale: 'en_short')}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text3,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CommitRow(commit: data.commits.first),
                    ],
                  ),
                ),
              ],

              // Top repo showcase
              if (data.repos.isNotEmpty) ...[
                if (data.commits.isEmpty) const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bg3.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FEATURED REPOSITORY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text4,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _RepoRow(repo: data.repos.first),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.8)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.text3,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CommitRow extends StatelessWidget {
  final GitHubCommit commit;
  const _CommitRow({required this.commit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                commit.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'in ${commit.repo.split('/').last}',
                style: const TextStyle(fontSize: 12, color: AppColors.text3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepoRow extends StatelessWidget {
  final GitHubRepo repo;
  const _RepoRow({required this.repo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                repo.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (repo.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    repo.description,
                    style: const TextStyle(fontSize: 12, color: AppColors.text2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.spark),
              const SizedBox(width: 4),
              Text(
                '${repo.stars}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SkeletonLoader(width: 36, height: 36, borderRadius: 10),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: 140, height: 14),
                  const SizedBox(height: 6),
                  const SkeletonLoader(width: 100, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (_) => const SkeletonLoader(width: 50, height: 40, borderRadius: 10)),
          ),
        ],
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
