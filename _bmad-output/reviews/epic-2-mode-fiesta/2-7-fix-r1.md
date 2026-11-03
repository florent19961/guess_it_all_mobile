# Correctifs r1 — story 2-7

Branche restackée sur `origin/main` (`c516b06`, 2-6 mergée) : `git rebase --onto origin/main
da47a11`, sans conflit.

| Finding | Décision | Preuve |
|---|---|---|
| **MAJOR-1** câblage provider non testé (M10, M11 survivent) | **Corrigé** : un test provider. Personnalisé, `minus_10s` fixé en M1, `startTurn` + `startTurnTimer` ; `gameMode == 'fiesta_custom'` et le `shown` porte `['minus_10s']`. | `test/providers/fiesta_round_draw_test.dart`, dernier test. M10 (`_trackWordShown` passe `null`) et M11 (`_initializeAnalytics` sans `gameMode`) rejoués : **tous deux tués** (exit 1). |
| MINOR-1 récap sans test | **Résidu assumé** (consigne lead : pas de test de récap). Fonction pure, recalcul aligné sur `catchUpPreview` (revue §4). | — |
| MINOR-2 validation après coup non testée (M13) | **Résidu assumé** (consigne lead : MINORs en doc seulement). Même chemin `_lastModifiers` que `invalidated`, qui est testé. | `analytics_service.dart`, `onWordValidatedAsGuessed` |
| MINOR-3 continuation étiquetée « actif » | **Documenté** : actifs, pas forcément appliqués ; croiser avec `isBonusContinuation`. | `docs/ANALYTICS.md`, section `modifiers` |
| MINOR-4 résidu 11 | **Documenté** : clé absente dans une partie Fiesta = inconnu, pas Classique ; le mode se lit sur `gameMode`. Note de report avec signal déclencheur. | `docs/ANALYTICS.md` ; `docs/notes_pour_plus_tard.md` (dernière entrée) |
| MINOR-5 libellé « Rattrapage » | **Laissé** (à la discrétion de Florent). | — |
| NITs (getter `gameModeId`, `pendingFiesta` vs `game.fiesta`) | **Non appliqués** : aucun code de production modifié ce round. | — |

Tests : +1 (provider), 0 retiré. Classique : le test figé de `main` sur le blob legacy passe (clés
omises, jamais `null`).
