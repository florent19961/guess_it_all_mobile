# Fix r1 — kit 2-10

Arbitrages du team-lead appliqués sur `2-10-kit-review-r1.md`.

## MAJOR
1. **Cartes sans effet** — `_useful` (`offers.dart`) : `canAdd` ET aucun modificateur de même
   `catalogId` ne touche déjà la cible (tirage N+1, choix déjà faits, cadeaux déjà donnés). Test
   `:96` corrigé (`no_pass` tiré → seule `double_points` reste).
2. **Cran vide → cran inférieur** (`_offer`) : forte → moyenne → légère, pour le 1 parmi 3 et le
   coup de pouce. « Vide » s'entend **après** exclusions (un cran dont toutes les cartes sont
   exclues compte comme vide) ; l'équipe n'est sautée que si tous les crans sont vides. Table
   inchangée, toujours « à recalibrer ». Conséquence widgets : la force affichée est celle de la
   carte (`kOfferStrength`), plus celle de l'écart ; `PickThreeCard` ne dit plus que l'écart.
3. **Tests** (toujours un seul fichier pur, 7 tests) : graine figée (`offerSeed('g',1,'bleue')`
   + liste d'offres figée) ; test `appBoost` (bonus/menée + malus/tête à 2 équipes, 20–10 après
   M1 donne 2 cadeaux grâce au cran inférieur, 3 équipes × 50 parties sans `block_guesser`) ;
   test du cran inférieur en Personnalisé (+ immunité `blockImmuneTeamIds`) ; une ligne pour M6/M7
   (fixture : `minus_10s` en tirage, `reversed` dès M3 → jamais proposés) ; une ligne co-leaders.

## MINOR
1. **Contrat qui a choisi quoi** — adopté : `pickThreeOffers(roundDraw:, choices: Map<chooserId,
   ModifierInstance>)` remplace `taken`. `appBoost(roundDraw:)`. Documenté dans la doc de la
   fonction et la ligne `lib/models/CLAUDE.md`.
2. `allTeams` magique supprimé : `block_guesser` écarté directement dans `_candidates` hors
   Personnalisé.
3. Duplication `Standings` / `computeCatchUp` — non fait (fichier `turn_time` hors périmètre), à
   reprendre par la lane cœur si utile.
4. Ordre de la map de `Standings` — rappel ajouté dans la ligne CLAUDE.md.
5. `gapOf` d'un id inconnu lève — non fait (appelant incohérent = bug à voir).
6. Scope de `block_guesser` offert (`round`) — non fait, à trancher avec 2-8.
7. `two_words` à 0 charge — non fait (catalogue hors périmètre).
8. Widgets — `Semantics(button, selected)` sur la carte d'offre fait ; `AppBoostCard` perd son
   paramètre `standings` devenu inutile. Repli silencieux de `_name`/`_color` et sous-titre
   « Dernière, à N points » non faits (cosmétique).
