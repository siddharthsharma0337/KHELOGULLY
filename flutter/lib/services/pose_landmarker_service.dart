import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Dart-side MethodChannel bridge to Shantanu's native Android MediaPipe
/// PoseLandmarker implementation in MainActivity.kt.
///
/// Channel: 'khelogully/pose_landmarker'
/// Methods: initialize, detect, close
class PoseLandmarkerService {
  static const _channel = MethodChannel('khelogully/pose_landmarker');

  /// Call once after camera is ready. Loads the .task model on the native side.
  Future<void> initialize() {
    return _channel.invokeMethod<void>('initialize', {
      'asset': 'assets/pose_landmarker_lite.task',
    });
  }

  /// Feed each [CameraImage] frame through the native MediaPipe model.
  /// Returns a [PoseResult] with 33 landmarks, or null if no person detected.
  Future<PoseResult?> detect({
    required CameraImage image,
    required int sensorOrientation,
    required bool isFrontCamera,
  }) async {
    // Downsample the Y-plane (grayscale luminance) by 4x before sending to
    // native — reduces MethodChannel payload from ~3MB to ~200KB per frame.
    const scale = 4;
    final yPlane = image.planes[0];
    final yBytes = yPlane.bytes;
    final bytesPerRow = yPlane.bytesPerRow;
    final width = image.width;
    final height = image.height;

    final outWidth = width ~/ scale;
    final outHeight = height ~/ scale;
    final downsampledBytes = Uint8List(outWidth * outHeight);

    var outIdx = 0;
    for (var j = 0; j < outHeight; j++) {
      final srcY = j * scale;
      final rowOffset = srcY * bytesPerRow;
      for (var i = 0; i < outWidth; i++) {
        final srcX = i * scale;
        downsampledBytes[outIdx++] = yBytes[rowOffset + srcX];
      }
    }

    final response = await _channel.invokeMapMethod<String, Object?>('detect', {
      'bytes': downsampledBytes,
      'width': outWidth,
      'height': outHeight,
      'sensorOrientation': sensorOrientation,
      'isFrontCamera': isFrontCamera,
    });

    if (response == null) return null;

    final landmarks = (response['landmarks'] as List<Object?>? ?? [])
        .cast<Map<Object?, Object?>>()
        .map(PoseLandmarkPoint.fromMap)
        .toList(growable: false);

    if (landmarks.isEmpty) return null;

    return PoseResult(
      landmarks: landmarks,
      width: (response['width'] as num).toInt(),
      height: (response['height'] as num).toInt(),
    );
  }

  /// Release the native MediaPipe landmarker. Call in [dispose].
  Future<void> close() => _channel.invokeMethod<void>('close');
}

class PoseResult {
  const PoseResult({
    required this.landmarks,
    required this.width,
    required this.height,
  });

  final List<PoseLandmarkPoint> landmarks;
  final int width;
  final int height;
}

class PoseLandmarkPoint {
  const PoseLandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  factory PoseLandmarkPoint.fromMap(Map<Object?, Object?> map) {
    return PoseLandmarkPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
      visibility: (map['visibility'] as num?)?.toDouble() ?? 0,
    );
  }

  final double x;
  final double y;
  final double z;
  final double visibility;
}
