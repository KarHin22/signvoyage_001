import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/gesture.dart';

// ---------------------------------------------------------------------------
// MediaPipe Hand Landmark Indices
// ---------------------------------------------------------------------------
// WRIST = 0
// THUMB:  CMC=1, MCP=2, IP=3,  TIP=4
// INDEX:  MCP=5, PIP=6, DIP=7, TIP=8
// MIDDLE: MCP=9, PIP=10,DIP=11,TIP=12
// RING:   MCP=13,PIP=14,DIP=15,TIP=16
// PINKY:  MCP=17,PIP=18,DIP=19,TIP=20
// ---------------------------------------------------------------------------
const int _wrist = 0;
const int _thumbTip = 4;
const int _thumbMcp = 2;
const int _indexMcp = 5;
const int _indexPip = 6;
const int _indexTip = 8;
const int _middlePip = 10;
const int _middleTip = 12;
const int _ringPip = 14;
const int _ringTip = 16;
const int _pinkyMcp = 17;
const int _pinkyPip = 18;
const int _pinkyTip = 20;

class SignRecognitionState {
  const SignRecognitionState({
    this.gesture = RecognizedGesture.none,
    this.gestureText = '',
    this.cameraIndex = 0,
    this.isInitialized = false,
    this.cameras = const [],
    this.error,
    this.handBoundingBox,
    this.isEmulator = false,
    this.imageSize = Size.zero,
  });

  final RecognizedGesture gesture;
  final String gestureText;
  final int cameraIndex;
  final bool isInitialized;
  final List<CameraDescription> cameras;
  final String? error;

  /// Bounding box in **normalized** coords (0.0–1.0), painted by HandBoundingBoxPainter.
  final Rect? handBoundingBox;
  final bool isEmulator;
  final Size imageSize;

  SignRecognitionState copyWith({
    RecognizedGesture? gesture,
    String? gestureText,
    int? cameraIndex,
    bool? isInitialized,
    List<CameraDescription>? cameras,
    String? error,
    Rect? handBoundingBox,
    bool clearBoundingBox = false,
    bool? isEmulator,
    Size? imageSize,
  }) {
    return SignRecognitionState(
      gesture: gesture ?? this.gesture,
      gestureText: gestureText ?? this.gestureText,
      cameraIndex: cameraIndex ?? this.cameraIndex,
      isInitialized: isInitialized ?? this.isInitialized,
      cameras: cameras ?? this.cameras,
      error: error ?? this.error,
      handBoundingBox: clearBoundingBox
          ? null
          : (handBoundingBox ?? this.handBoundingBox),
      isEmulator: isEmulator ?? this.isEmulator,
      imageSize: imageSize ?? this.imageSize,
    );
  }
}

