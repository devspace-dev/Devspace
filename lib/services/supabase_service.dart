import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/question_model.dart';
import '../models/question_reply_model.dart';
import '../models/question_pull_request_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/aura_ledger_model.dart';
import 'github_service.dart';


/// SQL Schema for Supabase (Run this in Supabase SQL Editor):
///
/// create table users (
///   id uuid references auth.users not null primary key,
///   name text,
///   email text unique,
///   handle text unique,
///   avatar text,
///   color bigint default 0,
///   aura bigint default 0,
///   aura_points bigint default 0,
///   role text default 'Student',
///   year text default '',
///   branch text default '',
///   building text default '',
///   stack text[] default '{}'::text[],
///   followers bigint default 0,
///   following bigint default 0,
///   bio text default '',
///   college text default '',
///   github_handle text default '',
///   profile_completed boolean default false,
///   is_admin boolean default false,
///   current_streak integer default 0,
///   longest_streak integer default 0,
///   last_challenge_completed_on date,
///   created_at timestamp with time zone default timezone('utc'::text, now()),
///   updated_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table posts (
///   id uuid default gen_random_uuid() primary key,
///   user_id uuid references users(id) on delete cascade,
///   content text default '',
///   tags text[] default '{}'::text[],
///   image_url text default '',
///   quote_post_id uuid references posts(id) on delete set null,
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
/// create table bookmarks (
///   id uuid default gen_random_uuid() primary key,
///   post_id uuid references posts(id) on delete cascade,
///   user_id uuid references users(id) on delete cascade,
///   created_at timestamp with time zone default timezone('utc'::text, now()),
///   unique(post_id, user_id)
/// );
///
/// create table comments (
///   id uuid default gen_random_uuid() primary key,
///   post_id uuid references posts(id) on delete cascade,
///   user_id uuid references users(id) on delete cascade,
///   content text not null default '',
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table questions (
///   id uuid default gen_random_uuid() primary key,
///   user_id uuid references users(id) on delete cascade,
///   title text not null default '',
///   body text not null default '',
///   tags text[] default '{}'::text[],
///   upvotes_count bigint default 0,
///   replies_count bigint default 0,
///   solved_reply_id uuid,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table question_replies (
///   id uuid default gen_random_uuid() primary key,
///   question_id uuid references questions(id) on delete cascade,
///   user_id uuid references users(id) on delete cascade,
///   content text not null default '',
///   parent_reply_id uuid references question_replies(id) on delete cascade,
///   replying_to_user_id uuid references users(id) on delete set null,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table question_votes (
///   id uuid default gen_random_uuid() primary key,
///   question_id uuid references questions(id) on delete cascade,
///   user_id uuid references users(id) on delete cascade,
///   created_at timestamp with time zone default timezone('utc'::text, now()),
///   unique(question_id, user_id)
/// );
///
/// create table notifications (
///   id uuid default gen_random_uuid() primary key,
///   to_uid uuid references users(id) on delete cascade,
///   from_uid uuid references users(id) on delete cascade,
///   type text default '',
///   post_id uuid references posts(id) on delete set null,
///   message text default '',
///   read boolean default false,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table conversations (
///   id uuid default gen_random_uuid() primary key,
///   participants uuid[] not null,
///   last_message text,
///   last_message_at timestamp with time zone default timezone('utc'::text, now()),
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table messages (
///   id uuid default gen_random_uuid() primary key,
///   conversation_id uuid references conversations(id) on delete cascade,
///   sender_id uuid references users(id) on delete cascade,
///   recipient_id uuid references users(id) on delete cascade,
///   content text not null,
///   is_read boolean default false,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table challenges (
///   id uuid default gen_random_uuid() primary key,
///   title text not null,
///   description text not null default '',
///   difficulty text not null default 'easy',
///   tech_stack text not null default 'General',
///   points_reward integer not null default 20,
///   publish_date date not null default (timezone('utc'::text, now())::date),
///   is_active boolean not null default true,
///   created_by uuid references users(id) on delete set null,
///   created_at timestamp with time zone default timezone('utc'::text, now()),
///   updated_at timestamp with time zone default timezone('utc'::text, now()),
///   constraint challenges_difficulty_check check (difficulty in ('easy', 'medium', 'hard'))
/// );
///
/// create table user_challenges (
///   id uuid default gen_random_uuid() primary key,
///   user_id uuid references users(id) on delete cascade not null,
///   challenge_id uuid references challenges(id) on delete cascade not null,
///   assigned_date date not null default timezone('utc'::text, now())::date,
///   selected_tech_stack text not null default 'General',
///   submission_text text default '',
///   submission_link text default '',
///   completed boolean not null default false,
///   completed_at timestamp with time zone,
///   created_at timestamp with time zone default timezone('utc'::text, now()),
///   updated_at timestamp with time zone default timezone('utc'::text, now()),
///   unique (user_id, assigned_date)
/// );

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  SupabaseClient get _client => Supabase.instance.client;

  String cleanErrorText(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();

      if (error.code == 'PGRST205' ||
          message.contains('could not find the table')) {
        return 'Supabase schema is missing the Q&A pull request table. Run the latest schema SQL, then retry.';
      }

      if (error.code == '42883' && message.contains('can_user_reply')) {
        return 'Supabase schema is missing the Q&A reply permission function. Run the latest schema SQL, then retry.';
      }

      if (error.code == '42501') {
        return 'Supabase access policy blocked this Q&A action. Re-run the latest schema SQL so the policies match the app.';
      }
    }

    final message = error.toString().trim();
    const badStatePrefix = 'Bad state: ';
    if (message.startsWith(badStatePrefix)) {
      return message.substring(badStatePrefix.length).trim();
    }
    return message;
  }

  String? _normalizeOptionalId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _normalizeOptionalUuid(String? value) {
    final normalized = _normalizeOptionalId(value);
    if (normalized == null) {
      return null;
    }
    if (!_uuidPattern.hasMatch(normalized)) {
      throw StateError('Quoted post reference is invalid. Please reopen the post and try again.');
    }
    return normalized;
  }

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
    final data =
        await _client.from('users').select().eq('id', id).maybeSingle();
    return data == null ? null : UserModel.fromJson(data);
  }

  Future<void> createUser({
    required String id,
    required String name,
    required String email,
    required String handle,
    String avatar = '',
    String coverUrl = '',
    List<String> roles = const ['Student'],
    String year = '',
    String branch = '',
    String building = '',
    List<String> stack = const [],
    String bio = '',
    String college = '',
    String githubHandle = '',
    bool profileCompleted = false,
  }) async {
    // 1. Insert core fields first (These MUST exist)
    await _client.from('users').upsert({
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'handle': handle,
      'avatar': avatar,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Attempt to update extended fields (In case they are missing in the current schema)
    try {
      await _client.from('users').update({
        'cover_url': coverUrl,
        'color': 0xFF7C3AED,
        'aura': 0,
        'role': roles,
        'year': year,
        'branch': branch,
        'building': building,
        'stack': stack,
        'followers': 0,
        'following': 0,
        'bio': bio,
        'college': college,
        'github_handle': githubHandle,
        'profile_completed': profileCompleted,
      }).eq('id', id);
    } catch (e) {
      // If some columns are missing, we still want the user to be able to log in.
      debugPrint('Extended user fields update failed (likely missing columns): $e');
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', uid);
  }

  /// Resets every user's aura to 0 for a fresh monthly leaderboard season
  Future<void> resetAllUsersMonthlyAura() async {
    try {
      await _client
          .from('users')
          .update({'aura': 0})
          .neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      debugPrint('Error executing resetAllUsersMonthlyAura: $e');
      rethrow;
    }
  }

  /// Returns users ranked by weekly aura points (earned in the last 7 days)
  Future<List<UserModel>> getWeeklyAuraLeaderboard({String? college}) async {
    try {
      final response = await _client.rpc(
        'get_aura_leaderboard',
        params: {
          'p_timeframe': 'weekly',
          'p_college': college,
          'p_limit': 100,
        },
      );
      if (response != null) {
        return (response as List).map((d) => UserModel.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('RPC get_aura_leaderboard failed for weekly, running fallback: $e');
    }

    try {
      final since = DateTime.now().subtract(const Duration(days: 7));
      final totals = await getAuraTotalsSince(since);
      var users = await getUsers(limit: 200);
      if (college != null && college.isNotEmpty) {
        users = users.where((u) => u.college == college).toList();
      }
      if (totals.isEmpty) return [];

      final activeUsers = users.where((u) => (totals[u.id] ?? 0) > 0).toList();
      activeUsers.sort((a, b) {
        final scoreA = totals[a.id] ?? 0;
        final scoreB = totals[b.id] ?? 0;
        return scoreB.compareTo(scoreA);
      });
      return activeUsers.map((u) => u.copyWith(aura: totals[u.id] ?? 0)).toList();
    } catch (e) {
      debugPrint('Error fetching weekly aura leaderboard fallback: $e');
      return [];
    }
  }

  /// Returns users ranked by monthly aura points (earned in current calendar month)
  Future<List<UserModel>> getMonthlyAuraLeaderboard({String? college}) async {
    try {
      final response = await _client.rpc(
        'get_aura_leaderboard',
        params: {
          'p_timeframe': 'monthly',
          'p_college': college,
          'p_limit': 100,
        },
      );
      if (response != null) {
        return (response as List).map((d) => UserModel.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('RPC get_aura_leaderboard failed for monthly, running fallback: $e');
    }

    try {
      final now = DateTime.now();
      final since = DateTime(now.year, now.month, 1);
      final totals = await getAuraTotalsSince(since);
      var users = await getUsers(limit: 200);
      if (college != null && college.isNotEmpty) {
        users = users.where((u) => u.college == college).toList();
      }
      if (totals.isEmpty) return [];

      final activeUsers = users.where((u) => (totals[u.id] ?? 0) > 0).toList();
      activeUsers.sort((a, b) {
        final scoreA = totals[a.id] ?? 0;
        final scoreB = totals[b.id] ?? 0;
        return scoreB.compareTo(scoreA);
      });
      return activeUsers.map((u) => u.copyWith(aura: totals[u.id] ?? 0)).toList();
    } catch (e) {
      debugPrint('Error fetching monthly aura leaderboard fallback: $e');
      return [];
    }
  }

  /// Returns users ranked by All-Time Aura
  Future<List<UserModel>> getAllTimeAuraLeaderboard({String? college}) async {
    try {
      final response = await _client.rpc(
        'get_aura_leaderboard',
        params: {
          'p_timeframe': 'all_time',
          'p_college': college,
          'p_limit': 100,
        },
      );
      if (response != null) {
        return (response as List).map((d) => UserModel.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('RPC get_aura_leaderboard failed for all_time, running fallback: $e');
    }

    var users = await getUsers(limit: 100);
    if (college != null && college.isNotEmpty) {
      users = users.where((u) => u.college == college).toList();
    }
    users.sort((a, b) => b.aura.compareTo(a.aura));
    return users;
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _client.from('users').update({'fcm_token': token}).eq('id', uid);
  }

  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Call the RPC to delete from public.users and potentially trigger auth deletion
    // Or just delete from public.users and let the user know they are unsubscribed
    await _client.from('users').delete().eq('id', user.id);
    await _client.auth.signOut();
  }

  Future<List<UserModel>> getUsers({
    int limit = 20,
    int offset = 0,
    String? query,
  }) async {
    var request = _client.from('users').select();

    if (query != null && query.isNotEmpty) {
      request = request.or('name.ilike.%$query%,handle.ilike.%$query%,branch.ilike.%$query%,building.ilike.%$query%');
    }

    final from = offset;
    final to = offset + limit - 1;
    final data = await request.order('aura', ascending: false).range(from, to);

    return (data as List).map((d) => UserModel.fromJson(d)).toList();
  }

  Future<Set<String>> getFollowingIds(String userId) async {
    final data = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return (data as List).map((row) => row['following_id'].toString()).toSet();
  }

  Future<List<String>> getFollowerIds(String userId) async {
    final data = await _client
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((row) => row['follower_id'].toString()).toList();
  }

  Future<Set<String>> getLikedStatusForPosts(String userId, List<String> postIds) async {
    if (postIds.isEmpty) return {};
    final data = await _client
        .from('likes')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    return (data as List).map((row) => row['post_id'].toString()).toSet();
  }

  Future<Set<String>> getBookmarkedStatusForPosts(String userId, List<String> postIds) async {
    if (postIds.isEmpty) return {};
    final data = await _client
        .from('bookmarks')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    return (data as List).map((row) => row['post_id'].toString()).toSet();
  }

  Future<List<String>> getFollowingIdList(String userId) async {
    final data = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((row) => row['following_id'].toString()).toList();
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    final distinctIds = userIds.toSet().toList();
    if (distinctIds.isEmpty) return const [];

    final data =
        await _client.from('users').select().inFilter('id', distinctIds);

    final usersById = {
      for (final row in data as List)
        row['id'].toString(): UserModel.fromJson(row as Map<String, dynamic>),
    };

    return userIds.map((id) => usersById[id]).whereType<UserModel>().toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOCIAL
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> follow(String fromUid, String toUid) async {
    await _client.from('follows').insert({
      'follower_id': fromUid,
      'following_id': toUid,
    });
  }

  Future<void> unfollow(String fromUid, String toUid) async {
    await _client
        .from('follows')
        .delete()
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
    String? documentUrl,
    String? documentName,
    String? quotePostId,
  }) async {
    final normalizedQuotePostId = _normalizeOptionalUuid(quotePostId);
    final params = <String, dynamic>{
      'p_content': content,
      'p_tags': tags,
      'p_image_url': imageUrl ?? '',
      'p_document_url': documentUrl ?? '',
      'p_document_name': documentName ?? '',
    };
    if (normalizedQuotePostId != null) {
      params['p_quote_post_id'] = normalizedQuotePostId;
    }

    try {
      final data = await _client.rpc(
        'create_post_with_aura',
        params: params,
      );
      return data.toString();
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST202') {
        // Fallback for older schema without document support
        final fallbackParams = <String, dynamic>{
          'p_content': content,
          'p_tags': tags,
          'p_image_url': imageUrl ?? '',
        };
        if (normalizedQuotePostId != null) {
          fallbackParams['p_quote_post_id'] = normalizedQuotePostId;
        }

        final data = await _client.rpc(
          'create_post_with_aura',
          params: fallbackParams,
        );
        return data.toString();
      }
      rethrow;
    }
  }

  Future<void> updatePostImage(String postId, String imageUrl) async {
    await _client
        .from('posts')
        .update({'image_url': imageUrl}).eq('id', postId);
  }

  Future<List<PostModel>> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final from = offset;
    final to = offset + limit - 1;
    final data = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);
    return (data as List).map((d) => PostModel.fromJson(d)).toList();
  }

  Future<List<PostModel>> getUserPosts(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final from = offset;
    final to = offset + limit - 1;
    final data = await _client
        .from('posts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);
    return (data as List).map((d) => PostModel.fromJson(d)).toList();
  }

  Future<PostModel?> getPostById(String postId) async {
    final data =
        await _client.from('posts').select().eq('id', postId).maybeSingle();
    return data == null ? null : PostModel.fromJson(data);
  }

  Future<void> updatePost(String postId, String content) async {
    await _client.from('posts').update({
      'content': content,
    }).eq('id', postId);
  }

  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIKES & COMMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> likePost(String postId, String uid) async {
    await _client.rpc(
      'like_post_with_aura',
      params: {
        'p_post_id': postId,
      },
    );
  }

  Future<void> unlikePost(String postId, String uid) async {
    await _client.rpc(
      'unlike_post',
      params: {
        'p_post_id': postId,
      },
    );
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

  Future<Set<String>> getLikedPostIds(String userId) async {
    final data =
        await _client.from('likes').select('post_id').eq('user_id', userId);
    return (data as List).map((row) => row['post_id'].toString()).toSet();
  }

  Future<void> bookmarkPost(String postId, String userId) async {
    await _client.from('bookmarks').upsert(
      {
        'post_id': postId,
        'user_id': userId,
      },
      onConflict: 'post_id,user_id',
    );
  }

  Future<void> removeBookmark(String postId, String userId) async {
    await _client
        .from('bookmarks')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  Future<Set<String>> getBookmarkedPostIds(String userId) async {
    final data =
        await _client.from('bookmarks').select('post_id').eq('user_id', userId);
    return (data as List).map((row) => row['post_id'].toString()).toSet();
  }

  Future<List<PostModel>> getBookmarkedPosts(String userId) async {
    final bookmarkRows = await _client
        .from('bookmarks')
        .select('post_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final postIds = (bookmarkRows as List)
        .map((row) => row['post_id'].toString())
        .where((id) => id.isNotEmpty)
        .toList();
    if (postIds.isEmpty) return const [];

    final postRows =
        await _client.from('posts').select().inFilter('id', postIds);

    final postsById = {
      for (final row in postRows as List)
        row['id'].toString(): PostModel.fromJson(row as Map<String, dynamic>),
    };

    return postIds
        .map((postId) => postsById[postId])
        .whereType<PostModel>()
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUESTIONS & REPLIES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<QuestionModel>> getQuestions({
    String filter = 'latest',
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client.from('questions').select();
    
    switch (filter) {
      case 'oldest':
        query = query.order('created_at', ascending: true);
        break;
      case 'popularity':
        query = query
            .order('upvotes_count', ascending: false)
            .order('created_at', ascending: false);
        break;
      case 'most replies':
        query = query
            .order('replies_count', ascending: false)
            .order('created_at', ascending: false);
        break;
      case 'relevance':
        query = query
            .order('upvotes_count', ascending: false)
            .order('replies_count', ascending: false)
            .order('created_at', ascending: false);
        break;
      case 'latest':
      default:
        query = query.order('created_at', ascending: false);
        break;
    }

    final from = offset;
    final to = offset + limit - 1;
    final data = await query.range(from, to);

    return (data as List)
        .map((d) => QuestionModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<QuestionModel?> getQuestionById(String questionId) async {
    final data = await _client
        .from('questions')
        .select()
        .eq('id', questionId)
        .maybeSingle();
    return data == null ? null : QuestionModel.fromJson(data);
  }

  Future<String> createQuestion({
    required String userId,
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final data = await _client
        .from('questions')
        .insert({
          'user_id': userId,
          'title': title,
          'body': body,
          'tags': tags,
          'upvotes_count': 0,
          'replies_count': 0,
        })
        .select()
        .single();

    return data['id'].toString();
  }

  Future<List<QuestionReplyModel>> getRepliesForQuestion(
      String questionId) async {
    final data = await _client
        .from('question_replies')
        .select()
        .eq('question_id', questionId)
        .order('created_at', ascending: true);
    return (data as List).map((d) => QuestionReplyModel.fromJson(d)).toList();
  }

  Future<String> addQuestionReply({
    required String questionId,
    required String userId,
    required String content,
    String? parentReplyId,
    String? replyingToUserId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw StateError('Reply cannot be empty.');
    }

    // Check if user can reply
    try {
      final canReply = await _client.rpc('can_user_reply', params: {
        'p_question_id': questionId,
        'p_user_id': userId,
      });

      if (canReply == false) {
        throw StateError('Your request to answer this question has not been accepted yet.');
      }
    } catch (e) {
      if (e is StateError) rethrow;
      debugPrint('can_user_reply RPC check bypassed or not configured: $e');
    }

    String? normalizedParentReplyId;
    if (parentReplyId != null && parentReplyId.trim().isNotEmpty) {
      final parentReply = await _client
          .from('question_replies')
          .select('id, question_id, parent_reply_id')
          .eq('id', parentReplyId)
          .maybeSingle();

      if (parentReply == null) {
        throw StateError('The reply you are responding to no longer exists.');
      }
      if (parentReply['question_id'].toString() != questionId) {
        throw StateError('This reply does not belong to the current question.');
      }

      final existingParentReplyId =
          (parentReply['parent_reply_id'] ?? '').toString().trim();
      if (existingParentReplyId.isNotEmpty) {
        throw StateError('Only one reply level is supported in this thread.');
      }

      normalizedParentReplyId = parentReply['id'].toString();
    }

    final data = await _client.from('question_replies').insert({
      'question_id': questionId,
      'user_id': userId,
      'content': trimmed,
      'parent_reply_id': normalizedParentReplyId,
      'replying_to_user_id': replyingToUserId,
    }).select('id').single();

    return data['id'].toString();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PULL REQUESTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> submitPullRequest({
    required String questionId,
    required String userId,
    required String message,
  }) async {
    // 1. Submit the PR
    await _client.from('question_pull_requests').upsert(
      {
        'question_id': questionId,
        'user_id': userId,
        'message': message,
        'status': 'pending',
      },
      onConflict: 'question_id,user_id',
    );

    // 2. Notify the question owner
    try {
      final question = await getQuestionById(questionId);
      if (question != null && question.userId != userId) {
        await pushNotification(
          toUid: question.userId,
          fromUid: userId,
          type: 'pr_request',
          questionId: questionId,
          message: 'offered to help with your question: "${question.title}"',
        );
      }
    } catch (e) {
      debugPrint('Failed to send PR notification: $e');
    }
  }

  Future<List<QuestionPullRequestModel>> getPullRequestsForQuestion(
      String questionId) async {
    final data = await _client
        .from('question_pull_requests')
        .select()
        .eq('question_id', questionId)
        .order('created_at', ascending: true);
    return (data as List)
        .map((d) => QuestionPullRequestModel.fromJson(d))
        .toList();
  }

  Future<void> updatePullRequestStatus({
    required String prId,
    required String status,
  }) async {
    await _client
        .from('question_pull_requests')
        .update({'status': status}).eq('id', prId);
  }

  Future<void> acceptPullRequestAsSolution({
    required String questionId,
    required String prId,
  }) async {
    // 1. Get PR info
    final pr = await _client.from('question_pull_requests').select().eq('id', prId).single();
    final prUserId = pr['user_id'].toString();
    final prMessage = pr['message'].toString();

    // 2. Accept the PR
    await _client.from('question_pull_requests').update({'status': 'accepted'}).eq('id', prId);

    // 3. Check if user already has access (just in case, but rpc usually handles it)
    // We'll skip it and just use the insert directly if rpc blocks it.
    
    // 4. Create a reply with the PR message
    // Note: We use the question owner's ID (the current user) to insert the reply
    // to avoid RLS errors, and attribute it to the PR author in the content.
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final prUser = await _client.from('users').select('handle').eq('id', prUserId).maybeSingle();
    final prUserHandle = prUser != null ? prUser['handle'] : 'a builder';

    final replyId = await _client.from('question_replies').insert({
      'question_id': questionId,
      'user_id': currentUser.id,
      'content': 'Accepted PR Solution from @$prUserHandle:\n\n$prMessage',
    }).select('id').single();

    // 5. Mark as solved
    await markSolvedReply(questionId: questionId, replyId: replyId['id'].toString());

    // 6. Notify the PR owner
    try {
      final question = await getQuestionById(questionId);
      if (question != null) {
        await pushNotification(
          toUid: prUserId,
          fromUid: question.userId,
          type: 'pr_accepted',
          questionId: questionId,
          message: 'Your solution for "${question.title}" was accepted!',
        );
      }
    } catch (e) {
      debugPrint('Failed to send PR acceptance notification: $e');
    }
  }

  Future<QuestionPullRequestModel?> getPullRequestStatus(
      String questionId, String userId) async {
    final data = await _client
        .from('question_pull_requests')
        .select()
        .eq('question_id', questionId)
        .eq('user_id', userId)
        .maybeSingle();
    return data == null ? null : QuestionPullRequestModel.fromJson(data);
  }

  Future<void> upvoteQuestion(String questionId, String userId) async {
    await _client.from('question_votes').insert({
      'question_id': questionId,
      'user_id': userId,
    });
  }

  Future<void> removeQuestionUpvote(String questionId, String userId) async {
    await _client
        .from('question_votes')
        .delete()
        .eq('question_id', questionId)
        .eq('user_id', userId);
  }

  Future<Set<String>> getUpvotedQuestionIds(String userId) async {
    final data = await _client
        .from('question_votes')
        .select('question_id')
        .eq('user_id', userId);
    return (data as List).map((row) => row['question_id'].toString()).toSet();
  }

  Future<void> markSolvedReply({
    required String questionId,
    required String replyId,
  }) async {
    await _client.rpc(
      'mark_question_reply_solved',
      params: {
        'p_question_id': questionId,
        'p_reply_id': replyId,
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> pushNotification({
    required String toUid,
    required String fromUid,
    required String type,
    String? postId,
    String? questionId,
    String? message,
    String? title,
  }) async {
    try {
      await _client.from('notifications').insert({
        'to_uid': toUid,
        'from_uid': fromUid,
        'type': type,
        'post_id': postId,
        'question_id': questionId,
        'message': message ?? '',
        'title': title,
      });
    } catch (e) {
      // Defensive fallback: if the title column does not exist in the database,
      // try inserting without the title column to prevent breaking the flow.
      debugPrint('pushNotification failed: $e. Retrying without title column.');
      try {
        await _client.from('notifications').insert({
          'to_uid': toUid,
          'from_uid': fromUid,
          'type': type,
          'post_id': postId,
          'question_id': questionId,
          'message': message ?? '',
        });
      } catch (err) {
        debugPrint('Fallback pushNotification failed: $err');
        rethrow;
      }
    }
  }

  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async {
    // Inserting with to_uid 'all_users' to trigger backend broadcast logic
    await pushNotification(
      toUid: 'all_users',
      fromUid: 'system',
      type: type,
      title: title,
      message: body,
    );
  }

  Stream<List<NotificationModel>> streamNotifications(String uid) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('to_uid', uid)
        .order('created_at', ascending: false)
        .limit(30)
        .map((list) => list.map((d) => NotificationModel.fromJson(d)).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true}).eq('id', notificationId);
  }

  Future<void> markAllNotificationsAsRead(String uid) async {
    await _client
        .from('notifications')
        .update({'read': true}).eq('to_uid', uid);
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

  Future<void> addComment(
    String postId,
    String userId,
    String content, {
    String? parentCommentId,
    String? replyingToUserId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw StateError('Comment cannot be empty.');
    }

    if (_client.auth.currentUser?.id != userId) {
      throw StateError('Authenticated user does not match comment author.');
    }

    // Use RPC for main comments to award aura, or direct insert for replies
    // For now, let's try direct insert to support new fields, and we might need to update the trigger/RPC later for aura
    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': trimmed,
      'parent_id': parentCommentId,
      'replying_to_user_id': replyingToUserId,
    });

    // Manually sync count since we didn't use the RPC
    await _client.rpc('sync_post_comment_count', params: {'p_post_id': postId});
    
    // Attempt to award aura manually if not using RPC
    try {
      await _client.rpc('award_aura', params: {
        'p_user_id': userId,
        'p_action': 'create_comment',
        'p_points': 3,
        'p_reference_type': 'comment',
        'p_reference_id': postId, // Using post ID as reference for now
      });
    } catch (e) {
      debugPrint('Failed to award aura for comment: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MESSAGING
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<ConversationModel>> getConversations(String userId) async {
    final data = await _client
        .from('conversations')
        .select()
        .contains('participants', [userId])
        .order('last_message_at', ascending: false);
    
    return (data as List).map((d) => ConversationModel.fromJson(d)).toList();
  }

  Stream<List<ConversationModel>> streamConversations(String userId) async* {
    // Yield the initial fetch immediately
    try {
      final initial = await getConversations(userId);
      yield initial;
    } catch (e) {
      debugPrint('Error in initial streamConversations fetch: $e');
    }

    // Poll periodically every 15 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 15));
      try {
        final data = await getConversations(userId);
        yield data;
      } catch (e) {
        debugPrint('Error in polling streamConversations: $e');
      }
    }
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .map((list) => list.map((d) => MessageModel.fromJson(d)).toList());
  }

  Future<Map<String, int>> getUnreadConversationCounts(
    String currentUserId,
    List<String> conversationIds,
  ) async {
    final distinctIds = conversationIds.toSet().toList();
    if (distinctIds.isEmpty) return const {};

    final data = await _client
        .from('messages')
        .select('conversation_id')
        .inFilter('conversation_id', distinctIds)
        .eq('is_read', false)
        .neq('sender_id', currentUserId)
        .limit(1000); // Sanity limit to avoid crashing on huge unread counts

    final counts = <String, int>{};
    for (final row in data as List) {
      final conversationId = row['conversation_id']?.toString() ?? '';
      if (conversationId.isEmpty) continue;
      counts.update(conversationId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    if (_client.auth.currentUser?.id != senderId) {
      throw StateError('Authenticated user does not match message sender.');
    }

    try {
      final convData = await _client
          .from('conversations')
          .select('participants')
          .eq('id', conversationId)
          .single();

      final participants = List<String>.from(convData['participants'] ?? []);
      final otherUserId = participants.firstWhere((id) => id != senderId, orElse: () => senderId);

      // Workaround: Bypass RPC to avoid payload column error in notifications
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'recipient_id': otherUserId,
        'content': trimmed,
      });

      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('conversations').update({
        'updated_at': now,
        'last_message': trimmed,
        'last_message_at': now,
        'last_message_sender_id': senderId,
      }).eq('id', conversationId);

      await pushNotification(
        toUid: otherUserId,
        fromUid: senderId,
        type: 'message',
        message: trimmed.length > 50 ? '${trimmed.substring(0, 47)}...' : trimmed,
      );
    } catch (e) {
      debugPrint('Failed to send message: $e');
      rethrow;
    }
  }

  Future<void> markConversationMessagesRead(
    String conversationId,
    String currentUserId,
  ) async {
    if (_client.auth.currentUser?.id != currentUserId) {
      throw StateError('Authenticated user does not match message reader.');
    }

    await _client.rpc(
      'mark_conversation_messages_read',
      params: {
        'p_conversation_id': conversationId,
      },
    );
  }

  Future<ConversationModel> getOrCreateConversation(
    String userA,
    String userB,
  ) async {
    if (_client.auth.currentUser?.id != userA) {
      throw StateError('Authenticated user does not match conversation starter.');
    }

    final data = await _client.rpc(
      'get_or_create_direct_conversation',
      params: {
        'p_other_user_id': userB,
      },
    );

    return ConversationModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<AuraLedgerModel>> getAuraLedger(String userId) async {
    final data = await _client
        .from('aura_ledger')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((d) => AuraLedgerModel.fromJson(d)).toList();
  }

  Future<Map<String, int>> getAuraTotalsSince(DateTime since) async {
    final data = await _client
        .from('aura_ledger')
        .select('user_id, points')
        .gte('created_at', since.toUtc().toIso8601String());

    final totals = <String, int>{};
    for (final row in data as List) {
      final userId = row['user_id']?.toString() ?? '';
      if (userId.isEmpty) continue;
      final points = (row['points'] as num?)?.toInt() ?? 0;
      totals.update(userId, (value) => value + points, ifAbsent: () => points);
    }
    return totals;
  }

  Future<void> syncGitHubAura(String userId, String githubHandle) async {
    if (githubHandle.isEmpty) return;

    try {
      final stats = await GitHubService.instance.getUserStats(githubHandle);
      if (stats == null) return;

      final prCount = await GitHubService.instance.getTotalPRs(githubHandle);
      final commitCount = await GitHubService.instance.getTotalCommits(githubHandle);

      // Calculate aura: 10 per PR, 1 per commit, 5 per repo
      final calculatedAura = (prCount * 10) + (commitCount * 1) + (stats['public_repos'] as int? ?? 0) * 5;
      
      // Limit to 500 max aura from GitHub for now to prevent gaming
      final awardAmount = calculatedAura > 500 ? 500 : calculatedAura;

      await _client.rpc('award_aura', params: {
        'p_user_id': userId,
        'p_action': 'github_sync',
        'p_points': awardAmount,
        'p_reference_type': 'github',
        'p_reference_id': githubHandle,
        'p_metadata': {
          'pr_count': prCount,
          'commit_count': commitCount,
          'repos': stats['public_repos'],
        },
      });
    } catch (e) {
      debugPrint('Failed to sync GitHub aura: $e');
    }
  }

  Future<void> upvoteReply(String replyId, String userId) async {
    await _client.from('reply_votes').insert({
      'reply_id': replyId,
      'user_id': userId,
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FOUNDER TOOLS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<void> deleteDailyChallenge(String challengeId) async {
    await _client.from('challenges').delete().eq('id', challengeId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DUELS & MATCHMAKING
  // ══════════════════════════════════════════════════════════════════════════

  Future<String> sendDuelRequest({
    required String senderId,
    required String receiverId,
    required String category,
    required String mode,
  }) async {
    final data = await _client.from('duel_requests').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'category': category,
      'mode': mode,
    }).select().single();
    final requestId = data['id'].toString();

    // Pre-create the arena_matches row with the same ID, so both players can read/write it.
    // This succeeds because the sender (player1_id) is the one inserting it, satisfying the RLS insert policy.
    try {
      await _client.from('arena_matches').insert({
        'id': requestId,
        'mode': mode,
        'player1_id': senderId,
        'player2_id': receiverId,
        'status': 'waiting',
      });
    } catch (e) {
      debugPrint('Failed to pre-create arena_matches row: $e');
    }

    String senderName = 'A peer';
    try {
      final userDoc = await _client.from('users').select('name').eq('id', senderId).maybeSingle();
      if (userDoc != null && userDoc['name'] != null) {
        senderName = userDoc['name'].toString();
      }
    } catch (_) {}

    try {
      await pushNotification(
        toUid: receiverId,
        fromUid: senderId,
        type: 'duel_invite',
        postId: requestId,
        message: '$senderName challenged you to a $mode in $category',
        title: 'New Duel Challenge! ⚔️',
      );
    } catch (e) {
      debugPrint('Failed to push duel invite notification: $e');
    }

    return requestId;
  }

  Future<void> updateDuelRequestStatus(String requestId, String status) async {
    await _client.from('duel_requests').update({'status': status}).eq('id', requestId);
  }

  Future<Map<String, dynamic>?> getDuelRequest(String requestId) async {
    try {
      final response = await _client
          .from('duel_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error getting duel request: $e');
      return null;
    }
  }

  Future<String> createLiveDuel({
    required String requestId,
    required String category,
    required String player1Id,
    required String player2Id,
  }) async {
    final data = await _client.from('live_duels').insert({
      'request_id': requestId,
      'category': category,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'status': 'in_progress',
    }).select().single();
    return data['id'].toString();
  }

  RealtimeChannel listenToIncomingDuelRequests(
      String userId, void Function(Map<String, dynamic> request) onInvite) {
    return _client
        .channel('public:duel_requests:incoming:$userId')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'duel_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'receiver_id',
              value: userId,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord['status'] == 'pending') {
                onInvite(newRecord);
              }
            })
        .subscribe();
  }

  RealtimeChannel listenToDuelRequestStatus(
      String requestId, void Function(Map<String, dynamic> request) onUpdate) {
    return _client
        .channel('public:duel_requests:status:$requestId')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'duel_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: requestId,
            ),
            callback: (payload) {
              onUpdate(payload.newRecord);
            })
        .subscribe();
  }
  Future<String?> findRandomMatch({
    required String userId,
    required String category,
    required String mode,
  }) async {
    final response = await _client.rpc('find_match', params: {
      'p_user_id': userId,
      'p_category': category,
      'p_mode': mode,
    });
    if (response != null) {
      return response.toString();
    }
    return null;
  }

  Future<void> leaveMatchmakingPool(String userId) async {
    await _client.from('matchmaking_pool').delete().eq('user_id', userId);
  }

  RealtimeChannel listenToLiveDuels(
      String userId, void Function(Map<String, dynamic> duel) onMatchFound) {
    return _client
        .channel('public:live_duels:matchmaking:$userId')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'live_duels',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'player1_id',
              value: userId,
            ),
            callback: (payload) {
              onMatchFound(payload.newRecord);
            })
        .subscribe();
  }

  Future<Map<String, dynamic>?> findArenaMatch(String mode) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    // 1. Try to use the atomic RPC function
    try {
      final response = await _client.rpc('find_arena_match', params: {
        'p_user_id': userId,
        'p_mode': mode,
      });
      if (response != null) {
        final matchId = response.toString();
        // Fetch the match record to get player1_id
        final matchData = await _client.from('arena_matches')
            .select('player1_id')
            .eq('id', matchId)
            .maybeSingle();
        return {
          'id': matchId,
          'player1_id': matchData?['player1_id']?.toString() ?? 'placeholder',
        };
      }
    } catch (e) {
      debugPrint('find_arena_match RPC failed, falling back to client-side query: $e');
    }

    // 2. Fallback to client-side query (in case they haven't run the SQL script yet)
    try {
      final data = await _client.from('arena_matches')
          .select()
          .eq('mode', mode)
          .eq('status', 'waiting')
          .neq('player1_id', userId)
          .isFilter('player2_id', null)
          .limit(1)
          .maybeSingle();
      
      if (data != null) {
         final id = data['id'].toString();
         final player1Id = data['player1_id'].toString();
         final update = await _client.from('arena_matches')
             .update({'player2_id': userId, 'status': 'playing'})
             .eq('id', id)
             .eq('status', 'waiting')
             .select()
             .maybeSingle();
         if (update != null) {
           return {
             'id': id,
             'player1_id': player1Id,
           };
         }
      }
    } catch (e) {
      debugPrint('Error finding match: $e');
    }
    return null;
  }
  
  Future<String> createArenaMatch(String mode, {String? opponentId}) async {
     final userId = _client.auth.currentUser?.id;
     if (userId == null) throw StateError('Not logged in');

     // Clean up any stranded matches (as player1 or player2) to avoid RLS active-match limits
     try {
       final activeMatches = await _client.from('arena_matches')
           .select()
           .or('player1_id.eq.$userId,player2_id.eq.$userId')
           .inFilter('status', ['waiting', 'playing']);
           
       for (var match in activeMatches) {
           final id = match['id'].toString();
           
           // If we found a stranded match where we are the host, we can just reuse it
           if (match['player1_id'] == userId) {
               try {
                 await _client.from('arena_matches').update({
                    'mode': mode,
                    'status': opponentId != null ? 'playing' : 'waiting',
                    'player2_id': opponentId, // works even if null
                 }).eq('id', id);
                 return id;
               } catch (_) {}
           }
           
           // Otherwise, mark it finished so it doesn't block us
           try {
               await _client.from('arena_matches').update({'status': 'finished'}).eq('id', id);
           } catch (_) {}
       }
     } catch (e) {
       debugPrint('Failed to clean up active matches: $e');
     }

     // 1. Insert the match with player2_id as null to comply with potential RLS restrictions
     final data = await _client.from('arena_matches').insert({
       'player1_id': userId,
       'mode': mode,
       'status': 'waiting'
     }).select().single();
     
     final newMatchId = data['id'].toString();

     // 2. If opponentId is provided, update the match to set the opponent and status to 'playing'
     if (opponentId != null) {
       await _client.from('arena_matches').update({
         'player2_id': opponentId,
         'status': 'playing'
       }).eq('id', newMatchId);
     }

     return newMatchId;
  }

  Future<void> updateArenaScore(String matchId, bool isPlayer1, int score) async {
     final column = isPlayer1 ? 'player1_score' : 'player2_score';
     await _client.from('arena_matches').update({column: score}).eq('id', matchId);
  }

  Future<void> finishArenaMatch(String matchId) async {
     await _client.from('arena_matches').update({'status': 'finished'}).eq('id', matchId);
  }
}
