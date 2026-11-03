# Correctifs r1 — story 2-5

Chaque finding a été re-tracé dans le code avant correction.

| Finding | Décision | Où |
|---|---|---|
| MAJOR-1 double tap pendant une révélation | **Corrigé** comme proposé : garde `ModalRoute.of(context)?.isCurrent` avant de pousser, puis `context.mounted` + `currentScreen == screenGame` après l'`await`. **Pas de test** : le bug vit dans la pile de routes (une route au-dessus de `home`), invisible au niveau provider ; le seul test possible est un test de widget, exclu par la règle de la lane. Recette device : double tap rapide = une seule révélation. | `game_screen.dart` `_startTurn` |
| MINOR-1 `block_guesser` fixé « pour tous » | **Corrigé** : `isForAllTeams(def)` filtre le tirage **et** les fixés. Un fixé « manche 3 seulement » hors M3 reste ignoré ; c'est à l'éditeur de 2-3 de l'interdire (documenté sur `fixedForRound`). | `symmetric_draw.dart` |
| MINOR-2 deux mutants survivants | **Corrigé.** `block_guesser` fixé dans la config « fixé » + assertion « jamais tiré ni fixé » dans la boucle. Nouveau test provider : `malusToReveal` non vide au premier tour de chaque équipe dans la manche, vide ensuite (malus toujours actif). Les deux mutants rejoués : **tués**. | `symmetric_draw_test.dart`, `fiesta_round_draw_test.dart` |
| MINOR-3 survivantes sans `canAdd` | **Tranché : pas de `canAdd` sur les survivantes.** Q8 (le tirage d'abord) et l'aperçu de transition doivent rester fonction de `(rules, gameId, manche)` seule. Invariant posé pour 2-8 / 2-10 : une instance de portée tour est consommée à la fin du tour ; une offre se pose après le tirage. | `notes_pour_plus_tard.md` |
| MINOR-4 aperçu recalculé vs mise à jour de l'app | **Noté** avec signal déclencheur (tout changement du catalogue ou de l'algorithme). | `notes_pour_plus_tard.md` |
| MINOR-5 vide sous le bouton | **Corrigé** : `Expanded(flex: 3)` + `Align(bottomCenter)` ; le bloc reste juste au-dessus du bouton et l'espace libre passe au-dessus. Classique inchangé (`isFiesta`). | `game_screen.dart` |
| MINOR-6 `MalusReveal` ne défile pas | **Corrigé** (peu cher) : `Center` + `SingleChildScrollView`, `Column` en `mainAxisSize.min`. | `malus_reveal.dart` |
| MINOR-7 `FiestaState.enterRound`, `followedBy` | **Non fait** : optionnel ; `FiestaState` est un type public de 2-2 et 2-6 est empilée sur ce provider. Le `followedBy` garde le diff de la transition à 12 lignes au lieu de ~140 de ré-indentation. | — |
| Hors périmètre : double tap « Manche suivante » (M1 → M3) | **Bug préexistant corrigé en passant** (demande du lead) : `nextRound` ne fait rien hors de l'écran de transition, donc un second appel depuis le jeu de la manche suivante est sans effet. Test provider : deux `nextRound` depuis la transition M1→M2 finissent en M2 (rouge avant le correctif, `Actual: <3>`). | `game_provider.dart` `nextRound`, `fiesta_round_draw_test.dart` |
