# Revue Codex — lane 1 r2 (2026-11-04)

## Verdict: NOT READY

Aucun BLOCKER.

### MAJOR

- `lib/screens/fiesta_ensembles_screen.dart:116,140` — M5 reste une perte de brouillon. Le correctif préserve bien un brouillon A lorsqu’on enregistre B, mais un brouillon incomplet A est écrasé si l’utilisateur ouvre B, le modifie de façon incomplète puis revient : `EnsembleDraftKept` remplace l’unique `draft` statique.  
  Correction : stocker les brouillons par `ensembleId` (avec une clé dédiée à la création), et ne supprimer/modifier que celui de l’éditeur concerné. Ajouter le scénario A brouillon → B brouillon → reprise de A.

### MINOR

- `lib/screens/turn_screen.dart:383,393` — régression visuelle r2 : une règle de manche `two_words` est désormais dans `turnModifiers`, puis ajoutée une seconde fois dans `extra` car `isTwoWordsOn` est vrai. Le badge « Deux mots à la fois » apparaît deux fois pendant le tour.  
  Correction : n’ajouter le badge `extra` que si `turnModifiers` ne contient pas déjà `two_words`.

- `lib/models/fiesta/fiesta_ensemble.dart:123` — le résidu M3 est fonctionnellement acceptable (un ancien `free_pass.perGame: true` joue bien « par manche », sans perte de passe), mais la clé de déduplication conserve le bit désormais inopérant. Deux ensembles identiques en jeu, l’un avec ce bit historique et l’autre sans, sont acceptés comme distincts.  
  Correction : normaliser `free_pass.perGame` à `false` à la lecture/édition, ou l’ignorer dans `settingsKey`.

- `test/models/fiesta/symmetric_draw_test.dart:228` — le test de réserve tue les mutants métier principaux (malus non instancié, `reserve: false`, filtre absent), mais pas une régression de persistance : supprimer `reserve` de `toJson` ou l’ignorer dans `tryFromJson` le laisse vert.  
  Correction : ajouter un aller-retour `GameState` puis une reprise de provider avec un malus `reserve: true`, et vérifier qu’il reste stocké mais sans effet.

- `test/providers/fiesta_pick_three_test.dart:126` — le nouveau test tue bien les mutants « fini après une carte », double choix dans une rangée et application incomplète. Il ne couvre toutefois ni trois rangées dans la machine provider, ni kill/reprise après le choix de rangée 1.  
  Correction : ajouter `pick3Choices: 3`, recharger après un choix intermédiaire, puis vérifier la reprise de la bonne rangée et l’application des trois cartes.

### Vérification des findings r1

- M1 corrigé : `both` est produit uniquement par les règles de manche ; les cartouches restent ciblées. `two_words` règle tire bien la seconde carte sans charge, y compris via le chemin commun de continuation. Analytics ne duplique pas le tag. Seul le doublon visuel ci-dessus subsiste.
- M2 corrigé : les malus stock sont instanciés avec `reserve: true`; `modifiersForTurn` est l’unique chemin d’application et les consommateurs examinés (badges, analytics, temps, révélation, fin de tour) passent par lui. Les offres, le récap et le plan de transition ne les appliquent ni ne les exposent.
- M3 : acceptable pour le gameplay lane 1 ; l’option est masquée et les blobs historiques sont interprétés « par manche ». Incohérence de déduplication signalée ci-dessus.
- M4 corrigé : `hasUnreadableFiesta` protège les deux relectures de `GameState` : reprise au démarrage et restauration du snapshot.
- M5 non acceptable : perte de brouillon toujours possible.
- M6 : l’invariant central à deux rangées est maintenant testé, avec les lacunes de mutation indiquées.
- Ensembles fournis : les 7 ids et noms, dans l’ordre, sont désormais bien verrouillés.

Revue réalisée en lecture seule ; aucun test n’a été exécuté afin de respecter cette contrainte.

