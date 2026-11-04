# Fiesta v2 — lane 1 — corrections de la revue r2

Dernier round avant merge. Arbitrages du lead appliqués ; nouveaux commits seulement (la lane 2
est empilée sur cette branche : ni rebase ni amend).

| # | Finding | Décision | Preuve |
|---|---|---|---|
| M5 | Un brouillon incomplet A écrasé par le brouillon d'un autre ensemble B | **Corrigé** : brouillons dans une map statique par id d'ensemble, clé dédiée `''` (`newDraftKey`) pour la création. Chaque éditeur ne lit, n'écrit et n'efface que SA clé (repris, gardé, enregistré, quitté sans enregistrer, ensemble supprimé). Aucun brouillon perdu. | `lib/screens/fiesta_ensembles_screen.dart:45` (`drafts`), `:117` (lecture), `:134` (enregistré), `:137` (gardé), `:171` (suppression) ; test `test/screens/fiesta_ensembles_flow_test.dart:114` : brouillon de création A (nom pris), puis brouillon de modification B (nom vidé), puis reprise de A intacte et de B intacte, deux clés en mémoire. |
| m1 | Badge « Deux mots » en double sur l'écran du tour (règle de manche) | **Corrigé** : le badge extra n'est ajouté que si `turnModifiers` ne contient pas déjà `two_words`. Pas de test (UI simple). | `lib/screens/turn_screen.dart:393` |
| m2 | `free_pass.perGame` inopérant mais compté dans la clé de doublon | **Corrigé** (le plus simple) : bit ignoré par `settingsKey` pour la Passe gratuite. | `lib/models/fiesta/fiesta_ensemble.dart:124` |
| m3 | Persistance de `reserve` non épinglée | **Corrigé** : aller-retour `GameState` (vraie chaîne JSON) avec un malus `reserve: true` : conservé, et ignoré par `modifiersForTurn` (règle 7). Mutant « `reserve` absent de `toJson` » : rouge (vérifié). | `test/models/game_state_test.dart:280` |
| m4 | 3 rangées et kill / reprise après la rangée 1 non couverts | **Résidu assumé** (arbitrage lead) : l'invariant central à 2 rangées est couvert par `fiesta_pick_three_test.dart:126` ; les choix sont persistés un par un (`offerChoices` avec `row`), la reprise relit la même file. | — |

Note de test : le test des brouillons écrit l'ensemble existant directement dans les préférences
(`givenPrefs`) au lieu de passer par `FiestaEnsembleService.create` : la file d'écritures du
service est un singleton, qu'un test précédent sous horloge simulée peut laisser figée (le test
restait bloqué).
