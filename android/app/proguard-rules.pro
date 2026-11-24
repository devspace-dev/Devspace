# DevSpace ProGuard / R8 Rules for Release Builds

# Flutter Engine & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings

# Firebase & Crashlytics
-keepattributes *Annotation*,SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keepclassmembers class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**
-dontwarn com.google.firebase.**

# SafeDevice & RootBeer (JNI and reflection for device integrity checks)
-keep class com.scottyab.rootbeer.** { *; }
-keepclassmembers class com.scottyab.rootbeer.** { *; }
-keep class com.lahad.safe_device.** { *; }
-keepclassmembers class com.lahad.safe_device.** { *; }

# Networking, OkHttp, and Java 8+ Desugaring
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class j$.** { *; }
-dontwarn j$.**
