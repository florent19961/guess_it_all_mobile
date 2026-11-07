# widgets/effects/

Effets visuels et animations.

## `startup_intro.dart`

`StartupIntro` : animation de démarrage « Le chrono se lance » (logo dessiné par `CustomPainter`, même géométrie que `scripts/render_logo.py`, puis titre lettre par lettre). Posée dans `MaterialApp.builder` (`app.dart`) : joue une seule fois par process (démarrage à froid), un tap la saute, fondu simple si `MediaQuery.disableAnimations`. Le splash natif est un fond `#2B3848` seul.

## `shooting_stars.dart`

`ShootingStars` : fond animé « ciel étoilé calme » via `CustomPainter` — étoiles qui scintillent sur 3 profondeurs en dérivant lentement, et une étoile filante toutes les 4 à 7 s. Un seul `Ticker` alimente un `ValueNotifier` : seul le painter se redessine (dans un `RepaintBoundary`), pas l'arbre.

Wrappe son `child` dans un `Material(type: transparent)` pour supporter les `TextField` imbriques.

Utilise sur tous les ecrans comme fond d'ecran.

## `score_reveal_chart.dart`

`ScoreRevealPainter` : le graphique de la révélation des scores, dessiné depuis une `ScoreTimeline` et une animation de 0 à 1. Aucun chiffre. Pas de logique de jeu. Étiquettes toujours à droite des têtes, dans une colonne réservée : rien n'est tracé à droite de la tête, donc aucun nom ne touche une courbe. `placeRevealLabels` reste une fonction pure du progrès (position moyennée sur une fenêtre, jamais d'état par image). Grandes polices : l'étiquette réduit jusqu'à tenir dans la hauteur, puis se coupe.
