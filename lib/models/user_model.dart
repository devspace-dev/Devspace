import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String name;
  final String handle;
  final String email;
  final String avatar;
  final String coverUrl;
  final Color color;
  int aura;
  final List<String> roles; // Changed from String role
  final String year;
  final String branch;
  final String building;
  final List<String> stack;
  int followers;
  int following;
  final int currentStreak;
  final String bio;
  final String college;
  final String githubHandle;
  final bool profileCompleted;
  final bool isAdmin;
  final String fcmToken;
  bool isFollowing;

  UserModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.email,
    required this.avatar,
    this.coverUrl = '',
    required this.color,
    required this.aura,
    required this.roles,
    required this.year,
    required this.branch,
    required this.building,
    required this.stack,
    required this.followers,
    required this.following,
    this.currentStreak = 0,
    required this.bio,
    required this.college,
    required this.githubHandle,
    required this.profileCompleted,
    this.isAdmin = false,
    this.fcmToken = '',
    this.isFollowing = false,
  });

  bool get isImageAvatar =>
      avatar.startsWith('http') || avatar.contains('/') || avatar.startsWith('data:');

  bool get isFounder => email.toLowerCase() == 'businessrexxon@gmail.com';

  String get role => roles.isNotEmpty ? roles.join(' · ') : '';

  String get academicLabel {
    if (year.isEmpty) return branch;
    if (branch.isEmpty) return year;
    return '$year · $branch';
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? handle,
    String? email,
    String? avatar,
    String? coverUrl,
    Color? color,
    int? aura,
    List<String>? roles,
    String? year,
    String? branch,
    String? building,
    List<String>? stack,
    int? followers,
    int? following,
    int? currentStreak,
    String? bio,
    String? college,
    String? githubHandle,
    bool? profileCompleted,
    bool? isAdmin,
    String? fcmToken,
    bool? isFollowing,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      coverUrl: coverUrl ?? this.coverUrl,
      color: color ?? this.color,
      aura: aura ?? this.aura,
      roles: roles ?? this.roles,
      year: year ?? this.year,
      branch: branch ?? this.branch,
      building: building ?? this.building,
      stack: stack ?? this.stack,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      currentStreak: currentStreak ?? this.currentStreak,
      bio: bio ?? this.bio,
      college: college ?? this.college,
      githubHandle: githubHandle ?? this.githubHandle,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isAdmin: isAdmin ?? this.isAdmin,
      fcmToken: fcmToken ?? this.fcmToken,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'handle': handle,
        'avatar': avatar,
        'cover_url': coverUrl,
        'color': color.toARGB32(),
        'aura': aura,
        'role': roles, // Storing as list
        'year': year,
        'branch': branch,
        'building': building,
        'stack': stack,
        'followers': followers,
        'following': following,
        'current_streak': currentStreak,
        'bio': bio,
        'college': college,
        'github_handle': githubHandle,
        'profile_completed': profileCompleted,
        'is_admin': isAdmin,
        'fcm_token': fcmToken,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawYear = json['year']?.toString() ?? '';
    final rawBranch = json['branch']?.toString() ?? '';
    final parsedAcademic = _parseAcademicInfo(rawYear, rawBranch);
    final building = json['building']?.toString() ?? '';
    final roleData = json['role'];
    List<String> roles = [];
    if (roleData is List) {
      roles = roleData.where((e) => e != null).map((e) => e.toString()).toList();
    } else if (roleData is String && roleData.isNotEmpty) {
      roles = [roleData];
    }

    final stackData = json['stack'];
    List<String> stack = [];
    if (stackData is List) {
      stack = stackData.where((e) => e != null).map((e) => e.toString()).toList();
    }

    final profileCompletedRaw = json['profile_completed'] ?? json['profileCompleted'];
    final explicitCompleted = profileCompletedRaw is bool ? profileCompletedRaw : null;
    
    final inferredCompleted = explicitCompleted ??
        (parsedAcademic.year.isNotEmpty &&
            parsedAcademic.branch.isNotEmpty &&
            building.isNotEmpty &&
            building != 'Not set' &&
            stack.isNotEmpty &&
            roles.isNotEmpty &&
            (json['college']?.toString() ?? '').isNotEmpty);

    return UserModel(
      id: (json['id'] ?? '0').toString(),
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      handle: json['handle']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      coverUrl: (json['cover_url'] ?? json['coverUrl'] ?? '').toString(),
      color: Color((json['color'] as num? ?? 0xFF7C3AED).toInt()),
      aura: (json['aura'] as num? ?? 0).toInt(),
      roles: roles,
      year: parsedAcademic.year,
      branch: parsedAcademic.branch,
      building: building,
      stack: stack,
      followers: (json['followers'] as num? ?? 0).toInt(),
      following: (json['following'] as num? ?? 0).toInt(),
      currentStreak:
          ((json['current_streak'] ?? json['currentStreak']) as num? ?? 0)
              .toInt(),
      bio: json['bio']?.toString() ?? '',
      college: json['college']?.toString() ?? '',
      githubHandle:
          (json['github_handle'] ?? json['githubHandle'] ?? '').toString(),
      profileCompleted: inferredCompleted,
      isAdmin: (json['is_admin'] ?? json['isAdmin']) == true,
      fcmToken: (json['fcm_token'] ?? json['fcmToken'] ?? '').toString(),
    );
  }

  static ({String year, String branch}) _parseAcademicInfo(
    String rawYear,
    String rawBranch,
  ) {
    if (rawBranch.isNotEmpty) {
      return (year: rawYear, branch: rawBranch);
    }

    if (rawYear.contains('·')) {
      final parts = rawYear.split('·').map((part) => part.trim()).toList();
      final year = parts.isNotEmpty ? parts.first : '';
      final branch = parts.length > 1 ? parts.sublist(1).join(' · ') : '';
      return (year: year, branch: branch);
    }

    return (year: rawYear, branch: rawBranch);
  }
}
