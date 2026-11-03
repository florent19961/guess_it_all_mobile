# Fix r2 — kit 2-10

- **MAJOR** : cas 20–10 après M1 du test `appBoost`, ajout de
  `expect(ids(wide), isNot(contains('block_guesser')))`. Mutant `!custom` retiré de
  `_candidates` : **tué** (vérifié, puis restauré).
- **MINOR 1** : test « cran vide APRÈS exclusions » (14–5, Rose déjà à 2 par les choix de Verte
  et Jaune → `double_points`, `two_words`). Mutant N2 (`candidates.isNotEmpty`) : **tué**.
- Doc : `choices` = seulement les choix des équipes passées AVANT, dans le commentaire de
  `pickThreeOffers` et la ligne `lib/models/CLAUDE.md`.
- MINOR 2 (mutant équivalent) et MINOR 4 (r1 acceptés) : rien à faire.
