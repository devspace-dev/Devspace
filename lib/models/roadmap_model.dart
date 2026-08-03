import 'package:flutter/material.dart';

class DeveloperResource {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final String readTime;
  final String quickTip;
  final List<ResourceSection> sections;
  final List<ResourceLink> externalLinks;

  const DeveloperResource({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.readTime,
    required this.quickTip,
    required this.sections,
    required this.externalLinks,
  });
}

class ResourceSection {
  final String title;
  final String summary;
  final List<ResourceItem> items;

  const ResourceSection({
    required this.title,
    required this.summary,
    required this.items,
  });
}

class ResourceItem {
  final String name;
  final String description;
  final String? codeSnippet;
  final String? tip;

  const ResourceItem({
    required this.name,
    required this.description,
    this.codeSnippet,
    this.tip,
  });
}

class ResourceLink {
  final String title;
  final String url;
  final IconData icon;

  const ResourceLink({
    required this.title,
    required this.url,
    required this.icon,
  });
}

// Backwards compatibility alias for LearningRoadmap
typedef LearningRoadmap = DeveloperResource;

const List<DeveloperResource> kDeveloperResources = [
  DeveloperResource(
    id: 'dsa_patterns',
    title: 'Top DSA Patterns & Sheet',
    subtitle: 'Must-know patterns for coding rounds',
    description:
      'Master the core patterns used in 80%+ of college placement coding rounds and technical interviews.',
    icon: Icons.code_rounded,
    color: Colors.blue,
    category: 'Placement & Coding',
    readTime: '6 min read',
    quickTip:
      'Stop solving 500+ random problems! Master these 7 patterns first to identify problem types instantly.',
    sections: [
      ResourceSection(
        title: 'Core Interview Patterns',
        summary: 'Recognize the pattern before writing code.',
        items: [
          ResourceItem(
            name: '1. Two Pointers',
            description:
              'Use when dealing with sorted arrays or strings. Compare items from left and right boundaries inward.',
            codeSnippet: '''// Two Pointer Technique (Python)
def two_sum_sorted(arr, target):
    left, right = 0, len(arr) - 1
    while left < right:
        curr = arr[left] + arr[right]
        if curr == target: return [left, right]
        elif curr < target: left += 1
        else: right -= 1
    return []''',
            tip: 'Best for: Two Sum II, Valid Palindrome, Container With Most Water.',
          ),
          ResourceItem(
            name: '2. Sliding Window',
            description:
              'Maintain a dynamic range (window) over an array/string to track contiguous sub-elements without re-scanning.',
            codeSnippet: '''// Sliding Window (Variable Length)
left = max_len = 0
seen = set()
for right in range(len(s)):
    while s[right] in seen:
        seen.remove(s[left])
        left += 1
    seen.add(s[right])
    max_len = max(max_len, right - left + 1)''',
            tip: 'Best for: Longest Substring Without Repeating Chars, Min Window Substring.',
          ),
          ResourceItem(
            name: '3. Fast & Slow Pointers (Floyd Cycle)',
            description:
              'Use two pointers moving at different speeds (1 step vs 2 steps) to detect loops in linked lists or arrays.',
            tip: 'Best for: Linked List Cycle Detection, Happy Number, Middle of Linked List.',
          ),
          ResourceItem(
            name: '4. Graph Traversal (BFS vs DFS)',
            description:
              'BFS uses a Queue for shortest path in unweighted graphs. DFS uses Stack/Recursion for exhaustive search and component exploration.',
            tip: 'Best for: Number of Islands, Word Ladder, Clone Graph.',
          ),
        ],
      ),
      ResourceSection(
        title: 'Top 10 Must-Solve Questions',
        summary: 'Essential problems every CS student should complete before interviews.',
        items: [
          ResourceItem(
            name: 'Array & Strings',
            description: '1. Two Sum (Easy)\n2. Best Time to Buy & Sell Stock (Easy)\n3. Product of Array Except Self (Medium)',
          ),
          ResourceItem(
            name: 'Strings & Trees',
            description: '4. Valid Anagram (Easy)\n5. Valid Parentheses (Easy)\n6. Binary Tree Level Order Traversal (Medium)',
          ),
          ResourceItem(
            name: 'Dynamic Programming & Graphs',
            description: '7. Climbing Stairs (Easy)\n8. Number of Islands (Medium)\n9. Coin Change (Medium)\n10. Longest Consecutive Sequence (Medium)',
          ),
        ],
      ),
    ],
    externalLinks: [
      ResourceLink(
        title: 'NeetCode 150 Practice Roadmap',
        url: 'https://neetcode.io/roadmap',
        icon: Icons.link_rounded,
      ),
      ResourceLink(
        title: 'Striver\'s SDE Sheet',
        url: 'https://takeuforward.org/strivers-sde-sheet-top-coding-interview-problems',
        icon: Icons.explore_rounded,
      ),
    ],
  ),
  DeveloperResource(
    id: 'git_fullstack_playbook',
    title: 'Full-Stack & Git Playbook',
    subtitle: 'Clean code & project workflow',
    description:
      'Practical standards for Git branching, clean project architecture, security, and project demo deployment.',
    icon: Icons.rocket_launch_rounded,
    color: Colors.purple,
    category: 'Project Building',
    readTime: '5 min read',
    quickTip:
      'Always keep API keys in .env files and never push credentials or build folders to GitHub!',
    sections: [
      ResourceSection(
        title: 'Professional Git Commit Standards',
        summary: 'Write readable commit messages that look great on your profile.',
        items: [
          ResourceItem(
            name: 'Conventional Commits Format',
            description:
              'Use semantic prefixes so team members and recruiters instantly understand what changed.',
            codeSnippet: '''# Conventional Commit Examples
git commit -m "feat: add Google OAuth login flow"
git commit -m "fix: resolve feed pagination null pointer exception"
git commit -m "docs: update API setup instructions in README"
git commit -m "refactor: simplify aura calculation service"''',
          ),
          ResourceItem(
            name: 'Essential .gitignore Checklist',
            description: 'Always ignore environment variables, dependencies, and OS files.',
            codeSnippet: '''# Essential .gitignore for Web / Mobile
.env
.env.local
node_modules/
build/
.dart_tool/
.DS_Store
*.log''',
          ),
        ],
      ),
      ResourceSection(
        title: 'Project Security & Launch Checklist',
        summary: 'Items to verify before sharing your live project link.',
        items: [
          ResourceItem(
            name: '1. Environment Variables',
            description: 'Store database credentials, Firebase/Supabase secret keys, and API tokens in .env. Use client-safe public keys for frontend.',
          ),
          ResourceItem(
            name: '2. Live Hosted Demo Link',
            description: 'Deploy frontend to Vercel/Netlify and backend to Render/Railway. Add the live URL directly in the GitHub repo "About" description.',
          ),
          ResourceItem(
            name: '3. Responsive Mobile Check',
            description: 'Test layout on mobile width (375px) before recording project demo videos or showcasing to evaluators.',
          ),
        ],
      ),
    ],
    externalLinks: [
      ResourceLink(
        title: 'Conventional Commits Specification',
        url: 'https://www.conventionalcommits.org',
        icon: Icons.commit_rounded,
      ),
      ResourceLink(
        title: 'Roadmap.sh Web Developer',
        url: 'https://roadmap.sh/full-stack',
        icon: Icons.map_rounded,
      ),
    ],
  ),
  DeveloperResource(
    id: 'system_design_basics',
    title: 'System Design Fundamentals',
    subtitle: 'Architecture, DB & Scaling',
    description:
      'Learn how web and mobile applications scale from 100 users to 100,000 users without crashing.',
    icon: Icons.alt_route_rounded,
    color: Colors.green,
    category: 'Web & Infrastructure',
    readTime: '7 min read',
    quickTip:
      'In system design interviews, start from high-level components (Client -> Server -> DB) before diving into specific tools!',
    sections: [
      ResourceSection(
        title: 'Core System Components',
        summary: 'The building blocks of modern scalable web applications.',
        items: [
          ResourceItem(
            name: 'Client-Server & API Gateway',
            description:
              'Clients send HTTP requests. An API Gateway handles routing, authentication checks, and rate-limiting before hitting microservices.',
          ),
          ResourceItem(
            name: 'Database Selection: SQL vs NoSQL',
            description:
              'Use SQL (PostgreSQL, MySQL) for structured data, ACID transactions, and relations. Use NoSQL (MongoDB, Redis) for unstructured data, high write speed, or key-value caching.',
          ),
          ResourceItem(
            name: 'Caching Layer (Redis)',
            description:
              'Store frequently read data (like user session, trending feed, leaderboard) in RAM to avoid expensive SQL database reads.',
            codeSnippet: '''// Redis Caching Pattern (Cache-Aside)
async function getUserProfile(userId) {
  const cached = await redis.get(`user:\${userId}`);
  if (cached) return JSON.parse(cached);
  
  const user = await db.users.findUnique({ where: { id: userId } });
  await redis.setex(`user:\${userId}`, 300, JSON.stringify(user));
  return user;
}''',
          ),
        ],
      ),
      ResourceSection(
        title: 'HTTP Status Codes Quick Reference',
        summary: 'Standard response codes for clean REST API design.',
        items: [
          ResourceItem(
            name: '200 OK / 201 Created',
            description: 'Request succeeded or new resource was successfully created.',
          ),
          ResourceItem(
            name: '400 Bad Request / 401 Unauthorized',
            description: '400: Invalid payload/missing parameters. 401: Authentication missing or expired token.',
          ),
          ResourceItem(
            name: '403 Forbidden / 404 Not Found',
            description: '403: Authenticated but insufficient permission. 404: Resource does not exist.',
          ),
          ResourceItem(
            name: '500 Internal Server Error / 502 Bad Gateway',
            description: 'Unhandled server exception or downstream microservice failure.',
          ),
        ],
      ),
    ],
    externalLinks: [
      ResourceLink(
        title: 'System Design Primer (GitHub)',
        url: 'https://github.com/donnemartin/system-design-primer',
        icon: Icons.storage_rounded,
      ),
      ResourceLink(
        title: 'ByteByteGo System Design Basics',
        url: 'https://bytebytego.com',
        icon: Icons.terminal_rounded,
      ),
    ],
  ),
  DeveloperResource(
    id: 'resume_github_prep',
    title: 'GitHub & Resume Guide',
    subtitle: 'Stand out to tech recruiters',
    description:
      'Transform your student profile, project READMEs, and LinkedIn outreach into a referral magnet.',
    icon: Icons.badge_rounded,
    color: Colors.orange,
    category: 'Career & Identity',
    readTime: '4 min read',
    quickTip:
      'When listing projects on your resume, use the formula: Built [X] using [Y] which resulted in [Z].',
    sections: [
      ResourceSection(
        title: 'GitHub Profile Optimization',
        summary: 'Make your GitHub look like an active builder portfolio.',
        items: [
          ResourceItem(
            name: '1. Pin Top 3 Projects',
            description:
              'Pin repos that have a complete README, live demo link, and clear tech tags rather than incomplete test repos.',
          ),
          ResourceItem(
            name: '2. Professional Repo README',
            description:
              'Every featured repo should include: Project Banner/Screenshot, Tech Stack badges, Key Features bullet points, and Local Setup instructions.',
          ),
        ],
      ),
      ResourceSection(
        title: 'LinkedIn Referral Outreach Template',
        summary: 'Concise message template for reaching out to alumni or engineers for referrals.',
        items: [
          ResourceItem(
            name: 'Referral Request Template',
            description: 'Keep outreach under 4 sentences. Be direct, polite, and attach your resume link.',
            codeSnippet: '''Hi [Name],

I saw you're working as [Role] at [Company]. I'm a [Year] CS student at [College], actively preparing for [Role] roles.

I built [Project Name] (live demo: [Link]) using [Tech Stack] and would love to learn about your experience at [Company].

If open positions match my background, would you be willing to refer me? Resume: [Link]. Thanks!''',
          ),
        ],
      ),
    ],
    externalLinks: [
      ResourceLink(
        title: 'GitHub Profile README Generator',
        url: 'https://rahuldkjain.github.io/gh-profile-readme-generator/',
        icon: Icons.create_rounded,
      ),
      ResourceLink(
        title: 'Shields.io Tech Badges',
        url: 'https://shields.io',
        icon: Icons.shield_rounded,
      ),
    ],
  ),
];

// Alias export for existing list reference
const List<DeveloperResource> kLearningRoadmaps = kDeveloperResources;
