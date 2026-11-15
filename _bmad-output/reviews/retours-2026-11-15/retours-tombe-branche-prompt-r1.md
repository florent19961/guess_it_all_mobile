# Revue r1 — L-TOMBE-BRANCHEMENT (`feat/retours-tombe-branche`) — tier RISQUÉ

Tu es reviewer, en LECTURE SEULE. Lis le patch `retours-tombe-branche-patch-r1.diff` (même dossier), puis le code
qu'il touche dans le worktree `/home/florent19961/guess-it-all-retours-tombe-branche`. Ne lance pas `git diff`
toi-même. Revue statique : le mutation testing est fait (`retours-tombe-branche-mutations-r1.md`), juge-le.

## Objectif

Spec `_bmad-output/specs/fiesta/retours-2026-11-15.md` §D4 (branchement) et §D2 (écran « Ce qui t'attend ») ; lis
l'en-tête (règle 7 : la 1.4.0 est en store). Le modèle (`dropForTurn`, `dropSeed`, `dropPool`, `DropFrequency`) est
déjà mergé ; son contrat est dans `lib/models/CLAUDE.md` (ligne `cartridge_drop.dart`). Cette lane : tirer la
cartouche au lancement du tour, la stocker dans le tour, lui donner ses effets, l'afficher.

## Décisions de la spec (ne pas re-trancher)

- Une chance par tour joué, sur l'équipe qui joue, ce tour seulement ; rien en continuation ; rien à Jamais.
- Tirage à graine ; app tuée et retour arrière retrouvent la même ; le remplaçant d'un joueur qui saute a son tirage.
- Bonus tombé appliqué comme armé ; malus comme reçu ; `block_guesser` : devineur tiré ; `block_giver` : cycle actuel
  du piège sans « Ce qui t'attend ». Pas de remboursement, stock (`cartridgesLeft`) inchangé.
- « Ce qui t'attend » s'affiche aussi pour une cartouche tombée seule : ligne en tête de « On vient de t'infliger »,
  provenance « Tombée du ciel » (jaune), même pour un bonus.
- Effets du tour, dont `WordEvent.modifiers`, incluent la cartouche tombée.

## Mécanisme choisi

- `startTurn` → `_drawDrop` (avant `_hasTurnReveal` et `turnTime`) → `FiestaTurnState.drop` (clé `drop`, omise si
  nulle, illisible = perdue seule). Pas de tirage si un `block_giver` reçu attend ce joueur.
- Bonus tombé : `_charge(id)` le rend `spent` (jamais écrit dans `charges`) → `turnTime`, `freePasses`,
  `isDoublePointsOn`, `spentBonuses`, `_eventContext`, `_conflict`, `_setCharge`, `reserve`. Aucun `ChargeUse`.
- Malus tombé : `droppedMalus` (pur) → instance `scope: turn` sans `fromTeamId`, ajoutée en fin de
  `_modifiersThisTurn`. `_isRoundRule` (sans envoyeur ET `scope: round`) remplace `fromTeamId == null` dans le
  masquage de l'avant-tour et `roundRulesThisTurn`. `droppedThisTurn` pour l'UI.
- `block_giver` tombé : `_pendingGiverBlock` synthétise une instance sans envoyeur ; `giverBlockScreen` prend
  `droppedGiverBlockPhrase`.

## Arbitrages de l'implémenteur (à challenger)

1. Phrase du piège tombé : « Une cartouche est tombée du ciel, X : tu ne joues pas ce tour. » (les 8 phrases
   existantes nomment un envoyeur).
2. Zone « Actif » de l'avant-tour d'une continuation : la cartouche tombée y apparaît (cercle bonus « armé » ou
   malus « reçu »), comme les malus reçus déjà révélés.
3. Pas de genre de fait « tombé » dans le récap archivé (`GameResult`) : aucun écran ne l'affiche, la cartouche
   n'est pas gardée après son tour ; pas de badge dans « Évolution des scores ».
4. Pas d'animation de chute (optionnelle).
5. Joueur piégé par un `block_giver` reçu : aucun tirage (son remplaçant tire avec `skips` + 1).

## Points précis à vérifier

1. Intégrité analytics : `_eventContext` sur tous les écrans du tour (tour, vérification, après kill, après
   `restorePreValidationState`) ; jamais deux fois le même id ; rien sur l'avant-tour d'un tour non lancé.
2. Stock : aucun chemin n'ajoute un `ChargeUse` pour une cartouche tombée ; `reserve`, `_chargesLeft` inchangés.
3. Continuation de fin de manche : `drop` survit (`_fiestaAtRoundEnd`), aucun nouveau tirage, `turnTime` ne
   rajoute pas un +10 s tombé (il est `spent`), un malus tombé devenu impossible en N+1 est perdu.
4. Entrées du tirage : `received` lu sur `_modifiersThisTurn` (pas la liste cachée), `armed`, `guesserIds` dans
   l'ordre de l'équipe, `leaderGap` sur `Team.score`, `skips` de l'équipe, `turnIndex` = `currentTurnIndex`.
5. Lecteurs de `fromTeamId == null` / `!= null` : `malusSender`, `_explain(from:)` de `turn_cartridges.dart`
   (`fromTeamId!`), `_malusBlock`, `targetRefusal`, `round_transition.dart` — l'instance tombée n'existe que dans
   `_modifiersThisTurn`, jamais dans `fiesta.active` : le confirmer.
6. Persistance (règle 7) : clé additive ; une partie 1.4.0 se relit ; une valeur mal typée ne casse que la clé.
7. Docs : `lib/models/CLAUDE.md`, `lib/providers/CLAUDE.md`, `lib/screens/CLAUDE.md`, `docs/tracking_evolution.md`,
   `docs/ANALYTICS.md`, tutoriel Fiesta.
8. Tests (4 dans `test/providers/fiesta_cartridge_drop_test.dart`, 1 pur de `droppedMalus` dans
   `test/models/fiesta/cartridge_drop_test.dart`) : valeur, redondance ; plus aucun mutant survivant.
9. `_isRoundRule` rend `scope` porteur de sens : vérifié sur la 1.4.0 (`v1.4.0+13`), les seules instances sans
   envoyeur sont les règles de manche (`scope: round`, `symmetric_draw.dart`) ; `inflictMalus` écrit `scope: turn`
   avec `from`. À confirmer.

## Format attendu

Rapport dans `retours-tombe-branche-review-r1.md` (même dossier) : verdict **READY** / **NOT READY**, puis findings
**BLOCKER / MAJOR / MINOR**, chacun avec `fichier:ligne`, le scénario concret et la correction proposée.
