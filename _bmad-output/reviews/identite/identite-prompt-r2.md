# Prompt de revue — identité visuelle r2 (tier STANDARD)

Lire `identite-patch-r2.diff` (diff complet sur la merge-base avec `origin/main`, **PNG exclus**, listés en bas ; les `.diff` de revue sont aussi exclus). Ne pas lancer `git diff`. Revue en lecture seule ; la lane recopiera le rapport dans `identite-review-r2.md`. Les PNG et le code peuvent être ouverts dans le worktree `/home/florent19961/guess-it-all-identite` (branche `feat/identite-visuelle`).

Branche rebasée sur `origin/main` après #26 et #27 (#27 a remplacé `shooting_stars.dart` : le fond de l'accueil est maintenant un dégradé `#22304A` → `#2B3848` ; l'intro reste un fond plat `#2B3848`, identique au splash, puis fond vers l'accueil).

Contexte r1 : objectif, décisions et questions dans `identite-prompt-r1.md` ; findings dans `identite-review-r1.md` ; corrections dans `identite-fix-r1.md`.

## 1. Corrections r1 à vérifier
- **MAJOR — double inset du foreground adaptive** : `adaptive_icon_foreground_inset: 0` (`pubspec.yaml`), `mipmap-anydpi-v26/ic_launcher.xml` → `android:inset="0%"`. Diamètre du dessin mesuré dans les foreground générés : 63,8 dp sur 108 (cercle sûr = 66 dp).
- **MINOR — `fullscreen: true` sous `android_12`** : retiré ; la régénération n'a modifié aucune ressource (clé bien ignorée).

## 2. Nouveau : splash natif sans logo
Décision Florent 2026-11-04 : l'intro A dessine le logo à partir de rien, donc le splash natif = fond `#2B3848` seul sur iOS, Android < 12 et Android 12+.
- Image `visuals/splash_vide.png` (4×4 transparente) pour `image` **et** `android_12.image`, plutôt qu'aucune image : sans image, `flutter_native_splash` 2.4.4 écrit pour iOS un `LaunchImage` 1×1 **RGB noir opaque** (`lib/ios.dart:72` du package, `Image(width: 1, height: 1)`) centré dans le storyboard → un point noir ; et Android 12+ retomberait sur l'icône du launcher. Vérifier que toutes les ressources générées (`splash.png`, `android12splash.png` dont `drawable-night-*`, `LaunchImage*.png`) sont transparentes et que `launch_background.xml` / `LaunchScreen.storyboard` n'affichent rien d'autre que le fond.
- `visuals/logo_bulle_chrono_splash.png` et `logo_bulle_chrono_android12.png` sont retirés (plus référencés) ; `render_logo.py` écrit `splash_vide.png` à leur place.

## 3. Nouveau : animation de démarrage « A · Le chrono se lance »
`lib/widgets/effects/startup_intro.dart`, branchée par `builder:` dans `lib/app.dart`. Référence HTML : timeline en ms — piste 0–300 (fondu), arc 0–560 (tracé horaire depuis le haut), point 0–120, bulle pop 300–720 (`Cubic(.34,1.56,.64,1)`), « ? » -24°→+12°→0° 560–940, logo décalé de la moitié de la hauteur du titre puis remonté 820–1120, lettres 860 + 35·i ms, 260 ms chacune (translateY 18 → 0 + fondu), courbe par défaut `Cubic(.2,.8,.2,1)`. Fin du jeu à 1450 ms, puis fondu de sortie 250 ms → ~1,7 s.

