import 'package:flutter/material.dart';

class CareerGoal {
  final String id;
  final String title;
  final String description;
  final String detailedDescription;
  final IconData icon;
  final List<String> skillTags;

  const CareerGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.detailedDescription,
    required this.icon,
    required this.skillTags,
  });
}

final List<CareerGoal> kCareerGoals = [
  CareerGoal(
    id: 'full_stack',
    title: 'Full Stack Engineer',
    description: 'Build complete products end-to-end.',
    detailedDescription:
        'Master both frontend (React, Flutter) and backend (Node.js, Django, REST APIs). '
        'Questions cover system design, databases, and end-to-end feature building. '
        'Ideal if you want to ship entire products independently.',
    icon: Icons.layers_rounded,
    skillTags: ['React', 'Node.js', 'SQL', 'REST APIs', 'System Design'],
  ),
  CareerGoal(
    id: 'backend',
    title: 'Backend Engineer',
    description: 'Power the systems behind great apps.',
    detailedDescription:
        'Deep focus on APIs, microservices, databases (SQL/NoSQL), caching, message queues, '
        'and distributed systems. You\'ll tackle concurrency, scalability, and reliability '
        'challenges faced by top product companies.',
    icon: Icons.storage_rounded,
    skillTags: ['APIs', 'Microservices', 'Kafka', 'Redis', 'PostgreSQL'],
  ),
  CareerGoal(
    id: 'frontend',
    title: 'Frontend Engineer',
    description: 'Craft beautiful, blazing-fast UIs.',
    detailedDescription:
        'UI/UX implementation, performance optimization, accessibility, component architecture, '
        'and modern frameworks (React, Vue, Flutter Web). Questions include rendering pipelines, '
        'state management, and web vitals.',
    icon: Icons.web_rounded,
    skillTags: ['React', 'CSS', 'Accessibility', 'Performance', 'Web Vitals'],
  ),
  CareerGoal(
    id: 'mobile',
    title: 'Mobile Developer',
    description: 'Ship polished apps on Android & iOS.',
    detailedDescription:
        'Flutter/Android/iOS development, app architecture (BLoC, Provider, MVVM), '
        'device APIs, animations, and app store publishing. Covers platform-specific '
        'optimization and cross-platform best practices.',
    icon: Icons.phone_android_rounded,
    skillTags: ['Flutter', 'Android', 'iOS', 'BLoC', 'Firebase'],
  ),
  CareerGoal(
    id: 'devops',
    title: 'DevOps / Cloud Engineer',
    description: 'Build and run infra at scale.',
    detailedDescription:
        'CI/CD pipelines, Docker, Kubernetes, AWS/GCP/Azure, infrastructure-as-code (Terraform), '
        'and monitoring/alerting. Questions cover deployment strategies, SRE principles, '
        'and cost optimization.',
    icon: Icons.cloud_rounded,
    skillTags: ['Kubernetes', 'Docker', 'AWS', 'Terraform', 'CI/CD'],
  ),
  CareerGoal(
    id: 'ml_engineer',
    title: 'Machine Learning Engineer',
    description: 'Build and deploy intelligent systems.',
    detailedDescription:
        'ML fundamentals, model training, evaluation, and deployment (MLOps). '
        'Questions cover feature engineering, neural networks, transformers, and working '
        'with TensorFlow, PyTorch, and scikit-learn in production environments.',
    icon: Icons.psychology_rounded,
    skillTags: ['PyTorch', 'MLOps', 'Python', 'Statistics', 'LLMs'],
  ),
  CareerGoal(
    id: 'data_engineer',
    title: 'Data Engineer',
    description: 'Design pipelines that power decisions.',
    detailedDescription:
        'ETL pipelines, Apache Spark, Kafka, data warehousing (BigQuery, Snowflake), '
        'and SQL optimization. Questions focus on data modeling, pipeline reliability, '
        'and large-scale batch/streaming processing.',
    icon: Icons.bar_chart_rounded,
    skillTags: ['Spark', 'Kafka', 'BigQuery', 'SQL', 'Airflow'],
  ),
  CareerGoal(
    id: 'cybersecurity',
    title: 'Cybersecurity Engineer',
    description: 'Protect systems from real-world threats.',
    detailedDescription:
        'Secure coding practices, OWASP Top 10, authentication systems, encryption, '
        'and vulnerability assessment. Questions cover penetration testing basics, '
        'threat modeling, and building secure APIs.',
    icon: Icons.security_rounded,
    skillTags: ['OWASP', 'Encryption', 'Auth', 'Pen Testing', 'Firewalls'],
  ),
  CareerGoal(
    id: 'competitive_programming',
    title: 'Competitive Programmer',
    description: 'Dominate DSA and coding contests.',
    detailedDescription:
        'Mastery of data structures and algorithms — arrays, trees, graphs, dynamic programming, '
        'and sorting. Focused on LeetCode/Codeforces-style problems with analysis of '
        'optimal time and space complexity.',
    icon: Icons.code_rounded,
    skillTags: ['DSA', 'DP', 'Graphs', 'Binary Search', 'C++'],
  ),
  CareerGoal(
    id: 'open_source',
    title: 'Open Source Contributor',
    description: 'Write code that ships to millions.',
    detailedDescription:
        'Reading and writing production-quality code, understanding large codebases, '
        'Git workflows, PR reviews, and documentation. Questions focus on code quality, '
        'API design, and collaborative engineering practices.',
    icon: Icons.diversity_3_rounded,
    skillTags: ['Git', 'Code Review', 'Documentation', 'Testing', 'APIs'],
  ),
];
