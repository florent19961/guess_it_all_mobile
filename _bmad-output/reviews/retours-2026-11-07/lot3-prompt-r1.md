# Revue lot 3 `retours-tour-icones` (tier standard), round 1

Lecture seule. Lis le patch `_bmad-output/reviews/retours-2026-11-07/lot3-patch-r1.diff` (ne lance pas `git diff`),
puis le code autour dans le worktree `/home/florent19961/guess-it-all-retours-tour-icones`, branche
`feat/retours-tour-icones`, base `origin/feat/retours-regles` (lot 1, encore en revue). Les 14 PNG de
`assets/icons/modifiers/` n'apparaissent dans le patch que comme binaires.

## Objectif

Décisions D3 (UI), D6, D7 : `/tmp/claude-1000/-home-florent19961-guess-it-all-audit/dc8da8fa-0844-4349-be94-32409786a766/scratchpad/spec-retours-2026-11-07.md`.
Maquette : `/tmp/claude-1000/-home-florent19961-guess-it-all-audit/dc8da8fa-0844-4349-be94-32409786a766/scratchpad/retours-7-novembre.html` (les sections `hidden` sont périmées).
Ces décisions sont prises par Florent : ne les re-tranche pas.

Corrections à la spec données par l'orchestrateur :
- Deux mots est retiré par le lot 1. `ModifierIcon` garde un repli texte pour `two_words` (historique des stats), sans PNG.
- `block_guesser.turnLabel` vaut `'ne répond pas'` : la pastille le fait précéder du prénom.
- Le mode `compact` de `TurnActionButtons` n'existe plus.
- `mime_no_arms` : émoji 💪 barré.
- `game_provider.dart` n'est pas touché. `settings_screen.dart`, `app.dart`, `players_screen.dart`,
  `fiesta_ensembles_screen.dart`, `fiesta_tutorial_screen.dart` (lot 4) et l'animation des scores (lot 2) non plus.

## Écarts et choix non dictés par la spec (à challenger)

1. Cercles allumés et reçus de `_Circle` : fond teinté à 30 % sur l'encre au lieu de plein. Les PNG ne se recolorent pas, et
   `plus_10s` (vert) ou `minus_10s` (rouge) disparaîtraient sur leur propre couleur.
2. `kModifierIcons` et `modifierIcon()` restent entiers : `score_reveal_chart.dart` les utilise tant que le lot 2 n'est pas
   mergé. La table se réduit à `two_words` ensuite.
3. Roulette du défi surprise : `⧉` (Deux mots) retiré, 6 ids au lieu de 7 glyphes, alternance bonus / malus conservée.
   `ChallengeReward.icon` devient `modifierId`.
4. Une raison de bulle si plusieurs sont vraies : l'ordre de `PassState`, le même que l'aide (blocage, dernier mot, temps).
5. Bouton grisé en pause : libellé seul aussi, comme tout bouton grisé.
6. Titre de l'étape d'aide « Passer (bloqué) » conservé : la spec ne retire ce libellé que du bouton.
7. La ligne « X ne répond pas ce tour » de l'AVANT-tour (`turn_cartridges.dart`) reste : D7 parle de l'écran de tour, et il
   n'y a pas de pastille à l'avant-tour.
8. Pastille `block_guesser` sans joueur résolu : nom du catalogue. Aucune pastille pour un id sans `turnLabel`
   (`block_giver`, `two_words` relu).

## Questions précises

1. `TurnActionButtons` : la hauteur reste-t-elle 114 dans tous les états, sans déplacement au passage actif → grisé ou
   (gratuit) → -5s ? `IntrinsicHeight` tient-il sous grande police ?
2. Bulle : un chemin où elle reste affichée, change de texte ou se relance à tort (rebuilds du chrono, reprise après pause,
   passage de grisé à actif) ? Le `_bubble.reset()` dans `didUpdateWidget` est-il sûr ?
3. `FractionalTranslation` + `Positioned(top: -3)` : la bulle peut-elle déborder en largeur ou être coupée sur 360 px ou
   avec une grande police ? Le `IgnorePointer` laisse-t-il bien passer les touchers vers ce qui est dessous ?
4. `ModifierIcon` : le `TextStyle(inherit: false)` et la strut forcée suffisent-ils au centrage d'un émoji sur Android et iOS ?
   Y a-t-il un écran où l'image se charge visiblement en retard (`gaplessPlayback`, roulette) ?
5. `_sentChip` : `onTap: () => _p.cancelSent(m)` après la fin du tour ou sur une instance périmée ? `cancelSent` a sa garde.
6. `ModifierBadges.playerName` : un autre appelant ou une relecture d'ancienne partie peut-il donner un `playerId` absent ?
7. Valeur des tests : ajouté 1 (bulle, `fiesta_v4_screens_test.dart`), retiré 1 (« Passe gratuite : son compteur a une
   étape », étape supprimée), retravaillés : annulation directe de la puce (dans le test d'écran chargé existant), joueur
   bloqué de `help_conditional_test.dart`. Le test de la bulle détecte-t-il une pause du chrono, ou un `passWord` déclenché
   sur un bouton grisé ? `no_pass` refuse déjà côté provider : est-ce une garantie vraiment exercée ?

## Format attendu

Par finding : BLOCKER / MAJOR / MINOR, `fichier:ligne`, preuve, correction proposée. Verdict final READY ou NOT READY.
Grille `thermo-nuclear-code-quality-review` limitée au diff. Vérifie aussi Android et iOS (`defaultTargetPlatform`, safe areas).
