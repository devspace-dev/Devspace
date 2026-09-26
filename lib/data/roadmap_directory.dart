import 'package:flutter/material.dart';

/// A link into a roadmap.sh roadmap. DevSpace does not host or reproduce
/// roadmap.sh's content (their license only permits linking to it) — this
/// is purely a searchable directory of links, opened in-app via
/// `url_launcher`'s `LaunchMode.inAppWebView`.
class RoadmapEntry {
  final String title;
  final String slug;
  final String category;
  final IconData icon;
  final Color color;

  const RoadmapEntry({
    required this.title,
    required this.slug,
    required this.category,
    required this.icon,
    required this.color,
  });

  String get url => 'https://roadmap.sh/$slug';
}

class RoadmapCategory {
  static const roleBased = 'Role-Based';
  static const skillBased = 'Skill-Based';
  static const beginners = 'Absolute Beginners';
  static const bestPractices = 'Best Practices';

  static const all = [roleBased, skillBased, beginners, bestPractices];
}

const _categoryDefaultColor = {
  RoadmapCategory.roleBased: Color(0xFFFF7A00),
  RoadmapCategory.skillBased: Color(0xFF3B82F6),
  RoadmapCategory.beginners: Color(0xFF32D74B),
  RoadmapCategory.bestPractices: Color(0xFF8B5CF6),
};

const _categoryDefaultIcon = {
  RoadmapCategory.roleBased: Icons.work_outline_rounded,
  RoadmapCategory.skillBased: Icons.bolt_rounded,
  RoadmapCategory.beginners: Icons.eco_rounded,
  RoadmapCategory.bestPractices: Icons.verified_outlined,
};

/// Keyword -> (icon, color) for techs/roles with a well-known identity.
/// Anything not matched falls back to the category default.
const Map<String, (IconData, Color)> _knownIcons = {
  'frontend': (Icons.web_asset_outlined, Color(0xFF38BDF8)),
  'backend': (Icons.dns_outlined, Color(0xFF22C55E)),
  'full-stack': (Icons.layers_outlined, Color(0xFFFF7A00)),
  'android': (Icons.android_rounded, Color(0xFF3DDC84)),
  'ios': (Icons.phone_iphone_rounded, Color(0xFF9CA3AF)),
  'devops': (Icons.hub_outlined, Color(0xFF0EA5E9)),
  'react': (Icons.flare_rounded, Color(0xFF61DAFB)),
  'vue': (Icons.change_history_rounded, Color(0xFF42B883)),
  'angular': (Icons.change_history_rounded, Color(0xFFDD0031)),
  'javascript': (Icons.javascript_rounded, Color(0xFFF7DF1E)),
  'typescript': (Icons.code_rounded, Color(0xFF3178C6)),
  'nodejs': (Icons.hexagon_outlined, Color(0xFF539E43)),
  'python': (Icons.data_object_rounded, Color(0xFF3776AB)),
  'java': (Icons.coffee_rounded, Color(0xFFEA2D2E)),
  'flutter': (Icons.flutter_dash_rounded, Color(0xFF02569B)),
  'react-native': (Icons.smartphone_rounded, Color(0xFF61DAFB)),
  'golang': (Icons.pets_rounded, Color(0xFF00ADD8)),
  'rust': (Icons.settings_rounded, Color(0xFFDE7B36)),
  'docker': (Icons.inventory_2_outlined, Color(0xFF2496ED)),
  'kubernetes': (Icons.blur_circular_rounded, Color(0xFF326CE5)),
  'aws': (Icons.cloud_outlined, Color(0xFFFF9900)),
  'sql': (Icons.table_chart_outlined, Color(0xFF4479A1)),
  'system-design': (Icons.account_tree_outlined, Color(0xFF8B5CF6)),
  'api-design': (Icons.api_rounded, Color(0xFF10B981)),
  'linux': (Icons.terminal_rounded, Color(0xFFFCC624)),
  'git-github': (Icons.merge_type_rounded, Color(0xFFF05032)),
  'mongodb': (Icons.storage_rounded, Color(0xFF47A248)),
  'cyber-security': (Icons.shield_outlined, Color(0xFFEF4444)),
  'machine-learning': (Icons.psychology_outlined, Color(0xFFEC4899)),
  'ai-engineer': (Icons.smart_toy_outlined, Color(0xFFEC4899)),
  'data-analyst': (Icons.query_stats_rounded, Color(0xFFF59E0B)),
  'ux-design': (Icons.brush_outlined, Color(0xFFF43F5E)),
  'html': (Icons.html_rounded, Color(0xFFE34F26)),
  'css': (Icons.css_rounded, Color(0xFF1572B6)),
  'php': (Icons.code_rounded, Color(0xFF777BB4)),
  'kotlin': (Icons.code_rounded, Color(0xFF7F52FF)),
  'swift-ui': (Icons.phone_iphone_rounded, Color(0xFFFA7343)),
  'nextjs': (Icons.arrow_forward_rounded, Color(0xFF9CA3AF)),
  'spring-boot': (Icons.eco_rounded, Color(0xFF6DB33F)),
  'django': (Icons.web_rounded, Color(0xFF0C4B33)),
  'terraform': (Icons.layers_outlined, Color(0xFF7B42BC)),
  'redis': (Icons.memory_rounded, Color(0xFFDC382D)),
  'graphql': (Icons.hub_outlined, Color(0xFFE10098)),
  'blockchain': (Icons.link_rounded, Color(0xFFF59E0B)),
  'game-developer': (Icons.sports_esports_outlined, Color(0xFF8B5CF6)),
  'qa': (Icons.fact_check_outlined, Color(0xFF22C55E)),
  'product-manager': (Icons.dashboard_customize_outlined, Color(0xFFFF7A00)),
  'datastructures-and-algorithms': (Icons.account_tree_outlined, Color(0xFF3B82F6)),
};

