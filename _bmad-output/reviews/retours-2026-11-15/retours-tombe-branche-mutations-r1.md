# Mutation testing r1 — L-TOMBE-BRANCHEMENT (`feat/retours-tombe-branche`)

Fait par l'implémenteur (la revue Codex est statique). Un mutant à la fois, appliqué par remplacement exact de
texte, contre `test/providers/fiesta_cartridge_drop_test.dart` seul
(`scripts/with-test-slot.sh flutter test …`), fichier restauré après chaque run. Script :
`/tmp/claude-1000/-home-florent19961-guess-it-all-audit/565d58c7-0639-4f50-b64e-014941061f77/scratchpad/mut/run.py`.

| # | Mutant (fichier) | Résultat | Test qui le tue |
|---|---|---|---|
| M1 | `startTurn` n'appelle plus `_drawDrop` (provider) | tué | les 4 |
| M2 | `FiestaTurnState.toJson` n'écrit plus `drop` (turn_effects) | tué | (a) app tuée |
| M3 | `fromJson` ignore `drop` (`drop is Map && false`, compile) (turn_effects) | tué | (a) app tuée |
| M4 | `_charge` sans repli sur le bonus tombé (provider) | tué | (b) ×2 |
| M5 | `_modifiersThisTurn` n'ajoute pas le malus tombé (provider) | tué | (a) chrono, (d) analytics |
| M6 | `_hasTurnReveal` ignore la cartouche tombée (provider) | tué | (a) |
| M7 | graine avec `skips: 0` (provider) | tué | (c) |
| M8 | `_fiestaAfterTurn` garde `drop` (provider) | tué | (a) vraie fin du tour |
| M9 | `_pendingGiverBlock` ignore le `block_giver` tombé (provider) | tué | (c) |
| M10 | `confirmGiverBlock` reporte `drop` au remplaçant (provider) | tué | (c) |
| M11 | `continuation: false` passé à `dropForTurn` (provider) | tué | (b) continuation (devant au score, un nouveau tirage perdrait le ×2) |
| M12 | bonus tombé vu `armed` au lieu de `spent` (provider) | tué | (b) |
| M13 | malus reçus lus sur la liste cachée (`currentTeamModifiers`) (provider) | tué | (d) |
| M14 | `gap: 0` au lieu de `leaderGap` (provider) | tué | (b) |
| M15 | `roundRulesThisTurn` = tout ce qui n'a pas d'envoyeur (provider) | tué | (a) |
| M17 | phrase du piège toujours avec envoyeur (provider) | tué | (c) |
| M18 | `droppedMalus` ne perd plus un malus impossible dans la manche (cartridge_drop) | **survit** | — |
| M19 | bonus tombé dépensé comme une charge (`ChargeUse`) au départ du chrono (provider) | tué | (b) stock |

M16 (garde « déjà tiré » dans `_drawDrop`) : mutant équivalent (un second `startTurn` relit les mêmes entrées :
le malus tombé n'a pas d'envoyeur, il n'entre pas dans `received`) ; la garde a été retirée du code.

## Survivants assumés

- **M18** (malus tombé perdu en N+1 s'il n'a plus de sens, ex. « Autre langue » tombé au dernier tour de M2 et
  poursuivi en M3) : le filtre est celui de `modifiersForTurn` pour un malus reçu, recopié dans `droppedMalus`
  (pur). Le tuer demande un 5ᵉ test (une fin de manche avec report, ou deux lignes de test pur de
  `droppedMalus`), hors des (a)-(d) autorisés : question posée à l'orchestrateur.
