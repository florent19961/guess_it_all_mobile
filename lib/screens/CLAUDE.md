# screens/

14 ecrans du jeu. Tous sont des StatefulWidget/StatelessWidget qui lisent le `GameProvider` via `Provider.of` ou `context.watch`.

## Flux de navigation

```
HomeScreen → SettingsScreen (Classique / Fiesta ; Auto / Personnalisé dans « Avancés »)
  → (CategoriesScreen) → PlayersScreen → (WordsScreen) → TeamsScreen
  → [Fiesta Personnalisé seulement : FiestaEnsemblesScreen, « Jouer » lance la partie]
  → GameScreen → CountdownScreen → TurnScreen → VerificationScreen
  → TransitionScreen (entre manches) → ResultsScreen → StatsScreen
```

## Ecrans

| Ecran | Role |
|-------|------|
| `home_screen.dart` | Accueil : 3 etats (partie suspendue, session existante, nouveau jeu) |
| `settings_screen.dart` | Premier ecran de toute partie : interrupteur Classique / Fiesta (Classique par defaut ; 1er choix de Fiesta → tuto Fiesta une fois), nb joueurs/equipes, mode mots, categories, parametres avances (modal ; en Fiesta, + Auto / Personnalise). Retour → accueil |
| `categories_screen.dart` | Selection categories et niveaux de difficulte (1-4) |
| `players_screen.dart` | Saisie noms joueurs + generation mots aleatoires avec cache metadata |
| `words_screen.dart` | Saisie mots par joueur (mode personnalise). Bouton "Grosse flemme" pour auto-remplir |
| `teams_screen.dart` | Composition equipes par drag-and-drop, noms editables, bouton aleatoire. « Commencer » lance la partie ; en Fiesta Personnalise, « Suivant » mene aux ensembles |
| `game_screen.dart` | Pre-tour : affiche manche, equipe/joueur courant, scores, bouton jouer |
| `countdown_screen.dart` | Decompte 3-2-1-GO anime |
| `turn_screen.dart` | Jeu actif : timer, mot courant (auto-size), boutons Passer/Valider, pause, sons, haptic |
| `verification_screen.dart` | Validation post-tour : toggle valid/invalide par mot, sauvegarde snapshot |
| `transition_screen.dart` | Entre manches, volontairement minimal (aucun score) : manche terminee, carte de la manche suivante (titre + regle), qui commence, temps bonus conserve, mots du dernier tour ; Fiesta : tirage, rattrapage, coup de pouce en une ligne chacun, 1 parmi 3 en carte (route `_PickThreeFlow` : passer le telephone puis choisir, non persistee) |
| `results_screen.dart` | Podium anime, tableau scores par manche, carte « Modificateurs de la partie » (Fiesta seulement), boutons Rejouer/Stats |
| `stats_screen.dart` | Stats detaillees : graphique evolution scores (fl_chart), top joueurs, temps moyen |
| `rules_screen.dart` | Regles completes du jeu (3 manches) + Revoir le tuto / le tuto Fiesta / les aides |
| `rules_tutorial_screen.dart` | Tuto des regles, 4 cartes (`Navigator.push` via `show`), pénalité de passe lue dans les reglages |
| `fiesta_tutorial_screen.dart` | Tuto Fiesta, 3 cartes (`Navigator.push` via `show`) |
| `fiesta_ensembles_screen.dart` | « Mes ensembles » (Fiesta Personnalise, apres les equipes) : compteur n / 10, Creer, Jouer / Modifier / Dupliquer / Supprimer (confirmation) |
| `fiesta_ensemble_editor_screen.dart` | Editeur d'un ensemble, ouvert par `Navigator.push` depuis la liste (rend `true` si enregistre). Catalogue + « Une seule reponse » (toute la partie), tirage 0 a 3. Bouton grise + explications tant que `validateEnsemble` rend des erreurs |

Invariant Fiesta : le choix du mode vit dans `GameProvider.pendingFiesta`, **en memoire
seulement** (Q10) : nul = Classique, `FiestaRules(mode: auto)` = Auto, mode `custom` =
Personnalise (l'ensemble, choisi apres les equipes, le remplace). `TeamsScreen` le passe a
`startGame` (ou mene aux ensembles en Personnalise). « Nouvelle partie » le vide (Classique par
defaut) ; « Rejouer » le garde et revient aux Parametres. Le chemin « Reprendre » de l'accueil
ne traverse jamais ces ecrans. Les anciens ecrans « Mode de jeu », « Auto ou Personnalise »,
« Mode Auto » et « Recap » sont supprimes (2026-11-04) : un `currentScreen` relu a leur nom
tombe sur l'accueil.

## Point d'entree des ensembles (contrat 2-3 → 2-4)

`FiestaEnsemblesScreen({required VoidCallback onBack, required ValueChanged<FiestaEnsemble> onUse})`.
L'ecran ne connait ni le provider ni la navigation : `onUse` recoit l'ensemble choisi, **deja
marque `lastUsedId`** ; `ensemble.rules` est un `FiestaRules` (mode `custom`, `ensembleName` =
nom) pret a etre gele par `startGame(fiesta: ...)`. Branchement (`app.dart`, route
`AppConstants.screenFiestaEnsembles`) : `onBack` → `screenTeams` ; `onUse` →
`setPendingFiesta(ensemble.rules)` puis `startGame(fiesta: ensemble.rules)`.
