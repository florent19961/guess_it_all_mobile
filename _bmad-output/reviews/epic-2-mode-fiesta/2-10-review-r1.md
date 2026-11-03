# Revue 2-10 CORE — r1

**Verdict : NOT READY**

Revue statique du seul patch `2-10-patch-r1.diff` (base `8bfdbd5`), sans recalcul de diff ni exécution de Flutter, Dart ou tests.

## Findings

### BLOCKER — `block_guesser` choisi bloque chaque tour de M(N+1), pas un seul tour

**Emplacements :** `lib/models/fiesta/offers.dart:158`, `lib/providers/game_provider.dart:1161`, `lib/providers/game_provider.dart:1344`.

**Scénario :** une équipe menée choisit `block_guesser` contre le leader. La fabrique force l'instance à `ModifierScope.round`, alors que le catalogue la définit avec `defaultScope: ModifierScope.turn`. Après le premier tour de l'équipe cible, `_fiestaAfterTurn` ne consomme que les instances de portée `turn`; la carte reste donc active, le compteur `blockedPlayerId` est vidé, et `needsBlockedGuesser` redemande un choix à chacun de ses tours suivants. Cela viole « un tour = fin de manche + continuation » et la règle « bloqué un tour ».

**Fix :** créer l'instance avec `scope: def.defaultScope`. En même temps, à l'entrée d'une nouvelle manche, filtrer toute instance dont `m.round < round`, quelle que soit sa portée : sinon un `block_guesser` de portée `turn` non consommé parce que la M(N+1) s'est terminée pendant la continuation fuit en M(N+2). Ajouter un test provider qui choisit réellement cette carte, vérifie sa consommation après le vrai tour de la cible et son expiration à la manche suivante.

### MINOR — le contrat persistant ajouté n'est pas testé directement

**Emplacements :** `lib/models/fiesta/fiesta_state.dart:73`, `lib/models/fiesta/fiesta_state.dart:119`, `test/models/game_state_test.dart:232`.

**Scénario :** les quatre tests provider sont utiles : ils couvrent AC1, AC5, AC6, Auto et le chemin Classique, et les tests purs déjà présents couvrent ordre, égalité, exclusions et graine. Ils n'épinglent toutefois pas la forme brute de `fiesta.offerChoices` : omission quand vide, aller-retour non vide, clé absente, et éléments corrompus ignorés individuellement.

**Fix :** ajouter un test ciblé `GameState`/`FiestaState` pour ces quatre cas, sans régénérer le blob Classique figé.

## Contrôles réalisés

- La garde de 2-5 (`nextRound` hors transition), la garde de file, et le calcul de `catchUpDue` restent intacts. Hors BLOCKER, tirage, cadeaux et choix sont lus avant le changement de manche, donc un double tap ne les applique pas deux fois ; l'undo restaure le snapshot pré-choix.
- Seuls les choix sont persistés ; `offerChoices` est omise vide et relue de façon tolérante. Offres, file et cadeaux restent recalculés. Aucun bump de `kCurrentSchemaVersion` ni écriture Fiesta en Classique ne figure dans le patch.
- `blockingTeam` conserve bien l'équipe qui a choisi, les cadeaux Auto ne créent pas de file, récap et tags analytics proviennent des instances activées. Fermer `_PickThreeFlow`, revenir en arrière, ou tuer l'app pendant cette route laisse une transition actionnable : la carte permet de rouvrir le flux pour l'équipe en attente.
- Passage thermo-nuclear limité au patch : l'ajout au `GameProvider` reste concentré sur son état canonique et s'appuie sur les fonctions pures du kit. Le fichier est déjà très grand, mais ce diff ne franchit pas le seuil des 1 000 lignes et aucun découpage supplémentaire ne supprime clairement de complexité.

## Tests

Revue strictement statique : aucune commande Flutter, Dart ou de test n'a été exécutée. La valeur des quatre tests a été évaluée à la lecture ; ils ne couvrent pas le BLOCKER ci-dessus.
