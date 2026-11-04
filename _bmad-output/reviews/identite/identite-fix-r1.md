# Corrections — identité visuelle r1

| Finding | Décision | Preuve |
|---|---|---|
| MAJOR — foreground adaptive rembourré deux fois | **Corrigé.** La clé existe dans `flutter_launcher_icons` 0.14.4 (`lib/config/config.dart:137`, utilisée dans `lib/android.dart:201`). Ajout de `adaptive_icon_foreground_inset: 0`, régénération. | `pubspec.yaml:46` ; `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml:7` → `android:inset="0%"`. Mesure du dessin dans les foreground générés : 63,8 dp de diamètre sur 108 (xxxhdpi 432 px), 63,2 dp (mdpi) — dans le cercle sûr de 66 dp. |
| MINOR — `fullscreen: true` sous `android_12` | **Corrigé.** Clé retirée. | `pubspec.yaml` section `android_12` (2 clés : `color`, `image`). `flutter_native_splash:create` relancé : aucune ressource modifiée, ce qui confirme que la clé était ignorée. |
