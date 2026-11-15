# SparkQuest Release ProGuard / R8 Keep Rules

-keep class com.sparkquest.sparkquest.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Billing Library
-keep class com.android.billingclient.** { *; }

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep public class * extends com.google.android.gms.ads.mediation.MediationAdapter { *; }

# WebRTC native JNI bindings
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Reactive BLE & Location / Geofencing
-keep class com.signify.hue.flutterreactiveble.** { *; }
-dontwarn com.signify.hue.flutterreactiveble.**

# Flutter deferred components (unused optional Play Core splitcompat/splitinstall classes)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
