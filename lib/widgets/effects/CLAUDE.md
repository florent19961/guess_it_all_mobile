# widgets/effects/

Effets visuels et animations.

## `startup_intro.dart`

`StartupIntro` : animation de démarrage « Le chrono se lance » (logo dessiné par `CustomPainter`, même géométrie que `scripts/render_logo.py`, puis titre lettre par lettre). Posée dans `MaterialApp.builder` (`app.dart`) : joue une seule fois par process (démarrage à froid), un tap la saute, fondu simple si `MediaQuery.disableAnimations`. Le splash natif est un fond `#2B3848` seul.

## `shooting_stars.dart`

`ShootingStars` : fond animé « ciel étoilé calme » via `CustomPainter` — étoiles qui scintillent sur 3 profondeurs en dérivant lentement, et une étoile filante toutes les 4 à 7 s. Un seul `Ticker` alimente un `ValueNotifier` : seul le painter se redessine (dans un `RepaintBoundary`), pas l'arbre.

Wrappe son `child` dans un `Material(type: transparent)` pour supporter les `TextField` imbriques.

Utilise sur tous les ecrans comme fond d'ecran.
