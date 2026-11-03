# Revue r2 : story 2-3 « Ensembles » (tier risqué ③)

Reviewer : Opus, adversarial, lecture seule.

**Ce qui a été lu :**
- `2-3-fix-r1.md` ;
- `2-3-delta-r1-r2.diff` ;
- `2-3-patch-r2.diff`, régénéré par `e6b2a57` : il contient désormais la règle « fixé sans manche », commit `eab071a` ;
- le code de `fiesta_rules.dart` (`readOr`), après restack sur `f6dcd61`.

Toutes les mutations ont été annulées par une réécriture inverse. `git status` est vide à la fin.

**Note de contexte :** pendant la revue, la lane avait encore la règle « fixé sans manche » en cours dans son arbre de travail. Elle l'a commitée et a régénéré le patch avant mes dernières mutations. Ce rapport porte sur `e6b2a57`.

## Verdict : READY avec MINOR

Pas de BLOCKER ni de MAJOR. M1 est clos. Les correctifs n'introduisent aucune régression trouvée.

## Vérifications demandées

1. **M1 est clos.**
   - **Lecture tolérante** : `readOr` de 2-2 lit une clé absente comme sa valeur par défaut, et une clé présente mais mal typée comme `null`. Les valeurs par défaut sont documentées : `CatchUpRules.auto`, `startRound` = 1, `charges` = 0.
   - **Test figé** : `frozenBlob` est un JSON littéral, et il se relit en entier. Le mutant R3 simule un futur champ requis : il est tué.
   - **Entrées illisibles conservées** : `_read` rend `(store, unreadable)` et `_write` les réécrit telles quelles. Le mutant R1 est tué.
   - **Règle documentée** dans `lib/models/CLAUDE.md` : tout champ ajouté à `FiestaRules`, `ModifierSetting` ou `CatchUpRules` est optionnel à la lecture.
   - **Aucun chemin restant ne détruit un ensemble lisible.** Les seules pertes sont la quarantaine du blob entier (corrompu ou venu du futur, voulue) et un `ensembles` qui n'est pas une liste (structurellement corrompu, équivalent à la quarantaine).
2. **Limite assumée, acceptable.** Un réglage d'id inconnu, ou mal formé, à l'intérieur d'un ensemble lisible disparaît quand cet ensemble est réécrit. Les ids du catalogue sont figés, et la mise à jour forcée empêche une version plus ancienne de relire le blob. Le cas ne vient donc que d'une corruption, ou d'un modificateur retiré volontairement du catalogue. La perte se limite à ce réglage, jamais à l'ensemble.
3. **L'interrupteur de rattrapage reste côté interface.**
   - off écrit les 5 curseurs à 0, on rend `CatchUpRules.auto` ;
   - l'état affiché vient de `catchUpOn` (un curseur > 0), et la carte de la liste dit la même chose ;
   - rien de nouveau n'est persisté.

   Les incohérences qui restent sont mineures (MINOR 3).
4. **Les correctifs mineurs tiennent.**
   - **`copyName`** : la base est coupée à 22 graphèmes et le suffixe « (copie) » est toujours présent. Pas de coupure au milieu d'un emoji. Le mutant R2 est tué.
   - **Message après un échec de `create`** : « Limite atteinte » n'apparaît que si la liste relue est vraiment pleine, sinon « Enregistrement impossible, réessaie. ».
   - **Garde `_using`** : un double tap n'appelle `onUse` qu'une fois, et seulement si l'écran est encore monté (`mounted`).
   - **Rejet de `mode != custom`** : l'entrée devient illisible, donc elle est conservée brute, pas détruite.
5. **NOUVEAU : un « fixé » sans `fixedRound` est bloqué.** `ensemble_validation.dart` produit le message « X est fixé, mais sur aucune manche. ». Le test « « fixé » sans manche → refusé » tue le mutant R7.
6. **Les correctifs n'introduisent rien de bloquant.** Il reste trois MINOR et deux NIT, listés ci-dessous.

## MINOR

1. **Les entrées illisibles ne comptent pas dans la borne et ne se suppriment jamais.** Avec 10 ensembles lisibles et k entrées illisibles, le blob contient 10 + k entrées. Si une version future sait relire ces entrées, l'utilisateur se retrouve à « 12 / 10 ». Rien ne plante : Créer et Dupliquer sont simplement grisés. C'est acceptable ; à documenter dans le doc de `_read`, en une ligne. Ne rien coder.
2. **Deux garanties ajoutées sans test.**
   - **R5** : on peut retirer le rejet de `mode != custom` sans qu'aucun test tombe.
   - **R6** : on peut abandonner une entrée qui n'est pas une `Map` (au lieu de la conserver) sans qu'aucun test tombe.

   Le correctif tient en deux lignes dans le test « ensemble illisible ignoré seul » : ajouter une entrée `"x"` et une entrée de mode `auto`, puis vérifier qu'elles sont réécrites.
3. **Rattrapage : incohérences d'interface** (`fiesta_ensemble_editor_screen.dart`, `_buildCatchUp`).
   - Si seul `cap` est > 0, l'interrupteur est sur on alors que le rattrapage n'a aucun effet. Même chose pour `b1` > 0 avec `cap` = 0.
   - Si l'on amène le dernier curseur non nul à 0, l'interrupteur bascule sur off et les curseurs disparaissent pendant le glissement.

   C'est de l'ergonomie, à juger en recette device. Correctif possible : définir « actif » comme `(b1 > 0 || b2 > 0) && cap > 0 || mal > 0 && malCap > 0`. On peut aussi garder les curseurs visibles tant que l'utilisateur n'a pas touché l'interrupteur.

## NIT

- `copyName` sur un nom dont le 22ᵉ graphème est une espace donne « abc  (copie) », avec un double espace. Un `.trimRight()` sur la base suffit.
- Les résidus S8 et S13 (ordre et position non testés) sont justifiés par la visibilité immédiate à l'écran. MINOR 7 (avalanche de messages) part en recette device. Ces résidus sont acceptés.

## Mutations r2 (`flutter test`, fichier ciblé)

| Mutant | Résultat |
|---|---|
| R1 `...unreadable` retiré de `_write` | tombé |
| R2 `copyName` revenu à l'ancienne troncature | tombé |
| R3 champ requis ajouté dans `FiestaEnsemble.tryFromJson` (futur champ) | tombé (test de format figé) |
| R4 `delete` garde `lastUsedId` (S7) | tombé |
| R5 rejet de `mode != custom` retiré | **survécu** (MINOR 2) |
| R6 entrée non `Map` abandonnée | **survécu** (MINOR 2) |
| R7 règle « fixé sans manche » retirée | tombé |
