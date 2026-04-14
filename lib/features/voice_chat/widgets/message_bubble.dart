import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDeaf = message.sender == MessageSender.deaf;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isDeaf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDeaf
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.senderLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDeaf
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDeaf
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
