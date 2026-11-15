# Mutation testing r1 — L-CACHE

Run by the implementer (Codex sandbox can't run `flutter test`). Each mutant was applied, these files were run
(`fiesta_turn_effects`, `fiesta_turn_reveal`, `fiesta_continuation_cartridges`, `turn_time_fiesta`,
`fiesta_cartridges`, `fiesta_catalog`), then restored with `git checkout -- <file>`; `git status` is clean
after each run.

| # | Mutation | Test qui le tue | Résultat |
|---|---|---|---|
| M1 | `passBlocked` ignore `hasFreePass` | `fiesta_turn_effects_test` « Passe gratuite + Interdit de passer » | tué |
| M2 | paire `no_pass` / `free_pass` remise dans `areCompatible` | même test + `fiesta_catalog_test` « symétrique » | tué |
| M3 | `_receivedHidden` toujours faux (rien de caché) | `fiesta_turn_reveal_test` « aucun malus reçu… » + `turn_time_fiesta_test` (aperçu 30) | tué |
| M4 | `_receivedHidden` sans `!isContinuation` | `fiesta_continuation_cartridges_test` « un −10 s déjà appliqué… » | tué |
| M5 | `_hasTurnReveal` ignore le piège | `fiesta_turn_reveal_test` « …jamais pour le joueur piégé… » | tué |
| M6 | `_hasTurnReveal` ignore la continuation | `fiesta_continuation_cartridges_test` « un −10 s déjà appliqué… » | **survivant au 1er passage** → assertion ajoutée (continuation : `startTurn` → décompte), puis tué |
| M7 | `startTurn` va toujours au décompte | `fiesta_turn_reveal_test` « aucun malus reçu… » + « app tuée… » | tué |
| M8 | écran révélé non persisté (`startTurn` sans `_saveGameState`) | `fiesta_turn_reveal_test` « app tuée sur « Ce qui t'attend » » | tué |
| M9 | `leaveTurnReveal` sans garde d'écran | — | **survivant assumé** : garde défensive, seul l'écran l'appelle ; pas de test (règle des tests minimaux) |

Écran « Ce qui t'attend » vérifié dans le code (`lib/screens/turn_reveal_screen.dart`) : « Déjà activé » est une
liste, une ligne par règle de manche (« Règle de la manche ») puis par bonus (« Ton bonus »). Pas de doublon
possible avec « On vient de t'infliger » : règles = `fromTeamId == null`, reçus = `fromTeamId != null`, bonus =
ids de cartouche seulement (jamais règle ni malus). Aucune correction nécessaire.
