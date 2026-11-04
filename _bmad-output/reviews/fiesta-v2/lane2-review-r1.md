# Revue Codex — lane 2 r1 (2026-11-04)

# NOT READY

## BLOCKER

- [game_provider.dart:1662](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/providers/game_provider.dart:1662), [round_transition.dart:116](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/models/fiesta/round_transition.dart:116) — les incompatibilités sont évaluées contre les règles de manche de l’émettrice, pas celles du prochain tour réel de la cible.  
  Scénario : A possède `Interdit de passer` en M1 et l’envoie à B. A termine la manche dans son tour ; B rejoue alors en M2, où `Passe gratuite` est une règle de manche. Le malus envoyé est conservé et appliqué, donc B cumule deux modificateurs incompatibles (`no_pass` + `free_pass`). Le même problème existe avec un malus identique déjà porté par une règle de la manche cible.  
  Correction : centraliser la résolution des malus en attente contre la manche logique effective de la cible, incluant les règles `always`/`draw` de cette manche, avant de les appliquer. Cette résolution doit être la source commune de l’UI, de la collision et de `modifiersForTurn`; ajouter un test de passage de manche avec incompatibilité cible.

## MAJOR

- [turn_cartridges.dart:281](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/widgets/fiesta/turn_cartridges.dart:281), [turn_cartridges.dart:439](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/widgets/fiesta/turn_cartridges.dart:439) — l’écran annoncé sans défilement est réellement scrollable, et les cercles de « CE TOUR » peuvent passer sous les 32 px.  
  Scénario : sur 360 × 740, Explosif avec plusieurs règles de manche, malus reçus cumulés et bonus armés : `rowSize` est réduit proportionnellement au nombre d’éléments, sans plancher. En parallèle, si `_fit` ne suffit plus, `SingleChildScrollView` devient utilisable. Des cartouches ou actions peuvent alors être hors écran, contrairement à la spec.  
  Correction : retirer le `SingleChildScrollView` et concevoir la zone sous contrainte réelle (budget vertical du `GameScreen`, grille/wrap à diamètre minimal garanti, réduction des marges/éléments structurels si nécessaire). Vérifier manuellement Android et iOS avec safe areas, notamment ce cas chargé.

## MINOR

- [fiesta_pick_three_test.dart:477](/home/florent19961/guess-it-all-fiesta-v2-tour/test/providers/fiesta_pick_three_test.dart:477), [offers_test.dart:191](/home/florent19961/guess-it-all-fiesta-v2-tour/test/models/fiesta/offers_test.dart:191) — le Coup de pouce Auto est seulement vérifié comme aperçu/instance active, pas lorsqu’il attribue précisément `Passe gratuite` en cartouche d’un seul tour.  
  Scénario : une mutation qui laisse `free_pass` actif toute la manche pour le cadeau Auto ne serait pas détectée par ces tests.  
  Correction : fixer une graine donnant `free_pass`, l’armer, démarrer le tour, vérifier les deux passes gratuites puis leur disparition au tour suivant.

Les tests ciblés couvrent bien les trois mutants annoncés : collision non consommante, retrait en fin de tour cible, restitution à l’annulation. Les cinq réécritures conservent globalement leurs invariants adaptés au nouveau modèle. En revanche, elles ne couvrent pas l’incompatibilité à travers une transition de manche, qui laisse passer le blocker ci-dessus.

Persistance (`from`, `target`, `freePass`), annulation, consommation unique, analytics/récap et Classique paraissent cohérents à l’inspection. Android/iOS utilisent bien `SafeArea` pour l’écran, les feuilles et le snack ; le problème de défilement reste toutefois commun aux deux plateformes. Aucun test n’a été exécuté afin de respecter la contrainte stricte de lecture seule.

