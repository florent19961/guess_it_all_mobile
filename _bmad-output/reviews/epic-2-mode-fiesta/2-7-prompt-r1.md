# Revue r1 — story 2-7 « Analytics, archive et récap des modificateurs » (tier risqué : intégrité analytics ⑤ + formes persistées ③ + payload Firestore ④)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-7-patch-r1.diff` (même
dossier), calculé contre `da47a11` (pointe de `feat/fiesta-2-6`, sur laquelle la lane est
empilée) — jamais `git diff` toi-même. Tu lis le code **avant** la spec, puis tu confrontes.
Rapport dans `2-7-review-r1.md` (même dossier). **Mutation testing obligatoire** sur les tests
ajoutés.

## Objectif de la story

Spec : `_bmad-output/specs/fiesta/2-7-analytics-archive-recap.md` (AC 1 à 6). Epic :
`_bmad-output/specs/fiesta/epic-fiesta.md` (ordre 2-7 → 2-11, § pourquoi les analytics passent
avant les effets de tour).

Chaque événement de mot porte les modificateurs actifs pour l'équipe qui joue ; la partie porte
son mode et ses règles Fiesta ; l'historique archive le mode et un récap ; l'écran Résultats
affiche une carte « Modificateurs de la partie » en Fiesta.

## Décisions déjà prises (ne pas rouvrir)

- Champs **additifs nullables** ; rien n'est exclu des stats ; la difficulté initiale du mot ne
  change pas (`computeStats`, `WordHistoryService` intouchés).
- 🔴 Règle 7 : tout blob analytics (`guessItAll_analytics_*`, **non enveloppé**), historique
  (`guessItAll_game_results`) ou document Firestore écrit par la version en store se relit ; une
  partie **Classique** écrit exactement l'ancienne forme (AC1 : aucune clé nouvelle, même pas
  `null`). Pas de bump `kCurrentSchemaVersion`.
- 2-11 (deux mots) réécrira le suivi « un mot affiché » : ici, contrat explicité / couture
  préparée seulement, pas de changement de comportement.
- Tests au minimum, pas de test de widget.

## Interprétations de l'implémenteur (à challenger)

1. **Clé absente en Classique** : `if (x != null)` dans chaque `toJson` ; relecture
   `is List` / `is String` / `is Map`, sans cast dur.
2. **`modifiers` = contexte du TOUR** : `_lastModifiers` à côté de `_lastRound`, effacé
   seulement par `_clearTrackingState`, donc `invalidated` / validation a posteriori gardent
   l'étiquette après le reset de `_lastShownWord`. Le provider (`_trackWordShown`) relit
   `currentTeamModifiers` (état persisté) à **chaque** mot : AC4 tient pour les mots affichés
   après un kill. Résidu connu : une vérification juste après un kill, sans nouveau `shown`, sort
   avec `modifiers` nul — comme `round`/`turn`/`teamId` aujourd'hui (défauts 1 / ''), hors
   périmètre.
3. **`[]` ≠ absent** : Fiesta sans modificateur ce tour écrit `[]`. Les doublons (deux
   `minus_10s`) sont gardés.
4. **Couture 2-11** : le service sépare le bloc « mot affiché » (`_lastShownTimestamp`,
   `_lastShownWord`) du « contexte du tour » ; le contrat « un seul mot à l'écran » est écrit sur
   `_recordEventWithDuration` et dans `docs/ANALYTICS.md`.
5. **`gameMode`** = `fiesta_auto` / `fiesta_custom` (absent = Classique, pas `'classique'` :
   AC1 l'interdit). `fiestaRules` = `FiestaRules.toJson()` brut.
6. **Pas de `HistoryEntry.modifiers`** (listé au périmètre, demandé par aucun AC) : la
   granularité tour est déjà dans les events, et ça évite de toucher la forme de la partie en
   cours (`game_state.dart`, point de collision). À challenger.
7. **Récap recalculé** (`lib/models/fiesta/modifier_recap.dart`) : tirage par la graine
   `(gameId, manche)` via `roundModifiers` ; rattrapage via `computeCatchUp` sur les scores
   cumulés `scoreByRound[0..r-1]`. Hypothèse : ces cumuls valent les scores vus à la transition
   (les points d'une continuation vont dans la manche suivante). Limite assumée : le rattrapage
   affiché est **accordé**, même si l'équipe n'a pas joué dans la manche suivante. Sections
   1 parmi 3 / bonus utilisés / joueurs bloqués masquées (stories à venir).
8. **Archivé tel qu'affiché** : `ModifierRecapLine{title, detail}` dans `GameResult` ; le
   libellé du mode (pill) se calcule depuis `pendingFiesta` à l'écran, n'est pas archivé.

## Questions précises

- **`copyWith` de `GameAnalytics`** : `gameMode` / `fiestaRules` survivent-ils à `addEvent`,
  `computeStats`, `endGame`, `finalizeOrphanedGames` ?
- **Chemins d'événements** : `shown`, `guessed`, `passed`, `expired`, `invalidated`, validation
  a posteriori (passed / expired) — chacun porte-t-il `modifiers` ? Un chemin où l'étiquette d'un
  tour fuit dans le tour suivant (équipe différente) avant le premier `shown` ?
- **Recalcul du récap** : la graine donne-t-elle exactement le tirage joué en M1/M2/M3, mode
  Personnalisé avec modificateurs fixés compris ? Les cumuls de `scoreByRound` égalent-ils les
  scores de la transition dans tous les cas (continuation, mots refusés en fin de manche, retour
  arrière, partie terminée par `nextRound` > 3) ? `roundsPlayed` vaut-il bien 3 en fin de partie ?
- **Écran** : `pendingFiesta` est-il garanti non nul sur l'écran Résultats d'une partie Fiesta
  (reprise après kill comprise) ?
- **Firestore** : le payload reste-t-il additif ? Une `Map` imbriquée (`fiestaRules.modifiers`)
  passe-t-elle les règles (`FIREBASE.md`) ?
- **Valeur des tests** (mutation) : garde `if (modifiers != null)` retirée, `copyWith` qui perd
  `gameMode`, `invalidated` non étiqueté, reset de `_lastModifiers` dans
  `_recordEventWithDuration`, `tryFromJson` qui ignore `modifiers`. Chaque assertion mord-elle ?
  (L'implémenteur a vérifié les trois premiers.)
- Les deux plateformes : rien de `Platform.*` ; la carte défile sur petit écran ?

## Format attendu

Pour chaque finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, scénario
concret, correction proposée. Verdict final : READY ou NOT READY.
