# Brancher les aides sur un écran

Le kit est prêt mais n'est branché que sur **Règles** (3 boutons) et **Accueil** (prompt
« Première partie ? » sur le premier « Jouer »). Ce fichier dit, écran par écran, quoi poser.

## Le geste, partout pareil

1. L'écran devient `StatefulWidget` s'il ne l'est pas (les `GlobalKey` vivent dans le `State`,
   jamais en `static` : deux montages = clé en double).
2. Une `GlobalKey` par contrôle à expliquer, posée en `key:` sur le widget (ou un
   `KeyedSubtree(key: …, child: …)` autour). Une clé posée sur un widget absent dans l'état
   courant de l'écran est **sautée** : passer toutes les clés, toujours.
3. Dernier enfant du `Stack` de l'écran :
   ```dart
   HelpButton(onPressed: () => CoachMarks.show(context, xxxHelp(...)))
   ```
   `CoachMarks.show` rend un `Future` qui se termine à « Compris », « Passer » ou au retour
   système (Android). La cible est ramenée dans l'écran par défilement si besoin.
4. Coin droit déjà occupé par `HomeButton(alignRight: true)` ou le bouton pause :
   `right: HelpButton.besideCornerButton`. Rangée de boutons existante : `HelpButton.inline`.

Les textes sont dans `help_content.dart`, une fonction par écran. Aucun ne parle d'un score
entre deux tours ou deux manches (les scores sont cachés pendant la partie) ; seuls les
résultats finaux en montrent.

## Écran par écran

| Écran | Fonction | Clés à poser | Bouton « ? » |
|---|---|---|---|
| `home_screen` | `homeHelp` | `play` (« Jouer » **ou** « Nouvelle partie »), `resume` (« Reprendre »), `replay` (« Rejouer »), `rules`, `history` | `right: 16` |
| `settings_screen` | `settingsHelp(passPenalty: provider.settings.passPenalty)` | `counts` (cartes Joueurs + Équipes), `wordChoice`, `categories` (bouton Catégories & Difficultés), `advanced` (bouton Avancés) | `HelpButton.inline` en tête de la `Row` Réinitialiser / Avancés |
| `players_screen` | `playersHelp` | `firstPlayer` (ligne du joueur 1), `words` (bouton Saisir/Voir mots du joueur 1), `next` | `right: 16` |
| `teams_screen` | `teamsHelp` | `firstTeam` (carte de la 1re équipe), `shuffle`, `start` (« Commencer ») | `right: 16` |
| `game_screen` (avant-tour) | `preTurnHelp(playerName: …)` | `team` (nom d'équipe + joueur), `roundRules` (icône info de la manche), `previousTurn` (« Tour précédent »), `start` | `right: besideCornerButton` |
| `game_screen` Fiesta | `fiestaPreTurnHelp` | `badges` (Actif ce tour), `doublePoints` (interrupteur Mot compte double), `turnTime` (`TurnTimeCard`) | même bouton : concaténer `preTurnHelp(...) + fiestaPreTurnHelp(...)` en Fiesta |
| `turn_screen` | `turnHelp(passPenalty: …)` | `timer`, `word`, `guessed`, `pass`, `pause` | `right: besideCornerButton` (pause à droite). 🔴 `provider.pauseTurn()` **avant** `CoachMarks.show`, reprise **après** : le chrono ne doit jamais tourner sous l'aide |
| `verification_screen` | `verificationHelp` | `wordList` (la liste défilante entière), `validate` | `right: 16` (HomeButton à gauche) |
| `transition_screen` | `transitionHelp` | `previousTurn` (« Voir les N mots devinés »), `next` (« Manche suivante » / « Voir les résultats »), `back` (`GameBackButton`), `home` (`HomeButton`) | `right: besideCornerButton` |
| `transition_screen` Fiesta | `fiestaTransitionHelp` | `catchUp` (`CatchUpCard`), `pickThree` (`PickThreeCard` / `PassPhonePanel`), `appBoost` (`AppBoostCard`) | même bouton : concaténer `fiestaTransitionHelp(...) + transitionHelp(...)` en Fiesta |
| `results_screen` | `resultsHelp` | `podium` (la rangée du podium), `details` (Détails par manche), `replay`, `stats` | `right: besideCornerButton` |

## Les seules aides automatiques

**Première partie sur ce téléphone, au premier tour de chaque joueur**, sur l'avant-tour et la
vérification (`first_game_help.dart`) :

```dart
// game_screen, après le premier build du tour (addPostFrameCallback) :
if (await FirstGameHelp.claim(FirstGameHelp.preTurn, player.id) && mounted) {
  await CoachMarks.show(context, preTurnHelp(...));
}
// verification_screen : idem avec FirstGameHelp.verification et verificationHelp(...)
// results_screen, initState : FirstGameHelp.finishFirstGame();
```

`claim` rend vrai une seule fois par joueur et par écran, et faux dès que
`guessItAll_firstGameDone` est vrai. « Revoir les aides » (Règles) appelle
`FirstGameHelp.reset()`. Rien d'autre ne s'affiche tout seul : pas de voile au premier
affichage d'un écran.

**Tuto Fiesta (3 cartes), automatique à la première partie Fiesta** — à brancher dans
`game_mode_screen`, au choix de Fiesta, avant de naviguer :
`if (!await StorageService().hasSeenFiestaTutorial()) await FiestaTutorialScreen.show(context);`
(`show` marque le flag).

**Aides Fiesta avant-tour et fin de manche : derrière le « ? » seulement**, jamais
automatiques (décision Florent : plus aucune surimpression automatique hors premier tour de
chaque joueur).

## Flags (`StorageService`)

| Clé | Lecture / écriture | Sens |
|---|---|---|
| `guessItAll_tutorialSeen` | `hasSeenTutorial` / `markTutorialSeen` | prompt « Première partie ? » déjà posé |
| `guessItAll_fiestaTutorialSeen` | `hasSeenFiestaTutorial` / `markFiestaTutorialSeen` | tuto Fiesta déjà vu |
| `guessItAll_firstGameDone` | `isFirstGameDone` / `markFirstGameDone` / `resetFirstGameDone` | première partie terminée |

Booléens autonomes, absents = `false` : clés neuves, aucune migration (règle 7). Exception :
`tutorialSeen` et `firstGameDone` absents **et** historique `guessItAll_game_results` non vide
= joueur déjà venu → lus `true` et écrits une fois. Un `false` écrit (« Revoir les aides ») prime.
