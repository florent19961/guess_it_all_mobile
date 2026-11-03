# Correction r1 — story 2-2

Chaque finding re-tracé dans le code avant décision. Signatures publiques inchangées
(`canAdd(active, candidate, {maxPerTurn})`, `FiestaRules`, `ModifierInstance`, JSON).

| # | Décision | Preuve |
|---|---|---|
| M-1 | **Corrigé.** `canAdd` plafonne par équipe : charge d'une équipe = instances `both` + les siennes ; une candidate `both` est jugée sur l'équipe la plus chargée. Compatibilité vérifiée sur toutes les actives qui partagent une équipe avec la candidate. | `lib/models/fiesta/modifier_instance.dart` `canAdd`. Tests `test/models/fiesta/fiesta_catalog_test.dart` : « le plafond est par équipe » (`[A1, B1] + both → true`, repro du reviewer) et « une instance pour tous compte pour chaque équipe » (`[no_pass@both] + two_words@B → false`). Mutation M8b rejouée : **tombe** (+6 −1). |
| m-1 | **Corrigé.** `readOr(json, key, fallback)` : clé absente → défaut du constructeur, présente et mal typée → `null`. Appliqué à `FiestaRules`, `CatchUpRules` (défauts = `.auto`), `ModifierSetting` (`startRound` 1, `charges` 0 ; `active` et `arrival` restent requis). `mode` reste bloquant (clé de structure). Règle écrite dans `lib/models/CLAUDE.md` et `docs/tracking_evolution.md`. | `fiesta_rules.dart` `readOr`. Test `game_state_test.dart` « un champ de règles ABSENT prend sa valeur par défaut, un champ mal typé invalide » (`carryOver` retiré, `malCap` retiré, clé inconnue ajoutée → relu ; `carryOver: 'oui'` → Classique). |
| m-2 | **Corrigé.** Contrat `target != both ⇒ teamId != null` : `assert` dans le constructeur et rejet dans `tryFromJson`. Documenté dans `lib/models/CLAUDE.md`. | `modifier_instance.dart` constructeur + `tryFromJson`. Pas de test dédié (garde d'invariant trivial, l'assert suffit en dev). |
| m-3 | **Corrigé.** Le blob legacy est un **littéral figé** (forme `toJson()` au 51c0b78, 27 clés) ; `..remove('fiesta')` et l'assertion redondante retirés. | `game_state_test.dart` « un blob Classique (sans `fiesta`) reste Classique, sans bruit ». Un renommage de clé fait maintenant tomber le test. |
| m-4 | **Corrigé.** Égalité avec la liste littérale des 11 ids. | `fiesta_catalog_test.dart` premier test. |
| m-5 | **Corrigé.** Phrase corrigée : `nature` est persistée avec l'instance ; nom et description seuls viennent du code. | `docs/tracking_evolution.md`, entrée 2-2. |
| m-6 | **Corrigé.** Ligne « Fiesta » ajoutée (gel / effacement / `isFiesta` / état dans `GameState`). | `lib/providers/CLAUDE.md` §Responsabilites. |
| m-7 | **Noté, pas de code** (correct pour 2-2). Avertissement pour 2-4 ajouté. | `lib/models/CLAUDE.md` §Fiesta — invariants (`teams_screen.dart` appelle `startGame()` sans argument). |
| m-8 | **Résidu assumé** (choix de spec : « sous-objet vide »). Recommandation écrite pour les stories d'effets : champs typés plutôt que clés dans la map. | `lib/models/CLAUDE.md` §Fiesta — invariants. |
| NIT copyWith | **Résidu assumé**, comme le reviewer le propose : la story qui décrémente des charges l'ajoute. | — |
| NIT `isEmpty` | **Corrigé.** Assertion cosmétique retirée. | `test/providers/fiesta_freeze_test.dart`. |
| NIT M12 | **Résidu assumé** (sans enjeu, pas de test). | — |
| NIT bornes `drawCount` / interrupteurs Auto | **Résidu assumé** : validation portée par l'éditeur (2-3) et l'écran Auto (2-4), pas par la relecture. | — |

Tests : 20 ciblés verts (+3 : plafond par équipe, pour-tous incompatible, champ absent = défaut),
aucun retiré. Suite complète : format OK, analyze 0 error / 0 warning (64 infos baseline),
**138 tests verts**.
