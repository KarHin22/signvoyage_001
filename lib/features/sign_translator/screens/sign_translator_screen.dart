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
          : (state.isEmulator && state.cameras.isNotEmpty && state.cameras[state.cameraIndex].lensDirection == CameraLensDirection.front)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Only available in actual mobile device',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(ref.read(signRecognitionProvider.notifier).cameraController!),
                    if (state.handBoundingBox != null && state.imageSize != Size.zero)
                      CustomPaint(
                        painter: HandBoundingBoxPainter(
                          box: state.handBoundingBox!,
                          imageSize: state.imageSize,
                        ),
                      ),
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

class HandBoundingBoxPainter extends CustomPainter {
  /// [box] uses **normalized** coordinates (0.0–1.0) from MediaPipe.
  final Rect box;
  /// [imageSize] is kept for API compatibility but not used for scaling
  /// since MediaPipe returns normalized coords.
  final Size imageSize;

  HandBoundingBoxPainter({required this.box, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    // MediaPipe landmarks are normalized (0.0–1.0), so we scale to screen size.
    final mappedBox = Rect.fromLTRB(
      box.left   * size.width,
      box.top    * size.height,
      box.right  * size.width,
      box.bottom * size.height,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF) // Cyan glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final glowPaint = Paint()
      ..color = const Color(0x3300E5FF) // Translucent fill
      ..style = PaintingStyle.fill;

    canvas.drawRect(mappedBox, glowPaint);
    canvas.drawRect(mappedBox, borderPaint);

    // Corner accent marks for a more polished HUD look
    const double cornerLen = 18.0;
    const double cw = 3.5;
    final accentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = cw
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset tl, Offset tr, Offset bl) {
      canvas.drawLine(tl, tr, accentPaint);
      canvas.drawLine(tl, bl, accentPaint);
    }

    final l = mappedBox.left;
    final t = mappedBox.top;
    final r = mappedBox.right;
    final b = mappedBox.bottom;

    drawCorner(Offset(l, t), Offset(l + cornerLen, t), Offset(l, t + cornerLen));
    drawCorner(Offset(r, t), Offset(r - cornerLen, t), Offset(r, t + cornerLen));
    drawCorner(Offset(l, b), Offset(l + cornerLen, b), Offset(l, b - cornerLen));
    drawCorner(Offset(r, b), Offset(r - cornerLen, b), Offset(r, b - cornerLen));
  }

  @override
  bool shouldRepaint(covariant HandBoundingBoxPainter oldDelegate) {
    return oldDelegate.box != box || oldDelegate.imageSize != imageSize;
  }
}
