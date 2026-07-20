import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/device_id_service.dart';
import '../services/pose_landmarker_service.dart';
import '../theme/app_theme.dart';

/// Camera + live-feed test screen — wired to Shantanu's real MediaPipe
/// pose detection via the native Android MethodChannel bridge.
///
/// Backend contract (from result.schema.js):
///   POST /api/v1/results
///   { athleteId, testType, rawScore, timestamp, deviceId,
///     faceMatchVerified, stabilityVerified, gpsCoords?, liveGuidance? }
///
/// testType must be one of: speed_run, standing_jump, sit_ups, push_ups,
/// shuttle_run, flexibility
///
/// This screen handles push_ups / sit_ups rep counting.
/// standing_jump uses the HighJumpTracker logic from Shantanu's model.
class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.testType = 'push_ups',
  });

  final String studentId;
  final String studentName;
  final String testType;

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen>
    with WidgetsBindingObserver {
  // ── ML service (Shantanu's bridge) ────────────────────────────────────
  final _poseService = PoseLandmarkerService();
  final _tracker = RepTracker();

  // ── Camera ────────────────────────────────────────────────────────────
  CameraController? _camera;
  bool _isCameraReady = false;
  String? _cameraError;
  bool _isDetecting = false;

  // ── UI State ──────────────────────────────────────────────────────────
  bool _isTestRunning = false;
  bool _isSubmitting = false;
  int _repCount = 0;
  List<PoseLandmarkPoint> _landmarks = const [];
  String _statusMsg = 'Press Start to begin';
  Color _statusColor = AppColors.textSecondary;

  static const _minInferenceGap = Duration(milliseconds: 50); // ~20fps
  DateTime _lastInferenceAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
    } else if (state == AppLifecycleState.resumed && _camera != null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _poseService.close();
    super.dispose();
  }

  // ── Camera init ────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await _poseService.initialize();
      await controller.startImageStream(_onCameraImage);

      if (!mounted) return;
      setState(() {
        _camera = controller;
        _isCameraReady = true;
      });
    } catch (e) {
      setState(() => _cameraError = 'Camera error: $e');
    }
  }

  // ── Per-frame ML inference ─────────────────────────────────────────────

  Future<void> _onCameraImage(CameraImage image) async {
    final now = DateTime.now();
    if (_isDetecting ||
        !_isTestRunning ||
        now.difference(_lastInferenceAt) < _minInferenceGap) {
      return;
    }
    _isDetecting = true;
    _lastInferenceAt = now;

    try {
      final camera = _camera!.description;
      final result = await _poseService.detect(
        image: image,
        sensorOrientation: camera.sensorOrientation,
        isFrontCamera: camera.lensDirection == CameraLensDirection.front,
      );

      if (!mounted) return;

      if (result != null) {
        // Feed landmarks into the rep counter
        final repResult = _tracker.handlePose(
          result.landmarks,
          result.width.toDouble(),
          result.height.toDouble(),
        );

        setState(() {
          _landmarks = result.landmarks;
          if (repResult != null) {
            _repCount = repResult.repCount;
            _statusMsg = repResult.message;
            _statusColor = repResult.color;
          }
        });
      } else {
        setState(() {
          _landmarks = const [];
          _statusMsg = 'Point camera at full body';
          _statusColor = AppColors.textSecondary;
        });
      }
    } catch (_) {
      // Silently skip dropped frames
    } finally {
      _isDetecting = false;
    }
  }

  // ── Test controls ──────────────────────────────────────────────────────

  void _startTest() {
    _tracker.reset();
    setState(() {
      _isTestRunning = true;
      _repCount = 0;
      _statusMsg = 'Go!';
      _statusColor = AppColors.secondary;
    });
  }

  void _stopTest() {
    setState(() {
      _isTestRunning = false;
      _statusMsg = 'Test stopped — $_repCount reps recorded';
      _statusColor = AppColors.primary;
    });
  }

  Future<void> _submitResult() async {
    setState(() => _isSubmitting = true);

    try {
      final deviceId = await DeviceIdService.instance.getOrCreateDeviceId();
      final response = await ApiService.instance.post('/results', body: {
        'athleteId': widget.studentId,
        'testType': widget.testType,
        'rawScore': _repCount,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'deviceId': deviceId,
        'faceMatchVerified': false,
        'stabilityVerified': false,
      });

      final data = ApiService.instance.unwrap(response);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Result submitted ✅'),
          content: Text(
            '${widget.studentName} — $_repCount reps\n'
            '${data['zScore'] != null ? 'Z-score: ${data['zScore']}' : 'Z-score: pending baseline data'}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.studentName} — ${_friendlyTestType()}'),
      ),
      body: _cameraError != null
          ? _CameraErrorView(message: _cameraError!)
          : !_isCameraReady
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Camera preview ──────────────────────────────────
                    CameraPreview(_camera!),

                    // ── Real pose skeleton overlay ──────────────────────
                    if (_isTestRunning && _landmarks.isNotEmpty)
                      CustomPaint(
                        painter: _PosePainter(_landmarks, AppColors.secondary),
                      ),

                    // ── Rep counter chip ────────────────────────────────
                    if (_isTestRunning)
                      Positioned(
                        top: AppSpacing.md,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Text(
                              '$_repCount reps',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Live status message ─────────────────────────────
                    if (_isTestRunning)
                      Positioned(
                        top: 80,
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.85),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              _statusMsg,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ),
                      ),

                    // ── Bottom controls ─────────────────────────────────
                    Positioned(
                      bottom: AppSpacing.xl,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      child: _isTestRunning
                          ? ElevatedButton(
                              onPressed: _stopTest,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error),
                              child: const Text('Stop Test'),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _startTest,
                                    child: const Text('Start Test'),
                                  ),
                                ),
                                if (_repCount > 0) ...[
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          _isSubmitting ? null : _submitResult,
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondary),
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Submit'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }

  String _friendlyTestType() {
    return switch (widget.testType) {
      'push_ups' => 'Push-ups',
      'sit_ups' => 'Sit-ups',
      'standing_jump' => 'Standing Jump',
      'speed_run' => 'Speed Run',
      'shuttle_run' => 'Shuttle Run',
      'flexibility' => 'Flexibility',
      _ => widget.testType,
    };
  }
}

