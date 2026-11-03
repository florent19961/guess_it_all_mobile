# Revue r1 — story 2-7 « Analytics, archive et récap » (tier risqué ③ ④ ⑤)

Reviewer : Opus, adversarial. Entrée : `2-7-patch-r1.diff` (delta sur `da47a11`), code lu avant la
spec. Worktree laissé propre (`git status` vide après les mutations).

## Verdict : **NOT READY** — 1 MAJOR (test), 0 BLOCKER

Le code de production est correct sur tout ce que j'ai pu tracer : règle 7 tenue dans les deux
sens, étiquettes justes sur tous les types d'événements, Firestore additif et idempotence
intacte. Le seul problème est un trou de test : le câblage provider, d'où viennent **toutes** les
étiquettes réelles, n'est vérifié par aucun test (mutation M10 survit). Ça se corrige avec un seul
test provider.

---

## 1. Règle 7

| Point | Constat |
|---|---|
| Blob analytics du store (`guessItAll_analytics_*`) | Se relit : `gameMode` lu en `is String`, `fiestaRules` en `is Map`, `modifiers` en `is List` + `whereType<String>`. Aucun cast dur ajouté. `finalizeOrphanedGames` réécrit sans nouvelle clé (test 1, M5/M7 tuées). |
| Historique `guessItAll_game_results` | `GameResult.tryFromJson` : `mode` en `is String`, `modifierRecap` en `is List` → `whereType<Map<String,dynamic>>` → `tryFromJson` par ligne. Une ligne invalide est ignorée seule. OK. |
| Classique = mêmes clés | Les trois `toJson` passent par `if (x != null)`. `_trackWordShown` passe `null` hors Fiesta, `_initializeAnalytics` passe `gameMode`/`fiestaRules` à null, `_archiveGameResult` passe `mode`/`modifierRecap` à null. Résultat comparé au `toJson` d'avant le patch : jeu de clés identique, pas de clé à `null`. M1/M6/M8 tuées. |
| `kCurrentSchemaVersion` | Inchangé (`persisted_schema.dart:22` = 1). `game_state.dart` non touché : la forme de la partie en cours ne bouge pas. |
| `copyWith` | `gameMode`/`fiestaRules` recopiés sans paramètre (`game_analytics.dart:251-254`). `addEvent`, `computeStats` et `endGame` passent tous par `copyWith`, donc les champs survivent. Pas d'autre constructeur dans `lib/`. M2 tuée. |
| Firestore | `firebase_sync_service.dart:164-176` : `game.toJson()` + `syncedAt`, puis `.doc(gameId).set(data)`, inchangé. Règles : `create` ne vérifie que `userId`/`gameId`, et `update: if false` existait déjà. La `Map` imbriquée `fiestaRules.modifiers` a pour clés des ids du catalogue (pas de `__x__`), donc elle passe. Payload : quelques dizaines d'octets par événement, loin du 1 Mo. |

## 2. Justesse des étiquettes

