# Revue « epic fix » Fiesta — r1

Tier **risqué** : ① machine à états (continuation, passage de manche, double validation), ②
scoring (×2, graphe), ③ persistance (`fiesta`, ensembles, `HistoryEntry`, `GameResult`), ⑤
intégrité analytics (kill). Lire `epic-fix-patch-r1.diff`, calculé contre la merge-base avec
`origin/main` (`f3de831`). 9 commits, un par point.

Sources :
- `epic-review-opus.md` et `epic-review-codex.md` (findings d'origine) ;
- `journal-arbitrages.md` ;
- `_bmad-output/specs/fiesta/epic-fiesta.md` (Q5, Q8).

Décisions de Florent :
- phase A = A1 à A5 ;
- phase B = B1 à B5, toutes ses recommandations validées.

## Ce que fait chaque commit

| # | Commit | Finding d'origine |
|---|---|---|
| A1 | garde d'écran `validateWords` + `savePreValidationState` | Opus M4 |
| A2 | interrupteur `carryOver` retiré (modèle + UI) | Opus M1 |
| A3 | `block_guesser` : proposé seulement, dès M2 (défaut, éditeur, validation) | Opus M2 |
| A4 | clés vides ou nulles omises (blob Fiesta, ensembles) | Codex MAJOR-4, Opus m9 |
| A5 | analytics : `WordEventContext` explicite, terminal sans durée après un kill | Codex MAJOR-2, Opus m4 |
| B1+B2 | règle de la continuation, `FiestaTurnState` typé, `planRoundTransition` pur | Codex MAJOR-1/5, Opus M3/M5, m1-m3, m8 |
| B3 | `HistoryEntry.pointsScored` optionnel, graphe sur `points` | Codex MAJOR-3 |
| B4 | aucun code : contrat Classique = règle 7 | Codex BLOCKER-1 |
| B5 | récap archivé en faits (`ModifierRecapItem`), texte formé à l'affichage | Opus m6 (et m7 en partie) |

## Interprétations prises (à challenger)

### 1. Règle de la continuation (B1)

**Ce qui s'applique.** La continuation est le MÊME tour que la fin de N. Elle joue avec ce qui
pesait sur l'équipe pendant ce tour de N :
- les modificateurs de manche de N (`no_pass`, `reversed`, `free_pass`…) ;
- ×2 / deux mots `spent` ;
- le compteur de passes gratuites ;
- le `block_guesser` de N et le devineur bloqué.

**Ce qui ne s'applique pas.** Rien de N+1 : ni tirage, ni cadeaux, ni choix (y compris un
`block_guesser` choisi pour N+1), ni charges.

> ⚠️ Lecture (a) retenue entre deux possibles. La lecture (b) aurait gardé seulement l'état du
> tour et les instances de portée tour, sans les modificateurs de manche de N. (a) donne un sens
> au « compteur de passes gratuites » gardé, et le plafond tenu en N tient par construction.
> À confirmer par l'orchestrateur ou Florent.

**Mécanisme.**
- `isContinuation` est dérivé de l'historique : l'équipe a joué la dernière entrée de N-1 et n'a
  aucune entrée en N. Il ne vient pas de `turnBonusTime`, que `startTurnTimer` efface et qui est
  aussi non nul sur la vérification de fin de manche.
- `currentTeamModifiers` = `modifiersForTurn(manche logique)`, la manche logique valant
  `round - 1` sur une continuation.
- `plan.apply` garde les instances de N et retire celles d'avant N.
- La fin d'une continuation (`_fiestaAfterTurn`) retire toutes les instances de manche < courante.
- Sur une continuation, aucune charge ne s'allume (`_chargesLeft` = 0).
- `malusToReveal` vaut au premier VRAI tour, pour tous les malus. Le cas spécial `minus_10s` /
  `firstFullTurn` disparaît, ce qui corrige m3.
- `blockingTeam` cherche le choix de la manche de l'instance effective.

**Coin non traité, à juger.** Une continuation qui finit à elle seule la manche N+1 enchaîne
une 2ᵉ continuation en N+2 avec la manche logique N+1.

### 2. B2 et B1 dans un seul commit

La règle repose sur le modèle. Choses à vérifier :
- `FiestaTurnState` garde les clés JSON exactes. Les valeurs `armed`/`spent` sont les `name` de
  `ChargeState`. `freePassesUsed` est omis à 0 : avant, la clé n'était jamais écrite à 0.
