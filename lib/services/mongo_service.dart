import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class MongoService {
  MongoService._internal();
  static final MongoService instance = MongoService._internal();

  late final Db _db;
  late final DbCollection _users;
  late final DbCollection _posts;
  late final DbCollection _notifs;
  late final DbCollection _comments;
  late final DbCollection _likes;
  late final DbCollection _follows;
  late final DbCollection _images;

  bool _isInitialized = false;
  String? _initializationError;

  // Local broadcasters for real-time feel (since mongo_dart doesn't have listeners like Firestore)
  final _usersController = StreamController<List<UserModel>>.broadcast();
  final _postsController = StreamController<List<PostModel>>.broadcast();

  Stream<List<UserModel>> get usersStream => _usersController.stream;
  Stream<List<PostModel>> get feedStream => _postsController.stream;
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  Future<void> init(String connectionUri) async {
    if (_isInitialized) return;
    final trimmedUri = connectionUri.trim();
    if (trimmedUri.isEmpty) {
      _initializationError =
          'MongoDB is not configured. Pass --dart-define=MONGO_URI=... when running the app.';
      throw StateError(_initializationError!);
    }

    try {
      _db = Db(trimmedUri);
      await _db.open();
      _users = _db.collection('users');
      _posts = _db.collection('posts');
      _notifs = _db.collection('notifications');
      _comments = _db.collection('comments');
      _likes = _db.collection('likes');
      _follows = _db.collection('follows');
      _images = _db.collection('images');

      await _users.createIndex(keys: {'email': 1}, unique: true);
      await _users.createIndex(keys: {'handle': 1}, unique: true);
      await _posts.createIndex(keys: {'createdAt': -1});

      _isInitialized = true;
      _initializationError = null;
      _refreshStreams();
    } catch (e) {
      _initializationError =
          'MongoDB initialization failed. Check your Atlas URI, database user, and network access. Original error: $e';
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (_isInitialized) return;
    throw StateError(
      _initializationError ??
          'MongoDB is not initialized. Configure MONGO_URI before using auth or data features.',
    );
  }

  void _refreshStreams() {
    _ensureInitialized();
    streamUsers().first.then((list) => _usersController.add(list));
    streamFeed().first.then((list) => _postsController.add(list));
  }

  Future<void> close() async {
    _ensureInitialized();
    await _db.close();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<UserModel?> getUserByEmail(String email) async {
    _ensureInitialized();
    final doc = await _users.findOne({'email': email.toLowerCase()});
    return doc == null ? null : UserModel.fromJson(doc);
  }

  Future<UserModel?> getUserByHandle(String handle) async {
    _ensureInitialized();
    final doc = await _users.findOne({'handle': handle.toLowerCase()});
    return doc == null ? null : UserModel.fromJson(doc);
  }

  Future<UserModel?> getUserById(String id) async {
    _ensureInitialized();
    final doc = await _users.findOne({'_id': ObjectId.parse(id)});
    return doc == null ? null : UserModel.fromJson(doc);
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    String? passwordHash,
    required String handle,
    String avatar = '',
    String role = 'Student',
    String year = '',
    String branch = '',
    String building = '',
    List<String> stack = const [],
    String bio = '',
    String college = 'Jaipur National University',
    String githubHandle = '',
    bool profileCompleted = false,
  }) async {
    _ensureInitialized();
    final doc = {
      'name': name,
      'email': email.toLowerCase(),
      if (passwordHash != null && passwordHash.isNotEmpty)
        'passwordHash': passwordHash,
      'handle': handle,
      'avatar': avatar,
      'color': 0xFF7C3AED, // Default violet
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
      'githubHandle': githubHandle,
      'profileCompleted': profileCompleted,
      'createdAt': DateTime.now().toUtc(),
    };
    final result = await _users.insertOne(doc);
    final user = UserModel.fromJson({
      ...doc,
      '_id': result.id as ObjectId,
    });
    _refreshStreams();
    return user;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    _ensureInitialized();
    final modifier = modify;
    for (final entry in data.entries) {
      modifier.set(entry.key, entry.value);
    }
    await _users.updateOne(
      where.eq('_id', ObjectId.parse(uid)),
      modifier,
    );
    _refreshStreams();
  }

  Stream<List<UserModel>> streamUsers() async* {
    _ensureInitialized();
    final docs = await _users.find(where.sortBy('aura', descending: true)).toList();
    yield docs.map((d) => UserModel.fromJson(d)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOCIAL (Follow/Unfollow)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> follow(String fromUid, String toUid) async {
    _ensureInitialized();
    await _follows.insertOne({
      'from': ObjectId.parse(fromUid),
      'to': ObjectId.parse(toUid),
      'followedAt': DateTime.now().toUtc(),
    });
    await _users.updateOne(where.eq('_id', ObjectId.parse(fromUid)), modify.inc('following', 1));
    await _users.updateOne(where.eq('_id', ObjectId.parse(toUid)), modify.inc('followers', 1));
    _refreshStreams();
  }

  Future<void> unfollow(String fromUid, String toUid) async {
    _ensureInitialized();
    await _follows.remove({
      'from': ObjectId.parse(fromUid),
      'to': ObjectId.parse(toUid),
    });
    await _users.updateOne(where.eq('_id', ObjectId.parse(fromUid)), modify.inc('following', -1));
    await _users.updateOne(where.eq('_id', ObjectId.parse(toUid)), modify.inc('followers', -1));
    _refreshStreams();
  }

  Future<bool> isFollowing(String fromUid, String toUid) async {
    _ensureInitialized();
    final doc = await _follows.findOne({
      'from': ObjectId.parse(fromUid),
      'to': ObjectId.parse(toUid),
    });
    return doc != null;
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
    _ensureInitialized();
    final doc = {
      'userId': ObjectId.parse(userId),
      'content': content,
      'tags': tags,
      'imageUrl': imageUrl ?? '',
      'likes': 0,
      'comments': 0,
      'reposts': 0,
      'createdAt': DateTime.now().toUtc(),
    };
    final result = await _posts.insertOne(doc);
    _refreshStreams();
    return (result.id as ObjectId).oid;
  }

  Stream<List<PostModel>> streamFeed() async* {
    _ensureInitialized();
    final docs = await _posts.find(where.sortBy('createdAt', descending: true).limit(50)).toList();
    yield docs.map((d) => PostModel.fromJson(d)).toList();
  }

  Stream<List<PostModel>> streamUserPosts(String userId) async* {
    _ensureInitialized();
    final docs = await _posts.find(where.eq('userId', ObjectId.parse(userId)).sortBy('createdAt', descending: true)).toList();
    yield docs.map((d) => PostModel.fromJson(d)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIKES & COMMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> likePost(String postId, String uid) async {
    _ensureInitialized();
    await _likes.insertOne({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
    });
    await _posts.updateOne(where.id(ObjectId.parse(postId)), modify.inc('likes', 1));
    _refreshStreams();
  }

  Future<void> unlikePost(String postId, String uid) async {
    _ensureInitialized();
    await _likes.remove({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
    });
    await _posts.updateOne(where.id(ObjectId.parse(postId)), modify.inc('likes', -1));
    _refreshStreams();
  }

  Future<bool> hasLiked(String postId, String uid) async {
    _ensureInitialized();
    final doc = await _likes.findOne({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
    });
    return doc != null;
  }

  Future<void> addComment(String postId, String uid, String text) async {
    _ensureInitialized();
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw StateError('Comment cannot be empty.');
    }
    await _comments.insertOne({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
      'text': trimmedText,
      'createdAt': DateTime.now().toUtc(),
    });
    await _posts.updateOne(where.id(ObjectId.parse(postId)), modify.inc('comments', 1));
    _refreshStreams();
  }

  Future<List<CommentModel>> getCommentsForPost(String postId) async {
    _ensureInitialized();
    final docs = await _comments.find(where.eq('postId', ObjectId.parse(postId)).sortBy('createdAt')).toList();
    return docs.map(CommentModel.fromJson).toList();
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
    _ensureInitialized();
    await _notifs.insertOne({
      'toUid': ObjectId.parse(toUid),
      'fromUid': ObjectId.parse(fromUid),
      'type': type,
      'postId': postId != null ? ObjectId.parse(postId) : null,
      'message': message ?? '',
      'read': false,
      'createdAt': DateTime.now().toUtc(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String uid) async* {
    _ensureInitialized();
    final docs = await _notifs.find(where.eq('toUid', ObjectId.parse(uid)).sortBy('createdAt', descending: true).limit(30)).toList();
    yield docs;
  }

  Future<String> uploadImage(String path, String base64Data) async {
    _ensureInitialized();
    await _images.update(
      where.eq('path', path),
      modify.set('data', base64Data),
      upsert: true,
    );
    return path; // or return a URL-like string
  }

  Future<String?> getImage(String path) async {
    _ensureInitialized();
    final doc = await _images.findOne(where.eq('path', path));
    return doc?['data'] as String?;
  }

  Future<bool> verifyPassword(String email, String passwordHash) async {
    _ensureInitialized();
    final doc = await _users.findOne({'email': email.toLowerCase()});
    if (doc == null) return false;
    return doc['passwordHash'] == passwordHash;
  }
}
