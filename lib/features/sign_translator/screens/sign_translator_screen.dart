import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../providers/sign_recognition_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  body: (state.error != null || kIsWeb || !state.isInitialized)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (kIsWeb)
                    const Icon(Icons.web, size: 64, color: Colors.grey)
                  else if (state.error != null)
Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    kIsWeb ? 'Camera not supported on web. Use mobile.' : state.error ?? 'Initializing...',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (!kIsWeb && state.error != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(signRecognitionProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
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
