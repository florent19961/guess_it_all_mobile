# widgets/

Widgets reutilisables organises en deux sous-repertoires.

## Sous-repertoires

| Repertoire | Role |
|------------|------|
| `common/` | Composants UI reutilisables (boutons, inputs, modals, sliders, toggles) |
| `effects/` | Effets visuels et animations de fond |
| `fiesta/` | Annonces de partie (2-5) : `ModifierBadge(s)`, `FiestaTurnZone` (`turn_cartridges.dart`, avant-tour « Actif pendant votre prochain tour / Votre réserve », cercles ~50 px qui rapetissent jusqu'à 36 px (la réserve seule jusqu'à 32 px) pour tenir sans défiler (la zone active sur plusieurs rangées, colonne Bonus ajustée) ; un cas extrême défile dans la zone, appui long = explication, feuille « Contre quelle équipe ? », fenêtre des blocages (joueurs par équipe, nommés à l'envoi), puces « Envoyé » (équipe visée, joueur nommé, ou « Envoyé » à 2 équipes), un appui propose d'annuler ; couleurs : `modifierColor` = malus `AppColors.malus` (#F87171), bonus `AppColors.success` |
| `help/` | Aides de prise en main : `HelpButton` (« ? »), `CoachMarks` (voile + bulle, étapes `CoachStep` ciblées par `GlobalKey`), textes par écran (`help_content.dart`), `TutorialPager`, `FirstGamePrompt` (tuto des règles d'office au 1er « Jouer »), `FirstGameHelp` (aides auto de la 1re partie). Branchement écran par écran → `help/WIRING.md` |
