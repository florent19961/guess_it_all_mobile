# Correctifs r1 : story 2-3 « Ensembles »

Restack préalable : `git rebase --onto feat/fiesta-2-2 a6d51a0`, sur le tip READY de 2-2
(`f6dcd61`, avec `readOr`). Un seul conflit, dans `docs/tracking_evolution.md` : les deux entrées
ont été gardées.

| Finding | Décision | Preuve |
|---|---|---|
| **M1** compat ascendante | **Corrigé**, en trois volets. | Voir le détail sous le tableau. |
| MINOR 1 (S7 / S8 / S9 / S13) | **S7 testé.** **S9 couvert** par le test du bug `copyName`. **S8 et S13 non testés**, résidu assumé. | Test « supprimer le dernier utilisé efface lastUsedId » : le mutant S7 tombe. Pourquoi S8 et S13 restent sans test : voir sous le tableau. |
| MINOR 2 `copyName` à 30 caractères / emoji | **Corrigé** | Le suffixe « (copie) » est toujours gardé : on tronque la **base** à 22 caractères, comptés en graphèmes (`characters`). Test : « la copie d'un nom de 30 caractères reste distincte ». |
| MINOR 3 interrupteur de rattrapage | **Corrigé**, sans toucher au modèle | Interrupteur de l'éditeur : off met les 5 curseurs à 0, on remet `CatchUpRules.auto`. L'état affiché est « actif » si un curseur est > 0 (`catchUpOn`, dans `fiesta_ensemble.dart`). Le résumé de la carte dit « rattrapage » ou « sans rattrapage ». |
| MINOR 4 message trompeur | **Corrigé** | Quand `create` échoue, l'éditeur relit la liste. Il n'annonce « Limite atteinte » que si elle est vraiment pleine, sinon « Enregistrement impossible, réessaie. ». S10 reste sans test (le reviewer l'accepte). |
| MINOR 5 double tap sur « Utiliser » | **Corrigé** | Garde `_using` dans `fiesta_ensembles_screen.dart` : `onUse` n'est appelé qu'une fois par tap, et seulement si l'écran est encore monté. |
| MINOR 6 `lib/models/CLAUDE.md` | **Corrigé** | Deux lignes de modèle ajoutées, plus l'invariant « champ ajouté = optionnel à la lecture, aussi pour les ensembles ». |
| MINOR 7 avalanche de messages | **Résidu assumé** | Ergonomie seulement, à juger en recette device. Un message par modificateur reste explicite. |
| NIT `mode: auto` accepté | **Corrigé** | `FiestaEnsemble.tryFromJson` rejette `mode != custom`. L'entrée est alors gardée brute, pas détruite. |
| NIT `fixed` avec `fixedRound == null` (= finding m8 de la revue de 2-4) | **Corrigé** : nouvelle règle bloquante dans `validateEnsemble` (« X est fixé, mais sur aucune manche. »). | L'interface ne peut pas produire cet état (l'éditeur affiche `?? 3`, les défauts posent 3), mais un blob relu, ancien ou modifié, peut le contenir : la règle reste donc. Test « « fixé » sans manche → refusé » ; sans la règle, il tombe (aucun message). |
| NIT `copyWith` ne remet pas `fixedRound` à `null` | Dette notée | À rapatrier dans les types de 2-2 au besoin. Aucun usage aujourd'hui. |
| NIT retour sans confirmation dans l'éditeur | Résidu | La maquette ne dit rien sur ce point. |

**M1, détail des trois volets :**

1. La lecture tolérante (`readOr`) vient de 2-2 et a été **vérifiée** : une clé absente prend sa
   valeur par défaut, un type faux rend le blob illisible.
2. **Test de format figé** `frozenBlob` : un JSON littéral, tel qu'écrit par cette version, doit
   se relire en entier.
3. **Les entrées illisibles sont réécrites telles quelles** par `_write` : `_read` rend
   `(store, unreadable)`. Un ensemble illisible n'est donc jamais détruit par la modification
   d'un autre. Mutant « `...unreadable` retiré » : le test tombe.

La règle « champ ajouté = optionnel à la lecture » est documentée dans `lib/models/CLAUDE.md`.

Limite assumée du volet 3 : un **réglage d'id inconnu, à l'intérieur d'un ensemble lisible**,
disparaît à la réécriture de cet ensemble. Les ids sont figés (`modifier_catalog.dart`) et
aucune version ne peut revenir en arrière (mise à jour forcée par `upgrader`) : ce cas n'arrive
que sur un blob corrompu.

**Pourquoi S8 et S13 restent sans test :** l'id et l'ordre des ensembles ne protègent aucune
donnée. Un échec se voit tout de suite à l'écran, en recette.

## Mutations rejouées

| Mutant | Résultat |
|---|---|
| `...unreadable` retiré de `_write` | tombé |
| `delete` garde `lastUsedId` (S7) | tombé |
| file `_serialized` retirée (r1) | tombé |
