# Correctifs — entre-manches r1

## MAJOR rattrapage (accessibilité + « 1er tour »)

**1. État en tête / en retard pour les lecteurs d'écran — corrigé.**
`lib/widgets/fiesta/turn_time_cards.dart:89-94` : le span du nom porte `semanticsLabel: '<équipe> en tête, '` / `'<équipe> en retard, '` ; le span des secondes reste lu tel quel (« −5 s »). Rien de visible n'est ajouté.
Le label est posé sur le span qui a du texte, pas sur le `TextSpan` parent : `TextSpan.computeSemanticsInformation` (flutter `painting/text_span.dart:411`) n'émet `semanticsLabel` que si `text != null`, un label sur le parent sans texte serait ignoré.
Preuve : test jetable (non committé, UI simple) `CatchUpLine` à deux équipes → label sémantique lu = `Rattrapage : Lions en tête, −5 s · Tigres en retard, +10 s`.
À l'œil, l'info ne repose pas que sur la couleur : le signe + / − reste affiché.

**2. « Seulement au 1er tour » — résidu assumé à l'écran, ajouté dans l'aide.**
L'étape « Rattrapage » de `fiestaTransitionHelp` ne le disait pas ; ajouté : `lib/widgets/help/help_content.dart:400-402` (« Seulement au premier tour de chaque équipe dans la manche (pas quand un tour coupé se poursuit). »).

## Intégration
Rebase sur `origin/main` (#29 inclus), sans conflit. `scripts/run-full-suite.sh` vert. Patch r2 : `entre-manches-patch-r2.diff` (merge-base = `origin/main`).
