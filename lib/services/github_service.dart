import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubRepo {
  final String name;
  final String description;
  final String language;
  final int stars;
  final String url;
  final DateTime updatedAt;

  const GitHubRepo({
    required this.name,
    required this.description,
    required this.language,
    required this.stars,
    required this.url,
    required this.updatedAt,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> j) => GitHubRepo(
        name:        j['name'] ?? '',
        description: j['description'] ?? '',
        language:    j['language'] ?? 'Unknown',
        stars:       j['stargazers_count'] ?? 0,
        url:         j['html_url'] ?? '',
        updatedAt:   DateTime.tryParse(j['updated_at'] ?? '') ?? DateTime.now(),
      );
}

class GitHubCommit {
  final String message;
  final String repo;
  final DateTime date;
  final String url;

  const GitHubCommit({
    required this.message,
    required this.repo,
    required this.date,
    required this.url,
  });
}

class GitHubService {
  GitHubService._();
  static final instance = GitHubService._();

  static const _base = 'https://api.github.com';
  // Optionally add a personal access token for higher rate limits:
  // static const _token = 'ghp_YOUR_TOKEN_HERE';

  Map<String, String> get _headers => {
        'Accept': 'application/vnd.github+json',
        // if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  // ── Fetch top 6 public repos ─────────────────────
  Future<List<GitHubRepo>> getRepos(String username) async {
    if (username.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$_base/users/$username/repos?sort=updated&per_page=6'),
        headers: _headers,
      );
      if (res.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .where((r) => r['fork'] == false) // exclude forks
          .map((r) => GitHubRepo.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Fetch recent commit events ───────────────────
  Future<List<GitHubCommit>> getRecentCommits(String username) async {
    if (username.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$_base/users/$username/events/public?per_page=30'),
        headers: _headers,
      );
      if (res.statusCode != 200) return [];
      final List<dynamic> events = jsonDecode(res.body);

      final commits = <GitHubCommit>[];
      for (final e in events) {
        if (e['type'] != 'PushEvent') continue;
        final repo    = e['repo']?['name'] ?? '';
        final payload = e['payload'] as Map<String, dynamic>? ?? {};
        final date    = DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now();

        for (final c in (payload['commits'] as List? ?? [])) {
          commits.add(GitHubCommit(
            message: (c['message'] as String? ?? '').split('\n').first,
            repo:    repo,
            date:    date,
            url:     'https://github.com/$repo',
          ));
          if (commits.length >= 5) break; // show only 5 latest commits
        }
        if (commits.length >= 5) break;
      }
      return commits;
    } catch (_) {
      return [];
    }
  }

  // ── Fetch user stats ─────────────────────────────
  Future<Map<String, dynamic>?> getUserStats(String username) async {
    if (username.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$_base/users/$username'),
        headers: _headers,
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Fetch Total Pull Requests ───────────────────
  Future<int> getTotalPRs(String username) async {
    if (username.isEmpty) return 0;
    try {
      final res = await http.get(
        Uri.parse('$_base/search/issues?q=author:$username+type:pr'),
        headers: _headers,
      );
      if (res.statusCode != 200) return 0;
      final data = jsonDecode(res.body);
      return data['total_count'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Fetch Total Commits (estimated) ─────────────
  Future<int> getTotalCommits(String username) async {
    if (username.isEmpty) return 0;
    try {
      final res = await http.get(
        Uri.parse('$_base/search/commits?q=author:$username'),
        headers: _headers,
      );
      if (res.statusCode != 200) return 0;
      final data = jsonDecode(res.body);
      return data['total_count'] ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
