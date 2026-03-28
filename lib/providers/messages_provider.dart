import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/supabase_service.dart';

class MessagesProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void init(String userId) {
    SupabaseService.instance.streamConversations(userId).listen((data) {
      _conversations = data;
      notifyListeners();
    });
  }

  Future<ConversationModel> startConversation(String myId, String otherId) async {
    return await SupabaseService.instance.getOrCreateConversation(myId, otherId);
  }

  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return SupabaseService.instance.streamMessages(conversationId);
  }

  Future<void> send(String conversationId, String senderId, String content) async {
    await SupabaseService.instance.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
    );
  }
}
