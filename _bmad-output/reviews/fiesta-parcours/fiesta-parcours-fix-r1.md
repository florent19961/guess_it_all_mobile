# Corrections r1 — fiesta-parcours

Revue : `fiesta-parcours-review-r1.md` (NOT READY, 1 MAJOR + 2 MINOR). Patch corrigé :
`fiesta-parcours-patch-r2.diff`.

| # | Finding | Décision | Preuve |
|---|---|---|---|
| 1 | MAJOR — retour système Android quitte l'app (Paramètres, Mes ensembles) | **Corrigé** | `PopScope(canPop: false)` → même destination que le bouton retour : `lib/screens/settings_screen.dart:119` (accueil), `lib/screens/fiesta_ensembles_screen.dart:95` (`onBack` = équipes). Test qui reproduit le bug : `test/screens/settings_system_back_test.dart:29` (`handlePopRoute()` doit être géré et mener à l'accueil). **Mutation vérifiée** : `canPop: true` → le test échoue. Les écrans supprimés avaient cette garde via `FiestaSetupScaffold` : régression du patch r1, pas un défaut ancien. |
| 2 | MINOR — « Tout réinitialiser » garde `_pendingFiesta` | **Corrigé** | `lib/providers/game_provider.dart:1909` (`clearLocalStorage`) et `:1918` (`resetGame`, déprécié). Assertion dans le test existant du reset : `test/providers/settings_persistence_test.dart:101`. **Mutation vérifiée** : retirer la ligne de `clearLocalStorage` → le test échoue. (`resetGame` n'a aucun appelant ni test : aligné sans test.) |
| 3 | MINOR — le test 1 sur 4 ne détecte ni mauvaise graine ni mauvaise probabilité | **Corrigé** | `test/models/fiesta/symmetric_draw_test.dart:116` : graine `drawSeed(id, 0)` épinglée en dur pour deux `gameId`, sorties de `drawsOneAnswer` épinglées sur 12 `gameId`, distribution resserrée à 35-65 / 200 (`:137`). **Mutations vérifiées**, toutes tuées : graine de la manche 1 au lieu de 0, `nextInt(3) == 0`, `nextInt(4) <= 1`. |

## Ajout demandé par Florent (même passe)

Le bouton rond « Réinitialiser » (icône refresh) quitte le coin haut droit des Paramètres : il
devient « Réinitialiser les paramètres », `AppButton` ghost petit, en bas de la fenêtre
« Avancés » (`lib/screens/settings_screen.dart:594`). Il ferme « Avancés » puis ouvre la même
confirmation qu'avant (`_showResetConfirmation`, appelée avec le contexte de l'écran, pas celui
de la fenêtre fermée). En haut à droite ne restent que le « ? » et la roue crantée. Aucune étape
d'aide ne ciblait le bouton retiré ; l'étape « Avancés » mentionne désormais la réinitialisation
(`lib/widgets/help/help_content.dart`). Doc : `WIRING.md`, `lib/screens/CLAUDE.md`,
`docs/tracking_evolution.md`. Pas de test (UI simple).

## Rebase

`origin/main` n'a pas bougé depuis la création de la branche (#32 thème pas encore mergé au
moment du fix) : rebase sans objet, merge-base inchangée.
