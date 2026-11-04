# Revue Codex — entre-manches r1

**Verdict : NOT READY** — un seul MAJOR (copie transmise par l'orchestrateur).

## MAJOR — `lib/widgets/fiesta/turn_time_cards.dart:89`
La ligne compacte du rattrapage ne dit plus en texte « en tête / en retard » : l'état ne passe que par la couleur (ligne 96), invisible aux lecteurs d'écran. Elle ne dit plus non plus que l'ajustement ne vaut que pour le 1er tour (hors continuation) de chaque équipe.

### Arbitrage orchestrateur (Florent veut un écran minimal)
- À FAIRE : garder la ligne compacte, rendre l'état accessible sans texte visible supplémentaire (`Semantics` / label par entrée) ; le signe + / − visible suffit à l'œil.
- RÉSIDU ASSUMÉ : « seulement le 1er tour » n'est pas réaffiché à l'écran ; il doit figurer dans l'étape d'aide « Rattrapage » du « ? ».