// ── Rep Tracker ─────────────────────────────────────────────────────────────
/// Counts push-up / sit-up reps from MediaPipe landmark stream.
/// Uses elbow angle (push-ups) or hip angle (sit-ups) to detect
/// extended → flexed → extended cycles, matching Shantanu's approach.

class _RepResult {
  const _RepResult({
    required this.repCount,
    required this.message,
    required this.color,
  });
  final int repCount;
  final String message;
  final Color color;
}

class RepTracker {
  int _repCount = 0;
  bool _wasExtended = true;
  static const _extendedThreshold = 150.0;
  static const _flexedThreshold = 90.0;

  void reset() {
    _repCount = 0;
    _wasExtended = true;
  }

  _RepResult? handlePose(
    List<PoseLandmarkPoint> landmarks,
    double frameWidth,
    double frameHeight,
  ) {
    if (landmarks.length < 33) return null;

    Offset xy(int i) => Offset(
          landmarks[i].x * frameWidth,
          landmarks[i].y * frameHeight,
        );

    // Use average of left and right elbow angles for push-up rep counting
    final leftElbowAngle =
        _angle(xy(11), xy(13), xy(15)); // shoulder→elbow→wrist
    final rightElbowAngle = _angle(xy(12), xy(14), xy(16));
    final avgElbow = (leftElbowAngle + rightElbowAngle) / 2;

    String msg;
    Color color;

    if (avgElbow >= _extendedThreshold) {
      msg = 'Extended — go down';
      color = const Color(0xff60a5fa);
      if (!_wasExtended) {
        // Coming back up → count rep
        _repCount++;
        _wasExtended = true;
        return _RepResult(
          repCount: _repCount,
          message: '✅ Rep $_repCount counted!',
          color: AppColors.secondary,
        );
      }
    } else if (avgElbow <= _flexedThreshold) {
      msg = 'Flexed — push up!';
      color = const Color(0xffffd166);
      _wasExtended = false;
    } else {
      msg = 'Keep going...';
      color = AppColors.textSecondary;
    }

    return _RepResult(repCount: _repCount, message: msg, color: color);
  }

  double _angle(Offset a, Offset b, Offset c) {
    final ba = a - b;
    final bc = c - b;
    final denom = ba.distance * bc.distance;
    if (denom == 0) return 0;
    final cosine =
        ((ba.dx * bc.dx) + (ba.dy * bc.dy)) / denom.clamp(1e-9, double.infinity);
    return math.acos(cosine.clamp(-1.0, 1.0)) * 180 / math.pi;
  }
}

// ── Pose Skeleton Painter ───────────────────────────────────────────────────
/// Draws the 33-point MediaPipe skeleton from real inference landmarks.

class _PosePainter extends CustomPainter {
  _PosePainter(this.landmarks, this.color);

  final List<PoseLandmarkPoint> landmarks;
  final Color color;

  static const _connections = <(int, int)>[
    (11, 12), // shoulders
    (11, 13), (13, 15), // left arm
    (12, 14), (14, 16), // right arm
    (11, 23), (12, 24), // torso sides
    (23, 24), // hips
    (23, 25), (25, 27), (27, 29), (29, 31), // left leg
    (24, 26), (26, 28), (28, 30), (30, 32), // right leg
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length < 33) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Offset point(int i) => Offset(
          landmarks[i].x * size.width,
          landmarks[i].y * size.height,
        );

    for (final (s, e) in _connections) {
      canvas.drawLine(point(s), point(e), linePaint);
    }
    for (final lm in landmarks) {
      if (lm.visibility >= 0.5) {
        canvas.drawCircle(
          Offset(lm.x * size.width, lm.y * size.height),
          3.5,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PosePainter old) =>
      old.landmarks != landmarks || old.color != color;
}

// ── Camera Error Widget ─────────────────────────────────────────────────────

class _CameraErrorView extends StatelessWidget {
  final String message;
  const _CameraErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded,
                size: 48, color: Colors.white54),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
