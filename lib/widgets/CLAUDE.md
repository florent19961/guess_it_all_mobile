# widgets/

Widgets reutilisables organises en deux sous-repertoires.

## Sous-repertoires

| Repertoire | Role |
|------------|------|
| `common/` | Composants UI reutilisables (boutons, inputs, modals, sliders, toggles) |
| `effects/` | Effets visuels et animations de fond |
| `fiesta/` | Annonces de partie (2-5) : `ModifierIcon(id, size)` (`modifier_badge.dart`), SEUL point d'affichage des icônes : `assets/icons/modifiers/<id>.png`, émojis calés d'un même centrage (`mime_no_arms`, `mime_eyes_closed` barrés par `slash.png`), repli texte pour `two_words` (historique) et un id inconnu, `ModifierBadge(s)` (`.turn` : mini-phrase `turnLabel`, `.catalog` : nom), `FiestaTurnZone` (`turn_cartridges.dart`, avant-tour « Actif pendant votre prochain tour / Votre réserve », cercles ~50 px qui rapetissent jusqu'à 36 px (la réserve seule jusqu'à 32 px) pour tenir sans défiler (la zone active sur plusieurs rangées, colonne Bonus ajustée) ; un cas extrême défile dans la zone, appui long = explication, feuille « Sur qui ? » pour tout malus, 2 équipes comprises (pour chaque équipe adverse, son nom puis ses prénoms, rien d'autre) ; un prénom qui ne peut pas recevoir le malus est grisé, un toucher montre la raison dans une bulle qui part seule (`Tooltip`, `GameProvider.targetRefusal`), et un malus que personne ne peut recevoir est grisé dans la réserve ; message d'erreur en bas : 3 s, glisser vers le bas le ferme ; feuilles du bas en `SheetTopBorder` (`modifier_badge.dart`, liseré sur le seul bord supérieur), puces « Envoyé » (prénom visé ; envoi de la 1.4.0 : équipe visée, ou « Envoyé » à 2 équipes), un appui annule, sans fenêtre ; couleurs : `modifierColor` = malus `AppColors.malus` (#F87171), bonus `AppColors.success` |
| `help/` | Aides de prise en main : `HelpButton` (« ? »), `CoachMarks` (voile + bulle, étapes `CoachStep` ciblées par `GlobalKey`), textes par écran (`help_content.dart`), `TutorialPager`, `FirstGamePrompt` (tuto des règles d'office au 1er « Jouer »), `FirstGameHelp` (aides auto de la 1re partie). Branchement écran par écran → `help/WIRING.md` |
