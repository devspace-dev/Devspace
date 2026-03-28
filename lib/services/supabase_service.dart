import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/question_model.dart';
import '../models/question_reply_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

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
    String role = 'Student',
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
        'role': role,
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

  Stream<List<UserModel>> streamUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('aura', ascending: false)
        .map((list) => list.map((d) => UserModel.fromJson(d)).toList());
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
    String? quotePostId,
  }) async {
    if (_client.auth.currentUser?.id != userId) {
      throw StateError('Authenticated user does not match post creator.');
    }

    final data = await _client.rpc(
      'create_post_with_aura',
      params: {
        'p_content': content,
        'p_tags': tags,
        'p_image_url': imageUrl ?? '',
        'p_quote_post_id': quotePostId,
      },
    );

    return data.toString();
  }

  Future<void> updatePostImage(String postId, String imageUrl) async {
    await _client
        .from('posts')
        .update({'image_url': imageUrl}).eq('id', postId);
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
    if (_client.auth.currentUser?.id != uid) {
      throw StateError('Authenticated user does not match like actor.');
    }

    await _client.rpc(
      'like_post_with_aura',
      params: {
        'p_post_id': postId,
      },
    );
  }

  Future<void> unlikePost(String postId, String uid) async {
    if (_client.auth.currentUser?.id != uid) {
      throw StateError('Authenticated user does not match like actor.');
    }

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

  Stream<List<QuestionModel>> streamQuestions() {
    return _client
        .from('questions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((list) => list.map((d) => QuestionModel.fromJson(d)).toList());
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

  Future<void> addQuestionReply({
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

    await _client.from('question_replies').insert({
      'question_id': questionId,
      'user_id': userId,
      'content': trimmed,
      'parent_reply_id': normalizedParentReplyId,
      'replying_to_user_id': replyingToUserId,
    });
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

  Future<void> addComment(String postId, String userId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw StateError('Comment cannot be empty.');
    }

    if (_client.auth.currentUser?.id != userId) {
      throw StateError('Authenticated user does not match comment author.');
    }

    await _client.rpc(
      'add_comment_with_aura',
      params: {
        'p_post_id': postId,
        'p_content': trimmed,
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MESSAGING
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<ConversationModel>> streamConversations(String userId) {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .map((d) => ConversationModel.fromJson(d))
            .where((c) => c.participants.contains(userId))
            .toList())
        .map((list) => list..sort((a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt)));
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list.map((d) => MessageModel.fromJson(d)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': trimmed,
    });

    // Update last message in conversation
    await _client.from('conversations').update({
      'last_message': trimmed,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  Future<ConversationModel> getOrCreateConversation(
      String userA, String userB) async {
    final participants = [userA, userB]..sort();

    final existing = await _client
        .from('conversations')
        .select()
        .contains('participants', participants)
        .maybeSingle();

    if (existing != null) {
      return ConversationModel.fromJson(existing);
    }

    final data = await _client
        .from('conversations')
        .insert({
          'participants': participants,
        })
        .select()
        .single();

    return ConversationModel.fromJson(data);
  }
}
