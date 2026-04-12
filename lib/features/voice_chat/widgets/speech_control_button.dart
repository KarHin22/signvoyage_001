import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/speech_provider.dart';

class SpeechControlButton extends ConsumerWidget {
  const SpeechControlButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (speechState.isListening)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((speechState.soundLevel + 2) / 12).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FloatingActionButton.large(
          heroTag: 'speech_control',
          onPressed: speechState.isAvailable
              ? () {
                  final notifier = ref.read(speechProvider.notifier);
                  if (speechState.isListening) {
                    notifier.stopListening();
                  } else {
                    notifier.startListening();
                  }
                }
              : null,
          backgroundColor: speechState.isListening
              ? colorScheme.error
              : colorScheme.primaryContainer,
          foregroundColor: speechState.isListening
              ? colorScheme.onError
              : colorScheme.onPrimaryContainer,
          child: Icon(
            speechState.isListening ? Icons.stop : Icons.mic,
            size: 36,
          ),
        ),
        if (!speechState.isAvailable && speechState.lastError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              speechState.lastError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}
