import 'package:flutter/foundation.dart';

enum MessageSender { hearing, deaf }

@immutable
class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  String get senderLabel =>
      sender == MessageSender.hearing ? 'Hearing' : 'You';
}
