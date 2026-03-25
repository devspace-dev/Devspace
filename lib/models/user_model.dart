import 'package:flutter/material.dart';

class UserModel {
  final int id;
  final String name;
  final String handle;
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
    int? aura,
    int? followers,
    int? following,
    bool? isFollowing,
  }) {
    return UserModel(
      id: id, name: name, handle: handle, avatar: avatar, color: color,
      aura: aura ?? this.aura, role: role, year: year,
      building: building, stack: stack,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      bio: bio, college: college,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
