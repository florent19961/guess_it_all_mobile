# screens/

14 ecrans du jeu. Tous sont des StatefulWidget/StatelessWidget qui lisent le `GameProvider` via `Provider.of` ou `context.watch`.

## Flux de navigation

```
HomeScreen → GameModeScreen ─ Classique ─────────────────────────────────────► SettingsScreen
                            └ Fiesta → FiestaChoiceScreen → Auto | Ensembles → FiestaRecapScreen ─┘
SettingsScreen → (CategoriesScreen) → PlayersScreen → (WordsScreen) → TeamsScreen
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
| `game_mode_screen.dart` | Nouvelle partie : Classique ou Fiesta |
| `fiesta_choice_screen.dart` | Fiesta : Mode Auto ou Personnalise |
| `fiesta_auto_screen.dart` | Mode Auto : 2 interrupteurs (au moins un) + regles communes |
| `fiesta_recap_screen.dart` | Recap Fiesta avant les Parametres ; cible de « Rejouer » apres une partie Fiesta |
| `fiesta_ensembles_screen.dart` | « Mes ensembles » (Fiesta Personnalise) : compteur n / 10, Creer, Utiliser / Modifier / Dupliquer / Supprimer (confirmation) |
| `fiesta_ensemble_editor_screen.dart` | Editeur d'un ensemble, ouvert par `Navigator.push` depuis la liste (rend `true` si enregistre). Bouton grise + explications tant que `validateEnsemble` rend des erreurs |

Invariant Fiesta : le choix du mode vit dans `GameProvider.pendingFiesta`, **en memoire
seulement** (Q10), et `TeamsScreen` le passe a `startGame`. Le chemin « Reprendre » de l'accueil
ne traverse jamais les ecrans de mode.

## Point d'entree des ensembles (contrat 2-3 → 2-4)

`FiestaEnsemblesScreen({required VoidCallback onBack, required ValueChanged<FiestaEnsemble> onUse})`.
L'ecran ne connait ni le provider ni la navigation : `onUse` recoit l'ensemble choisi, **deja
marque `lastUsedId`** ; `ensemble.rules` est un `FiestaRules` (mode `custom`, `ensembleName` =
nom) pret a etre gele par `startGame(fiesta: ...)`. Branchement (`app.dart`, route
`AppConstants.screenFiestaEnsembles`) : `onBack` → `screenFiestaChoice` ; `onUse` →
`setPendingFiesta(ensemble.rules)` puis `screenFiestaRecap`. Le « Modifier » du recap en
Personnalise revient a cette liste.
