# widgets/effects/

Effets visuels et animations.

## Fichier unique : `shooting_stars.dart`

`ShootingStarsBackground` : fond anime avec etoiles filantes sur 2 couches parallax via `CustomPainter`.

Wrappe son `child` dans un `Material(type: transparent)` pour supporter les `TextField` imbriques.

Utilise sur tous les ecrans comme fond d'ecran.
