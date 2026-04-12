import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/gesture.dart';

class SignRecognitionNotifier extends StateNotifier<SignRecognitionState> {
  SignRecognitionNotifier() : super(const SignRecognitionState()) {
    init();
  }

  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.stream, // Real-time
    ),
  );
  FlutterTts? _tts;
  late final StreamSubscription<CameraImage> _subscription;

  final List<CameraDescription> _cameras = [];
  bool _isDetecting = false;

  Future<void> init() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.8);
      await _tts!.setVolume(1.0);

      final cameras = await availableCameras();
      _cameras.addAll(cameras);
      state = state.copyWith(cameras: _cameras);
      
      await _initCamera(state.cameraIndex);
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
    if (_isDetecting || !_cameraController!.value.isInitialized) return;
    _isDetecting = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isNotEmpty) {
      final gesture = _classifyGesture(poses.first);
      if (gesture != RecognizedGesture.none) {
        state = state.copyWith(
          gesture: gesture,
          gestureText: gesture.englishText,
        );
      }
    }

    _isDetecting = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // Simplified for Android/iOS - use WriteBuffer for full impl
    // For brevity, implement basic InputImage conversion
    return null; // Placeholder - full impl needed
  }

  RecognizedGesture _classifyGesture(Pose pose) {
    final landmarks = pose.landmarks;
    final rightThumb = landmarks[PoseLandmarkType.rightThumb];
    final rightIndex = landmarks[PoseLandmarkType.rightIndex];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    if (rightIndex.y! < rightWrist.y! && rightThumb.y! < rightWrist.y!) {
      // Thumbs up approximation
      return RecognizedGesture.thumbsUp;
    }
    // Add more classifications based on landmarks...
    return RecognizedGesture.none;
  }

  Future<void> toggleCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    final newIndex = (state.cameraIndex + 1) % _cameras.length;
    await _initCamera(newIndex);
    state = state.copyWith(cameraIndex: newIndex);
  }

  Future<void> speakGesture() async {
    if (state.gestureText.isNotEmpty) {
      await _tts!.speak(state.gestureText);
    }
  }

// dispose handled by autoDispose
}

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

final signRecognitionProvider = StateNotifierProvider.autoDispose<SignRecognitionNotifier, SignRecognitionState>((ref) {
  return SignRecognitionNotifier();
});

