# Prompt de revue — identité visuelle r1 (tier STANDARD : thème + outillage + ressources natives)

Lire `identite-patch-r1.diff` (diff sur la merge-base avec `origin/main`, **images PNG exclues**, listées plus bas). Ne pas lancer `git diff`. Revue en lecture seule : écrire le rapport dans `identite-review-r1.md`, à côté de ce fichier. Les PNG peuvent être ouverts directement dans le worktree `/home/florent19961/guess-it-all-identite` (branche `feat/identite-visuelle`).

## Objectif (choix validés par Florent le 2026-11-04)
1. **Icône d'app + splash natif = logo « Bulle chrono »**, uniquement le duo de marque rose `#F19B9B` + teal `#7DD3C0` sur navy `#2B3848` (fond de l'accueil). Le fond icône/splash passe de `#1a2744` à `#2B3848` partout dans la config `flutter_launcher_icons` / `flutter_native_splash` du `pubspec.yaml`.
2. **Couleurs d'équipe 3 et 4 → « Pastels accordés »** : `team3` `#A78BFA` → `#B6A6F5` (lavande), `team4` `#FBBF24` → `#F2D47C` (jaune beurre). Équipes 1/2 inchangées. `AppColors.warning` reste `#FBBF24` (but : l'équipe 4 ne ressemble plus à une alerte).
3. **Hors périmètre** : aucune animation de démarrage (décision en attente).

## Ce qui a été fait
- `scripts/render_logo.py` (Pillow, rendu 4x puis LANCZOS) reproduit le SVG validé dans un canevas 1024 : fond `#2B3848` ; piste d'anneau r=345, trait 58, teal 22 % ; arc teal opaque 270° horaire du haut (512,167) à la gauche (167,512), bouts ronds ; point r=44 en (512,167) ; bulle rose r=215 en (512,490) + queue triangle (475,632)(368,748)(377,615) avec contour arrondi 18 px ; « ? » blanc Bangers 300 px, centré x=512, ligne de base y=600, rotation -6° autour de (512,600). Rayon du dessin mesuré : 388,6 px.
- Sorties `visuals/` :
  - `logo_bulle_chrono.png` 1024 **RGB sans alpha** (icône iOS + icône Android legacy) ;
  - `logo_bulle_chrono_foreground.png` 1024 transparent, dessin ramené dans 97 % du cercle sûr 66/108 dp (adaptive icon) ;
  - `logo_bulle_chrono_splash.png` 768 transparent (image 4x ≈ 192 pt/dp, iOS + Android < 12) ;
  - `logo_bulle_chrono_android12.png` 1152 transparent, dessin dans 97 % du cercle de 768 (doc `flutter_native_splash` 2.4.4, cas « sans fond d'icône »).
- Ressources régénérées : `dart run flutter_launcher_icons` puis `dart run flutter_native_splash:create`.
- `visuals/icone_guess_it_all.png` supprimé : plus aucune référence (grep). Les `.jpg` de `visuals/` (déjà non référencés avant) sont laissés.
- Tests : 0 ajouté, 0 retiré (UI/thème/ressources, aucune zone risquée). `scripts/run-full-suite.sh` vert (226 tests).

## Points à challenger
- `values-v31/styles.xml` et `values-night-v31/styles.xml` **gagnent** `windowSplashScreenBackground` + `windowSplashScreenAnimatedIcon` : sur `main`, ces entrées n'existaient pas (les ressources avaient été générées avant la section `android_12`, ou par une autre version). Effet attendu : sur Android 12+, splash navy + logo au lieu du comportement système par défaut. Est-ce cohérent et sans effet de bord (`windowBackground`, mode nuit) ?
- La clé `fullscreen: true` sous `android_12` (préexistante, non touchée) : est-elle lue à cet endroit par le package ? Sinon c'est du mort préexistant à signaler, pas à corriger ici.
- `LaunchScreen.storyboard` : `LaunchImage` passe de 1024 à 768 (taille de l'image 4x) — cohérent avec le rendu iOS (192 pt) ?

## Questions précises
1. **Deux plateformes** (règle 8) : icône Android (legacy + adaptive) et iOS, splash Android < 12, Android 12+ et iOS — chaque cible pointe-t-elle sur le bon visuel et la bonne couleur `#2B3848` ? Reste-t-il une trace de `#1a2744` côté icône/splash ?
2. **Alpha / zones sûres** : icône iOS sans canal alpha (App Store) ? Foreground adaptive dans le cercle de 66 dp sur 108 ? Image Android 12 dans le cercle de 768 sur 1152 ? Le calcul d'échelle dans `render_logo.py` (`place`, `radius`) est-il juste ?
3. **Couleurs du splash** : fond pré-12 / iOS (`color`) et 12+ (`android_12.color`) identiques ; pas de fond d'icône Android 12 → le visuel 1152 « sans fond » est-il le bon choix ?
4. **Usages des couleurs d'équipe** : `team3`/`team4` utilisés dans `history_screen.dart` (palette) et `transition_screen.dart:501` (team3 à 14 % d'alpha) — rendu acceptable avec les nouvelles teintes ? Un usage de `AppColors.warning` qui voulait dire « équipe 4 », ou une valeur codée en dur `0xFFA78BFA` / `0xFFFBBF24` qui signifie une équipe, a-t-il été oublié ?
5. **Résidus** : référence restante à `icone_guess_it_all.png`, à `#1a2744` (hors `docs/privacy-policy.html`, qui est la charte de la page web et volontairement non touchée) ou aux anciennes couleurs d'équipe ?
6. **Script** : fidélité au SVG (sens de l'arc, rotation du « ? » — SVG `rotate(-6)` = anti-horaire à l'écran = PIL `rotate(+6)`), lisibilité, sur-dimensionnement.

## Format attendu
Findings classés BLOCKER / MAJOR / MINOR / NIT, chacun avec `fichier:ligne`, scénario, correction proposée. Terminer par un verdict READY / NOT READY.

## Fichiers binaires (PNG) modifiés, non inclus dans le diff
- `android/app/src/main/res/drawable-hdpi/android12splash.png`
- `android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png`
- `android/app/src/main/res/drawable-hdpi/splash.png`
- `android/app/src/main/res/drawable-mdpi/android12splash.png`
- `android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png`
- `android/app/src/main/res/drawable-mdpi/splash.png`
- `android/app/src/main/res/drawable-night-hdpi/android12splash.png`
- `android/app/src/main/res/drawable-night-mdpi/android12splash.png`
- `android/app/src/main/res/drawable-night-xhdpi/android12splash.png`
- `android/app/src/main/res/drawable-night-xxhdpi/android12splash.png`
- `android/app/src/main/res/drawable-night-xxxhdpi/android12splash.png`
- `android/app/src/main/res/drawable-v21/background.png`
- `android/app/src/main/res/drawable-xhdpi/android12splash.png`
- `android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png`
- `android/app/src/main/res/drawable-xhdpi/splash.png`
- `android/app/src/main/res/drawable-xxhdpi/android12splash.png`
- `android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png`
- `android/app/src/main/res/drawable-xxhdpi/splash.png`
- `android/app/src/main/res/drawable-xxxhdpi/android12splash.png`
- `android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png`
- `android/app/src/main/res/drawable-xxxhdpi/splash.png`
- `android/app/src/main/res/drawable/background.png`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- `ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`
- `visuals/icone_guess_it_all.png`
- `visuals/logo_bulle_chrono.png`
- `visuals/logo_bulle_chrono_android12.png`
- `visuals/logo_bulle_chrono_foreground.png`
- `visuals/logo_bulle_chrono_splash.png`
