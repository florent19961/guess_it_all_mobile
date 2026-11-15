# Revue statique r1 — L-TOMBE-BRANCHEMENT

Verdict : READY

Portée : lecture du patch r1 et du worktree à `0647257`, y compris le test ajouté après le patch. Aucun test, Flutter ni `git diff` n'a été lancé.

## Contrôles de conformité

- `GameProvider.startTurn` tire avant de choisir l'écran, sur l'équipe et le joueur courants. Les entrées sont bien les règles de manche complètes, les malus reçus qui jouent réellement, les bonus armés, l'écart réel au leader et les `skips` de l'équipe ([game_provider.dart:738](../../../lib/providers/game_provider.dart#L738), [game_provider.dart:769](../../../lib/providers/game_provider.dart#L769)). `dropForTurn` exclut les continuations ; l'état déjà stocké est donc conservé sans nouveau tirage.
- La clé additive `turn.drop` est omise à `null`, tolérante à la relecture et vidée à la vraie fin ; la continuation garde le même `FiestaTurnState` ([turn_effects.dart:42](../../../lib/models/fiesta/turn_effects.dart#L42), [turn_effects.dart:80](../../../lib/models/fiesta/turn_effects.dart#L80), [game_provider.dart:1844](../../../lib/providers/game_provider.dart#L1844)). L'absence de clé dans une partie 1.4.0 relit donc sans effet.
- Le bonus tombé suit la voie générique d'une charge `spent` sans écrire de `ChargeUse`; le malus est ajouté aux modificateurs du tour, donc aux effets, au score et à `WordEvent.modifiers` ([game_provider.dart:886](../../../lib/providers/game_provider.dart#L886), [game_provider.dart:1174](../../../lib/providers/game_provider.dart#L1174), [game_provider.dart:1774](../../../lib/providers/game_provider.dart#L1774)).
- Le piège tombé passe par le décompte puis l'écran piège, sans révélation ; son remplaçant repart d'un `turn` vide avec `skips + 1` ([game_provider.dart:1632](../../../lib/providers/game_provider.dart#L1632), [game_provider.dart:1695](../../../lib/providers/game_provider.dart#L1695)). Les lecteurs `fromTeamId == null` sont séparés avec `scope == round`, évitant de traiter le malus tombé comme une règle de manche.
- Aucune fuite n'est visible avant « Commencer le tour » : `currentTeamModifiers` masque les non-règles à l'avant-tour et `droppedThisTurn` applique la même garde ([game_provider.dart:1523](../../../lib/providers/game_provider.dart#L1523), [game_provider.dart:1553](../../../lib/providers/game_provider.dart#L1553)).

## Findings

### MINOR — preuve de mutation M18 incohérente avec le test livré

`_bmad-output/reviews/retours-2026-11-15/retours-tombe-branche-mutations-r1.md:4-5,26,32-33` indique que M18 survit car la campagne ne lance que `test/providers/fiesta_cartridge_drop_test.dart`. Or le patch contient aussi [test/models/fiesta/cartridge_drop_test.dart:185](../../../test/models/fiesta/cartridge_drop_test.dart#L185), qui appelle directement `droppedMalus` et exige que `other_language` soit `null` en M3. Le mutant décrit, qui retire le filtre d'éligibilité de [cartridge_drop.dart:60](../../../lib/models/fiesta/cartridge_drop.dart#L60), le ferait retourner non nul et ferait échouer cette assertion.

Correction proposée : rejouer M18 avec ce test modèle inclus, puis le marquer « tué » (ou expliciter que la table ne mesure volontairement que les quatre tests provider et retirer la conclusion « survivant assumé »). C'est un défaut de traçabilité de la campagne, pas un défaut fonctionnel constaté du branchement.

## Synthèse des tests lus

Les quatre tests provider couvrent respectivement la persistance/app tuée + chrono + purge, le ×2/scoring/continuation/stock/analytics, le cycle `block_giver` et le vivier avec malus reçu + ordre analytics. Le test modèle supplémentaire couvre précisément le scénario M18 de malus perdu en continuation. Aucun BLOCKER ni MAJOR relevé.