Choix d'implémentation à challenger :
1. **Démarrage à froid seulement** : l'état de `StartupIntro` vit dans `MaterialApp.builder`, au-dessus du Navigator ; `GuessItAllApp` se reconstruit à chaque `notifyListeners` mais la position/type de l'élément ne change pas, donc l'état et le flag `_done` survivent. Retour d'arrière-plan : même process, pas de rejeu. Cas limite : Android recrée l'activité avec un nouveau moteur (option dev « Ne pas conserver les activités », process tué) → l'intro rejoue, ce qui est un vrai redémarrage. Acceptable ?
2. **Structure stable** : `Stack([child, if (!_done) overlay])` — retirer le dernier enfant ne recrée pas l'app (Navigator, état de l'accueil). Vérifier.
3. **Tap = passer** : `GestureDetector(opaque)` plein écran → arrêt de `_play` + fondu de sortie 250 ms. Les taps pendant l'intro ne traversent pas vers l'accueil.
4. **Animations réduites** : `MediaQuery.disableAnimations` lu une fois dans `didChangeDependencies` → logo et titre à l'état final, fondu d'entrée 300 ms, sortie à 900 ms + 250 ms. Les deux contrôleurs sont en `AnimationBehavior.preserve` : sinon Flutter réduit leurs durées à 5 % dans ce mode (vérifié par un test jetable : sans `preserve`, l'intro réduite durait ~2 frames).
5. **Titre** : `'Guess It All'` en `AppTextStyles.title(fontSize: 72)` — même style **et même taille** que `home_screen.dart` (retour Florent 2026-11-04), réduit seulement par le `FittedBox` sur écran étroit, mais une `Row` de `Text` par lettre (nécessaire pour l'animation par lettre) : perte de crénage entre lettres. `FittedBox(scaleDown)` sur `width - 48`. Le `Material` autour de la scène évite le soulignement jaune du `DefaultTextStyle` de `WidgetsApp` (on est au-dessus du Navigator). Acceptable ?
6. **Logo peint** : `_StartupLogoPainter`, constantes recopiées de `render_logo.py` (renvoi documenté des deux côtés, pas de codegen). Pivot du pop = centre de la boîte bulle + queue (543, 516). Le « ? » : inclinaison fixe -6° autour de (512, 600) comme l'icône (la maquette HTML tournait autour de (512, 485) — choix : coller à l'icône), puis balancier autour du centre de la boîte du glyphe. `TextPainter` recréé à chaque frame (≈ 1,5 s une seule fois) : acceptable ?
7. **Démarrage non retardé** : `main.dart` intact ; les tâches de démarrage restent avant `runApp`, l'intro joue après. Le splash natif couvre l'attente des tâches, puis l'intro.
8. **Jointure splash → intro (Android 12+ surtout)** : le premier frame Flutter est un fond `#2B3848` vide (piste à opacité 0, arc non dessiné tant que sa progression vaut 0, point à opacité 0). Le splash Android 12 sans icône doit donc s'enchaîner sans saut. Y a-t-il un frame où l'app (accueil) apparaît avant l'overlay ?
9. **Dialogue `UpgradeAlert`** : il s'ouvre dans le Navigator, donc sous l'intro ; il apparaît après le fondu (≤ 1,7 s). OK ?
  _(Rectifié après revue r2 : faux — le fond étoilé de l'accueil tourne en boucle, un `pumpAndSettle()` au niveau de l'app ne se stabilise jamais ; les tests existants l'évitent.)_
## Questions précises
- **Tests qui pendent** : aucun test existant ne monte `GuessItAllApp` (grep `GuessItAllApp` dans `test/` : vide), donc aucun `pumpAndSettle` ne voit l'intro ; et l'intro se termine seule (pas d'animation en boucle) : un futur test qui monterait l'app avec `pumpAndSettle` finirait en ~1,7 s simulées. Confirmer. Aucun test ajouté (UI, hors zones risquées) ; comportement vérifié par des tests jetables non commités (tap → disparition en ≤ 400 ms ; mode réduit ≈ 1,15 s ; changement d'écran ne rejoue pas) et par des captures de frames.
- **Deux plateformes** : rien de spécifique Android/iOS dans l'intro ; `disableAnimations` = « Supprimer les animations » Android / « Réduire les animations » iOS. Divergence possible ?
- **Résidus** : référence restante aux visuels supprimés, à `#1a2744`, à une image de splash avec logo ?
- `scripts/run-full-suite.sh` vert (226 tests).

## Format attendu
Findings classés BLOCKER / MAJOR / MINOR / NIT, chacun avec `fichier:ligne`, scénario, correction proposée. Verdict READY / NOT READY.

## Fichiers binaires (PNG) ajoutés / modifiés / supprimés, non inclus dans le diff
- `android/app/src/main/res/drawable-hdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png` (M)
- `android/app/src/main/res/drawable-hdpi/splash.png` (M)
- `android/app/src/main/res/drawable-mdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png` (M)
- `android/app/src/main/res/drawable-mdpi/splash.png` (M)
- `android/app/src/main/res/drawable-night-hdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-night-mdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-night-xhdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-night-xxhdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-night-xxxhdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-v21/background.png` (M)
- `android/app/src/main/res/drawable-xhdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png` (M)
- `android/app/src/main/res/drawable-xhdpi/splash.png` (M)
- `android/app/src/main/res/drawable-xxhdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png` (M)
- `android/app/src/main/res/drawable-xxhdpi/splash.png` (M)
- `android/app/src/main/res/drawable-xxxhdpi/android12splash.png` (M)
- `android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png` (M)
- `android/app/src/main/res/drawable-xxxhdpi/splash.png` (M)
- `android/app/src/main/res/drawable/background.png` (M)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (M)
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (M)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (M)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (M)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png` (M)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` (M)
- `ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png` (M)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` (M)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` (M)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` (M)
- `visuals/icone_guess_it_all.png` (D)
- `visuals/logo_bulle_chrono.png` (A)
- `visuals/logo_bulle_chrono_foreground.png` (A)
- `visuals/splash_vide.png` (A)
