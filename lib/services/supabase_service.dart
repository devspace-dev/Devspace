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
import '../models/aura_summary_model.dart';
import 'calling_service.dart';
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

  void initCalling(String userId) {
    CallingService.instance.init(userId);
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

  Stream<List<UserModel>> streamUsers() {
    return Stream.fromFuture(
      _client
          .from('users')
          .select()
          .order('aura', ascending: false)
          .then((list) => (list as List).map((d) => UserModel.fromJson(d as Map<String, dynamic>)).toList()),
    );
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

  Stream<List<QuestionModel>> streamQuestions({String filter = 'latest'}) async* {
    final baseQuery = _client.from('questions').select();
    late final dynamic query;

    switch (filter) {
      case 'oldest':
        query = baseQuery.order('created_at', ascending: true);
        break;
      case 'popularity':
        query = baseQuery
            .order('upvotes_count', ascending: false)
            .order('created_at', ascending: false);
        break;
      case 'most replies':
        query = baseQuery
            .order('replies_count', ascending: false)
            .order('created_at', ascending: false);
        break;
      case 'relevance':
        query = baseQuery
            .order('upvotes_count', ascending: false)
            .order('replies_count', ascending: false);
        break;
      case 'latest':
      default:
        query = baseQuery.order('created_at', ascending: false);
        break;
    }

    final data = await query.limit(50);
    yield (data as List).map((d) => QuestionModel.fromJson(d as Map<String, dynamic>)).toList();
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
    final canReply = await _client.rpc('can_user_reply', params: {
      'p_question_id': questionId,
      'p_user_id': userId,
    });

    if (canReply != true) {
      throw StateError('Your request to answer this question has not been accepted yet.');
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
  }) async {
    await _client.from('notifications').insert({
      'to_uid': toUid,
      'from_uid': fromUid,
      'type': type,
      'post_id': postId,
      'question_id': questionId,
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
        .map((list) => list
          ..sort((a, b) =>
              (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt)));
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
        .neq('sender_id', currentUserId);

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
        message: trimmed.length > 50 ? trimmed.substring(0, 47) + '...' : trimmed,
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
}
