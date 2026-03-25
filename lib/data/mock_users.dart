import 'package:flutter/material.dart';
import '../models/user_model.dart';

final UserModel kMe = UserModel(
  id: 0, name: 'You', handle: 'you', avatar: 'YO',
  color: const Color(0xFF7C3AED), aura: 1240,
  role: 'Full Stack Dev', year: '2nd Year · CSE',
  building: 'DevSpace Platform',
  stack: ['React', 'Node.js', 'MongoDB'],
  followers: 38, following: 61,
  bio: 'Building cool stuff in public 🚀',
  college: 'MNIT Jaipur',
);

final List<UserModel> kUsers = [
  UserModel(
    id: 1, name: 'Aryan Mehta', handle: 'aryan_dev', avatar: 'AM',
    color: const Color(0xFF7C3AED), aura: 2840,
    role: 'Full Stack Developer', year: '3rd Year · CSE',
    building: 'AI-powered study planner',
    stack: ['React', 'Node.js', 'MongoDB'],
    followers: 142, following: 89,
    bio: 'Code. Ship. Repeat 🔁',
    college: 'MNIT Jaipur',
  ),
  UserModel(
    id: 2, name: 'Priya Sharma', handle: 'priya.ml', avatar: 'PS',
    color: const Color(0xFFDB2777), aura: 4210,
    role: 'ML Engineer', year: '4th Year · AIDS',
    building: 'Facial recognition attendance',
    stack: ['Python', 'TensorFlow', 'Flask'],
    followers: 310, following: 67,
    bio: 'Training models & minds 🧠',
    college: 'MNIT Jaipur',
  ),
  UserModel(
    id: 3, name: 'Rohan Verma', handle: 'rohan_v', avatar: 'RV',
    color: const Color(0xFF059669), aura: 980,
    role: 'App Developer', year: '2nd Year · IT',
    building: 'Campus food delivery app',
    stack: ['Flutter', 'Firebase', 'Dart'],
    followers: 54, following: 102,
    bio: 'Flutter everything 📱',
    college: 'MNIT Jaipur',
  ),
  UserModel(
    id: 4, name: 'Sneha Kulkarni', handle: 'sneha.ui', avatar: 'SK',
    color: const Color(0xFFD97706), aura: 1750,
    role: 'Frontend Developer', year: '3rd Year · CSE',
    building: 'College design system',
    stack: ['Vue.js', 'Figma', 'Tailwind'],
    followers: 198, following: 143,
    bio: 'Pixels perfectionist ✨',
    college: 'MNIT Jaipur',
  ),
  UserModel(
    id: 5, name: 'Dev Patel', handle: 'devpatel', avatar: 'DP',
    color: const Color(0xFF0891B2), aura: 3100,
    role: 'Backend Engineer', year: '4th Year · IT',
    building: 'Microservices auth system',
    stack: ['Go', 'Docker', 'Redis'],
    followers: 220, following: 55,
    bio: 'Go routines go brrr 🐹',
    college: 'MNIT Jaipur',
  ),
];

List<UserModel> get allUsers => [kMe, ...kUsers];