Source : `_trackWordShown` (`game_provider.dart:617-635`) relit `currentTeamModifiers` (`fiesta.active`
persisté, filtré `both` ou `teamId` de l'équipe courante) **à chaque `shown`**.

| Événement | Étiquette | Verdict |
|---|---|---|
| `shown` | lue de l'état persisté | ✅ |
| `guessed` / `passed` / `expired` | `_lastModifiers` via `_recordEventWithDuration` | ✅ (M14 tuée) |
| `invalidated` | `_lastModifiers`, survit au reset du mot | ✅ (M3/M4 tuées) |
| validé après coup (`onWordValidatedAsGuessed`) | `_lastModifiers` | ✅ dans le code, **non testé** (M13 survit) → MINOR-2 |
| Reprise après kill, mot suivant | relu de l'état persisté | ✅ AC4 tenu |
| Annulation (`restorePreValidationState`) puis revalidation | même tour, aucun `shown` entre les deux → même contexte | ✅ (les doublons d'événements existaient déjà, hors périmètre) |
| Tour de continuation (M r+1) | étiquettes de la **nouvelle** manche | ✅ comme « actif ». Voir MINOR-3 sur « actif » vs « appliqué » |
| Tour suivant, autre équipe | seul `validateWords` émet entre deux tours, toujours pour le tour courant. Le prochain `shown` écrase le contexte | ✅ pas de fuite |

**Résidu 11** (vérification juste après un kill → `modifiers` absent) : la valeur est **nulle,
jamais périmée** (`resumeGame` → `_clearTrackingState`). C'est le même défaut que `round`/`turn`/
`teamId` aujourd'hui (défauts 1 / ''). Acceptable, mais à documenter → MINOR-4.

## 3. Couture 2-11 : saine

Le patch ne change rien au comportement et pose deux blocs. Le bloc « mot affiché »
(`_lastShownTimestamp`, `_lastShownWord`) est le seul que 2-11 devra remplacer par une
`Map<word, timestamp>`. Le bloc « contexte du tour », qui contient `_lastModifiers`, est par
nature indépendant du nombre de mots à l'écran. Le contrat est écrit à deux endroits : le
commentaire de `_recordEventWithDuration` et `docs/ANALYTICS.md`. 2-11 n'aura rien à défaire ici.

## 4. Récap recalculé

- **Tirage** : `roundModifiers(rules, gameId, round)` est exactement l'appel fait par
  `startGame` (M1) et `_fiestaForRound` (M2/M3), fixés du mode Personnalisé compris. Il est
  déterministe (FNV-1a), donc identique à ce qui a été appliqué.
- **Rattrapage** : `catchUpPreview` calcule sur `t.score` à la transition. Le récap calcule sur
  `scoreByRound.take(r)`. Les deux sont égaux pour trois raisons :
  1. `score` et `scoreByRound` sont toujours mis à jour ensemble (`game_provider.dart:932-937`, le seul endroit qui les modifie).
  2. Les points d'une continuation vont dans `scoreByRound[r]`, la manche suivante.
  3. L'annulation restaure les deux ensemble (`:1551-1553`).
- **`roundsPlayed`** : il vaut 3 sur les deux chemins de fin, que ce soit `validateWords` en M3 ou `nextRound` > 3, qui ne modifie pas `currentRound`.
- **Limite connue** (« accordé » au lieu de « consommé ») : jugée **acceptable**. C'est ce que
  la transition a annoncé aux joueurs. Le cas où ça ne correspond pas (une équipe qui ne rejoue
  jamais un tour normal dans la manche suivante) est rare et sans enjeu. Correction de libellé
  bon marché proposée en MINOR-5.

## 5. Interprétations

| # | Interprétation | Verdict |
|---|---|---|
| `gameMode` absent en Classique | La spec propose `'classique'` dans le périmètre, mais l'AC1 (« aucune clé nouvelle ») l'emporte. Absent = Classique ou ancienne version, ce qui revient au même puisque Fiesta n'est jamais sorti en store (dernier tag `v1.0`). | ✅ conforme |
| Pas de `HistoryEntry.modifiers` | Aucun AC ne le demande. La décision d'epic (« chaque événement de mot ») est couverte par les événements, et ça évite de toucher le point de collision `game_state.dart`. L'écart est journalisé dans `tracking_evolution.md`. | ✅ conforme |
| `[]` en Fiesta sans modificateur | Cohérent avec « rien n'est exclu » et distingue « Fiesta sans modificateur » d'« inconnu ». Les doublons sont gardés, et le nombre compte (`minus_10s` ×2). | ✅ conforme |

Aucune interprétation ne contredit les décisions.

## 6. Mutation testing (`test/services/fiesta_analytics_test.dart`, 5 tests)

| Mutation | Résultat |
|---|---|
| M1 garde `modifiers` retirée de `WordEvent.toJson` | tuée |
| M2 `copyWith` perd `gameMode` | tuée |
| M3 `invalidated` sans étiquette | tuée |
| M4 reset de `_lastModifiers` dans `_recordEventWithDuration` | tuée |
| M5 `WordEvent.fromJson` ignore `modifiers` | tuée |
| M6 garde `gameMode` retirée de `GameAnalytics.toJson` | tuée |
| M7 `GameAnalytics.fromJson` ignore `gameMode` | tuée |
| M8 garde `mode` retirée de `GameResult.toJson` | tuée |
| M9 `GameResult.fromJson` ignore `modifierRecap` | tuée |
| M14 `guessed`/`passed` sans étiquette | tuée |
| **M10 `_trackWordShown` passe `null`** | **survit** |
| **M11 `_initializeAnalytics` ne passe pas `gameMode`** | **survit** |
| M12 `buildModifierRecap` ignore la borne `roundsPlayed` | survit |
| M13 validation après coup sans étiquette | survit |
| M15 `_archiveGameResult` perd le récap | survit |

Aucun autre test ne référence ces symboles (vérifié par grep sur `test/`). Les tests du service et
des modèles valent bien leur coût. Le provider et le récap ne sont pas couverts du tout.

---

## Findings

### MAJOR-1 : le câblage provider des étiquettes n'est pas testé (M10, M11 survivent)

- **Où** : `lib/providers/game_provider.dart:630-634` (`modifiers:` de `_trackWordShown`) et
  `:519-521` (`gameMode`/`fiestaRules` dans `_initializeAnalytics`).
- **Scénario** : un refactor de 2-8 à 2-11 (qui retouchent tous `_trackWordShown`) passe
  `null`, lit l'équipe suivante, ou lit un cache mémoire au lieu de `fiesta.active`. Toute la
  télémétrie Fiesta en production perd ses étiquettes, et la suite reste verte. Les tests de
  service passent les modificateurs **à la main** : ils ne prouvent ni l'AC2 (« tiré en M2 →
  l'événement porte `minus_10s` ») ni l'AC4 (« relu de l'état persisté ») de bout en bout.
- **Correction** : un test provider de ~25 lignes, sur le modèle de
  `test/providers/turn_time_fiesta_test.dart`. Lancer une partie Personnalisé avec `minus_10s`
  fixé en M1, appeler `startTurn()` + `startTurnTimer()`, puis vérifier
  `analytics.currentGame!.gameMode == 'fiesta_custom'` et que le dernier événement `shown` a
  `modifiers == ['minus_10s']`. En option, ajouter un kill (`forgetCurrentGame` + rechargement)
  avant le `shown` pour couvrir l'AC4. Ce test tue M10 et M11.

### MINOR-1 : `buildModifierRecap` n'a aucun test (M12, M15 survivent)

- **Où** : `lib/models/fiesta/modifier_recap.dart:26-75`, `game_provider.dart:1225`.
- **Scénario** : la borne `round < roundsPlayed`, la reconstitution des scores cumulés et le
  signe du malus du leader ne sont vérifiés nulle part. Une erreur s'afficherait et serait
  archivée pour toujours dans l'historique.
- **Correction** : un test unitaire pur. Deux équipes, `scoreByRound` [5,0,0] et [1,0,0], règles
  Auto, `roundsPlayed: 3` : vérifier une ligne « Rattrapage » avec le malus en « − » et l'écart
  en « + », et l'égalité avec `computeCatchUp` sur `t.score`. Optionnel : `roundsPlayed: 1` → pas
  de ligne Rattrapage.

### MINOR-2 : validation après coup non testée (M13 survit)

- **Où** : `lib/services/analytics_service.dart:252`.
- **Correction** : ajouter `onWordPassed` + `onWordValidatedAsGuessed` au test 3, qui balaie déjà tous les événements. Une ligne.

### MINOR-3 : en continuation, l'étiquette dit « actif » alors que l'effet ne s'applique pas

- **Où** : `game_provider.dart:630` et `composeTurnSeconds` (une continuation garde ses secondes
  « sans modificateur », Q5).
- **Scénario** : `minus_10s` tiré en M2. Les mots de la continuation en début de M2 portent
  `['minus_10s']`, alors que le tour n'a pas eu −10 s. Pour recalibrer les poids, ces mots
  biaisent légèrement la mesure.
- **Correction** : aucune dans le code. Une phrase dans `docs/ANALYTICS.md` : « `modifiers` =
  actifs pour l'équipe, pas forcément appliqués : une continuation ignore les effets de durée.
  Croiser avec `turn`/`HistoryEntry.isBonusContinuation` ».

### MINOR-4 : documenter le résidu 11 pour qui lira les données

- **Où** : `docs/ANALYTICS.md` (section `modifiers`).
- **Scénario** : dans une partie qui a un `gameMode`, un événement `invalidated` sans `modifiers`
  (vérification juste après un kill) sera lu comme Classique par un analyste.
- **Correction** : dire explicitement « dans une partie Fiesta, une clé absente = inconnu (reprise
  après kill), pas Classique ». Pour une vraie correction, hors périmètre, `resumeGame` pourrait
  restaurer `round`/`turn`/`teamId`/`playerId`/`modifiers` depuis le dernier événement relu. Ça
  corrigerait aussi le défaut existant de `round`. À consigner dans `notes_pour_plus_tard.md` si
  ce n'est pas fait.

### MINOR-5 : libellé du rattrapage

- **Où** : `modifier_recap.dart:65` (`title: 'Rattrapage'`).
- **Correction** : `'Rattrapage annoncé'`, ou garder tel quel. Ça aligne le texte sur la limite
  assumée sans rien coûter. À la discrétion de Florent.

### NIT (grille thermo-nucléaire, limitée au diff)

- `_game.fiesta == null ? null : fiestaModeId(_game.fiesta!.rules)` est dupliqué
  (`game_provider.dart:520` et `:1224`). Un getter `String? get gameModeId` supprimerait les
  deux ternaires et le `!`.
- `_archiveGameResult` : `_game.fiesta == null ? null : modifierRecap` reproduit la garde que le
  getter fait déjà (il renvoie `const []` en Classique). Acceptable, parce que null (clé absente)
  ≠ `[]` (Fiesta sans rien) : garder, mais sans redupliquer le test.
- `results_screen.dart:353` lit `provider.pendingFiesta` (concept de configuration) au lieu de
  `provider.game.fiesta!.rules` (la règle gelée). C'est équivalent par invariant, mais la branche
  `rules == null` est impossible quand `isFiesta` est vrai. Lire `game.fiesta` supprime la
  branche.
- `fiestaRules.ensembleName` est du texte libre saisi par l'utilisateur et envoyé à Firestore.
  C'est dans la lignée des mots saisis à la main (déjà envoyés via `wordMetadata`), donc pas un
  écart. À savoir.
- Taille : `game_provider.dart` passait déjà les 1 000 lignes avant le patch (1 588 après, +16).
  Le diff provider est **focalisé** (import, deux arguments, un getter, deux champs) : le calcul
  est bien sorti dans `modifier_recap.dart`, une fonction pure. Pas de code « spaghetti » ajouté
  dans les flux existants.
- Placer `ModifierRecapLine` dans `game_result.dart` est cohérent avec « archivé tel
  qu'affiché ».

## Pour passer READY

MAJOR-1 (un test provider). MINOR-1 et MINOR-2 sont recommandés dans le même tour, faits en
tests seulement. MINOR-3 et MINOR-4 relèvent de la documentation. Aucune modification du code de
production n'est requise.
