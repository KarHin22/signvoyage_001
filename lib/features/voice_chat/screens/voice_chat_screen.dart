import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../providers/speech_provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/rotated_display_panel.dart';
import '../widgets/message_bubble.dart';
import '../widgets/speech_control_button.dart';
import '../widgets/text_input_bar.dart';

class VoiceChatScreen extends ConsumerStatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speechProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    ref.read(conversationProvider.notifier).addMessage(text, MessageSender.deaf);
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);
    final messages = ref.watch(conversationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Auto-add hearing message when speech recognition finishes
    ref.listen<SpeechState>(speechProvider, (previous, next) {
      if (previous != null &&
          previous.isListening &&
          !next.isListening &&
          next.currentWords.isNotEmpty) {
        ref
            .read(conversationProvider.notifier)
            .addMessage(next.currentWords, MessageSender.hearing);
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation',
            onPressed: () {
              ref.read(conversationProvider.notifier).clearConversation();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Rotated panel for hearing person across the table
            const Expanded(
              flex: 2,
              child: RotatedDisplayPanel(),
            ),

            // Divider with label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.swap_vert,
                      size: 20,
                      color: colorScheme.outline,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // Conversation history
            Expanded(
              flex: 3,
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'Tap the mic button to start\nor type a message below',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: messages[index]);
                      },
                    ),
            ),

            // Live transcription preview
            if (speechState.isListening &&
                speechState.currentWords.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.tertiaryContainer,
                child: Text(
                  speechState.currentWords,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onTertiaryContainer,
                      ),
                ),
              ),

            // Text input
            TextInputBar(
              controller: _textController,
              onSend: _handleSend,
            ),

            // Mic button
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const SpeechControlButton(),
            ),
          ],
        ),
      ),
    );
  }
}
