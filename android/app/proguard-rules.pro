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
