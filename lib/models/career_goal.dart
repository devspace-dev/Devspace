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

const List<CareerGoal> kCareerGoals = [
  CareerGoal(
    id: 'fullstack',
    title: 'Full Stack Engineer',
    description: 'Master both frontend and backend development to build complete web applications.',
    detailedDescription: 'As a Full Stack Engineer, you will tackle challenges that span the entire web stack. Your questions will focus on integrating responsive UIs with robust server-side logic, managing databases, and understanding end-to-end performance. You will be expected to build scalable features from the ground up, ensuring seamless user experiences and efficient data handling.',
    icon: Icons.layers_rounded,
    skillTags: ['React/Next.js', 'Node.js', 'PostgreSQL', 'System Design'],
  ),
  CareerGoal(
    id: 'backend',
    title: 'Backend Engineer',
    description: 'Design and build the scalable systems that power modern applications.',
    detailedDescription: 'Backend Engineer challenges will dive deep into server-side architecture, API design, and database optimization. You will receive questions about distributed systems, microservices, caching strategies, and concurrency. Your goal is to build high-performance systems that are reliable, secure, and capable of handling massive amounts of traffic and data.',
    icon: Icons.dns_rounded,
    skillTags: ['Go/Python', 'Redis', 'Docker', 'Microservices'],
  ),
  CareerGoal(
    id: 'frontend',
    title: 'Frontend Engineer',
    description: 'Create beautiful, interactive, and performant user interfaces.',
    detailedDescription: 'Frontend Engineer questions focus on building exceptional user experiences using modern web technologies. You will be challenged with complex UI components, state management patterns, and web performance optimization. Your tasks will involve creating accessible, responsive designs that feel smooth and engaging across all devices and screen sizes.',
    icon: Icons.web_rounded,
    skillTags: ['TypeScript', 'Tailwind CSS', 'State Management', 'Web Vitals'],
  ),
  CareerGoal(
    id: 'mobile',
    title: 'Mobile Developer',
    description: 'Build high-quality native and cross-platform mobile applications.',
    detailedDescription: 'Mobile Developer challenges center around building fluid and responsive apps for iOS and Android. You will receive questions on Flutter or Native development, local storage, push notifications, and mobile-specific performance tuning. Your goal is to master the nuances of mobile platforms and deliver apps that feel native and perform exceptionally well.',
    icon: Icons.smartphone_rounded,
    skillTags: ['Flutter', 'Swift/Kotlin', 'Firebase', 'Mobile UI'],
  ),
  CareerGoal(
    id: 'devops',
    title: 'DevOps/Cloud Engineer',
    description: 'Automate infrastructure and ensure reliable software delivery.',
    detailedDescription: 'As a DevOps or Cloud Engineer, your questions will focus on infrastructure as code, CI/CD pipelines, and cloud platform management. You will tackle challenges related to container orchestration, monitoring, and security in the cloud. Your objective is to build automated systems that enable fast, reliable, and secure software deployments at scale.',
    icon: Icons.cloud_done_rounded,
    skillTags: ['AWS/Azure', 'Kubernetes', 'Terraform', 'CI/CD'],
  ),
  CareerGoal(
    id: 'ml_engineer',
    title: 'Machine Learning Engineer',
    description: 'Build and deploy intelligent models to solve complex problems.',
    detailedDescription: 'ML Engineer challenges involve the entire machine learning lifecycle, from data preprocessing to model deployment. Your questions will focus on choosing the right algorithms, tuning hyperparameters, and scaling ML models in production. You will be expected to understand both the mathematical foundations and the engineering required to build production-grade AI systems.',
    icon: Icons.psychology_rounded,
    skillTags: ['PyTorch', 'Scikit-learn', 'MLOps', 'Data Science'],
  ),
  CareerGoal(
    id: 'data_engineer',
    title: 'Data Engineer',
    description: 'Build the data pipelines and infrastructure for large-scale analytics.',
    detailedDescription: 'Data Engineer questions focus on designing and maintaining complex data pipelines and data warehouses. You will be challenged with ETL processes, data modeling, and distributed data processing frameworks. Your goal is to ensure that data is clean, accessible, and ready for analysis, providing the foundation for data-driven decision making.',
    icon: Icons.storage_rounded,
    skillTags: ['Apache Spark', 'Airflow', 'BigQuery', 'Data Modeling'],
  ),
  CareerGoal(
    id: 'cybersecurity',
    title: 'Cybersecurity Engineer',
    description: 'Protect systems and data from evolving security threats.',
    detailedDescription: 'Cybersecurity Engineer challenges will dive into application security, network protection, and cryptography. Your questions will focus on identifying vulnerabilities, implementing secure coding practices, and responding to security incidents. You will be expected to stay ahead of the curve and build systems that are resilient against sophisticated cyber attacks.',
    icon: Icons.security_rounded,
    skillTags: ['Penetration Testing', 'SecOps', 'OAuth', 'Cryptography'],
  ),
  CareerGoal(
    id: 'comp_programmer',
    title: 'Competitive Programmer',
    description: 'Master algorithms and data structures to solve complex puzzles.',
    detailedDescription: 'Competitive Programmer challenges focus on algorithmic problem-solving and efficiency. You will receive questions on advanced data structures, dynamic programming, and graph theory. Your goal is to write optimal code that passes within strict time and memory limits, honing your ability to think logically and solve complex mathematical problems.',
    icon: Icons.emoji_events_rounded,
    skillTags: ['C++', 'Algorithms', 'Data Structures', 'Problem Solving'],
  ),
  CareerGoal(
    id: 'open_source',
    title: 'Open Source Contributor',
    description: 'Contribute to the global developer community through open source.',
    detailedDescription: 'Open Source Contributor challenges focus on collaboration, code review, and maintaining public projects. Your questions will involve understanding existing codebases, writing maintainable code, and interacting with community maintainers. You will be expected to follow best practices for contributing to diverse projects and building a strong developer identity in the open source world.',
    icon: Icons.group_work_rounded,
    skillTags: ['Git/GitHub', 'Documentation', 'Code Review', 'Community'],
  ),
];
