import 'dart:async';

import 'package:flutter/material.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/supabase_service.dart';

typedef ConversationStreamLoader = Stream<List<ConversationModel>> Function(
  String userId,
);
typedef ConversationStarter = Future<ConversationModel> Function(
  String myId,
  String otherId,
);
typedef MessageStreamLoader = Stream<List<MessageModel>> Function(
  String conversationId,
);
typedef MessageSender = Future<void> Function({
  required String conversationId,
  required String senderId,
  required String content,
});
typedef ConversationReadMarker = Future<void> Function(
  String conversationId,
  String currentUserId,
);
typedef UnreadCountsLoader = Future<Map<String, int>> Function(
  String currentUserId,
  List<String> conversationIds,
);

class MessagesProvider extends ChangeNotifier {
  MessagesProvider({
    ConversationStreamLoader? conversationStreamLoader,
    ConversationStarter? conversationStarter,
    MessageStreamLoader? messageStreamLoader,
    MessageSender? messageSender,
    ConversationReadMarker? conversationReadMarker,
    UnreadCountsLoader? unreadCountsLoader,
  })  : _conversationStreamLoader =
            conversationStreamLoader ?? _defaultConversationStreamLoader,
        _conversationStarter = conversationStarter ?? _defaultConversationStarter,
        _messageStreamLoader = messageStreamLoader ?? _defaultMessageStreamLoader,
        _messageSender = messageSender ?? _defaultMessageSender,
        _conversationReadMarker =
            conversationReadMarker ?? _defaultConversationReadMarker,
        _unreadCountsLoader = unreadCountsLoader ?? _defaultUnreadCountsLoader;

  final ConversationStreamLoader _conversationStreamLoader;
  final ConversationStarter _conversationStarter;
  final MessageStreamLoader _messageStreamLoader;
  final MessageSender _messageSender;
  final ConversationReadMarker _conversationReadMarker;
  final UnreadCountsLoader _unreadCountsLoader;

  StreamSubscription<List<ConversationModel>>? _conversationSubscription;
  List<ConversationModel> _conversations = [];
  final Map<String, bool> _sending = {};
  final Map<String, String?> _sendErrors = {};
  bool _isLoading = false;
  String? _error;
  String? _activeUserId;

  List<ConversationModel> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUnreadCount =>
      _conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);
  bool isSending(String conversationId) => _sending[conversationId] ?? false;
  String? sendError(String conversationId) => _sendErrors[conversationId];

  static Stream<List<ConversationModel>> _defaultConversationStreamLoader(
    String userId,
  ) {
    return SupabaseService.instance.streamConversations(userId);
  }

  static Future<ConversationModel> _defaultConversationStarter(
    String myId,
    String otherId,
  ) {
    return SupabaseService.instance.getOrCreateConversation(myId, otherId);
  }

  static Stream<List<MessageModel>> _defaultMessageStreamLoader(
    String conversationId,
  ) {
    return SupabaseService.instance.streamMessages(conversationId);
  }

  static Future<void> _defaultMessageSender({
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    return SupabaseService.instance.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
    );
  }

  static Future<void> _defaultConversationReadMarker(
    String conversationId,
    String currentUserId,
  ) {
    return SupabaseService.instance.markConversationMessagesRead(
      conversationId,
      currentUserId,
    );
  }

  static Future<Map<String, int>> _defaultUnreadCountsLoader(
    String currentUserId,
    List<String> conversationIds,
  ) {
    return SupabaseService.instance.getUnreadConversationCounts(
      currentUserId,
      conversationIds,
    );
  }

  Future<void> init(String userId, {bool force = false}) async {
    if (!force &&
        _activeUserId == userId &&
        _conversationSubscription != null) {
      return;
    }

    await _conversationSubscription?.cancel();
    _activeUserId = userId;
    _conversations = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    _conversationSubscription = _conversationStreamLoader(userId).listen(
      (data) async {
        try {
          final conversationIds = data.map((item) => item.id).toList();
          if (conversationIds.isEmpty) {
            _conversations = [];
            _isLoading = false;
            _error = null;
            notifyListeners();
            return;
          }

          final unreadCounts = await _unreadCountsLoader(
            userId,
            conversationIds,
          );
          
          _conversations = data
              .map(
                (conversation) => conversation.copyWith(
                  unreadCount: unreadCounts[conversation.id] ?? 0,
                ),
              )
              .toList();
          _error = null;
        } catch (e) {
          _conversations = data;
          _error = 'Failed to load direct messages: $e';
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _isLoading = false;
        _error = 'Failed to load direct messages: $error';
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    final userId = _activeUserId;
    if (userId == null) return;
    await init(userId, force: true);
  }

  Future<ConversationModel> startConversation(String myId, String otherId) async {
    try {
      final conversation = await _conversationStarter(myId, otherId);
      // If we don't have it in our list yet, we might want to refresh
      // but the stream will catch it.
      return conversation;
    } catch (e) {
      throw StateError('Failed to start conversation: $e');
    }
  }

  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return _messageStreamLoader(conversationId);
  }

  Future<bool> send(
    String conversationId,
    String senderId,
    String content,
  ) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _sending[conversationId] == true) return false;

    _sending[conversationId] = true;
    _sendErrors[conversationId] = null;
    notifyListeners();

    try {
      await _messageSender(
        conversationId: conversationId,
        senderId: senderId,
        content: trimmed,
      );
      _sendErrors[conversationId] = null;
      return true;
    } catch (e) {
      _sendErrors[conversationId] = 'Failed to send message: $e';
      return false;
    } finally {
      _sending[conversationId] = false;
      notifyListeners();
    }
  }

  Future<void> markConversationRead(
    String conversationId,
    String currentUserId,
  ) async {
    // Optimistic UI update
    bool changed = false;
    _conversations = _conversations.map((c) {
      if (c.id == conversationId && c.unreadCount > 0) {
        changed = true;
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();
    
    if (changed) notifyListeners();

    try {
      await _conversationReadMarker(conversationId, currentUserId);
    } catch (e) {
      _error = 'Failed to update message read state: $e';
      notifyListeners();
    }
  }

  void clearConversationError(String conversationId) {
    if (!_sendErrors.containsKey(conversationId)) return;
    _sendErrors[conversationId] = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    super.dispose();
  }
}
