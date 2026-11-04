# Revue Codex — identité visuelle r1

Verdict : **NOT READY** (1 MAJOR, 1 MINOR). Rapport recopié par la lane : Codex ne peut pas écrire de fichier.

## MAJOR — icône adaptive Android rembourrée deux fois
`scripts/render_logo.py` cadre déjà le dessin dans la zone sûre de 66 dp, et `flutter_launcher_icons` ajoute son inset par défaut de 16 % (`mipmap-anydpi-v26/ic_launcher.xml`) : le dessin ne fait plus qu'environ 43 dp sur 108.
Correction proposée : `adaptive_icon_foreground_inset: 0` dans la config `flutter_launcher_icons` (vérifier que la clé existe dans la version installée ; sinon agrandir seulement la source du foreground), régénérer, vérifier le ratio dans `ic_launcher.xml` et les PNG de foreground générés.

## MINOR — `fullscreen: true` sous `android_12` ignoré
`flutter_native_splash` ne lit pas `fullscreen` dans la section `android_12` : clé morte et trompeuse.
Correction proposée : la retirer (garder le comportement actuel, non plein écran).
