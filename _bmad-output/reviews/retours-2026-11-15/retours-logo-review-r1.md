# Revue r1 — L-LOGO (feat/retours-logo)

Verdict : READY

Revue en lecture seule : aucun build, aucun test lancé. La suite verte (590) est reprise du prompt, je ne l'ai pas vérifiée.

## Vérifications faites (preuves)

1. **Ressources natives identiques à 713e88a^.** `git diff --stat 713e88a^ HEAD -- android/app/src/main/res ios/Runner` est vide. `visuals/icone_guess_it_all.png` est octet pour octet celui de `713e88a^` (`cmp` OK). La conformité à D5 est donc établie pour Android (mipmap, adaptive `ic_launcher.xml`, `colors.xml`, splash, `values-v31`) et pour iOS (AppIcon, LaunchImage, storyboard).
2. **Config outils identique à avant 713e88a.** Les sections `flutter_launcher_icons` et `flutter_native_splash` de `pubspec.yaml` sont identiques à celles de `713e88a^` (`diff` sans écart, fond `#1a2744`, logo sur le splash). `fullscreen: true` est repris tel quel, c'est conforme à « config d'avant ».
3. **Pas de revert en bloc.** `lib/theme/app_theme.dart:34-35` garde `team3 = 0xFFB6A6F5` et `team4 = 0xFFF2D47C` (pastel). Le commit `6d0a067` ne touche que `lib/CLAUDE.md`, `lib/app.dart`, `lib/widgets/effects/CLAUDE.md`, `startup_intro.dart`, `pubspec.yaml`, les ressources natives, `visuals/` et `scripts/render_logo.py`. Rien d'autre n'est retiré.
4. **`lib/app.dart`.** Le seul changement de `6d0a067` est la suppression de l'import `startup_intro.dart` et du `builder:` (-4 lignes). Le `MaterialApp` n'a pas d'autre modification. Le reste de la différence avec `713e88a^` vient de l'évolution normale de la branche (écrans), pas de ce patch.
5. **Références mortes.** `grep -rnI "StartupIntro|startup_intro|render_logo|logo_bulle_chrono|splash_vide|Bulle chrono"` hors `_bmad-output/`, `.git`, `build` et `.dart_tool` ne trouve que `docs/tracking_evolution.md:1463-1465`, l'entrée historique attendue.
6. **Orphelins.** Les assets déclarés dans `pubspec.yaml` (l.59-64) ne référencent ni `visuals/` ni l'intro. `lib/widgets/effects/` ne contient plus que `CLAUDE.md`, `score_reveal_chart.dart` et `shooting_stars.dart`. `scripts/` n'a plus de script logo. Aucun import ni asset orphelin trouvé.

## Findings

### MINOR-1 — Arbitrage `values-v31` / `values-night-v31` (`android/app/src/main/res/values-v31/styles.xml`)
- Constat : les fichiers sont repris de `713e88a^`, donc `windowBackground = @drawable/launch_background` (layer-list fond + `splash`), sans `windowSplashScreenBackground` ni `windowSplashScreenAnimatedIcon`.
- Conséquence : sur Android 12+, le système affiche l'icône du launcher (adaptive, fond `#1a2744`) sur la couleur de fond du thème. Ce n'est pas le splash natif avec logo plein cadre.
- C'est l'état livré jusqu'à la 1.1.3, et 033db71 avait retiré exprès les attributs pour éviter la troncature par le masque circulaire.
- L'arbitrage est donc le bon au regard de « l'écran de lancement d'avant ».
- Point non vérifiable ici : `windowBackground` étant un layer-list et non une couleur unie, la couleur de fond du splash système peut différer de `#1a2744`. À constater sur un appareil Android 12+ à la recette.
- Pas d'action requise dans ce patch.

### MINOR-2 — iOS `Icon-App-1024x1024@1x.png` a un canal alpha
- Preuve : mode RGBA, extrema du canal alpha (255, 255), donc opaque partout. Le fichier d'avant 713e88a est lui aussi RGBA.
- L'icône est identique à celle acceptée par Apple jusqu'à la 1.1.3, donc le risque de rejet est faible.
- Apple documente toutefois qu'une icône 1024 ne doit pas avoir de canal alpha. Si un rejet ITMS apparaît au prochain envoi, l'option `remove_alpha_ios: true` de `flutter_launcher_icons` règle le problème. Elle ne fait pas partie de « sans retouche ».
- Pas d'action requise, simple point de vigilance.

### Pour information, sans finding
- `visuals/icone_guess_it_all.jpg` est laissé tel quel (non référencé avant 713e88a déjà).
- La spec demande de retirer aussi « tests associés » : aucun test ne référençait `StartupIntro`, il n'y a donc rien à retirer.
- L'icône des fiches store (512 de Play) est hors dépôt, liste de Florent.

## Verdict : READY

BLOCKER : aucun.
MAJOR : aucun.
