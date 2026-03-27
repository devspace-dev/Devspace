import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/question_model.dart';
import '../models/question_reply_model.dart';

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
///   branch text,
///   building text,
///   stack text[],
///   followers bigint default 0,
///   following bigint default 0,
///   bio text,
///   college text,
///   github_handle text default '',
///   profile_completed boolean default false,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table posts (
///   id uuid default gen_random_uuid() primary key,
///   user_id uuid references users(id) on delete cascade,
///   content text,
///   tags text[],
///   image_url text,
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
///   content text not null,
///   created_at timestamp with time zone default timezone('utc'::text, now())
/// );
///
/// create table questions (
///   id uuid default gen_random_uuid() primary key,
///   user_id uuid references users(id) on delete cascade,
///   title text not null,
///   body text not null,
///   tags text[],
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
///   content text not null,
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
    await _client.from('users').insert({
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'handle': handle,
      'avatar': avatar,
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

  Future<Set<String>> getFollowingIds(String userId) async {
    final data = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return (data as List)
        .map((row) => row['following_id'].toString())
        .toSet();
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
    String? quotePostId,
  }) async {
    final data = await _client.from('posts').insert({
      'user_id': userId,
      'content': content,
      'tags': tags,
      'image_url': imageUrl ?? '',
      'quote_post_id': quotePostId,
      'likes_count': 0,
      'comments_count': 0,
      'reposts_count': 0,
    }).select().single();

    return data['id'].toString();
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
    final data = await _client
        .from('posts')
        .select()
        .eq('id', postId)
        .maybeSingle();
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
    await _client.from('likes').insert({
      'post_id': postId,
      'user_id': uid,
    });
    await _syncPostLikeCount(postId);
  }

  Future<void> unlikePost(String postId, String uid) async {
    await _client.from('likes').delete().eq('post_id', postId).eq('user_id', uid);
    await _syncPostLikeCount(postId);
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
    final data = await _client
        .from('likes')
        .select('post_id')
        .eq('user_id', userId);
    return (data as List)
        .map((row) => row['post_id'].toString())
        .toSet();
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
    final data = await _client
        .from('bookmarks')
        .select('post_id')
        .eq('user_id', userId);
    return (data as List)
        .map((row) => row['post_id'].toString())
        .toSet();
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

    final postRows = await _client
        .from('posts')
        .select()
        .inFilter('id', postIds);

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
    final data = await _client.from('questions').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'tags': tags,
      'upvotes_count': 0,
      'replies_count': 0,
    }).select().single();

    return data['id'].toString();
  }

  Future<List<QuestionReplyModel>> getRepliesForQuestion(String questionId) async {
    final data = await _client
        .from('question_replies')
        .select()
        .eq('question_id', questionId)
        .order('created_at', ascending: true);
    return (data as List)
        .map((d) => QuestionReplyModel.fromJson(d))
        .toList();
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
    return (data as List)
        .map((row) => row['question_id'].toString())
        .toSet();
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
    await _client.from('notifications').update({'read': true}).eq('id', notificationId);
  }

  Future<void> markAllNotificationsAsRead(String uid) async {
    await _client.from('notifications').update({'read': true}).eq('to_uid', uid);
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
    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': trimmed,
    });
    await _syncPostCommentCount(postId);
  }

  Future<void> _syncPostLikeCount(String postId) async {
    final data = await _client.from('likes').select('id').eq('post_id', postId);
    await _client
        .from('posts')
        .update({'likes_count': (data as List).length}).eq('id', postId);
  }

  Future<void> _syncPostCommentCount(String postId) async {
    final data =
        await _client.from('comments').select('id').eq('post_id', postId);
    await _client
        .from('posts')
        .update({'comments_count': (data as List).length}).eq('id', postId);
  }

}
