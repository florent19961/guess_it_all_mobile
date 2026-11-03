# Revue epic fix Fiesta — r1

## Verdict : NOT READY

Revue **strictement statique** du patch imposé `epic-fix-patch-r1.diff`, du
code du worktree, des deux revues initiales et des arbitrages. Aucun programme
Flutter/Dart ni aucun test n'a été exécuté ; aucune recette appareil n'est
couverte par ce rapport.

## Findings

### BLOCKER

Aucun.

### MAJOR

#### MAJOR-1 — une continuation en chaîne réutilise l'état de tour de deux manches auparavant

- **Emplacements :** `lib/providers/game_provider.dart:1110-1133`,
  `lib/models/fiesta/turn_effects.dart:79-81`,
  `lib/models/fiesta/round_transition.dart:44-52`,
  `lib/providers/game_provider.dart:1279-1295`.
- **Scénario :** l'équipe A finit M1 avec, par exemple, `double_points` dépensé
  (ou un devineur déjà bloqué). Sa continuation en M2 vide à elle seule le
  pool de M2. `validateWords` ouvre alors M3 sans appeler `_fiestaAfterTurn` :
  il conserve `FiestaTurnState` via `afterRoundEnd()` (ligne 1130). Le plan M3
  enlève bien les instances M1, mais ne vide pas ce state. M3 est de nouveau
  reconnu comme continuation et applique les instances M2 (lignes 1279-1295)
  **en plus** de `double_points`/`two_words`, `freePassesUsed` ou
  `blockedPlayerId` encore issus de M1.
- **Impact :** le plafond de deux ne tient plus : deux effets M2 + un bonus
  dépensé M1 font trois, et deux bonus M1 font quatre. Un `block_guesser` M2
  peut aussi être considéré comme déjà choisi grâce au `blockedPlayerId` M1,
  donc ne pas être annoncé puis être consommé à la fin de cette seconde
  continuation. C'est exactement la famille B1/Codex MAJOR-1 qu'une manche
  logique devait éliminer. Le kill, l'undo et une double validation
  persistante/rejouée conservent ce même état fautif.
- **Fix :** faire posséder ce cas au cycle pur de `FiestaTurnState`/transition :
  lorsqu'une **continuation** termine encore une manche, finaliser d'abord son
  tour logique N (state vide et instances N consommées), puis appliquer le
  plan vers N+2. La nouvelle continuation doit ainsi n'avoir que le contexte
  M(N+1), jamais celui de M(N). Ajouter un test M1→M2→M3 où la continuation
  M2 termine le pool, avec ×2/deux mots et `block_guesser`, puis kill, undo et
  double tap.

`test/providers/fiesta_pick_three_test.dart:195-288` a une bonne valeur pour
le chemin normal M2→M3 (plafond, kill et undo), mais il ne termine pas M2 dans
sa continuation et ne peut donc pas détecter cette chaîne.

### MINOR

Aucun.

## Vérification des constats initiaux et des décisions

