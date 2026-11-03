# Review r1 — story 2-4 (choix du mode, Auto, Récap, Rejouer)

Reviewer : Opus (adversarial, code d'abord). Patch : `2-4-patch-r1.diff` sur `feat/fiesta-2-2`.
Worktree : `/home/florent19961/guess-it-all-fiesta-2-4` @ `8554e7a`.

## Verdict : NOT READY

Deux MAJOR, tous deux petits à corriger. Le parcours Classique est intact, le diff
`game_provider.dart` est minimal, et la gestion du retour (PopScope) est saine.

---

## MAJOR

### M1 — Une partie Fiesta reprise après un kill redevient Classique au « Retour aux équipes »

- `lib/providers/game_provider.dart:93` (`_loadFromStorage` restaure `_game.fiesta` mais pas
  `_pendingFiesta`) + `lib/screens/teams_screen.dart:78-81` (`startGame(fiesta: provider.pendingFiesta)`).
- Scénario : on lance une partie Fiesta. Au 1er tour, l'app est tuée (téléphone qui tourne, l'OS
  libère la mémoire). À la relance, la partie est restaurée **avec** `fiesta`, mais
  `_pendingFiesta == null`. Sur l'écran de jeu, « Retour aux équipes » (`game_screen.dart:236`,
  `goBackToTeams`), puis « Lancer » → `startGame(fiesta: null)` → `clearFiesta: true`. La partie
  repart en **Classique**, sans rien dire.
- Le même trou rend aussi inopérantes, après un kill, les deux captures ajoutées dans
  `endGameAndGoHome` et `restartWithSamePlayers`. Elles ne marchent aujourd'hui que parce que la
  config attendue est encore en mémoire (cf. mutation M2 ci-dessous).
- Correctif (racine, 1 ligne) : dans `_loadFromStorage`, après `_game = GameState.fromJson(...)`,
  écrire `_pendingFiesta = _game.fiesta?.rules;`. C'est sûr : l'état restauré est la partie gelée,
  et la remettre en attente est exactement le sens de Q12. Ajouter, au besoin, une assertion au
  test existant : un 2e `GameProvider()` sur les mêmes prefs a `pendingFiesta` non nul.

### M2 — Le Récap affiche « Tirage symétrique : Oui » pour un ensemble où il est coupé

- `lib/screens/fiesta_recap_screen.dart:120-125` : `value: rules.drawCount > 0`.
- La story 2-3 (lane `fiesta-2-3`) traite le tirage comme `rules.symmetric && rules.drawCount > 0`
  : l'interrupteur de l'éditeur est `fiesta_ensemble_editor_screen.dart:344`, la liste
  `fiesta_ensembles_screen.dart:178`, et `ensemble_validation.dart:19` fait de même.
  `drawCount` vaut 1 par défaut.
- Scénario : on coupe « Tirage symétrique » dans l'éditeur 2-3, puis « Utiliser ». Le Récap
  affiche « 1 par manche · Oui ». Le critère 3 (« résumé : tirage ») est faux à l'intégration
  2-3/2-4.
- Correctif : `final draw = rules.symmetric && rules.drawCount > 0;` puis
  `detail: draw ? '${rules.drawCount} par manche' : 'Désactivé', value: draw`. Signaler aussi à 2-2
  que le commentaire `// Mode Auto` sur `symmetric` (`fiesta_rules.dart:111`) est périmé.

---

## MINOR

- **m1 — Test : la capture de `endGameAndGoHome` n'est pas couverte.** Mutation M2 (supprimer
  `_pendingFiesta = _game.fiesta?.rules;`, `game_provider.dart:1163`) → le test **passe**. La
  config est encore en mémoire depuis `setPendingFiesta`, donc le « Rejouer de l'accueil » ne
  prouve rien. Le correctif de M1 donne le moyen de le tester : rejouer après un rechargement du
  provider.
