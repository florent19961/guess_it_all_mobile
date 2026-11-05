# Brancher les aides sur un écran

Le kit est branché partout (tous les écrans du tableau ci-dessous, plus **Règles** et le
tuto des règles ouvert d'office au premier « Jouer » de l'**Accueil**). Ce fichier décrit le geste et ce que porte
chaque écran, pour en ajouter un ou vérifier un branchement.

## Le geste, partout pareil

1. L'écran devient `StatefulWidget` s'il ne l'est pas (les `GlobalKey` vivent dans le `State`,
   jamais en `static` : deux montages = clé en double).
2. Une `GlobalKey` par contrôle à expliquer, posée en `key:` sur le widget (ou un
   `KeyedSubtree(key: …, child: …)` autour). Une clé posée sur un widget absent dans l'état
   courant de l'écran est **sautée** : passer toutes les clés, toujours. 🔴 Règle : élément
   affiché = une étape l'explique ; élément absent = pas d'étape, et aucun texte n'en parle.
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
| `home_screen` | `homeHelp(playLabel: …)` (« Jouer » ou « Nouvelle partie », le libellé du bouton) | `play` (« Jouer » **ou** « Nouvelle partie »), `resume` (« Reprendre »), `replay` (« Rejouer »), `rules`, `history` | `right: 16` |
| `settings_screen` | `settingsHelp(passPenalty: provider.settings.passPenalty)` | `counts` (cartes Joueurs + Équipes), `mode` (interrupteur Classique / Fiesta de la section « Mode de jeu »), `wordChoice`, `categories` (bouton Catégories & Difficultés), `longGame` (avertissement « partie longue », au-delà de 50 mots), `advanced` (bouton Avancés ; « Réinitialiser les paramètres » vit en bas de cette fenêtre) | `HelpButton.inline` en tête de la `Row` « ? » / Avancés |
| `players_screen` | `playersHelp(randomWords: …)` (texte du bouton de mots selon le mode) | `firstPlayer` (ligne du joueur 1), `words` (bouton Saisir/Voir mots du joueur 1), `next` | `right: 16` |
| `fiesta_ensembles_screen` | `fiestaEnsemblesHelp(hasMine, full, hasDraft, selectedHasModifiers)` | `ready` (toute la liste ; la phrase sur les pastilles rouges et vertes seulement si la ligne dépliée en a), `firstMine` (1re ligne personnelle, toujours montée, absente sans ensemble personnel ; le crayon et la corbeille n'apparaissent qu'une fois un perso sélectionné, le texte le dit), `create` (titre selon l'état : créer, reprendre le brouillon, limite atteinte), `next` (« Suivant ») | `right: 16` |
| `fiesta_ensemble_editor_screen` | `fiestaEditorHelp(tab, hasCounts)` : seul le menu ouvert est expliqué | `tabs`, `menu` (le menu ouvert), `noDraw` (« Rien à tirer »), `locked` (1re ligne verrouillée du menu ouvert), `challenges` (cadre Défis surprises, ouvert), `save` (« Enregistrer ») | `right: 16` |
| `teams_screen` | `teamsHelp` | `firstTeam` (carte de la 1re équipe), `shuffle`, `incomplete` (message, si une équipe a moins de 2 joueurs), `start` (« Commencer ») | `right: 16` |
| `game_screen` (avant-tour) | `preTurnHelp(playerName: …, firstTurnOfGame: …)` | `team` (nom d'équipe + joueur), `roundRules` (icône info de la manche), `previousTurn` (« N mots », dès le 2e tour), `bonusTime` (« Temps bonus », seulement s'il y a du temps reporté), `back` (retour, s'il est affiché ; le titre dit où il mène), `start` | `right: besideCornerButton` |
| `game_screen` Fiesta | `fiestaPreTurnHelp(FiestaPreTurnKeys)` | Une clé par type d'élément, posée seulement s'il est à l'écran (`FiestaTurnZone`, sauf `reuseChoices`) : pas d'élément, pas d'étape. `reuseChoices`, `thisTurn` (cadre « Actif », sans clé sur « Rien pour l'instant »), `firstRule`, `firstReceived`, `firstArmed`, `blockedGuesser`, `reserveBonus`, `reserveMalus`, `firstUnusable` (1re cartouche grisée), `sent` | même bouton : `preTurnHelp(fiesta: fiestaPreTurnHelp(...))`, étapes insérées avant « Commencer le tour » |
| `turn_screen` | `turnHelp(passPenalty: provider.currentPassPenalty, passState, reversed, buttonsUnderWord, secondWordShown)` — pas `settings.passPenalty` : la Passe gratuite Fiesta la met à 0. `passState` donne le titre et le texte de « Passer » (disponible, bloqué, dernier mot, pas assez de temps) | `timer`, `modifiers` (badges du tour), `blockedGuesser`, `freePasses`, `word`, `guessed`, `pass`, `pause`, `endTurn`. Deux mots : pas de `guessed` ni `pass`, l'étape du mot explique les boutons de chaque carte | `right: besideCornerButton` (pause à droite). 🔴 `provider.pauseTurn()` **avant** `CoachMarks.show`, reprise **après** : le chrono ne doit jamais tourner sous l'aide |
| `verification_screen` | `verificationHelp` | `doubled` (ligne « Mot compte double »), `wordList` (la liste défilante entière), `expired` (section « Mot en cours »), `passed` (section « Mots passés »), `validate` | `right: 16` (HomeButton à gauche) |
| `transition_screen` (écran fixe après M3 seulement) | `transitionHelp` | `previousTurn` (« Voir les N mots devinés »), `back` (`GameBackButton`), `next` (« Voir les résultats ») — dans cet ordre, l'action finale en dernier | coin haut droit |
| `history_screen` | `historyHelp(stats, hasPlayers, hasSetup)` : texte des tendances selon les lignes affichées, et de « Rejouer » selon que l'archive a ses réglages | `trends`, `firstGame`, `replay` (1re carte) ; pas de « ? » sans partie | coin haut droit |
| `results_screen` | `resultsHelp(hasPlayedCartridges: …)` | `podium` (la rangée du podium), `details` (Détails par manche), `back` (retour, s'il est affiché), `replay`, `stats` | `right: besideCornerButton` |

## Les seules aides automatiques

**Première partie sur ce téléphone, au premier tour de chaque joueur**, sur l'avant-tour et la
vérification (`first_game_help.dart`) :

```dart
// game_screen, après le premier build du tour (addPostFrameCallback) :
final gameId = provider.game.gameId; // String? : pas d'id = pas d'aide auto
if (gameId != null &&
    await FirstGameHelp.claim(
        gameId: gameId,
        playerId: player.id,
        screen: FirstGameHelp.preTurn) &&
    mounted) {
  await CoachMarks.show(context, preTurnHelp(...));
}
// verification_screen : idem avec FirstGameHelp.verification et verificationHelp(...)
// results_screen, initState : FirstGameHelp.finishFirstGame();
```

`claim({gameId, playerId, screen})` rend vrai une seule fois par (joueur, écran), et
seulement pendant la première partie : le premier `gameId` qui appelle `claim` est enregistré
(`guessItAll_firstGameId`), les paires montrées sont persistées
(`guessItAll_firstGameHelpShown`, liste de chaînes ; absent = vide) — un kill ne remontre rien.
Un **autre** `gameId` marque `firstGameDone` et rend faux : une première partie abandonnée ne
traîne pas sur les suivantes. Faux aussi dès que `guessItAll_firstGameDone` est vrai. « Revoir les aides » (Règles) appelle
`FirstGameHelp.reset()`. Rien d'autre ne s'affiche tout seul : pas de voile au premier
affichage d'un écran.

**Tuto Fiesta (3 cartes), automatique au premier choix de Fiesta** — branché dans
`settings_screen` (`_setMode`), quand l'interrupteur passe sur Fiesta :
`if (!await StorageService().hasSeenFiestaTutorial()) await FiestaTutorialScreen.show(context);`
(`show` marque le flag).

**Aides Fiesta avant-tour : derrière le « ? » seulement**, jamais
automatiques (décision Florent : plus aucune surimpression automatique hors premier tour de
chaque joueur).

## Flags (`StorageService`)

| Clé | Lecture / écriture | Sens |
|---|---|---|
| `guessItAll_tutorialSeen` | `hasSeenTutorial` / `markTutorialSeen` | onboarding des règles de première partie traité : question « Première partie ? » posée (anciennes versions) **ou** tuto des règles ouvert. Faux → le premier « Jouer » ouvre le tuto d'office, sans question. Sens inchangé, pas de migration |
| `guessItAll_fiestaTutorialSeen` | `hasSeenFiestaTutorial` / `markFiestaTutorialSeen` | tuto Fiesta déjà vu |
| `guessItAll_firstGameDone` | `isFirstGameDone` / `markFirstGameDone` / `resetFirstGameDone` | première partie terminée |
| `guessItAll_firstGameId` | `loadFirstGameId` / `saveFirstGameId` | `gameId` de la première partie (absent = pas encore enregistrée) |
| `guessItAll_firstGameHelpShown` | `addFirstGameHelpShown` | liste de `écran:joueur` déjà montrés (absent = vide) |

Booléens autonomes, aucune migration (règle 7). Au démarrage (`main.dart`, tâche locale),
`FirstGameHelp.initAtStartup()` écrit **une seule fois** chaque flag tuto / première partie
absent : `true` si `guessItAll_word_history` (présent dans la version en store) ou
`guessItAll_game_results` est non vide, `false` sinon. Ensuite le flag est présent et n'est plus
jamais recalculé : une première partie abandonnée (qui écrit aussi l'historique des mots) ne
peut pas faire basculer une install neuve. Un `false` écrit (« Revoir les aides ») prime.

## Test

`test/widgets/help_walkthrough_test.dart`, `test/widgets/help_conditional_test.dart` et `test/screens/preturn_help_test.dart` font défiler
les aides à 360 × 640 (`test/helpers/coach_walk.dart`) : chaque étape doit percer le voile sur une
cible dans l'écran. Un nouvel écran avec aide s'y ajoute.

## Limites connues

- `CoachMarks` mesure la cible une fois par étape : pas de nouvelle mesure si la taille de
  l'écran change pendant l'aide (écran partagé, pliable, clavier). L'app est bloquée en
  portrait, c'est accepté.
