# screens/

Les ecrans du jeu. Tous sont des StatefulWidget/StatelessWidget qui lisent le `GameProvider` via `Provider.of` ou `context.watch`.

## Flux de navigation

```
HomeScreen → SettingsScreen (Classique / Fiesta)
  → (CategoriesScreen)
  → [Fiesta seulement : FiestaEnsemblesScreen, « Suivant » → joueurs]
  → PlayersScreen → (WordsScreen) → TeamsScreen (« Commencer » lance la partie)
  → GameScreen → CountdownScreen → [GiverBlockedScreen, le piège] → TurnScreen → VerificationScreen
  → TransitionScreen (animation après M1 et M2, écran fixe après M3) [Défi surprise : ChallengeRouteScreen, 1 ou 2 fois, après l'animation de M1 ou M2] → [ScoreRevealScreen, une fois] → ResultsScreen → StatsScreen
```

## Ecrans

| Ecran | Role |
|-------|------|
| `home_screen.dart` | Accueil : 3 etats (partie suspendue, session existante, nouveau jeu) |
| `settings_screen.dart` | Premier ecran de toute partie, **sans defilement** (390 × 763 et 360 × 740 utiles) : sections Joueurs, Equipes, « Mode de jeu » (interrupteur Classique / Fiesta ; Classique a la premiere ouverture, puis le dernier choix relu ; 1er choix actif de Fiesta → tuto Fiesta une fois, jamais a une restauration), Choix des mots, puis categories, parametres avances (modal sans defilement, curseurs `compact` ; en bas, « Reinitialiser les parametres » avec confirmation). En haut a droite : « ? » et roue crantee seulement. Retour (bouton et retour systeme) → accueil |
| `categories_screen.dart` | Selection categories et niveaux de difficulte (1-4) |
| `players_screen.dart` | Saisie noms joueurs + generation mots aleatoires avec cache metadata. Retour (bouton et systeme) → Parametres (Fiesta : → ensembles) |
| `words_screen.dart` | Saisie mots par joueur (mode personnalise). Bouton "Grosse flemme" pour auto-remplir. Retour (bouton et systeme) → joueurs, mots sauvegardes |
| `teams_screen.dart` | Composition equipes par drag-and-drop, noms editables, bouton aleatoire. Retour (bouton et systeme) → joueurs. « Commencer » lance la partie (avec `pendingFiesta`, l'ensemble deja choisi) |
| `game_screen.dart` | Pre-tour : manche, grande carte d'equipe (Classique et Fiesta : nom d'equipe en Bangers couleur, joueur dessous, « N mots restants » + « N mots »). Fiesta : `FiestaTurnZone`, sans defilement dans les cas realistes (Explosif) ; un cas extreme defile dans la zone, jamais sous le bouton : « ACTIF PENDANT VOTRE PROCHAIN TOUR » puis « VOTRE RESERVE ». Sur petit ecran dans les cas charges seulement (`FiestaTurnZone.fitsIn`), la carte se resserre. Lien discret « ↻ Reprendre les choix de X » apres le piege. A 2 equipes : ni « contre X » ni « bloque par X », pastille « ⇄ Envoye », « 🚫 Bob ». Le temps reporte s'affiche comme en Classique |
| `countdown_screen.dart` | Decompte 3-2-1-GO anime |
| `turn_screen.dart` | Jeu actif : timer, mot courant (auto-size), boutons Passer/Valider (`TurnWordText`, `TurnActionButtons`), pause, sons, haptic. Chrono a zero : `endTurn` directement dans le callback du Timer, jamais dans un `addPostFrameCallback` (il ne demande pas de frame, le tour restait sur « 1s » jusqu'a un toucher). Deux mots : meme fond, meme mot et memes boutons superposes deux fois, espacements resserres, sans defilement |
| `verification_screen.dart` | Validation post-tour : toggle valid/invalide par mot, sauvegarde snapshot |
| `transition_screen.dart` | Fin de manche, Classique et Fiesta, aucun score. Apres M1 et M2 : animation ~2,8 s (`_RoundStage`, sons `impact-bass-1` et `whoosh-short`, vibration, un toucher fait passer, animations reduites respectees) puis `nextRound`, directement vers l'avant-tour. Apres M3 : ecran fixe (retour, « Voir les N mots devines », « Voir les resultats ») |
| `giver_blocked_screen.dart` | Le piege d'« Interdit de faire deviner » : phrase, « Passe le telephone a X. », « Suivant » (`confirmGiverBlock`). Rien n'est consomme avant : une app tuee la remontre |
| `score_reveal_screen.dart` | `EndOfGameScreen`, ce que montre `screenResults` : `ScoreRevealScreen` tant que `GameState.scoreRevealSeen` est faux, sinon `ResultsScreen`. Aucun écran ni chemin de plus : tout ce qui mène aux résultats passe par cet aiguillage, l'historique n'y passe jamais. `ScoreRevealScreen` (maquette `curve(2)`) : graphique fixe tracé en 4,5 s sans chiffres (`ScoreRevealPainter`), légende dans l'ordre des équipes pour ne rien dévoiler, cartouches jouées qui tombent ; fin : vainqueur (jamais d'égalité, `getTeamsSortedByScore`), scores, « Voir les résultats ». Un toucher ou le retour système va aux résultats. L'animation attend le départ de la musique (0,8 s au plus) pour que son gong tombe à la fin du tracé. Animations réduites : la fin directement, sans aucun son. Le graphique passe avant le titre et la légende quand la place manque, le bouton reste toujours visible. Une app tuée pendant la révélation rouvre sur les résultats |
| `surprise_challenge_screen.dart` | Défi surprise, autonome et piloté par ses paramètres : VS coupé, règle, action, « Qui a gagné ? », roulette, « Les Moulins gagnent ! » en couleur d'équipe sans ombre. « Passer ce défi » jusqu'au choix du gagnant, retour système bloqué, animations réduites respectées |
| `challenge_route_screen.dart` | Branche `SurpriseChallengeScreen` sur le provider : `currentChallenge` traduit en noms et couleurs, issue rendue à `finishChallenge` |
| `results_screen.dart` | Podium anime, tableau scores par manche, carte « Modificateurs de la partie » (Fiesta seulement), boutons Rejouer/Stats |
| `stats_screen.dart` | Stats detaillees : graphique evolution scores (fl_chart), top joueurs, temps moyen |
| `rules_screen.dart` | Regles completes du jeu (3 manches) + Revoir le tuto / le tuto Fiesta / les aides |
| `rules_tutorial_screen.dart` | Tuto des regles, 4 cartes (`Navigator.push` via `show`), pénalité de passe lue dans les reglages |
| `fiesta_tutorial_screen.dart` | Tuto Fiesta, 3 cartes (`Navigator.push` via `show`) |
| `fiesta_ensembles_screen.dart` | La liste des ensembles (Fiesta, juste apres Parametres, avant les joueurs ; retour bouton et systeme → Parametres). « Prets a jouer » : les 8 ensembles **fournis** (`kProvidedEnsembles`, Voir / Dupliquer) puis les miens (n / 10 ; Voir / Modifier / Dupliquer / Supprimer avec confirmation) ; un tap selectionne ; « Fiesta classique » preselectionne a defaut d'attente ou de dernier utilise. « Creer un ensemble » (« Reprendre le brouillon » s'il y en a un) et « Modifier » POUSSENT `FiestaEnsembleEditorScreen` ; enregistre → selectionne. Brouillon = `FiestaEnsemblesScreen.draft` (statique, en memoire tant que l'app est ouverte, jamais persiste). « Suivant » → joueurs |
| `fiesta_ensemble_view_screen.dart` | Page « Voir » d'un ensemble (fourni ou mien), en lecture seule : 3 blocs « Toujours », « Aleatoire par manche », « Cartouches » (au hasard, puis pour tout le monde), bouton « Dupliquer » Défis surprises : une ligne dans le bloc Cartouches |
| `fiesta_ensemble_editor_screen.dart` | « Nouvel ensemble » / « Modifier l'ensemble » : nom, puis 3 onglets avec compteur (Toujours / Aleatoire par manche / Cartouches), cadres verts. Chaque menu n'affiche que ce qui y est possible ; le verrouille (`FiestaRules.lockReason`) dit pourquoi, garde ses reglages, et « Tout » / « Tous » ne le touchent jamais. Le premier interrupteur aleatoire fait passer « Combien par manche » de 0 a 1. Brouillon, popup et validation (`validateEnsemble`) : erreurs seulement apres un premier appui En bas de Cartouches, derrière « Si tu veux vraiment pousser plus loin » : interrupteur « Défis surprises » (déplié s'il est actif) |

Invariant Fiesta : le choix du mode vit dans `GameProvider.pendingFiesta` (regles en memoire,
dernier choix relu de `GameSettings` et du `lastUsedId` au demarrage et a « Nouvelle partie ») :
nul = Classique, sinon l'ensemble choisi juste apres Parametres.
`TeamsScreen` le passe a
`startGame`. « Nouvelle partie » retrouve le dernier
choix ; « Rejouer » le garde et revient aux Parametres. Le chemin « Reprendre » de l'accueil
ne traverse jamais ces ecrans. Les anciens ecrans « Mode de jeu », « Auto ou Personnalise »,
« Mode Auto » et « Recap » sont supprimes (2026-11-04) : un `currentScreen` relu a leur nom
tombe sur l'accueil.

## Point d'entree des ensembles

`FiestaEnsemblesScreen({FiestaRules? selected, required VoidCallback onBack, required ValueChanged<FiestaRules> onNext})`.
L'ecran ne connait ni le provider ni la navigation. `selected` = `pendingFiesta` : l'ensemble
aux memes regles (JSON egal) est preselectionne, sinon le `lastUsedId` du stockage, sinon
« Fiesta classique » (« Rejouer »
repasse par Parametres puis cet ecran, l'ensemble precedent selectionne). `onNext` recoit les
regles choisies (`ensembleName` = nom), apres `markUsed`. Branchement (`app.dart`) : `onBack` → `screenSettings` ; `onNext` →
`setPendingFiesta(rules)` puis `screenPlayers`.
