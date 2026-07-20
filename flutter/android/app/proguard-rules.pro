# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# MediaPipe
-keep class com.google.mediapipe.** { *; }

# Suppress warnings for optional classes not bundled
-dontwarn com.google.android.play.core.**
-dontwarn com.google.mediapipe.proto.**
