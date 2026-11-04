# Revue Codex r1 — fiesta-parcours (copie transmise par la session principale)

**Verdict : NOT READY.**

Validé : formes persistées additives, `oneAnswer` absent → `true`, reprise / historique /
payloads, routes supprimées → accueil, Personnalisé via « Mes ensembles », plafonds et exclusion
Dessiner / mimes, tuto Fiesta et aide, badge.

## Findings

1. **MAJOR** — le retour système Android quitte l'app sur les nouveaux écrans :
   `lib/screens/settings_screen.dart:321` et `lib/screens/fiesta_ensembles_screen.dart:107`
   n'interceptent pas le retour. → `PopScope(canPop: false, onPopInvokedWithResult: …)` :
   Paramètres → Accueil, Mes ensembles → Équipes (même destination que leur bouton retour). Un seul
   test qui reproduit le bug (retour système simulé, ex. `tester.binding.handlePopRoute()`), sur
   Paramètres suffit.
2. **MINOR** — « Tout réinitialiser » garde `_pendingFiesta` :
   `lib/providers/game_provider.dart:1901` (et `resetGame` déprécié L1913). → le vider dans les
   deux ; assertion dans un test existant du reset.
3. **MINOR** — le test 1 sur 4 (`test/models/fiesta/symmetric_draw_test.dart:114`) ne détecte ni
   une mauvaise graine ni une mauvaise probabilité. → épingler quelques `gameId` connus à la sortie
   de `Random(drawSeed(id, 0))` (valeurs en dur) et garder un contrôle de distribution.