- **m2 — La mutation M1 n'est tuée que par le scénario artificiel.** Sans la ligne `allWords`
  (`:1190`), seul le 3e bloc échoue (Classique lancé avec une config en attente, ce qui ne se
  produit pas via l'UI). L'écueil « lire avant `GameState.initial()` » n'est jamais visible en
  mémoire. Le test garde de la valeur, mais son intitulé surestime ce qu'il protège. La couverture
  après rechargement (m1) le rendrait réel.
- **m3 — `startNewGame` qui efface la config en attente n'est pas testé.** Mutation M4 : retirer
  `_pendingFiesta = null` à `:1180` → tout passe. Pas de fuite Classique, car Mode de jeu fait
  `setPendingFiesta(null)` sur Classique (`game_mode_screen.dart:53`). Seul effet : Mode de jeu
  présélectionne Fiesta. On peut accepter. La règle « un seul test » de la story l'explique.
- **m4 — « Rejouer » de l'accueil après un kill post-`endGameAndGoHome` repart en Classique.**
  `clearGameState` a effacé la partie gelée : impossible sans persistance. C'est cohérent avec Q10,
  mais Q12 ne le dit pas. Une ligne dans `docs/notes_pour_plus_tard.md` suffit.
- **m5 — Le retour du Récap ouvert par « Rejouer » mène à Mode Auto/Ensembles, pas aux Résultats
  ni à l'Accueil** (`fiesta_recap_screen.dart:40`). Pour repasser en Classique depuis un Rejouer,
  il faut 3 retours (Auto → Fiesta → Mode de jeu). Acceptable. À vérifier en recette.
- **m6 — Retour des Paramètres en Classique → Accueil, pas Mode de jeu**
  (`settings_screen.dart:250-254`). La story l'autorise (« seulement si trivial »). Le
  `tracking_evolution` devrait le mentionner.
- **m7 — Doublons (grille thermo-nucléaire).** `_Hint` (`fiesta_auto_screen.dart:122-133`)
  reproduit le style « détail » de `FiestaLine` (`bodySmall`, 12, `gray400`). La chaîne de
  l'auto-calibrage (`+b1 s / +b2 s × écart…`) est écrite deux fois : dans l'écran Auto et
  `_autoLines` du Récap. Pistes : exposer un `FiestaHint` dans `fiesta_setup_widgets.dart` et
  factoriser `catchUpSummary(CatchUpRules)`. Taille des écrans : OK (≤ 150 lignes).
- **m8 — `fixedRound ?? 3`** (`fiesta_recap_screen.dart:131`) : valeur par défaut magique dans
  l'UI. Si `fixedRound` peut être nul pour `fixed`, c'est au modèle 2-2 de le dire.
- **m9 — Bouchon 2-3 : remplacement facile mais non immédiat.** La route et la constante
  `screenFiestaEnsembles = 'fiestaEnsembles'` sont **identiques** dans les deux lanes : conflit de
  merge trivial dans `constants.dart` et `app.dart`. `FiestaEnsemblesScreen({onBack, onUse})`
  attend `ValueChanged<FiestaEnsemble>` : le câblage sera
  `onBack: → screenFiestaChoice`, `onUse: (e) { setPendingFiesta(e.rules); goToScreen(screenFiestaRecap); }`.
  Le bouchon est isolé dans un fichier, et son commentaire (`fiesta_ensembles_stub_screen.dart:10-13`)
  est juste. « Modifier » du Récap en Personnalisé ouvre la **liste**, pas l'éditeur de
  l'ensemble que demande le Périmètre. Acceptable si 2-3 n'expose pas de route d'éditeur.

---

## Points vérifiés OK

- **Classique inchangé** : Accueil → Jouer/Nouvelle partie/Valider (abandon) → `startNewGame`
  (en attente = nul) → Mode de jeu (Classique par défaut) → `setPendingFiesta(null)` → Paramètres →
  Joueurs → Équipes → `startGame(fiesta: null)` → `clearFiesta`. Rejouer après Classique →
  Paramètres. Retour des Paramètres → Accueil, comme avant. Aucune fuite trouvée par l'UI.
- **Reprendre** (critère 6) : `resumeGame` intact, ne traverse pas les écrans de mode.
- **Kill pendant la configuration** (critère 7) : `goToScreen` ne persiste pas sans mots. Après
  `restartWithSamePlayers`, seule la session est sauvée. Le Récap sans config en attente renvoie à
  Mode de jeu (`fiesta_recap_screen.dart:26-31`). Pas de crash.
- **Annuler et `_saveGameState`** ne sont pas touchés. Aucune clé `guessItAll_*` modifiée.
- **Plateformes** : aucun `Platform.*`. Le `PopScope(canPop: false)` du squelette commun gère le
  retour système Android sur les 5 écrans neufs. L'app est mono-route (switch sur
  `currentScreen`), donc le swipe iOS n'a rien à dépiler : pas de régression.
- **Diff `game_provider.dart`** : environ 20 lignes, localisées (champ, setter, 3 points
  d'effacement ou capture, 1 ternaire de route). Il ne gêne pas les lanes suivantes.
- **Test mis à jour** (`home_screen_new_game_test.dart`) : légitime, la cible change selon le
  critère 1.

## Mutation testing (`test/providers/fiesta_replay_test.dart`)

| # | Mutation | Résultat |
|---|----------|----------|
| M1 | supprimer `if (_game.allWords.isNotEmpty) _pendingFiesta = …` (`:1190`) | tuée (bloc 3 seulement) |
| M2 | supprimer la capture dans `endGameAndGoHome` (`:1163`) | **survit** |
| M4 | supprimer `_pendingFiesta = null` dans `startNewGame` (`:1180`) | **survit** (suite des 2 fichiers) |

Toutes les mutations ont été annulées par une modification inverse. `git status` est propre.