| Constat initial | État statique | Preuves |
|---|---|---|
| Opus M1 — réglage `carryOver` inopérant | Corrigé : l'interrupteur et l'écriture disparaissent ; l'ancienne clé est ignorée à la lecture. | `lib/widgets/fiesta/fiesta_setup_widgets.dart:267-295`, `lib/models/fiesta/fiesta_rules.dart:138-165,171-216` |
| Opus M2 — `block_guesser` inatteignable | Corrigé pour les nouveaux/édités ensembles : défaut offer M2, éditeur limité et validateur défensif. | `lib/models/fiesta/fiesta_ensemble.dart:39-62`, `lib/screens/fiesta_ensemble_editor_screen.dart:249-264`, `lib/models/fiesta/ensemble_validation.dart:29-33` |
| Opus M3 — blocage N+1 brûlé par la continuation | Corrigé sur le chemin simple : manche logique, sélection seulement à son effet réel, consommation des instances appliquées. **Reste cassé dans MAJOR-1 pour la continuation en chaîne.** | `lib/models/fiesta/round_transition.dart:91-105`, `lib/providers/game_provider.dart:1279-1295,1476-1488,1588-1603` |
| Opus M4 — double validation | Corrigé sans bloquer la validation légitime : les deux gardes admettent l'écran Vérification, dont une reprise, et refusent seulement l'appel après mutation. | `lib/providers/game_provider.dart:1004-1009,1948-1967`; reprise : `lib/providers/game_provider.dart:1709-1724` |
| Opus m6 — récap figé en français | Corrigé : archivage en faits, formatage à l'affichage ; une ancienne ligne `{title,detail}` devient un item illisible ignoré seul. | `lib/models/game_result.dart:72-117,182-231`, `lib/models/fiesta/modifier_recap.dart:37-80,85-156` |
| Opus m9 — clés Fiesta vides/null | Corrigé : `active`, `turn`, `catchUpDue`, ids optionnels, `fixedRound`, `ensembleName` et `lastUsedId` sont conditionnels ; les lecteurs restent tolérants. | `lib/models/fiesta/fiesta_state.dart:66-129`, `lib/models/fiesta/fiesta_rules.dart:28-56,154-216`, `lib/models/fiesta/modifier_instance.dart:39-85`, `lib/services/fiesta_ensemble_service.dart:180-190` |
| Codex BLOCKER-1 — `turnAllottedSeconds` Classique | Décision Florent explicitement validée : ajout optionnel, pas changement de forme, lecture tolérante. Le champ reste hors du présent diff fonctionnel. | `_bmad-output/reviews/epic-2-mode-fiesta/journal-arbitrages.md:38`, `docs/tracking_evolution.md:620-630`, `lib/models/game_state.dart:306-312` |
| Codex MAJOR-1 — plafond/effets N et N+1 | Corrigé pour une continuation ordinaire par `modifiersForTurn` et le refus d'armer ; **MAJOR-1 ci-dessus révèle le trou de la continuation en chaîne.** | `lib/providers/game_provider.dart:1378-1417`, `lib/models/fiesta/round_transition.dart:91-105` |
| Codex MAJOR-2 — analytics après kill | Corrigé : contexte explicite lu avant mutation ; terminal sans `shown` en mémoire est ajouté avec `durationMs: null`, jamais inventé. | `lib/providers/game_provider.dart:664-680,1031-1042`, `lib/services/analytics_service.dart:161-215`, test ciblé `test/providers/fiesta_two_words_test.dart:241-301` |
| Codex MAJOR-3 — graphe ne compte pas ×2 | Corrigé : points optionnels, absence = nombre de mots ; le graphe cumule `entry.points`. Classique n'écrit pas la clé car le multiplicateur vaut un. | `lib/models/game_state.dart:15-70`, `lib/providers/game_provider.dart:1015-1029,1070-1104`, `lib/screens/stats_screen.dart:348-379` |
| Codex MAJOR-4 — persistance conditionnelle | Corrigé avec lectures tolérantes et sérialisation gelée. `carryOver` est accepté/ignoré ; une arrivée `block_guesser` invalide est signalée. | `lib/models/fiesta/fiesta_state.dart:66-129`, `lib/models/fiesta/fiesta_rules.dart:138-216`, `lib/models/fiesta/ensemble_validation.dart:14-80`, `test/services/fiesta_ensemble_service_test.dart:68-120` |
| Codex MAJOR-5 — état magique/provider géant | Partiellement corrigé et explicitement différé : `FiestaTurnState`, `planRoundTransition` et la table de charges retirent une vraie duplication ; l'extraction `FiestaView` reste reportée. | `lib/models/fiesta/turn_effects.dart:7-107`, `lib/models/fiesta/round_transition.dart:8-105`, `docs/notes_pour_plus_tard.md:213-232` |

## Contrats contrôlés

- **B1, chemin normal :** `isContinuation` est historique et survit à la
  reprise/à l'undo (`game_provider.dart:1262-1284`), les instances sont
  filtrées par manche logique (`:1286-1295`), les charges sont indisponibles
  pendant une continuation (`:1378-1392`) et `catchUpDue` n'est consommé que
  si `turnBonusTime == null` (`:584-599`). Les gardes de transition et de
  validation rendent leurs doubles taps idempotents (`:1203-1209`, `:1004-1009`).
  MAJOR-1 est l'exception non couverte à cette conclusion.
- **B2 :** les seules clés de `turn` restent `freePassesUsed`,
  `blockedPlayerId`, `doublePoints`, `twoWords`, `secondWord` et
  `secondExpiredWord`; elles sont conditionnelles et le parsing est clé par
  clé tolérant (`turn_effects.dart:83-105`). Le plan pur alimente les trois
  aperçus et l'application (`game_provider.dart:1239-1260,1583-1586`).
- **Persistance :** `kCurrentSchemaVersion` reste à 1
  (`lib/services/persisted_schema.dart:18-22`). Dans ce correctif, le seul
  ajout à l'historique de `guessItAll_gameState` est `pointsScored`, optionnel
  et approuvé. Le récap Fiesta non publié bascule en ids ; l'ancien texte est
  ignoré sans crash. Aucune clé racine `guessItAll_*` n'est renommée.
- **Analytics/Classique :** les appels Classique gardent `modifiers: null`,
  donc l'ancienne forme JSON (`lib/providers/game_provider.dart:668-680`,
  `lib/models/word_event.dart:48-61`). Le seul changement voulu après kill est
  l'ajout d'un terminal à durée inconnue ; les parcours ordinaires émettent les
  mêmes types et contexte d'événements.

## Qualité et valeur des tests, par lecture

Les tests ajoutés visent de vrais invariants risqués : sérialisation figée,
double validation, reprise analytics avec deux cartes, score ×2 et chemin
normal M2→M3 avec kill/undo. Le refactor ne se contente pas de déplacer le
code : il remplace la map typée à l'exécution et les trois dérivations de
transition par des frontières pures. En revanche, MAJOR-1 montre que la
frontière de cycle de vie n'est pas encore complète : `afterRoundEnd()` est
inconditionnel alors que la continuation peut clôturer une autre manche.
L'extraction de la vue Fiesta est un report explicite, pas un oubli, mais le
provider reste à 2 026 lignes et ce correctif doit fermer le trou de cycle
avant approbation.
