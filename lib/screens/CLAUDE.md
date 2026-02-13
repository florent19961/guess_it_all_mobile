# screens/

14 ecrans du jeu. Tous sont des StatefulWidget/StatelessWidget qui lisent le `GameProvider` via `Provider.of` ou `context.watch`.

## Flux de navigation

```
HomeScreen → SettingsScreen → (CategoriesScreen) → PlayersScreen → (WordsScreen) → TeamsScreen
  → GameScreen → CountdownScreen → TurnScreen → VerificationScreen
  → TransitionScreen (entre manches) → ResultsScreen → StatsScreen
```

## Ecrans

| Ecran | Role |
|-------|------|
| `home_screen.dart` | Accueil : 3 etats (partie suspendue, session existante, nouveau jeu) |
| `settings_screen.dart` | Config : nb joueurs/equipes, mode mots, categories, parametres avances (modal) |
| `categories_screen.dart` | Selection categories et niveaux de difficulte (1-4) |
| `players_screen.dart` | Saisie noms joueurs + generation mots aleatoires avec cache metadata |
| `words_screen.dart` | Saisie mots par joueur (mode personnalise). Bouton "Grosse flemme" pour auto-remplir |
| `teams_screen.dart` | Composition equipes par drag-and-drop, noms editables, bouton aleatoire |
| `game_screen.dart` | Pre-tour : affiche manche, equipe/joueur courant, scores, bouton jouer |
| `countdown_screen.dart` | Decompte 3-2-1-GO anime |
| `turn_screen.dart` | Jeu actif : timer, mot courant (auto-size), boutons Passer/Valider, pause, sons, haptic |
| `verification_screen.dart` | Validation post-tour : toggle valid/invalide par mot, sauvegarde snapshot |
| `transition_screen.dart` | Entre manches : scores, medailles, indicateur bonus |
| `results_screen.dart` | Podium anime, tableau scores par manche, boutons Rejouer/Stats |
| `stats_screen.dart` | Stats detaillees : graphique evolution scores (fl_chart), top joueurs, temps moyen |
| `rules_screen.dart` | Regles completes du jeu (3 manches) |
