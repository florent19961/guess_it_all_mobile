# providers/

Gestion d'etat centralisee via Provider.

## Fichier unique : `game_provider.dart`

`GameProvider` (ChangeNotifier, ~1276 lignes) : cerveau de l'application.

### Responsabilites

- **Settings** : modification des parametres (equipes, joueurs, mots, duree, categories)
- **Joueurs/Equipes** : ajout, suppression, formation des equipes (manuelle/aleatoire)
- **Generation de mots** : mode aleatoire (avec cache metadata `_wordMetadataCache`) ou personnalise
- **Flux de jeu** : startGame, startTurn, markWordAsGuessed, passWord, validateWords, nextRound
- **Navigation** : changement d'ecran via `GameState.currentScreen`
- **Analytics** : tracking des evenements via `AnalyticsService`
- **Persistance** : sauvegarde/restauration etat via `StorageService`

### Points d'attention

- `_wordMetadataCache` est en memoire (non persiste). Si l'app est tuee, il est `null` au redemarrage. Un fallback `lookupWordsMetadata()` reconstitue les metadonnees depuis les categories.
- La navigation arriere est complexe : depend de l'ecran courant, du tour, et de l'existence de snapshots de validation.
- `_ensureWordsForPlayer()` conserve les mots existants d'un joueur si le compte est suffisant (meme apres changement de categories).

### Dependances

Utilise `StorageService`, `AnalyticsService`, `UserService` (singletons).
