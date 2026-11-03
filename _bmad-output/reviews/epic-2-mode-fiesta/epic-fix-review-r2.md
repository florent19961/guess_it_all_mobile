# Revue epic fix Fiesta — r2

## Verdict : NOT READY

Revue strictement statique du patch imposé `epic-fix-patch-r2.diff`, du
correctif `cd522a6` et du worktree. Aucun programme Flutter/Dart ni test n'a
été exécuté.

## Findings

### BLOCKER

Aucun.

### MAJOR

#### MAJOR-1 — une continuation en chaîne annonce `minus_10s` sans l'appliquer

- **Emplacements :** `lib/providers/game_provider.dart:1506-1517`,
  `lib/models/fiesta/turn_time.dart:34-50`,
  `test/providers/fiesta_pick_three_test.dart:291-368`.
- **Scénario :** A finit M1, sa continuation vide M2, puis ouvre M3. Le
  nouveau calcul prend M2 comme manche logique et `malusToReveal` retourne
  donc tous les malus M2, y compris `minus_10s`. Mais `turnBonusTime` est
  encore posé : `composeTurnSeconds` retourne alors exactement ce temps
  reporté, « sans aucun modificateur de temps ». L'écran annonce donc « le
  tour démarre avec 10 secondes de moins » alors que le chrono ne les retire
  pas. Le test ajouté ne configure que `block_guesser`, il ne peut pas tuer ce
  mutant.
- **Impact :** la nouvelle règle est correcte pour les malus qui pèsent encore
  réellement sur le tour logique M2 (`block_guesser`, `no_pass`, etc.), mais
  elle n'est pas cohérente pour le malus temporel. Elle contredit le contrat
  conservé « continuation = temps reporté, sans modificateur » et affiche une
  règle de jeu fausse dans un chemin de partie réel.
- **Correctif attendu :** conserver explicitement la sémantique du temps
  reporté et ne pas révéler `minus_10s` dans cette continuation, ou faire
  valider puis implémenter l'alternative produit consistant à l'appliquer. Un
  test M1→M2→M3 avec `minus_10s` M2 doit épingler le choix retenu.

### MINOR

Aucun.

## Vérifications r2

- `_fiestaAtRoundEnd` (`game_provider.dart:1493-1497`) appelle bien
  `_fiestaAfterTurn` seulement lorsqu'une continuation achève la manche. À ce
  moment, `currentTeamModifiers` est encore M1, l'état de tour est vidé et les
  instances antérieures à M2 sont retirées (`:1472-1484`). Le plan vers M3 ne
  garde ensuite que M2 (`round_transition.dart:44-52`) : le plafond de deux
  est donc conservé pour les effets réellement appliqués.
- La persistance et l'undo reprennent `GameState.toJson()` (`:1959-2018`) ; le
  test de chaîne exerce bien le kill/reprise et le retour arrière. La garde de
  `validateWords` (`:1004-1008`) et celle de `nextRound` (`:1199-1205`) rendent
  les doubles taps inertes après la première mutation.
- Pour une continuation ordinaire, la manche logique reste N et le nombre de
  tours réels est positif : `malusToReveal` reste vide. Pour la chaîne, le
  calcul M2 rend correctement un blocage M2, que le test vérifie.
- Le test M1→M2→M3 tuerait bien l'ancien `afterRoundEnd()` inconditionnel : le
  `double_points` M1 restait `spent`, tandis que l'attendu r2 exige
  `isDoublePointsOn == false` (`fiesta_pick_three_test.dart:326-342`). Aucun
  autre écart r1→r2 n'a été relevé par lecture statique.
