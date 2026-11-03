# Revue r2 — kit 2-10 (head `d1c370c`)

J'ai lu `2-10-kit-patch-r2.diff` et `2-10-kit-fix-r1.md`, puis j'ai relu `offers.dart` et
`offers_test.dart` en entier.

- Tests : 7/7 au vert.
- `flutter analyze` sur les 3 fichiers : aucun problème.
- 12 mutations testées puis annulées. `cmp` confirme que `offers.dart` est revenu à l'identique,
  et `git status` est propre.

## Verdict : NOT READY (un seul MAJOR, corrigeable en 1 ligne de test)

## MAJOR

### M1 : le test « jamais Bloquer un devineur » en Auto ne peut pas échouer (décision 5 non protégée)

**Où** : `test/models/fiesta/offers_test.dart`, test « coup de pouce », boucle des 50 parties.

**Mutation** : `(!custom || blockImmuneTeamIds…)` remplacé par `(blockImmuneTeamIds…)` dans
`offers.dart` (`_candidates`). Le mutant **survit**.

**Pourquoi** :
- La boucle utilise le classement 20/18/5 après M2. Le leader n'a que 2 points d'écart avec la
  2ᵉ équipe, donc son malus est léger. Le cran « forte » n'est jamais consulté, et
  `block_guesser` ne peut pas sortir.
- Le seul cas où la tête a un écart de plus de 7 (20–10 après M1) ne vérifie que
  `hasLength(2)`. Avec le mutant, Rose reçoit `block_guesser`, la liste fait toujours 2
  éléments, et le test passe.

C'est exactement le mutant M10 de r1, que le fix annonçait couvert.

**Correctif (1 ligne)** : dans le cas 20–10 après M1, ajouter
`expect(ids(gifts), isNot(contains('block_guesser')))`, ou figer la liste attendue. Avec le
mutant, le cran « forte » contient `block_guesser`, la ligne échoue, et le mutant est tué.

## Vérifié et correct

- **Cartes sans effet** (`_useful`) : `canAdd` est appliqué, et aucun modificateur avec le même
  `catalogId` ne doit déjà toucher la cible. Les sources prises en compte sont le tirage de N+1,
  les choix déjà faits et les cadeaux déjà donnés. Le mutant N3 (doublons permis) est tué.
- **Cran inférieur** (`_offer`) : la boucle `for (s = index; s >= 0; s--)` est bornée, donc pas
  de boucle infinie. Elle renvoie `const []` quand tous les crans sont vides, et l'équipe est
  alors sautée (test « plafond à tous les crans »). Le mutant N1 (pas de cran inférieur) est tué
  deux fois : en Personnalisé avec immunité, et en Auto 20–10. Le cran ne descend pas plus bas
  que nécessaire : il s'arrête dès qu'un cran a au moins une carte utile. Une seule carte reste
  donc possible, ce qui est accepté par la décision 1.
- **Déterminisme** : le même `Random` est consommé cran après cran, ce qui reste déterministe
  pour des entrées identiques. `choices.values` ne dépend pas de l'ordre, puisque `canAdd` et
  `_useful` ne regardent pas l'ordre.
- **Graine figée** : `offerSeed('g',1,'bleue') == 1610297326`, plus une liste d'offres figée. Le
  mutant N4 (graine sans `teamId`) est tué. Une modification de la formule entre deux versions
  serait donc détectée.
- **API pour la lane cœur** :
  - `pickThreeOffers(roundDraw:, choices: Map<chooserId, …>, blockImmuneTeamIds:)` et
    `appBoost(roundDraw:)` sont cohérents.
  - La règle « prochaine équipe = première de `choosingOrder` absente de `choices` et dont les
    offres ne sont pas vides » est documentée dans la doc de la fonction et dans
    `lib/models/CLAUDE.md`.
  - Les mutants N8 (choix ignorés) et N6/N7 (`startRound` / `arrival` ignorés) sont tués.
- **Widgets** :
  - Chaque carte affiche sa propre force (`_strength(offer)`). `AppBoostCard` n'a plus besoin de
    `standings`.
  - L'en-tête du choix affiche la force de `offers.first`, ce qui est juste puisque toutes les
    offres viennent d'un même cran.
  - `Semantics(button, selected)` a été ajouté.
- Les mutants N10 (pas de malus en Auto), N11 (immunité ignorée) et N12 (co-leader pris pour
  cible) sont tués.

## MINOR (non bloquants)

1. **« Vide APRÈS exclusions » n'est pas figé par un test.** La mutation N2 remplace
   `picked.isNotEmpty` par `candidates.isNotEmpty`, et elle survit. Le code est conforme à la
   décision, mais rien ne la protège.

   Test d'une ligne proposé : 14–5 (cran « forte »), avec Rose déjà à 2 modificateurs (par
   exemple `choices: {'verte': reversed→rose, 'jaune': no_pass→rose}`). Le résultat attendu est
   `unorderedEquals(['double_points', 'two_words'])`.
2. **`[...roundDraw, ...gifts]` dans `appBoost`** : la mutation N9 survit, et c'est un mutant
   équivalent. Les cadeaux visent chacun une équipe différente, avec un bonus par menée et un
   malus pour le leader. Ils ne peuvent donc jamais se gêner entre eux. Le code n'est pas faux,
   seulement inutile pour l'instant. On peut le garder par robustesse.
3. **Contrat `choices`** : il faut passer uniquement les choix des équipes **précédentes**.
   Si la lane cœur recalcule les offres de l'équipe en cours après son choix (pour un affichage
   ou une revalidation), son propre choix s'exclut lui-même et les offres changent. Le plus
   simple est d'ajouter une phrase dans la doc. L'alternative plus robuste est d'ignorer
   `choices[teamId]` dans `pickThreeOffers`.
4. **MINOR de r1 non traités** : la duplication entre `Standings` et `computeCatchUp`,
   l'exception de `gapOf` sur un id inconnu, le scope de `block_guesser`, `two_words` à 0
   charge, le repli silencieux de `_name`/`_color` et le sous-titre « Dernière ». Tous sont
   **acceptables** : ils sont hors périmètre ou à trancher avec 2-8 ou la lane cœur, et aucun ne
   touche le score.
