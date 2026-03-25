import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

/// Central Firestore access layer.
/// Every collection name lives here — change once, updates everywhere.
class FirebaseService {
  FirebaseService._();
  static final instance = FirebaseService._();

  final _db = FirebaseFirestore.instance;

  // ── Collection refs ─────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users  => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _posts  => _db.collection('posts');
  CollectionReference<Map<String, dynamic>> get _notifs => _db.collection('notifications');

  // ══════════════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Create or update user document on first sign-in.
  Future<void> upsertUser(UserModel user) async {
    await _users.doc(user.id.toString()).set({
      'id':       user.id,
      'name':     user.name,
      'handle':   user.handle,
      'avatar':   user.avatar,
      'color':    user.color.value,
      'aura':     user.aura,
      'role':     user.role,
      'year':     user.year,
      'building': user.building,
      'stack':    user.stack,
      'followers': user.followers,
      'following': user.following,
      'bio':      user.bio,
      'college':  user.college,
      'photoUrl': '',
      'githubHandle': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fetch a single user by uid.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Stream all users for real-time People tab.
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _users.orderBy('aura', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  /// Update specific user fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  /// Increment aura atomically — safe for concurrent updates.
  Future<void> incrementAura(String uid, int points) async {
    await _users.doc(uid).update({
      'aura': FieldValue.increment(points),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FOLLOW / UNFOLLOW
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> follow(String fromUid, String toUid) async {
    final batch = _db.batch();
    batch.set(
      _users.doc(fromUid).collection('following').doc(toUid),
      {'uid': toUid, 'followedAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _users.doc(toUid).collection('followers').doc(fromUid),
      {'uid': fromUid, 'followedAt': FieldValue.serverTimestamp()},
    );
    batch.update(_users.doc(fromUid), {'following': FieldValue.increment(1)});
    batch.update(_users.doc(toUid),   {'followers': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> unfollow(String fromUid, String toUid) async {
    final batch = _db.batch();
    batch.delete(_users.doc(fromUid).collection('following').doc(toUid));
    batch.delete(_users.doc(toUid).collection('followers').doc(fromUid));
    batch.update(_users.doc(fromUid), {'following': FieldValue.increment(-1)});
    batch.update(_users.doc(toUid),   {'followers': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<bool> isFollowing(String fromUid, String toUid) async {
    final doc = await _users.doc(fromUid).collection('following').doc(toUid).get();
    return doc.exists;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // POSTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Create a new post document.
  Future<String> createPost({
    required String userId,
    required String content,
    required List<String> tags,
    String? imageUrl,
  }) async {
    final ref = await _posts.add({
      'userId':    userId,
      'content':   content,
      'tags':      tags,
      'imageUrl':  imageUrl ?? '',
      'likes':     0,
      'comments':  0,
      'reposts':   0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Real-time feed stream — latest 50 posts.
  Stream<List<Map<String, dynamic>>> streamFeed() {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Stream posts for a specific user's profile.
  Stream<List<Map<String, dynamic>>> streamUserPosts(String userId) {
    return _posts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Likes ────────────────────────────────────────
  Future<void> likePost(String postId, String uid) async {
    final batch = _db.batch();
    batch.set(_posts.doc(postId).collection('likes').doc(uid), {'uid': uid});
    batch.update(_posts.doc(postId), {'likes': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> unlikePost(String postId, String uid) async {
    final batch = _db.batch();
    batch.delete(_posts.doc(postId).collection('likes').doc(uid));
    batch.update(_posts.doc(postId), {'likes': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<bool> hasLiked(String postId, String uid) async {
    final doc = await _posts.doc(postId).collection('likes').doc(uid).get();
    return doc.exists;
  }

  // ── Bookmarks (stored on user doc) ───────────────
  Future<void> bookmark(String uid, String postId) async {
    await _users.doc(uid).collection('bookmarks').doc(postId).set({'postId': postId});
  }

  Future<void> unbookmark(String uid, String postId) async {
    await _users.doc(uid).collection('bookmarks').doc(postId).delete();
  }

  // ── Comments ─────────────────────────────────────
  Future<void> addComment(String postId, String uid, String text) async {
    final batch = _db.batch();
    batch.set(
      _posts.doc(postId).collection('comments').doc(),
      {'uid': uid, 'text': text, 'createdAt': FieldValue.serverTimestamp()},
    );
    batch.update(_posts.doc(postId), {'comments': FieldValue.increment(1)});
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> streamComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> pushNotification({
    required String toUid,
    required String fromUid,
    required String type,   // 'like' | 'comment' | 'follow' | 'repost'
    String? postId,
    String? message,
  }) async {
    await _notifs.add({
      'toUid':   toUid,
      'fromUid': fromUid,
      'type':    type,
      'postId':  postId ?? '',
      'message': message ?? '',
      'read':    false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String uid) {
    return _notifs
        .where('toUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> markNotificationRead(String notifId) async {
    await _notifs.doc(notifId).update({'read': true});
  }
}
