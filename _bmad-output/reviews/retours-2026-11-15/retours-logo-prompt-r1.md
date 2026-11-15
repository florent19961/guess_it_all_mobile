# Revue r1 — L-LOGO (`feat/retours-logo`) — tier standard, sans mutation testing

Lecture seule. Lis le patch `_bmad-output/reviews/retours-2026-11-15/retours-logo-patch-r1.diff` (ne lance pas
`git diff` toi-même ; les binaires y apparaissent comme « Binary files differ » : pour les comparer, utilise
`git diff --stat 713e88a^ HEAD -- android/app/src/main/res ios/Runner` ou `git show 713e88a^:<chemin>`).
Écris ton rapport dans `_bmad-output/reviews/retours-2026-11-15/retours-logo-review-r1.md`.

## Objectif (spec `_bmad-output/specs/fiesta/retours-2026-11-15.md`, section D5)

Retour à l'ancien logo, sans animation :
- icône de l'app (iOS, Android, adaptive) = l'ancien `visuals/icone_guess_it_all.png`, restauré depuis `713e88a^`
  sans retouche ; config `flutter_launcher_icons` et `flutter_native_splash` = celle d'avant 713e88a (fond
  `#1a2744`, logo sur le splash natif) ;
- écran de lancement d'avant, le logo sans animation : retrait de `lib/widgets/effects/startup_intro.dart`, de son
  branchement dans `lib/app.dart`, et de ce qu'elle laisse orphelin (`scripts/render_logo.py`, visuels « Bulle
  chrono ») ;
- 🔴 ne PAS revert 713e88a en bloc : les couleurs d'équipe pastel (`lib/theme/app_theme.dart`) restent ;
- ressources natives régénérées par les outils.

## Ce que fait le patch

- `visuals/icone_guess_it_all.png` restauré (octets de `713e88a^`) ; `logo_bulle_chrono.png`,
  `logo_bulle_chrono_foreground.png`, `splash_vide.png`, `scripts/render_logo.py`, `startup_intro.dart` supprimés.
- `pubspec.yaml` : sections `flutter_launcher_icons` / `flutter_native_splash` identiques à `713e88a^`
  (y compris `fullscreen: true` sous `android_12`, que l'outil ignore — repris tel quel).
- `dart run flutter_launcher_icons` et `dart run flutter_native_splash:create` tournent sous WSL : toutes les
  images Android/iOS, `colors.xml`, `ic_launcher.xml` (inset 16 %), `LaunchScreen.storyboard` sortent identiques à
  `713e88a^`.
- Arbitrage : l'outil réécrit dans `values-v31/styles.xml` et `values-night-v31/styles.xml`
  `windowSplashScreenBackground` + `windowSplashScreenAnimatedIcon`. Le commit 033db71 (janvier) les avait retirés
  exprès (masque circulaire Android 12+ qui tronquait l'icône, remplacé par `windowBackground`). Ces deux fichiers
  sont repris de `713e88a^` → toute l'arborescence `android/app/src/main/res` et `ios/Runner` est identique à
  `713e88a^`.
- Docs : `lib/CLAUDE.md`, `lib/widgets/effects/CLAUDE.md`, entrée `docs/tracking_evolution.md`.
- Tests : aucun ajouté ni retiré (aucun test ne référençait `StartupIntro`). Suite complète verte (590).

## Points à vérifier

1. `git diff --stat 713e88a^ HEAD -- android/app/src/main/res ios/Runner` est vide (aucune ressource native qui
   diffère de l'avant-713e88a), et rien de 713e88a hors identité n'est annulé (`lib/theme/app_theme.dart` intact).
2. Aucune référence morte : `StartupIntro`, `startup_intro`, `render_logo`, `logo_bulle_chrono`, `splash_vide`,
   « Bulle chrono » hors `_bmad-output/` et de l'entrée historique de `docs/tracking_evolution.md`.
3. `lib/app.dart` : le `MaterialApp` revient à l'état d'avant (pas de `builder`), sans autre changement.
4. L'arbitrage `values-v31` est-il le bon au regard de « l'écran de lancement d'avant » ? Risque Android 12+ si
   `windowBackground` seul (comportement système : icône du launcher sur le fond) ?
5. iOS : `Icon-App-1024x1024@1x.png` a un canal alpha (opaque partout), comme avant 713e88a — l'outil avertit.
   Cette icône a été acceptée par Apple jusqu'à la 1.1.3 ; est-ce un risque de rejet à signaler ?
6. Orphelins restants créés par ce changement (imports, assets déclarés, docs) ; `visuals/icone_guess_it_all.jpg`
   (non référencé avant 713e88a déjà) laissé tel quel.

## Format attendu

Verdict **READY** / **NOT READY**, puis findings classés **BLOCKER / MAJOR / MINOR**, chacun avec `fichier:ligne`,
l'affirmation et comment la vérifier. Pas de finding cosmétique.