- `_fiestaForRound` a disparu. Aperçu (`nextRoundModifiers`, `appBoostPreview`,
  `catchUpPreview`) et `nextRound` lisent `_transitionPlan`.
- `_pendingChoices` sert encore à la file. Le plan relit `offerChoices` de la manche suivante :
  même source.
- `FiestaView` (~400 lignes) est reporté dans `notes_pour_plus_tard.md`. Le provider passe de
  2 067 à 2 026 lignes.

### 3. Analytics (A5)

- Le service ne garde plus aucun contexte en mémoire : les champs `_last*` ont été supprimés.
- Un terminal sans `shown` en mémoire est écrit avec `durationMs` nul. Le `shown` lui-même peut
  manquer, parce que les événements sont sauvegardés en fin de tour et à la mise en
  arrière-plan.
- `WordRoundStats` compte une durée nulle comme 0 ms, comme il le faisait déjà pour la
  validation a posteriori. C'est documenté.
- Les factories `WordEvent.shown` / `withDuration`, devenues orphelines, ont été supprimées.

### 4. Persistance

- `HistoryEntry.pointsScored` est le seul ajout de premier niveau dans `guessItAll_gameState`.
  Il est approuvé : jamais écrit en Classique, absent = un point par mot.
- `carryOver` : l'ancienne clé est ignorée à la relecture. Le blob figé des ensembles la contient
  encore et se relit.
- Une ligne de récap `{title, detail}` (build de dev) est ignorée seule. La forme ancienne n'est
  pas relue : rien n'a été publié.
- `kCurrentSchemaVersion` est inchangé.

### 5. Tests

- **Ajoutés :**
  - A1 double tap ;
  - A3 validation ;
  - A4 sérialisation figée ;
  - A5 vrai redémarrage, en plein tour à deux cartes et sur la vérification ;
  - B1 scénario M2→M3 (×2 + deux tirages + blocage de M2, kill, retour arrière) ;
  - B3 dernier point du graphe = score.
- **Réécrit :** `pick_three` « Bloquer un devineur » (ex-:151), qui figeait l'ancien comportement.
- **Mis à jour parce qu'ils figeaient l'ancienne continuation :**
  - `double_points` : continuation, et activation en continuation, désormais refusée ;
  - `round_draw` ;
  - `turn_time_fiesta`.
- **Helpers corrigés :** `pick_three.playTurn` et `freeze_test`, qui validaient sans passer par
  `endTurn` (bloqué par A1).
- Tous les tests nouveaux ou réécrits ont été vus rouges avant le correctif, ou tués par mutant.
- Suite complète : **213/213**, format et analyze verts.
- Le graphe B3 est testé sur `Σ HistoryEntry.points`, la seule valeur que le widget cumule. Le
  widget n'est pas testé, conformément à la règle « pas de widget test ».

## Questions précises

1. La règle de la continuation tient-elle sur **tous** les chemins ? Chemins à suivre :
   - kill avant ou pendant la continuation, et sur sa vérification ;
   - retour arrière depuis le vrai tour suivant ;
   - double tap ;
   - `two_words` qui tire la carte B au départ de la continuation ;
   - rattrapage consommé au premier vrai tour (`turnBonusTime == null`, inchangé) ;
   - égalité de scores.
2. `isContinuation` dérivé de l'historique : trouves-tu un état où il se trompe ? Pistes :
   - entrée de continuation fusionnée (`isBonusContinuation`) ou non ;
   - M1 ;
   - partie reprise d'avant ce correctif ;
   - partie à 3 équipes.
3. `plan.apply` / `_fiestaAfterTurn` : une instance peut-elle survivre indûment ou être perdue ?
   Exemple : un `block_guesser` de N contre une équipe qui ne joue pas en N.
4. A5 : un événement peut-il partir avec le contexte du tour **suivant** ? Le contexte est lu
   avant les mutations dans `markWordAsGuessed`, `passWord`, `endTurn` et `validateWords`.
5. Mutation testing sur les tests ajoutés et réécrits.
6. Grille thermo-nucléaire limitée au diff : reste-t-il une duplication ou une racine à
   simplifier ?

Format attendu : verdict READY / NOT READY, puis findings BLOCKER / MAJOR / MINOR avec
`fichier:ligne` et scénario.
