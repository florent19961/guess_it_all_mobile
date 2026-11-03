# providers/

Gestion d'etat centralisee via Provider.

## Fichier unique : `game_provider.dart`

`GameProvider` (ChangeNotifier, ~1276 lignes) : cerveau de l'application.

### Responsabilites

- **Settings** : modification des parametres (equipes, joueurs, mots, duree, categories)
- **Joueurs/Equipes** : ajout, suppression, formation des equipes (manuelle/aleatoire)
- **Generation de mots** : mode aleatoire (avec cache metadata `_wordMetadataCache`) ou personnalise
- **Flux de jeu** : startGame, startTurn, markWordAsGuessed, passWord, validateWords, nextRound
- **Fiesta** : `startGame({FiestaRules? fiesta})` gele la config dans `GameState.fiesta` ; `startGame()` sans argument l'EFFACE (`clearFiesta`, le `copyWith` part de `_game`). Getter `isFiesta`. Tout l'etat Fiesta vit dans `GameState`, jamais dans des champs du provider (persistance + retour arriere)
- **Navigation** : changement d'ecran via `GameState.currentScreen`
- **Analytics** : tracking des evenements via `AnalyticsService`
- **Persistance** : sauvegarde/restauration etat via `StorageService`

### Points d'attention

- `_wordMetadataCache` est en memoire (non persiste). Si l'app est tuee, il est `null` au redemarrage. Un fallback `lookupWordsMetadata()` reconstitue les metadonnees depuis les categories.
- La navigation arriere est complexe : depend de l'ecran courant, du tour, et de l'existence de snapshots de validation.
- `_ensureWordsForPlayer()` conserve les mots existants d'un joueur si le compte est suffisant (meme apres changement de categories).
- **Durée du tour** : `turnTime` (composée par `composeTurnSeconds`) est lue par `startTurn` ET `startTurnTimer`. Ne jamais recalculer la durée ailleurs : l'avant-tour et le chrono divergeraient. `timeSpent` se mesure sur `turnAllottedSeconds`, pas sur le réglage.
- **Effets de tour Fiesta (2-8)** : `canPassWith(secondesAffichées)` est la **seule** garde de la passe (`passWord` ET le bouton de `turn_screen`), sur la pénalité **effective** (`currentPassPenalty`) ; sous `no_pass`, `passWord` sort avant `onWordPassed`. `validateWords` vide `fiesta.turn` et consomme les instances de portée **tour** de l'équipe — sauf en fin de manche, où la même équipe poursuit en N+1 (continuation) : consommées à la fin de ce tour-là.
- **Rattrapage Fiesta** : `catchUpPreview` (transition, calculé sur les scores) → `nextRound` le pose dans `fiesta.catchUpDue` → `startTurnTimer` le consomme au premier tour non-continuation de l'équipe.

### Dependances

Utilise `StorageService`, `AnalyticsService`, `UserService` (singletons).
