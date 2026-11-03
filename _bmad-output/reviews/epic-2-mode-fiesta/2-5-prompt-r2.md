# Revue r2 — story 2-5 (tier risqué : machine à états)

Même reviewer, même posture que r1. Lis `2-5-patch-r2.diff` (même dossier ; toujours contre
`1061923`, la lane n'est pas restackée car 2-6 est empilée dessus), puis `2-5-review-r1.md` et
`2-5-fix-r1.md`. Rapport dans `2-5-review-r2.md`.

## Ce que r2 doit vérifier

1. **MAJOR-1** (`game_screen.dart` `_startTurn`) : les deux gardes ferment-elles chaque chemin
   du scénario r1 (double tap, N malus, retour système Android pendant la révélation, écran
   changé sous la révélation) ? La garde `isCurrent` peut-elle bloquer un tap **légitime**
   (dialogue ouvert puis fermé, route `home` remplacée après une reprise) ? L'absence de test
   est-elle acceptable (bug de pile de routes, tests de widget exclus par la lane) ?
2. **MINOR-1/2** : `isForAllTeams` filtre tirage et fixés ; les deux nouveaux tests tuent bien
   leurs mutants (rejoue-les).
3. **MINOR-3** : la décision « pas de `canAdd` sur les survivantes, invariant porté par 2-8 /
   2-10 » est-elle tenable, et l'entrée de `notes_pour_plus_tard.md` suffit-elle à 2-8 / 2-10 ?
4. **MINOR-5/6** : `Expanded` + `Align(bottomCenter)` sur le jeu Fiesta, `MalusReveal`
   défilant : débordement possible sur petit écran ? Classique toujours identique ?
5. Régression : rien d'autre n'a bougé (diff r1 → r2 limité à `game_screen`, `malus_reveal`,
   `symmetric_draw`, deux tests, `notes_pour_plus_tard`).

## Format attendu

Pour chaque finding : sévérité, `fichier:ligne`, scénario, correction. Verdict : READY ou NOT
READY.
