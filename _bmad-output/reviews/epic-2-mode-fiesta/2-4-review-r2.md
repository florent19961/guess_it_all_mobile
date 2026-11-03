# Review r2 — story 2-4

Reviewer : Opus. Inputs : `2-4-fix-r1.md`, `2-4-patch-r2.diff`, worktree @ `95931a0`.

## Verdict : READY

Les deux MAJOR de r1 sont corrigés à la racine. Toutes les mutations annoncées sont tuées, plus
une que j'ai ajoutée, et le correctif n'introduit rien de nouveau.

## M1 — corrigé

`lib/providers/game_provider.dart:105-108` : `_pendingFiesta = _game.fiesta?.rules;` juste après
`GameState.fromJson` dans `_loadFromStorage`. L'invariant « en partie, `pendingFiesta` =
`fiesta?.rules` » a été vérifié sur chaque chemin :

| Chemin | `pendingFiesta` | OK |
|--------|-----------------|----|
| Lancement (`teams_screen` → `startGame(fiesta: pendingFiesta)`) | = config gelée par construction | ✅ |
| Kill puis relance, partie en cours ou suspendue | restaurée depuis `GameState.fiesta` | ✅ |
| Kill puis relance, puis « Retour aux équipes » et « Lancer » (le scénario de M1) | config restaurée → relance Fiesta | ✅ |
| Reprendre (`resumeGame`) | intact | ✅ |
| Abandon (« Nouvelle partie » + Valider) puis `startNewGame` | `null` | ✅ |
| Rejouer depuis Résultats (`allWords` non vide) | relu depuis `_game.fiesta` → Récap si Fiesta, Paramètres si Classique | ✅ |
| Kill sur Résultats, relance, puis Rejouer | restaurée au chargement et relue | ✅ |
| Accueil après `endGameAndGoHome`, puis Rejouer de l'accueil | gardée en mémoire (aucune remise à zéro) → Récap | ✅ |
| Kill **après** `endGameAndGoHome`, puis Rejouer de l'accueil | `null` → Classique (résidu m4, noté dans `notes_pour_plus_tard`) | assumé |

Supprimer la capture dans `endGameAndGoHome` ne rouvre pas le trou. `setPendingFiesta` n'est
appelable que depuis les écrans de configuration, injoignables en cours de partie : seul
« Nouvelle partie » y mène, et il passe par `startNewGame`. L'attente vaut donc déjà la config
gelée au moment de `endGameAndGoHome`, y compris après un kill grâce à la restauration. La
mutation D ci-dessous confirme que le test protège ce chemin.

## M2 — corrigé

`lib/screens/fiesta_recap_screen.dart:103` : `final draw = rules.symmetric && rules.drawCount > 0;`.
`draw` sert au détail (« N par manche » ou « Désactivé ») et au Oui/Non. C'est le même contrat
que l'éditeur 2-3.

## Mutations (`test/providers/fiesta_replay_test.dart`, annulées par édition inverse)

| # | Mutation | Résultat |
|---|----------|----------|
| A | retirer la restauration dans `_loadFromStorage` | tuée (`Expected: false`, bloc rechargement) |
| B | retirer `_pendingFiesta = null` dans `startNewGame` | tuée (`Expected: null`) |
| C | retirer la garde `allWords` de `restartWithSamePlayers` | tuée (`Expected: settings`) |
| D | *(ajoutée)* `_pendingFiesta = null` dans `endGameAndGoHome` | tuée (`Expected: fiestaRecap`, Rejouer de l'accueil) |

État de départ : les 3 tests (2 fichiers) sont verts. `dart format` est propre. Les infos
`flutter analyze` sont toutes antérieures au patch, aucune sur une ligne du diff. `git status` est
propre après les mutations.

## Nouveautés du correctif : rien de bloquant

- `FiestaHint` et `catchUpSummary` (`fiesta_setup_widgets.dart:308-323`) : la factorisation est
  correcte et `_Hint` a disparu.
- `_fixedLabel` (`fiesta_recap_screen.dart`) : plus de manche inventée. Le Récap affiche « fixé »
  quand `fixedRound` est nul. C'est honnête, et le sens de « fixé sans manche » pour le moteur
  revient à 2-2/2-3.
- **MINOR** : `FiestaLine` (`fiesta_setup_widgets.dart`) garde son propre style de détail
  (`bodySmall` 12 `gray400`), le même que `FiestaHint`. Il pourrait réutiliser `FiestaHint`.
  Cosmétique, non bloquant.
- Toujours pour l'orchestrateur, inchangé depuis r1 : m9 (constante `screenFiestaEnsembles`
  commune aux deux lanes, câblage `onUse: (e) { setPendingFiesta(e.rules); … }` au merge 2-3) et
  le commentaire `// Mode Auto` périmé sur `symmetric` dans 2-2.
