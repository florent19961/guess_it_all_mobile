# widgets/effects/

Effets visuels et animations.

## Fichier unique : `shooting_stars.dart`

`ShootingStars` : fond animé « ciel étoilé calme » via `CustomPainter` — étoiles qui scintillent sur 3 profondeurs en dérivant lentement, et une étoile filante toutes les 4 à 7 s. Un seul `Ticker` alimente un `ValueNotifier` : seul le painter se redessine (dans un `RepaintBoundary`), pas l'arbre.

Wrappe son `child` dans un `Material(type: transparent)` pour supporter les `TextField` imbriques.

Utilise sur tous les ecrans comme fond d'ecran.
