# screens/

Les ecrans du jeu. Tous sont des StatefulWidget/StatelessWidget qui lisent le `GameProvider` via `Provider.of` ou `context.watch`.

## Flux de navigation

```
HomeScreen → SettingsScreen (Classique / Fiesta ; Auto / Personnalisé dans « Avancés »)
  → (CategoriesScreen)
  → [Fiesta Personnalisé seulement : FiestaEnsemblesScreen, « Suivant » → joueurs]
  → PlayersScreen → (WordsScreen) → TeamsScreen (« Commencer » lance la partie)
  → GameScreen → CountdownScreen → TurnScreen → VerificationScreen
  → TransitionScreen (entre manches) → ResultsScreen → StatsScreen
```

## Ecrans

| Ecran | Role |
|-------|------|
| `home_screen.dart` | Accueil : 3 etats (partie suspendue, session existante, nouveau jeu) |
| `settings_screen.dart` | Premier ecran de toute partie, **sans defilement** (390 × 763 et 360 × 740 utiles) : sections Joueurs, Equipes, « Mode de jeu » (interrupteur Classique / Fiesta ; Classique par defaut ; 1er choix de Fiesta → tuto Fiesta une fois), Choix des mots, puis categories, parametres avances (modal sans defilement, curseurs `compact` ; en Fiesta, + Auto / Personnalise ; en bas, « Reinitialiser les parametres » avec confirmation). En haut a droite : « ? » et roue crantee seulement. Retour (bouton et retour systeme) → accueil |
| `categories_screen.dart` | Selection categories et niveaux de difficulte (1-4) |
| `players_screen.dart` | Saisie noms joueurs + generation mots aleatoires avec cache metadata. Retour (bouton et systeme) → Parametres (Fiesta Personnalise : → ensembles) |
| `words_screen.dart` | Saisie mots par joueur (mode personnalise). Bouton "Grosse flemme" pour auto-remplir. Retour (bouton et systeme) → joueurs, mots sauvegardes |
| `teams_screen.dart` | Composition equipes par drag-and-drop, noms editables, bouton aleatoire. Retour (bouton et systeme) → joueurs. « Commencer » lance la partie (avec `pendingFiesta`, l'ensemble deja choisi en Personnalise) |
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
| `fiesta_ensembles_screen.dart` | « Fiesta personnalisee » (Fiesta Personnalise, juste apres Parametres, avant les joueurs ; retour bouton et systeme → Parametres). Un seul ecran, aucune page poussee : en haut « Prets a jouer » (ensembles enregistres, n / 10 ; aucun → « Fiesta classique » fourni par l'app = `defaultEnsembleRules`, jamais stocke), un tap selectionne ; Modifier (charge l'ensemble dans l'editeur) / Dupliquer / Supprimer (confirmation). En dessous, l'editeur en ligne (`FiestaEnsembleEditor`, `lib/widgets/fiesta/`) : un ensemble enregistre apparait en haut, selectionne. Saisie non enregistree : « Abandonner les modifications ? » avant Modifier un autre, Annuler, Retour (bouton et systeme) et Suivant ; selectionner pendant une modification referme l'editeur (Modifier selectionne aussi l'ensemble), l'affichage ne contredit jamais la selection. « Suivant » (grise sans selection) → joueurs |

Invariant Fiesta : le choix du mode vit dans `GameProvider.pendingFiesta`, **en memoire
seulement** (Q10) : nul = Classique, `FiestaRules(mode: auto)` = Auto, mode `custom` =
Personnalise (l'ensemble, choisi juste apres Parametres, le remplace). `TeamsScreen` le passe a
`startGame`. « Nouvelle partie » le vide (Classique par
defaut) ; « Rejouer » le garde et revient aux Parametres. Le chemin « Reprendre » de l'accueil
ne traverse jamais ces ecrans. Les anciens ecrans « Mode de jeu », « Auto ou Personnalise »,
« Mode Auto » et « Recap » sont supprimes (2026-11-04) : un `currentScreen` relu a leur nom
tombe sur l'accueil.

## Point d'entree des ensembles

`FiestaEnsemblesScreen({FiestaRules? selected, required VoidCallback onBack, required ValueChanged<FiestaRules> onNext})`.
L'ecran ne connait ni le provider ni la navigation. `selected` = `pendingFiesta` : l'ensemble
aux memes regles (JSON egal) est preselectionne, sinon le `lastUsedId` du stockage (« Rejouer »
repasse par Parametres puis cet ecran, l'ensemble precedent selectionne). `onNext` recoit les
regles choisies (mode `custom`, `ensembleName` = nom), apres `markUsed` pour un ensemble
enregistre. Branchement (`app.dart`) : `onBack` → `screenSettings` ; `onNext` →
`setPendingFiesta(rules)` puis `screenPlayers`.
