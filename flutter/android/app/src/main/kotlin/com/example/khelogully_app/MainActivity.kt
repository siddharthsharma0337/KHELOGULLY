package com.example.khelogully_app

import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private var landmarker: PoseLandmarker? = null
    private var lastTimestampMs = 0L
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "khelogully/pose_landmarker"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    try {
                        initializeLandmarker(call.argument<String>("asset"))
                        result.success(null)
                    } catch (error: Throwable) {
                        result.error("INIT_FAILED", error.message, null)
                    }
                }
                "detect" -> {
                    val args = call.arguments as Map<*, *>
                    executor.execute {
                        try {
                            val detectionResult = detect(args)
                            mainHandler.post {
                                result.success(detectionResult)
                            }
                        } catch (error: Throwable) {
                            mainHandler.post {
                                result.error("DETECT_FAILED", error.message, null)
                            }
                        }
                    }
                }
                "close" -> {
                    executor.execute {
                        landmarker?.close()
                        landmarker = null
                        mainHandler.post {
                            result.success(null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initializeLandmarker(assetPath: String?) {
        if (landmarker != null) {
            return
        }
        val flutterAssetPath = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(
            assetPath ?: "assets/pose_landmarker_lite.task"
        )
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(flutterAssetPath)
            .setDelegate(Delegate.GPU) // GPU Acceleration
            .build()
        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.VIDEO)
            .setMinPoseDetectionConfidence(0.7f)
            .setMinTrackingConfidence(0.7f)
            .build()
        landmarker = PoseLandmarker.createFromOptions(this, options)
    }

    private fun detect(args: Map<*, *>): Map<String, Any> {
        val bytes = args["bytes"] as ByteArray
        val width = args["width"] as Int
        val height = args["height"] as Int
        val sensorOrientation = args["sensorOrientation"] as Int
        val isFrontCamera = args["isFrontCamera"] as Boolean

        val bitmap = grayscaleToBitmap(bytes, width, height)
            .rotate(sensorOrientation.toFloat(), isFrontCamera)

        val mpImage = BitmapImageBuilder(bitmap).build()
        val timestampMs = max(System.currentTimeMillis(), lastTimestampMs + 1)
        lastTimestampMs = timestampMs
        val detection = landmarker?.detectForVideo(mpImage, timestampMs)
        val pose = detection?.landmarks()?.firstOrNull().orEmpty()
        return mapOf(
            "width" to bitmap.width,
            "height" to bitmap.height,
            "landmarks" to pose.map { landmark ->
                mapOf(
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z(),
                    "visibility" to landmark.visibility().orElse(0f)
                )
            }
        )
    }

    private fun grayscaleToBitmap(bytes: ByteArray, width: Int, height: Int): Bitmap {
        val pixels = IntArray(width * height)
        for (i in pixels.indices) {
            val g = bytes[i].toInt() and 0xff
            pixels[i] = -0x1000000 or (g shl 16) or (g shl 8) or g
        }
        return Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
    }

    private fun Bitmap.rotate(degrees: Float, mirror: Boolean): Bitmap {
        val matrix = Matrix().apply {
            postRotate(degrees)
            if (mirror) {
                postScale(-1f, 1f)
            }
        }
        return Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)
    }
}
