import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../providers/sign_recognition_provider.dart';
class SignTranslatorScreen extends ConsumerWidget {
  const SignTranslatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signRecognitionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: state.isInitialized ? () => ref.read(signRecognitionProvider.notifier).toggleCamera() : null,
          ),
        ],
      ),
      body: state.isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                if (ref.read(signRecognitionProvider.notifier).cameraController != null)
                  CameraPreview(ref.read(signRecognitionProvider.notifier).cameraController!),
                // Subtitle overlay
                if (state.gestureText.isNotEmpty)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(seconds: 3),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.gestureText,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: state.gestureText.isNotEmpty ? () => ref.read(signRecognitionProvider.notifier).speakGesture() : null,
                tooltip: 'Speak',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
