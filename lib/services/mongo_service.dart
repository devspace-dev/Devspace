import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
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

  // Local broadcasters for real-time feel (since mongo_dart doesn't have listeners like Firestore)
  final _usersController = StreamController<List<UserModel>>.broadcast();
  final _postsController = StreamController<List<PostModel>>.broadcast();

  Future<void> init(String connectionUri) async {
    if (_isInitialized) return;
    _db = Db(connectionUri);
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
    _refreshStreams();
  }

  void _refreshStreams() {
    streamUsers().first.then((list) => _usersController.add(list));
    streamFeed().first.then((list) => _postsController.add(list));
  }

  Future<void> close() async => await _db.close();

  // ══════════════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<UserModel?> getUserByEmail(String email) async {
    final doc = await _users.findOne({'email': email.toLowerCase()});
    return doc == null ? null : UserModel.fromJson(doc);
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _users.findOne({'_id': ObjectId.parse(id)});
    return doc == null ? null : UserModel.fromJson(doc);
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String passwordHash,
    required String handle,
    String avatar = '',
    String college = '',
  }) async {
    final doc = {
      'name': name,
      'email': email.toLowerCase(),
      'passwordHash': passwordHash,
      'handle': handle,
      'avatar': avatar,
      'color': 0xFF7C3AED, // Default violet
      'aura': 0,
      'role': 'Developer',
      'year': '1st Year',
      'building': 'Not set',
      'stack': [],
      'followers': 0,
      'following': 0,
      'bio': '',
      'college': college,
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
    await _users.updateOne(
      where.eq('_id', ObjectId.parse(uid)),
      modify.setAll(data),
    );
    _refreshStreams();
  }

  Stream<List<UserModel>> streamUsers() async* {
    final docs = await _users.find(where.sortBy('aura', descending: true)).toList();
    yield docs.map((d) => UserModel.fromJson(d)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOCIAL (Follow/Unfollow)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> follow(String fromUid, String toUid) async {
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
    await _follows.remove({
      'from': ObjectId.parse(fromUid),
      'to': ObjectId.parse(toUid),
    });
    await _users.updateOne(where.eq('_id', ObjectId.parse(fromUid)), modify.inc('following', -1));
    await _users.updateOne(where.eq('_id', ObjectId.parse(toUid)), modify.inc('followers', -1));
    _refreshStreams();
  }

  Future<bool> isFollowing(String fromUid, String toUid) async {
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
    return (result.id as ObjectId).hexString;
  }

  Stream<List<PostModel>> streamFeed() async* {
    final docs = await _posts.find(where.sortBy('createdAt', descending: true).limit(50)).toList();
    yield docs.map((d) => PostModel.fromJson(d)).toList();
  }

  Stream<List<PostModel>> streamUserPosts(String userId) async* {
    final docs = await _posts.find(where.eq('userId', ObjectId.parse(userId)).sortBy('createdAt', descending: true)).toList();
    yield docs.map((d) => PostModel.fromJson(d)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIKES & COMMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> likePost(String postId, String uid) async {
    await _likes.insertOne({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
    });
    await _posts.updateOne(where.id(ObjectId.parse(postId)), modify.inc('likes', 1));
    _refreshStreams();
  }

  Future<void> unlikePost(String postId, String uid) async {
    await _likes.remove({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
    });
    await _posts.updateOne(where.id(ObjectId.parse(postId)), modify.inc('likes', -1));
    _refreshStreams();
  }

  Future<bool> hasLiked(String postId, String uid) async {
    final doc = await _likes.findOne({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
    });
    return doc != null;
  }

  Future<void> addComment(String postId, String uid, String text) async {
    await _comments.insertOne({
      'postId': ObjectId.parse(postId),
      'uid': ObjectId.parse(uid),
      'text': text,
      'createdAt': DateTime.now().toUtc(),
    });
    await _posts.updateOne(where.id(ObjectId.parse(postId)), modify.inc('comments', 1));
    _refreshStreams();
  }

  Stream<List<Map<String, dynamic>>> streamComments(String postId) async* {
    final docs = await _comments.find(where.eq('postId', ObjectId.parse(postId)).sortBy('createdAt')).toList();
    yield docs;
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
    final docs = await _notifs.find(where.eq('toUid', ObjectId.parse(uid)).sortBy('createdAt', descending: true).limit(30)).toList();
    yield docs;
  }

  Future<String> uploadImage(String path, String base64Data) async {
    await _images.update(
      where.eq('path', path),
      modify.set('data', base64Data),
      upsert: true,
    );
    return path; // or return a URL-like string
  }

  Future<String?> getImage(String path) async {
    final doc = await _images.findOne(where.eq('path', path));
    return doc?['data'] as String?;
  }

  Future<bool> verifyPassword(String email, String passwordHash) async {
    final doc = await _users.findOne({'email': email.toLowerCase()});
    if (doc == null) return false;
    return doc['passwordHash'] == passwordHash;
  }
}
