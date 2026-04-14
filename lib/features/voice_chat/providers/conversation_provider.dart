import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

class ConversationNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void addMessage(String text, MessageSender sender) {
    if (text.trim().isEmpty) return;
    state = [
      ...state,
      ChatMessage(
        text: text.trim(),
        sender: sender,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void clearConversation() {
    state = [];
  }
}

final conversationProvider =
    NotifierProvider<ConversationNotifier, List<ChatMessage>>(
        ConversationNotifier.new);
