# Corrections sons-fond r1

- MAJOR cadence — **corrigé**. Les départs sont maintenant la somme cumulée de 12 écarts tirés entre 4 et 7 s (`_shotGaps`), et le cycle vaut leur somme (`_shotCycle`) : l'écart à la jonction du cycle est le dernier écart, donc aussi entre 4 et 7 s. `lib/widgets/effects/shooting_stars.dart` (`_shotGaps`, `_shotCycle`, `_shots`).
