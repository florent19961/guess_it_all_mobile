# Revue r2 : story 2-3 « Ensembles » (tier risqué ③)

Même posture qu'en r1 : reviewer Opus adversarial, lecture seule.

## Ce que tu lis

- `2-3-patch-r2.diff` : le delta complet de 2-3. Il est calculé sur
  `git merge-base feat/fiesta-2-2 HEAD` (`f6dcd61`, le tip READY de 2-2, avec `readOr`), hors
  dossier de revues.
- `2-3-delta-r1-r2.diff` : seulement les correctifs, sur `lib/` et `test/`.
- `2-3-review-r1.md` : ta revue précédente.
- `2-3-fix-r1.md` : la décision de l'implémenteur pour chaque finding, avec sa preuve.

Ne lance jamais `git diff` toi-même. Le contexte (story, epic, maquette) est inchangé : voir
`2-3-prompt-r1.md`.

Rapport à écrire dans `2-3-review-r2.md`.

## Ce que tu vérifies

1. **M1 est-il clos ?** Il l'est si les trois conditions suivantes tiennent :
   - le blob figé (`frozenBlob`) se relit en entier ;
   - les entrées illisibles sont réécrites telles quelles (`_read` rend `(store, unreadable)`,
     `_write` les ajoute) ;
   - `readOr` de 2-2 tient bien « clé absente = défaut ».

   Cherche aussi un chemin qui détruit encore un ensemble. La limite assumée est celle-ci : un
   réglage d'id inconnu, à l'intérieur d'un ensemble lisible, disparaît quand cet ensemble est
   réécrit. Est-elle acceptable ?
2. **Les nouveaux chemins** sont-ils sûrs ?
   - Une entrée brute qui n'est pas une `Map` est-elle bien conservée ?
   - Combinaison avec la borne : les entrées illisibles ne comptent pas dans les 10. Est-ce un
     problème ?
   - Le rejet de `mode != custom` garde-t-il l'entrée au lieu de la détruire ?
3. **Interrupteur de rattrapage, côté interface seulement :**
   - off met les 5 curseurs à 0, on remet `CatchUpRules.auto` ;
   - « actif » se lit comme `catchUpOn` (un curseur > 0).

   Y a-t-il une incohérence ? Par exemple : seul `cap` est > 0, donc l'interrupteur est sur on
   alors que le rattrapage n'a aucun effet.
4. **Les autres correctifs :**
   - `copyName` : troncature en graphèmes, suffixe toujours présent ;
   - le message après un échec de `create` ;
   - la garde `_using` sur « Utiliser ».
5. **Mutation testing des tests ajoutés.** Pour chacun : le format figé, S7, `copyName`, et la
   ré-écriture des entrées illisibles, ainsi que la règle « fixé sans manche » de
   `validateEnsemble` (finding m8 de la revue 2-4).
6. **Les résidus assumés** (S8, S13, MINOR 7, NIT) : sont-ils bien justifiés ?

## Format attendu

Identique à r1. Termine par un verdict READY / READY avec MINOR / NOT READY, puis la liste des
mutations avec leur résultat.
