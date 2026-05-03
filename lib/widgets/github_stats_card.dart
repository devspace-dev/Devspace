import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';
import '../theme/app_colors.dart';

class GitHubStatsCard extends StatefulWidget {
  final String githubHandle;

  const GitHubStatsCard({super.key, required this.githubHandle});

  @override
  State<GitHubStatsCard> createState() => _GitHubStatsCardState();
}

class _GitHubStatsCardState extends State<GitHubStatsCard> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (widget.githubHandle.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final stats = await GitHubService.instance.getUserStats(widget.githubHandle);
      if (stats == null) throw Exception('No stats');
      
      final prs = await GitHubService.instance.getTotalPRs(widget.githubHandle);
      final commits = await GitHubService.instance.getTotalCommits(widget.githubHandle);

      if (mounted) {
        setState(() {
          _stats = stats;
          _stats!['prs'] = prs;
          _stats!['commits'] = commits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect to GitHub';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchGitHub() async {
    if (widget.githubHandle.isEmpty) return;
    final url = Uri.parse('https://github.com/${widget.githubHandle}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.githubHandle.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _launchGitHub,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117), // GitHub Dark Background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Minimal SVG replacement with Icon
                const Icon(Icons.code_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'GITHUB ACTIVITY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white54,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              )
            else ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white12,
                    backgroundImage: _stats?['avatar_url'] != null
                        ? NetworkImage(_stats!['avatar_url'])
                        : null,
                    child: _stats?['avatar_url'] == null
                        ? const Icon(Icons.person, color: Colors.white54, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stats?['login'] ?? widget.githubHandle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (_stats?['bio'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _stats!['bio'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Repositories',
                    value: '${_stats?['public_repos'] ?? 0}',
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  _StatItem(
                    label: 'Commits',
                    value: '${_stats?['commits'] ?? 0}',
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  _StatItem(
                    label: 'Pull Requests',
                    value: '${_stats?['prs'] ?? 0}',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
