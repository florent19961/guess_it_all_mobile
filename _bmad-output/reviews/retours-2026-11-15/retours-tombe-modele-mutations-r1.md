# Mutation testing r1 — L-TOMBE-MODÈLE

Mutations appliquées une à une sur `3913ba9` (script, fichier restauré par `git checkout` après chaque run). Tests
lancés à chaque fois : `test/models/fiesta/cartridge_drop_test.dart`, `test/services/fiesta_ensemble_service_test.dart`,
`test/models/fiesta/cartridge_gifts_test.dart` (via `scripts/with-test-slot.sh`). **14 / 14 tuées, 0 survivante.**
Mutant équivalent écarté : retirer `chance <= 0` (à Jamais, `nextDouble() >= 0` est toujours vrai).

| # | Mutation | Fichier | Test qui la tue | Résultat |
|---|---|---|---|---|
| 1 | Jet inversé : `nextDouble() >= chance` → `<` | `cartridge_drop.dart` | « Rarement ⊂ Parfois ⊂ Souvent, tour par tour » | tuée |
| 2 | Chances échangées (Rarement 1/2, Souvent 1/6) | `fiesta_rules.dart` | « Rarement ⊂ Parfois ⊂ Souvent, tour par tour » | tuée |
| 3 | `skips` retiré de la graine | `cartridge_drop.dart` | « déterministe par (partie, tour, joueur, sauts) … » | tuée |
| 4 | `giverId` retiré de la graine | `cartridge_drop.dart` | « déterministe par (partie, tour, joueur, sauts) … » | tuée |
| 5 | ×2 : `gap > kDoublePointsMinGap` → `>=` | `cartridge_gifts.dart` | « ×2 seulement à plus de 10 points du leader » (+ 2 tests D3 de `cartridge_gifts_test`) | tuée |
| 6 | Continuation ignorée (`|| continuation` retiré) | `cartridge_drop.dart` | « rien à Jamais ni sur un tour de continuation » | tuée |
| 7 | Clé `dropFrequency` émise à Jamais | `fiesta_rules.dart` | « réglage persisté : clé omise à Jamais… » ; « écriture figée : une clé vide ou nulle est omise » (service) | tuée |
| 8 | Clé absente relue Rarement (≠ Jamais) | `fiesta_rules.dart` | « réglage persisté … » ; « format figé Fiesta v3 : relu en entier » (`frozenBlob`) ; « aller-retour » (service) | tuée |
| 9 | Borne lue 3 → 4 | `fiesta_rules.dart` | « réglage persisté … hors bornes = illisible » | tuée |
| 10 | Malus reçu : `areCompatible` retiré | `cartridge_drop.dart` | « malus reçu : ni identique ni incompatible ; bonus armé : identique » | tuée |
| 11 | Malus reçu : identique non exclu | `cartridge_drop.dart` | idem | tuée |
| 12 | Bonus armé non exclu | `cartridge_drop.dart` | idem | tuée |
| 13 | `block_guesser` : `guesserIds.length >= 2` → `>= 1` | `cartridge_drop.dart` | « Bloquer un devineur : 3 joueurs au moins … » | tuée |
| 14 | Devineur bloqué = toujours le premier | `cartridge_drop.dart` | « Bloquer un devineur tombé : le bloqué est un des devineurs » | tuée |