class SignRecognitionNotifier
    extends AutoDisposeNotifier<SignRecognitionState> {
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  Timer? _subtitleTimer;
  bool _disposed = false;

  HandLandmarkerPlugin? _handPlugin;
  FlutterTts? _tts;

  final List<CameraDescription> _cameras = [];
  bool _isDetecting = false;

  final List<RecognizedGesture> _gestureBuffer = [];
  static const int _bufferSize = 3;
  DateTime _lastSpokenTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  SignRecognitionState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _subtitleTimer?.cancel();
      _cameraController?.dispose();
      _handPlugin?.dispose();
    });

    Future.microtask(() => _init());
    return const SignRecognitionState();
  }

  Future<void> _init() async {
    try {
      // TTS – fire-and-forget to avoid blocking on emulator
      _tts = FlutterTts();
      _tts!.setLanguage('en-US');
      _tts!.setSpeechRate(0.8);
      _tts!.setVolume(1.0);
      _tts!.awaitSpeakCompletion(true);
      _tts!.setStartHandler(() => debugPrint('TTS Started'));
      _tts!.setErrorHandler((msg) => debugPrint('TTS Error: $msg'));
      _tts!.setCompletionHandler(() => debugPrint('TTS complete'));

      if (kIsWeb) {
        state = state.copyWith(
          isInitialized: true,
          error: 'Camera not supported on web',
        );
        return;
      }

      final status = await Permission.camera.request();
      if (!status.isGranted) {
        state = state.copyWith(error: 'Camera permission denied');
        return;
      }

      bool isEmu = false;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        isEmu = !androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        isEmu = !iosInfo.isPhysicalDevice;
      }

      // Initialise the MediaPipe hand landmark plugin
      if (Platform.isAndroid) {
        _handPlugin = HandLandmarkerPlugin.create(
          numHands: 1,
          minHandDetectionConfidence: 0.5, // Lower = easier to detect
          // Use CPU on emulator (no GPU); GPU on physical device
          delegate: isEmu
              ? HandLandmarkerDelegate.cpu
              : HandLandmarkerDelegate.gpu,
        );
        debugPrint(
          '✅ HandLandmarkerPlugin created (delegate: ${isEmu ? "CPU" : "GPU"})',
        );
      }

      final cameras = await availableCameras();
      _cameras.addAll(cameras);

      // Prefer front camera for selfie-style signing
      int initialIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (initialIndex == -1) initialIndex = cameras.isNotEmpty ? 0 : -1;

      if (initialIndex != -1) {
        state = state.copyWith(
          cameras: _cameras,
          cameraIndex: initialIndex,
          isEmulator: isEmu,
          error: null,
        );
        await _initCamera(initialIndex);
      } else {
        state = state.copyWith(error: 'No camera available');
      }
    } catch (e) {
      debugPrint('Init error: $e');
      state = state.copyWith(error: 'Failed to initialize: $e');
    }
  }

  Future<void> _initCamera(int cameraIndex) async {
    try {
      final camera = _cameras[cameraIndex];
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processImage);

      state = state.copyWith(isInitialized: true, error: null);
    } catch (e) {
      debugPrint('Camera init error: $e');
      state = state.copyWith(
        isInitialized: false,
        error: 'Camera init failed: $e',
      );
    }
  }

  void _processImage(CameraImage image) async {
    if (_disposed ||
        _isDetecting ||
        _cameraController?.value.isInitialized != true) {
      return;
    }
    _isDetecting = true;

    // ── Desktop / non-Android mock ──────────────────────────────────────────
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await Future.delayed(const Duration(seconds: 2));
      if (_disposed) {
        _isDetecting = false;
        return;
      }
      final mockGesture = [
        RecognizedGesture.goodJob,
        RecognizedGesture.bad,
        RecognizedGesture.goodbye,
        RecognizedGesture.peace,
        RecognizedGesture.letterA,
        RecognizedGesture.letterC,
        RecognizedGesture.letterI,
        RecognizedGesture.letterL,
        RecognizedGesture.letterY,
      ][math.Random().nextInt(9)];
      _addToBufferAndUpdate(
        mockGesture,
        const Rect.fromLTWH(0.25, 0.25, 0.5, 0.5),
      );
      _isDetecting = false;
      return;
    }

    // ── iOS: hand_landmarker not supported – show placeholder ───────────────
    if (Platform.isIOS) {
      _isDetecting = false;
      return;
    }

    // ── Android: real MediaPipe detection ────────────────────────────────────
    try {
      final sensorOrientation = _cameras[state.cameraIndex].sensorOrientation;
      final hands = _handPlugin!.detect(image, sensorOrientation);

      if (hands.isNotEmpty) {
        final lm = hands.first.landmarks; // List<Landmark> with 21 points
        final box = _boundingBoxFromLandmarks(lm);
        final rawGesture = _classifyGesture(lm);
        _addToBufferAndUpdate(rawGesture, box);
      } else {
        _gestureBuffer.clear();
        if (state.handBoundingBox != null ||
            state.gesture != RecognizedGesture.none) {
          _setGestureAndBox(RecognizedGesture.none, null);
        }
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Buffer / debounce helper
  // ---------------------------------------------------------------------------
  void _addToBufferAndUpdate(RecognizedGesture raw, Rect? box) {
    _gestureBuffer.add(raw);
    if (_gestureBuffer.length > _bufferSize) _gestureBuffer.removeAt(0);

    RecognizedGesture debounced = state.gesture;
    if (_gestureBuffer.length == _bufferSize) {
      final counts = <RecognizedGesture, int>{};
      for (final g in _gestureBuffer) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
      int maxCount = 0;
      RecognizedGesture top = RecognizedGesture.none;
      for (final e in counts.entries) {
        if (e.value > maxCount) {
          maxCount = e.value;
          top = e.key;
        }
      }
      if (maxCount >= 2) debounced = top;
    }
    _setGestureAndBox(debounced, box);
  }

  // ---------------------------------------------------------------------------
  // Bounding box from normalized landmarks
  // ---------------------------------------------------------------------------
  Rect _boundingBoxFromLandmarks(List<Landmark> lm) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final l in lm) {
      if (l.x < minX) minX = l.x;
      if (l.y < minY) minY = l.y;
      if (l.x > maxX) maxX = l.x;
      if (l.y > maxY) maxY = l.y;
    }
    // Add 10% padding (coords are 0.0–1.0)
    const pad = 0.05;
    return Rect.fromLTRB(
      (minX - pad).clamp(0.0, 1.0),
      (minY - pad).clamp(0.0, 1.0),
      (maxX + pad).clamp(0.0, 1.0),
      (maxY + pad).clamp(0.0, 1.0),
    );
  }

  // ---------------------------------------------------------------------------
  // Gesture classification using 21 MediaPipe landmarks
  // ---------------------------------------------------------------------------
  // All coordinates are normalized (0.0–1.0). Y increases downward.
  // A finger is "extended" when its TIP.y < PIP.y (tip is above the knuckle).
  RecognizedGesture _classifyGesture(List<Landmark> lm) {
    if (lm.length < 21) return RecognizedGesture.none;

    // Convenience accessors
    final wrist      = lm[_wrist];
    final thumbTip   = lm[_thumbTip];
    final thumbMcp   = lm[_thumbMcp];
    final indexMcp   = lm[_indexMcp];
    final indexPip   = lm[_indexPip];
    final indexTip   = lm[_indexTip];
    final middleMcp  = lm[9];
    final middlePip  = lm[_middlePip];
    final middleTip  = lm[_middleTip];
    final ringMcp    = lm[13];
    final ringPip    = lm[_ringPip];
    final ringTip    = lm[_ringTip];
    final pinkyMcp   = lm[_pinkyMcp];
    final pinkyPip   = lm[_pinkyPip];
    final pinkyTip   = lm[_pinkyTip];

    // ── Distance helper ─────────────────────────────────────────────────────
    double dist(Landmark a, Landmark b) =>
        math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

    // Scale reference = palm height (wrist → index MCP)
    final palmH = dist(indexMcp, wrist).clamp(0.05, 1.0);

    // ── Finger extension (tip above PIP joint) ──────────────────────────────
    final indexUp  = indexTip.y  < indexPip.y;
    final middleUp = middleTip.y < middlePip.y;
    final ringUp   = ringTip.y   < ringPip.y;
    final pinkyUp  = pinkyTip.y  < pinkyPip.y;

    // ── Thumb helpers ────────────────────────────────────────────────────────
    // Thumb "open": tip is far from its own MCP
    final thumbLen  = dist(thumbTip, thumbMcp);
    final thumbOpen = thumbLen > palmH * 0.55;

    // Thumb direction relative to its MCP (scale-invariant):
    //   Up   → tip is significantly above (lower Y) than MCP
    //   Down → tip is significantly below (higher Y) than MCP
    final thumbPointsUp   = thumbTip.y < thumbMcp.y - palmH * 0.25;
    final thumbPointsDown = thumbTip.y > thumbMcp.y + palmH * 0.25;

    // Thumb pointing sideways (away from index MCP in X)
    final thumbSideways = (thumbTip.x - indexMcp.x).abs() > palmH * 0.35;

    // Thumb resting beside curled fist (ASL A): tip close to index MCP
    final thumbBesideFist = dist(thumbTip, indexMcp) < palmH * 0.75;

    // Pinky length-based extension (more reliable for diagonal poses)
    final pinkyLen     = dist(pinkyTip, pinkyMcp);
    final pinkyLongUp  = pinkyLen > palmH * 0.50;

    // ── Gesture rules — ordered from MOST specific to LEAST ─────────────────

    // ✌️ Peace: index + middle up, ring + pinky curled
    if (indexUp && middleUp && !ringUp && !pinkyUp) {
      return RecognizedGesture.peace;
    }

    // 👋 Goodbye: all four fingers extended (open flat hand)
    if (indexUp && middleUp && ringUp && pinkyUp) {
      return RecognizedGesture.goodbye;
    }

    // 🤙 Letter Y — thumb OUT sideways + pinky UP, others curled
    // Check BEFORE Good Job so the open-thumb signal doesn't get swallowed.
    if (thumbOpen && thumbSideways && pinkyLongUp &&
        !indexUp && !middleUp && !ringUp) {
      return RecognizedGesture.letterY;
    }

    // 🖖 Letter L — thumb OUT sideways + index UP, others curled
    // Must be BEFORE Good Job (which also has thumb open + others curled).
    if (thumbOpen && thumbSideways && indexUp &&
        !middleUp && !ringUp && !pinkyUp) {
      return RecognizedGesture.letterL;
    }

    // 👍 Good Job — thumb points UP, all fingers curled
    if (thumbPointsUp && !indexUp && !middleUp && !ringUp && !pinkyUp) {
      return RecognizedGesture.goodJob;
    }

    // 👎 Bad — thumb points DOWN, all fingers curled
    if (thumbPointsDown && !indexUp && !middleUp && !ringUp && !pinkyUp) {
      return RecognizedGesture.bad;
    }

    // ☝️ Letter I — only pinky extended, thumb NOT open sideways
    if (!thumbOpen && !indexUp && !middleUp && !ringUp && pinkyLongUp) {
      return RecognizedGesture.letterI;
    }

    // ☝️ Letter D — only index up, others curled
    if (indexUp && !middleUp && !ringUp && !pinkyUp) {
      return RecognizedGesture.letterD;
    }

    // 👊 Letter A — closed fist, thumb rests beside index knuckle (not tucked under)
    if (!indexUp && !middleUp && !ringUp && !pinkyUp && thumbBesideFist) {
      return RecognizedGesture.letterA;
    }

    // 🤏 Letter C — fingers partially curled into a C / arc shape.
    // Each fingertip sits BELOW its PIP joint (partially curled past straight)
    // but ABOVE its MCP (not a tight fist). Thumb must be to the side.
    final indexC  = indexTip.y  > indexPip.y  && indexTip.y  < indexMcp.y;
    final middleC = middleTip.y > middlePip.y && middleTip.y < middleMcp.y;
    final ringC   = ringTip.y   > ringPip.y   && ringTip.y   < ringMcp.y;
    final thumbC  = thumbSideways || thumbOpen;
    if (indexC && middleC && ringC && thumbC) {
      return RecognizedGesture.letterC;
    }

    return RecognizedGesture.none;
  }

  // ---------------------------------------------------------------------------
  // State update + TTS
  // ---------------------------------------------------------------------------
  void _setGestureAndBox(RecognizedGesture gesture, Rect? box) {
    if (_disposed) return;

    final isNewGesture =
        gesture != RecognizedGesture.none && gesture != state.gesture;

    state = state.copyWith(
      gesture: gesture,
      gestureText: gesture != RecognizedGesture.none
          ? gesture.englishText
          : state.gestureText,
      handBoundingBox: box,
      clearBoundingBox: box == null,
    );

    if (isNewGesture) {
      debugPrint('👐 Gesture: ${gesture.englishText}');
      final now = DateTime.now();
      if (now.difference(_lastSpokenTime).inSeconds >= 2) {
        speakGesture();
        _lastSpokenTime = now;
      }

      _subtitleTimer?.cancel();
      _subtitleTimer = Timer(const Duration(seconds: 3), () {
        if (!_disposed) {
          state = state.copyWith(
            gesture: RecognizedGesture.none,
            gestureText: '',
          );
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Camera toggle
  // ---------------------------------------------------------------------------
  Future<void> toggleCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    if (_cameras.isEmpty) return;
    final newIndex = (state.cameraIndex + 1) % _cameras.length;
    state = state.copyWith(cameraIndex: newIndex);
    await _initCamera(newIndex);
  }

  Future<void> speakGesture() async {
    if (state.gestureText.isNotEmpty) {
      await _tts?.speak(state.gestureText);
    }
  }
}

final signRecognitionProvider =
    AutoDisposeNotifierProvider<SignRecognitionNotifier, SignRecognitionState>(
      SignRecognitionNotifier.new,
    );
