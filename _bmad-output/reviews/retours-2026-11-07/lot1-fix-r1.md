# Lot 1, correction du round 1

Commit de tête : `4523902` (poussé sur `feat/retours-regles`). Seuls des tests changent, `lib/` n'est pas touché.

Suite complète (`scripts/run-full-suite.sh`) : code de sortie 0, `+582: All tests passed!`. 580 avant ce round, plus les 2 tests ajoutés.

## Findings

| Finding | Décision | Preuve |
|---|---|---|
| M-1 `two_words` dans `fiesta.active` | Écarté par l'orchestrateur | Retracé sur v1.2.0+11 : cartouche seulement, jamais règle de manche, et l'envoi ne crée que des malus. Pas de filtre défensif. |
| M-2 graine et poids non verrouillés | Corrigé | `test/models/fiesta/cartridge_gifts_test.dart` : « poids : valeurs décidées (D2) » et « la manche et l'équipe changent chacune le tirage » |
| N-1 libellé « 18 ids » | Corrigé | `test/models/fiesta/fiesta_catalog_test.dart:20` : « 17 ids » |

Le test de graine passe par `roundGifts` et non par `giftSeed` : il couvre donc aussi les arguments passés à l'appel (mutations 3 et 4 ci-dessous). Le scénario `planRoundTransition` recalculé n'est pas ajouté, comme demandé.

## Mutations

Exécutées pour de bon, une à une, sur `lib/`, avec restauration après chaque run et `git diff -- lib` vide à la fin. Tests lancés à chaque fois : `cartridge_gifts_test`, `game_state_test`, `fiesta_catalog_test`, `fiesta_two_words_legacy_test`. Sans mutation : 44 passent. Aucune mutation n'a provoqué d'erreur de compilation : chaque échec vient d'une assertion. **17 jouées, 17 tuées.**

| # | Mutation | Tuée par |
|---|---|---|
| 1 | `giftSeed` sans `teamId` | la manche et l'équipe changent chacune le tirage |
| 2 | `giftSeed` sans manche | idem |
| 3 | Appel dans `roundGifts` sans équipe | idem |
| 4 | Appel dans `roundGifts` sans manche | idem |
| 5 | Poids par défaut 4 | poids : valeurs décidées |
| 6 | Poids du ×2 à 3 | poids : valeurs décidées ; poids : Mot compte double |
| 7 | Tirage sans remise | avec remise |
| 8 | `kMaxAllCount` à 11 | allCount borné à 10 |
| 9 | Relecture de `allCount` bornée à 5 | idem |
| 10 | `trailingCount` borné à 10 | idem |
| 11 | `two_words` remis dans `kModifierCatalog` | 17 ids ; Deux mots allumé ; ensemble enregistré ; modifierById |
| 12 | `two_words` remis dans `kChargeBonusKeys` | tour en cours ; Deux mots allumé ; reprise des choix ; modifierById |
| 13 | `two_words` remis dans `kCartridgeOnlyIds` | modifierById |
| 14 | `two_words` retiré de la liste de lecture seule | tour en cours ; instance et cartouches ; ensemble enregistré ; modifierById |
| 15 | Paire `no_pass`/`two_words` remise | modifierById |
| 16 | Filtre de `ReplacedChoices.bonuses` retiré | reprise des choix |
| 17 | `replaced` gardé quand il ne reste rien à reprendre | reprise des choix |

Le test statistique du poids laisse passer un poids par défaut de 4, comme le disait le reviewer : c'est l'assertion exacte qui tue la mutation 5. Je garde les deux, l'un fige la valeur, l'autre vérifie que le poids agit vraiment sur le tirage.
