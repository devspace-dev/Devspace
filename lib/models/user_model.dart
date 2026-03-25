import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

class UserModel {
  final String id;
  final String name;
  final String handle;
  final String email;
  final String avatar;
  final Color color;
  int aura;
  final String role;
  final String year;
  final String branch;
  final String building;
  final List<String> stack;
  int followers;
  int following;
  final String bio;
  final String college;
  final String githubHandle;
  final bool profileCompleted;
  bool isFollowing;

  UserModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.email,
    required this.avatar,
    required this.color,
    required this.aura,
    required this.role,
    required this.year,
    required this.branch,
    required this.building,
    required this.stack,
    required this.followers,
    required this.following,
    required this.bio,
    required this.college,
    required this.githubHandle,
    required this.profileCompleted,
    this.isFollowing = false,
  });

  bool get hasImageAvatar =>
      avatar.startsWith('http') || avatar.contains('/') || avatar.startsWith('data:');

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
    Color? color,
    int? aura,
    String? role,
    String? year,
    String? branch,
    String? building,
    List<String>? stack,
    int? followers,
    int? following,
    String? bio,
    String? college,
    String? githubHandle,
    bool? profileCompleted,
    bool? isFollowing,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      color: color ?? this.color,
      aura: aura ?? this.aura,
      role: role ?? this.role,
      year: year ?? this.year,
      branch: branch ?? this.branch,
      building: building ?? this.building,
      stack: stack ?? this.stack,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      bio: bio ?? this.bio,
      college: college ?? this.college,
      githubHandle: githubHandle ?? this.githubHandle,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': ObjectId.fromHexString(id),
        'name': name,
        'email': email,
        'handle': handle,
        'avatar': avatar,
        'color': color.toARGB32(),
        'aura': aura,
        'role': role,
        'year': year,
        'branch': branch,
        'building': building,
        'stack': stack,
        'followers': followers,
        'following': following,
        'bio': bio,
        'college': college,
        'githubHandle': githubHandle,
        'profileCompleted': profileCompleted,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawYear = json['year'] as String? ?? '';
    final rawBranch = json['branch'] as String? ?? '';
    final parsedAcademic = _parseAcademicInfo(rawYear, rawBranch);
    final building = json['building'] as String? ?? '';
    final stack = List<String>.from(json['stack'] as List? ?? []);
    final explicitCompleted = json['profileCompleted'] as bool?;
    final inferredCompleted = explicitCompleted ??
        (parsedAcademic.year.isNotEmpty &&
            parsedAcademic.branch.isNotEmpty &&
            building.isNotEmpty &&
            building != 'Not set' &&
            stack.isNotEmpty &&
            (json['role'] as String? ?? '').isNotEmpty &&
            (json['college'] as String? ?? '').isNotEmpty);

    return UserModel(
      id: (json['_id'] as ObjectId).oid,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      color: Color(json['color'] as int? ?? 0xFF7C3AED),
      aura: json['aura'] as int? ?? 0,
      role: json['role'] as String? ?? '',
      year: parsedAcademic.year,
      branch: parsedAcademic.branch,
      building: building,
      stack: stack,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      bio: json['bio'] as String? ?? '',
      college: json['college'] as String? ?? '',
      githubHandle: json['githubHandle'] as String? ?? '',
      profileCompleted: inferredCompleted,
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