(IconData, Color) _resolveIcon(String slug, String category) {
  for (final entry in _knownIcons.entries) {
    if (slug == entry.key || slug.startsWith('${entry.key}-')) {
      return entry.value;
    }
  }
  return (
    _categoryDefaultIcon[category]!,
    _categoryDefaultColor[category]!,
  );
}

RoadmapEntry _entry(String title, String slug, String category) {
  final (icon, color) = _resolveIcon(slug, category);
  return RoadmapEntry(
    title: title,
    slug: slug,
    category: category,
    icon: icon,
    color: color,
  );
}

/// All roadmap.sh roadmaps, fetched from roadmap.sh/roadmaps.
final List<RoadmapEntry> kRoadmapDirectory = [
  // Role-Based
  _entry('Frontend', 'frontend', RoadmapCategory.roleBased),
  _entry('Backend', 'backend', RoadmapCategory.roleBased),
  _entry('Full Stack', 'full-stack', RoadmapCategory.roleBased),
  _entry('Android', 'android', RoadmapCategory.roleBased),
  _entry('DevOps', 'devops', RoadmapCategory.roleBased),
  _entry('DevSecOps', 'devsecops', RoadmapCategory.roleBased),
  _entry('Data Analyst', 'data-analyst', RoadmapCategory.roleBased),
  _entry('SEO', 'seo', RoadmapCategory.roleBased),
  _entry('AI Engineer', 'ai-engineer', RoadmapCategory.roleBased),
  _entry('AI and Data Scientist', 'ai-data-scientist', RoadmapCategory.roleBased),
  _entry('Data Engineer', 'data-engineer', RoadmapCategory.roleBased),
  _entry('Machine Learning', 'machine-learning', RoadmapCategory.roleBased),
  _entry('PostgreSQL', 'postgresql-dba', RoadmapCategory.roleBased),
  _entry('iOS', 'ios', RoadmapCategory.roleBased),
  _entry('Blockchain', 'blockchain', RoadmapCategory.roleBased),
  _entry('QA', 'qa', RoadmapCategory.roleBased),
  _entry('Software Architect', 'software-architect', RoadmapCategory.roleBased),
  _entry('API Design', 'api-design', RoadmapCategory.roleBased),
  _entry('Cyber Security', 'cyber-security', RoadmapCategory.roleBased),
  _entry('UX Design', 'ux-design', RoadmapCategory.roleBased),
  _entry('Technical Writer', 'technical-writer', RoadmapCategory.roleBased),
  _entry('Game Developer', 'game-developer', RoadmapCategory.roleBased),
  _entry('Server Side Game Developer', 'server-side-game-developer', RoadmapCategory.roleBased),
  _entry('MLOps', 'mlops', RoadmapCategory.roleBased),
  _entry('Product Manager', 'product-manager', RoadmapCategory.roleBased),
  _entry('Engineering Manager', 'engineering-manager', RoadmapCategory.roleBased),
  _entry('Developer Relations', 'devrel', RoadmapCategory.roleBased),
  _entry('BI Analyst', 'bi-analyst', RoadmapCategory.roleBased),
  _entry('AI Red Teaming', 'ai-red-teaming', RoadmapCategory.roleBased),
  _entry('Network Engineer', 'network-engineer', RoadmapCategory.roleBased),
  _entry('Forward Deployed Engineer', 'forward-deployed-engineer', RoadmapCategory.roleBased),

  // Skill-Based
  _entry('Claude Code', 'claude-code', RoadmapCategory.skillBased),
  _entry('Python for Data Analysis', 'python-data-analysis', RoadmapCategory.skillBased),
  _entry('R Programming', 'r-programming', RoadmapCategory.skillBased),
  _entry('Vibe Coding', 'vibe-coding', RoadmapCategory.skillBased),
  _entry('Power BI', 'power-bi', RoadmapCategory.skillBased),
  _entry('LeetCode', 'leetcode', RoadmapCategory.skillBased),
  _entry('Python', 'python', RoadmapCategory.skillBased),
  _entry('Computer Science', 'computer-science', RoadmapCategory.skillBased),
  _entry('SQL', 'sql', RoadmapCategory.skillBased),
  _entry('React', 'react', RoadmapCategory.skillBased),
  _entry('Vue', 'vue', RoadmapCategory.skillBased),
  _entry('Angular', 'angular', RoadmapCategory.skillBased),
  _entry('JavaScript', 'javascript', RoadmapCategory.skillBased),
  _entry('TypeScript', 'typescript', RoadmapCategory.skillBased),
  _entry('Node.js', 'nodejs', RoadmapCategory.skillBased),
  _entry('System Design', 'system-design', RoadmapCategory.skillBased),
  _entry('Java', 'java', RoadmapCategory.skillBased),
  _entry('ASP.NET Core', 'aspnet-core', RoadmapCategory.skillBased),
  _entry('Spring Boot', 'spring-boot', RoadmapCategory.skillBased),
  _entry('Flutter', 'flutter', RoadmapCategory.skillBased),
  _entry('C Programming', 'c', RoadmapCategory.skillBased),
  _entry('C++', 'cpp', RoadmapCategory.skillBased),
  _entry('Rust', 'rust', RoadmapCategory.skillBased),
  _entry('Go', 'golang', RoadmapCategory.skillBased),
  _entry('AI Product Builders', 'ai-product-builder', RoadmapCategory.skillBased),
  _entry('Design Architecture', 'software-design-architecture', RoadmapCategory.skillBased),
  _entry('React Native', 'react-native', RoadmapCategory.skillBased),
  _entry('Design System', 'design-system', RoadmapCategory.skillBased),
  _entry('Prompt Engineering', 'prompt-engineering', RoadmapCategory.skillBased),
  _entry('MongoDB', 'mongodb', RoadmapCategory.skillBased),
  _entry('Linux', 'linux', RoadmapCategory.skillBased),
  _entry('Kubernetes', 'kubernetes', RoadmapCategory.skillBased),
  _entry('Docker', 'docker', RoadmapCategory.skillBased),
  _entry('AWS', 'aws', RoadmapCategory.skillBased),
  _entry('Terraform', 'terraform', RoadmapCategory.skillBased),
  _entry('Data Structures & Algorithms', 'datastructures-and-algorithms', RoadmapCategory.skillBased),
  _entry('Redis', 'redis', RoadmapCategory.skillBased),
  _entry('Git and GitHub', 'git-github', RoadmapCategory.skillBased),
  _entry('PHP', 'php', RoadmapCategory.skillBased),
  _entry('Cloudflare', 'cloudflare', RoadmapCategory.skillBased),
  _entry('AI Agents', 'ai-agents', RoadmapCategory.skillBased),
  _entry('Next.js', 'nextjs', RoadmapCategory.skillBased),
  _entry('Kotlin', 'kotlin', RoadmapCategory.skillBased),
  _entry('HTML', 'html', RoadmapCategory.skillBased),
  _entry('CSS', 'css', RoadmapCategory.skillBased),
  _entry('Swift & SwiftUI', 'swift-ui', RoadmapCategory.skillBased),
  _entry('Shell / Bash', 'shell-bash', RoadmapCategory.skillBased),
  _entry('Laravel', 'laravel', RoadmapCategory.skillBased),
  _entry('Elasticsearch', 'elasticsearch', RoadmapCategory.skillBased),
  _entry('WordPress', 'wordpress', RoadmapCategory.skillBased),
  _entry('Django', 'django', RoadmapCategory.skillBased),
  _entry('Ruby', 'ruby', RoadmapCategory.skillBased),
  _entry('Ruby on Rails', 'ruby-on-rails', RoadmapCategory.skillBased),
  _entry('Scala', 'scala', RoadmapCategory.skillBased),

  // Absolute Beginners
  _entry('Frontend Beginner', 'frontend-beginner', RoadmapCategory.beginners),
  _entry('Backend Beginner', 'backend-beginner', RoadmapCategory.beginners),
  _entry('DevOps Beginner', 'devops-beginner', RoadmapCategory.beginners),
  _entry('Git and GitHub Beginner', 'git-github-beginner', RoadmapCategory.beginners),

  // Best Practices
  _entry('AWS Best Practices', 'aws-best-practices', RoadmapCategory.bestPractices),
  _entry('API Security Best Practices', 'api-security-best-practices', RoadmapCategory.bestPractices),
  _entry('Backend Performance Best Practices', 'backend-performance-best-practices', RoadmapCategory.bestPractices),
  _entry('Frontend Performance Best Practices', 'frontend-performance-best-practices', RoadmapCategory.bestPractices),
  _entry('Code Review Best Practices', 'code-review-best-practices', RoadmapCategory.bestPractices),
];
