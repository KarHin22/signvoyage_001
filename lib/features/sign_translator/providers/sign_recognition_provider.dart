import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/gesture.dart';

class SignRecognitionState {
  const SignRecognitionState({
    this.gesture = RecognizedGesture.none,
    this.gestureText = '',
    this.cameraIndex = 1, // Default front
    this.isInitialized = false,
    this.cameras = const [],
  });

  final RecognizedGesture gesture;
  final String gestureText;
  final int cameraIndex;
  final bool isInitialized;
  final List<CameraDescription> cameras;

  SignRecognitionState copyWith({
    RecognizedGesture? gesture,
    String? gestureText,
    int? cameraIndex,
    bool? isInitialized,
    List<CameraDescription>? cameras,
  }) {
    return SignRecognitionState(
      gesture: gesture ?? this.gesture,
      gestureText: gestureText ?? this.gestureText,
      cameraIndex: cameraIndex ?? this.cameraIndex,
      isInitialized: isInitialized ?? this.isInitialized,
      cameras: cameras ?? this.cameras,
    );
  }
}

class SignRecognitionNotifier extends AutoDisposeNotifier<SignRecognitionState> {
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;
  Timer? _subtitleTimer;

  bool _disposed = false;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base, // Real-time
    ),
  );
  FlutterTts? _tts;

  final List<CameraDescription> _cameras = [];
  bool _isDetecting = false;

  @override
  SignRecognitionState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _subtitleTimer?.cancel();
      _cameraController?.dispose();
      _poseDetector.close();
    });

    Future.microtask(() => _init());
    return const SignRecognitionState();
  }

  Future<void> _init() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.8);
      await _tts!.setVolume(1.0);

      final cameras = await availableCameras();
      _cameras.addAll(cameras);

      int initialIndex = state.cameraIndex;
      if (initialIndex >= _cameras.length) {
        initialIndex = 0;
      }
      
      state = state.copyWith(cameras: _cameras, cameraIndex: initialIndex);
      
      if (_cameras.isNotEmpty) {
        await _initCamera(state.cameraIndex);
      }
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }

  Future<void> _initCamera(int cameraIndex) async {
    final camera = _cameras[cameraIndex];
    _cameraController = CameraController(camera, ResolutionPreset.medium);

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_processImage);

    state = state.copyWith(isInitialized: true);
  }

  void _processImage(CameraImage image) async {
    if (_disposed || _isDetecting || _cameraController?.value.isInitialized != true) return;
    _isDetecting = true;

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await Future.delayed(const Duration(seconds: 2));
      if (_disposed) return;

      final random = math.Random().nextInt(10);
      RecognizedGesture mockGesture = RecognizedGesture.none;
      if (random == 0) { mockGesture = RecognizedGesture.thumbsUp; }
      else if (random == 1) { mockGesture = RecognizedGesture.yeah; }
      else if (random == 2) { mockGesture = RecognizedGesture.ok; }
      else if (random == 3) { mockGesture = RecognizedGesture.peace; }

      if (mockGesture != RecognizedGesture.none && mockGesture != state.gesture) {
        _setGesture(mockGesture);
      }
      _isDetecting = false;
      return;
    }

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isNotEmpty) {
      final gesture = _classifyGesture(poses.first);
      if (gesture != RecognizedGesture.none && gesture != state.gesture) {
        _setGesture(gesture);
      }
    }

    _isDetecting = false;
  }

  void _setGesture(RecognizedGesture gesture) {
    if (_disposed) return;
    state = state.copyWith(
      gesture: gesture,
      gestureText: gesture.englishText,
    );
    speakGesture();

    _subtitleTimer?.cancel();
    _subtitleTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) {
        state = state.copyWith(gesture: RecognizedGesture.none, gestureText: '');
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameras.isEmpty) return null;
    final camera = _cameras[state.cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = sensorOrientation;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + 0) % 360;
      } else {
        rotationCompensation = (sensorOrientation - 0 + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21 && format != InputImageFormat.yuv_420_888) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  RecognizedGesture _classifyGesture(Pose pose) {
    final landmarks = pose.landmarks;
    final rightThumb = landmarks[PoseLandmarkType.rightThumb];
    final rightIndex = landmarks[PoseLandmarkType.rightIndex];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    if (rightThumb != null && rightIndex != null && rightWrist != null) {
      if (rightIndex.y < rightWrist.y && rightThumb.y < rightWrist.y) {
        // Thumbs up approximation
        return RecognizedGesture.thumbsUp;
      }
    }
    // Add more classifications based on landmarks...
    return RecognizedGesture.none;
  }

  Future<void> toggleCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    if (_cameras.isEmpty) return;
    final newIndex = (state.cameraIndex + 1) % _cameras.length;
    await _initCamera(newIndex);
    state = state.copyWith(cameraIndex: newIndex);
  }

  Future<void> speakGesture() async {
    if (state.gestureText.isNotEmpty) {
      await _tts?.speak(state.gestureText);
    }
  }
}

final signRecognitionProvider = AutoDisposeNotifierProvider<SignRecognitionNotifier, SignRecognitionState>(
  SignRecognitionNotifier.new,
);
