import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../providers/conversation_provider.dart';

class RotatedDisplayPanel extends ConsumerWidget {
  const RotatedDisplayPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(conversationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Find the last message from the deaf user
    String displayText = 'Your typed replies will appear here\nfor the other person to read';
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].sender == MessageSender.deaf) {
        displayText = messages[i].text;
        break;
      }
    }

    return RotatedBox(
      quarterTurns: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
