# utils/

Constantes et utilitaires.

## Fichiers

| Fichier | Role |
|---------|------|
| `reversed_word.dart` | `reversedWordDisplay` : malus « Mot a l'envers » (2-8), MAJUSCULES inversees par graphemes |
| `constants.dart` | `AppConstants` : toutes les constantes du jeu (defauts, limites, cles stockage, noms d'ecrans, modes, niveaux difficulte avec emojis) |
| `team_names.dart` | `kFunnyTeamNames`, `drawTeamNames` : ~30 noms d'équipe drôles, tirés distincts par `createTeams` (renommage manuel toujours possible ; le « Rejouer » de l'historique garde les noms archivés) |

## Sous-repertoire

- `word_categories/` : chargement et generation de mots depuis les fichiers JSON
