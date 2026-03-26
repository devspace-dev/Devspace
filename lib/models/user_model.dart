import 'package:flutter/material.dart';


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
  final String building;
  final List<String> stack;
  int followers;
  int following;
  final String bio;
  final String college;
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
    required this.building,
    required this.stack,
    required this.followers,
    required this.following,
    required this.bio,
    required this.college,
    this.isFollowing = false,
  });

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
    String? building,
    List<String>? stack,
    int? followers,
    int? following,
    String? bio,
    String? college,
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
      building: building ?? this.building,
      stack: stack ?? this.stack,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      bio: bio ?? this.bio,
      college: college ?? this.college,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'handle': handle,
        'avatar': avatar,
        'color': color.value,
        'aura': aura,
        'role': role,
        'year': year,
        'building': building,
        'stack': stack,
        'followers': followers,
        'following': following,
        'bio': bio,
        'college': college,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '0',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      color: Color(json['color'] as int? ?? 0xFF7C3AED),
      aura: json['aura'] as int? ?? 0,
      role: json['role'] as String? ?? '',
      year: json['year'] as String? ?? '',
      building: json['building'] as String? ?? '',
      stack: List<String>.from(json['stack'] as List? ?? []),
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      bio: json['bio'] as String? ?? '',
      college: json['college'] as String? ?? '',
    );
  }
}
