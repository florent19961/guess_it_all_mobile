# Règles ProGuard pour Guess It All
# Flutter recommande de garder ces règles minimales

# Conserver les classes Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Conserver les annotations
-keepattributes *Annotation*

# Règles pour audioplayers (lecture audio)
-keep class xyz.luan.audioplayers.** { *; }

# Règles pour shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Règles pour Play Core (deferred components) - classes non utilisées mais référencées par Flutter
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
