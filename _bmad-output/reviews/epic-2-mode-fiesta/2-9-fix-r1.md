# Fix r1 — 2-9 (revue Codex r1 : NOT READY, 1 MAJOR + 1 MINOR)

| Finding | Correction | Vérification |
|---|---|---|
| MAJOR (AC8) : aucun test d'une continuation NON activée en fin de M1 puis activée avec la charge de M2 | Test provider ajouté (`fiesta_double_points_test.dart`, 3ᵉ test) : M1 fini sans ×2, `nextRound`, armement en continuation (`turnBonusTime` non nul), départ → `isDoublePointsOn`, une dépense `chargesUsed` en M2, `scoreByRound` = [4, 2, 0], score 6. Test de continuation existant conservé. | Mutant « armed jamais passé à spent quand `turnBonusTime != 0` » : le nouveau test casse (seul à casser). |
| MINOR : carte « Actif ce tour » (`game_screen.dart`) affichait `double_points` non dépensé | La carte lit `turnModifiers` (sans la charge) et ajoute le badge « ×2 Mot compte double » seulement si `isDoublePointsOn`. La carte « Bonus » reste l'offre de la charge. La carte de tirage du tout premier tour (`RoundDrawCard`) annonce toujours le tirage complet. | UI, pas de test (consigne). |

Aucun changement de code de prod hors `game_screen.dart`.
