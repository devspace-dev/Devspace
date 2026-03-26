import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

/// SQL Schema for Supabase (Run this in Supabase SQL Editor):
/// 
/// create table users (
///   id uuid references auth.users not null primary key,
///   name text,
///   email text unique,
///   handle text unique,
///   avatar text,
///   color bigint,
///   aura bigint default 0,
///   role text,
///   year text,
///   building text,
///   stack text[],
///   followers bigint default 0,
///   following bigint default 0,
///   bio text,
///   college text,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table posts (
///   id uuid default gen_random_uuid() primary key,
///   user_id uuid references users(id) on delete cascade,
///   content text,
///   tags text[],
///   image_url text,
///   likes_count bigint default 0,
///   comments_count bigint default 0,
///   reposts_count bigint default 0,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
/// 
/// create table follows (
///   id uuid default gen_random_uuid() primary key,
///   follower_id uuid references users(id) on delete cascade,
///   following_id uuid references users(id) on delete cascade,
///   created_at timestamp with time zone default timezone('utc'::text, now()),
///   unique(follower_id, following_id)
/// );
/// 
/// create table likes (
///   id uuid default gen_random_uuid() primary key,
///   post_id uuid references posts(id) on delete cascade,
///   user_id uuid references users(id) on delete cascade,
///   created_at timestamp with time zone default timezone('utc'::text, now()),
///   unique(post_id, user_id)
/// );
/// 
/// create table notifications (
///   id uuid default gen_random_uuid() primary key,
///   to_uid uuid references users(id) on delete cascade,
///   from_uid uuid references users(id) on delete cascade,
///   type text,
///   post_id uuid references posts(id) on delete set null,
///   message text,
///   read boolean default false,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> init() async {
    // Handled in main.dart initialization
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<UserModel?> getUserByEmail(String email) async {
    final data = await _client
        .from('users')
        .select()
        .eq('email', email.toLowerCase())
        .maybeSingle();
    return data == null ? null : UserModel.fromJson(data);
  }

  Future<UserModel?> getUserByHandle(String handle) async {
    final data = await _client
        .from('users')
        .select()
        .eq('handle', handle.toLowerCase())
        .maybeSingle();
    return data == null ? null : UserModel.fromJson(data);
  }

  Future<UserModel?> getUserById(String id) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : UserModel.fromJson(data);
  }

  Future<void> createUser({
    required String id,
    required String name,
    required String email,
    required String handle,
    String avatar = '',
    String college = '',
  }) async {
    await _client.from('users').insert({
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'handle': handle,
      'avatar': avatar,
      'color': 0xFF7C3AED,
      'aura': 0,
      'role': 'Developer',
      'year': '1st Year',
      'building': 'Not set',
      'stack': [],
      'followers': 0,
      'following': 0,
      'bio': '',
      'college': college,
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', uid);
  }

  Stream<List<UserModel>> streamUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('aura', ascending: false)
        .map((list) => list.map((d) => UserModel.fromJson(d)).toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOCIAL
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> follow(String fromUid, String toUid) async {
    await _client.from('follows').insert({
      'follower_id': fromUid,
      'following_id': toUid,
    });
    // Triggers or RPC should be used to increment counts for better consistency
  }

  Future<void> unfollow(String fromUid, String toUid) async {
    await _client.from('follows').delete()
      .eq('follower_id', fromUid)
      .eq('following_id', toUid);
  }

  Future<bool> isFollowing(String fromUid, String toUid) async {
    final data = await _client
        .from('follows')
        .select()
        .eq('follower_id', fromUid)
        .eq('following_id', toUid)
        .maybeSingle();
    return data != null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // POSTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<String> createPost({
    required String userId,
    required String content,
    required List<String> tags,
    String? imageUrl,
  }) async {
    final data = await _client.from('posts').insert({
      'user_id': userId,
      'content': content,
      'tags': tags,
      'image_url': imageUrl ?? '',
    }).select().single();
    return data['id'].toString();
  }

  Stream<List<PostModel>> streamFeed() {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((list) => list.map((d) => PostModel.fromJson(d)).toList());
  }

  Stream<List<PostModel>> streamUserPosts(String userId) {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((list) => list.map((d) => PostModel.fromJson(d)).toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIKES & COMMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> likePost(String postId, String uid) async {
    await _client.from('likes').insert({
      'post_id': postId,
      'user_id': uid,
    });
  }

  Future<void> unlikePost(String postId, String uid) async {
    await _client.from('likes').delete().eq('post_id', postId).eq('user_id', uid);
  }

  Future<bool> hasLiked(String postId, String uid) async {
    final data = await _client
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    return data != null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> pushNotification({
    required String toUid,
    required String fromUid,
    required String type,
    String? postId,
    String? message,
  }) async {
    await _client.from('notifications').insert({
      'to_uid': toUid,
      'from_uid': fromUid,
      'type': type,
      'post_id': postId,
      'message': message ?? '',
    });
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String uid) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('to_uid', uid)
        .order('created_at', ascending: false)
        .limit(30);
  }
  // ══════════════════════════════════════════════════════════════════════════
  // COMMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<CommentModel>> getCommentsForPost(String postId) async {
    final data = await _client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return (data as List).map((d) => CommentModel.fromJson(d)).toList();
  }

  Future<void> addComment(String postId, String userId, String content) async {
    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }
}
