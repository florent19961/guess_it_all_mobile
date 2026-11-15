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
| M18 | `droppedMalus` ne perd plus un malus impossible dans la manche (cartridge_drop) | tué | (e) test pur `droppedMalus` (`test/models/fiesta/cartridge_drop_test.dart`) |
| M18b | `droppedMalus` ne perd plus un malus identique à une règle (cartridge_drop) | tué | (e) |
| M18c | `droppedMalus` ne perd plus un malus incompatible (un seul mime) (cartridge_drop) | tué | (e) |
| M19 | bonus tombé dépensé comme une charge (`ChargeUse`) au départ du chrono (provider) | tué | (b) stock |

M16 (garde « déjà tiré » dans `_drawDrop`) : mutant équivalent (un second `startTurn` relit les mêmes entrées :
le malus tombé n'a pas d'envoyeur, il n'entre pas dans `received`) ; la garde a été retirée du code.

## Survivants

Aucun. M18 survivait en première passe ; l'orchestrateur a autorisé un 5ᵉ test, pur, de `droppedMalus`
(« Autre langue » perdue en M3, malus identique à une règle, second mime), qui tue M18, M18b et M18c (mutants
lancés contre `test/models/fiesta/cartridge_drop_test.dart`).
