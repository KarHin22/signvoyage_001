import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechState {
  final bool isAvailable;
  final bool isListening;
  final String currentWords;
  final String lastError;
  final double soundLevel;

  const SpeechState({
    this.isAvailable = false,
    this.isListening = false,
    this.currentWords = '',
    this.lastError = '',
    this.soundLevel = 0.0,
  });

  SpeechState copyWith({
    bool? isAvailable,
    bool? isListening,
    String? currentWords,
    String? lastError,
    double? soundLevel,
  }) {
    return SpeechState(
      isAvailable: isAvailable ?? this.isAvailable,
      isListening: isListening ?? this.isListening,
      currentWords: currentWords ?? this.currentWords,
      lastError: lastError ?? this.lastError,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

class SpeechNotifier extends Notifier<SpeechState> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  SpeechState build() => const SpeechState();

  Future<void> initialize() async {
    final available = await _speech.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    state = state.copyWith(isAvailable: available);
  }

  Future<void> startListening() async {
    if (!state.isAvailable) return;

    state = state.copyWith(
      isListening: true,
      currentWords: '',
      lastError: '',
    );

    await _speech.listen(
      onResult: _onResult,
      onSoundLevelChange: _onSoundLevelChange,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  void _onResult(SpeechRecognitionResult result) {
    state = state.copyWith(currentWords: result.recognizedWords);
    if (result.finalResult) {
      state = state.copyWith(isListening: false);
    }
  }

  void _onError(SpeechRecognitionError error) {
    state = state.copyWith(
      lastError: error.errorMsg,
      isListening: false,
    );
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      state = state.copyWith(isListening: false);
    }
  }

  void _onSoundLevelChange(double level) {
    state = state.copyWith(soundLevel: level);
  }
}

final speechProvider =
    NotifierProvider<SpeechNotifier, SpeechState>(SpeechNotifier.new);
