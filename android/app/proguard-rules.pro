# Proguard rules untuk NextPSA Flutter App

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ✅ Keep Google Play Core classes (untuk split installs)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Keep Dart/Flutter classes yang diperlukan
-keep class com.google.dart.** { *; }

# Keep classes dengan Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes yang extend dari Android classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep model classes (optional, bisa disesuaikan)
-keep class com.example.** { *; }
-keep class id.pintarbisnis.** { *; }

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Firebase/Crashlytics (jika digunakan)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
