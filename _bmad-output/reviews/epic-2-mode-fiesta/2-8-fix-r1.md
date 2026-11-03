# Fix r1 — story 2-8

Revue : `2-8-review-r1.md` (READY, 3 MINOR). Les 3 sont appliqués. Patch : `2-8-patch-r2.diff`.

| Finding | Correction |
|---|---|
| m1 deux définitions du tour | Décision du lead : un seul tour, la fin de manche plus sa continuation. L'appel à `_fiestaAfterTurn` est retiré de la branche fin de manche de `validateWords`, et le drapeau `turnOver` est supprimé. Compteurs et instances de portée tour vivent jusqu'à la vraie fin. Contrepartie acceptée : une `free_pass` de manche N+1 hérite du compteur de N. Le test de continuation (équipes de 3) vérifie maintenant que l'instance, `freePassesUsed` = 1 et le devineur bloqué survivent à `nextRound`, que le sélecteur ne se rouvre pas, puis que tout tombe à la fin de ce tour. Mutant vérifié : si l'on vide `turn` en fin de manche, le test casse. |
| m2 kill pendant l'annonce | `BlockedGuesser.pick` rend le `Player`. `setBlockedGuesser` n'est appelé qu'**après** `announce`, derrière la garde `mounted` / `currentScreen` de main. |
| m3 prédicats dupliqués | Ajout du getter `hasFreePass`. `currentPassPenalty` devient `hasFreePass ? 0 : réglage`. Ajout du helper `_has(id)`, utilisé par `passBlocked`, `isWordReversed` et `blockableGuessers`. `effectivePassPenalty` et `isPassBlocked` sont retirés de `turn_effects.dart`. Le bouton lit `provider.hasFreePass` et la même garde `canPassWith` que `passWord`. |

NIT non traités : l'extraction de la section du provider (fichier déjà au-delà de 1k lignes avant
2-8), et le libellé « gratuit » sous « Passer (bloqué) », un cas impossible par Q14.
