# Revue lane « theme » — round 1 (tier standard, lecture seule)

Lis `_bmad-output/reviews/theme/theme-patch-r1.diff` (ne lance pas `git diff`) et le code de
`lib/` au besoin. Écris ton rapport dans `_bmad-output/reviews/theme/theme-review-r1.md`.

## Objectif
Retour device Florent 2026-11-04 : un « bleu-violet » hors charte et des Switch qui ne
ressemblent pas à la charte. Cause : `AppTheme.darkTheme` ne définissait aucun `colorScheme`,
donc Material 3 appliquait sa palette violette par défaut à tout widget non stylé.
Périmètre : `lib/theme/app_theme.dart` (+ `lib/theme/CLAUDE.md`). Aucune couleur `AppColors`
ni couleur d'équipe modifiée. Aucun test ajouté (thème).

## Questions
1. Plus aucun violet M3 possible ? Le constructeur nu `ColorScheme(...)` fait-il bien retomber
   tous les rôles non fournis (primaryContainer, tertiary, surfaceContainer*, inverse*,
   surfaceTint…) sur primary/secondary/surface, sans valeur violette ? (Flutter 3.44.8)
2. Contraste des `onX` (onPrimary/onSecondary/onError = `backgroundMain`, onSurface blanc) :
   lisibles ? Un widget existant dépend-il de `onPrimary` blanc ?
3. Effets sur les widgets existants (Switch L: fiesta_auto_screen 114, fiesta_setup_widgets 255,
   fiesta_ensemble_editor_screen 440 ; TextButton ; TextField curseur/sélection ; SnackBar ;
   InkWell ; AlertDialog/Dialog ; bottom sheet) : régression visuelle ? Android **et** iOS
   (curseur iOS via `textSelectionTheme`).
4. Sur-dimensionnement : un sous-thème ajouté est-il inutile ?

## Format
Findings BLOCKER / MAJOR / MINOR avec `fichier:ligne`, puis verdict READY / NOT READY.
