# Fix r1 — story 2-4

Réponse à `2-4-review-r1.md`. Chaque finding a été re-tracé dans le code avant d'agir.

| # | Décision | Preuve |
|---|----------|--------|
| **M1** | **Corrigé à la racine.** Confirmé : `_loadFromStorage` relisait `_game.fiesta` sans toucher `_pendingFiesta`, et `teams_screen.dart` relance avec `startGame(fiesta: provider.pendingFiesta)` → `clearFiesta`. Une ligne après `GameState.fromJson` : `_pendingFiesta = _game.fiesta?.rules;`. Invariant écrit en commentaire et dans `tracking_evolution` : **en partie, `pendingFiesta` = `fiesta?.rules`**. | `lib/providers/game_provider.dart` (`_loadFromStorage`) ; test : 2ᵉ `GameProvider()` sur les mêmes prefs → `pendingFiesta.symmetric == false` (rouge avant le fix, vert après). |
| **M2** | **Corrigé.** `draw = rules.symmetric && rules.drawCount > 0`, utilisé pour le détail et le Oui/Non. | `lib/screens/fiesta_recap_screen.dart`, `_customLines`. |
| m1 / mutation M2 | **Simplifié la racine.** Avec le fix M1, l'invariant tient aussi après un kill, et `endGameAndGoHome` n'efface pas l'attente : sa capture était redondante. **Supprimée** (remplacée par un commentaire qui dit pourquoi l'attente n'est pas effacée). La mutation n'a plus d'objet. | `game_provider.dart`, `endGameAndGoHome`. |
| m2 / mutation M1 | **Accepté tel quel.** La garde `allWords` est tuée par le bloc Classique, et maintenant aussi par le bloc après rechargement. | mutation rejouée : test rouge. |
| m3 / mutation M4 | **Tuée.** Une assertion ajoutée au test existant : `startNewGame` sur le provider rechargé → `pendingFiesta == null`. | mutation rejouée : test rouge. |
| m4 | **Résidu assumé**, noté. | `docs/notes_pour_plus_tard.md`, entrée du 2026-11-03. |
| m5 | **Accepté** (Q12 dit « passe par le Récap » ; retour = écran d'édition, comme partout ailleurs dans le parcours). À vérifier en recette. | — |
| m6 | **Documenté.** | `docs/tracking_evolution.md`, entrée 2-4. |
| m7 | **Corrigé en partie.** `_Hint` → `FiestaHint` public dans `fiesta_setup_widgets.dart`. `catchUpSummary(CatchUpRules)` factorise la ligne du Récap (Auto et Personnalisé). L'écran Auto garde sa formulation détaillée sur trois lignes (maquette `auto`), ce n'est pas le même texte. | `lib/widgets/fiesta/fiesta_setup_widgets.dart`. |
| m8 | **Corrigé.** Plus de `?? 3` : la validation de 2-3 ne garantit **pas** `fixedRound` pour `fixed` (`ensemble_validation.dart:44-45` tolère le nul), donc le Récap affiche « fixé » sans inventer de manche, « fixé manche N » sinon. | `fiesta_recap_screen.dart`, `_fixedLabel`. |
| m9 | **Laissé à l'orchestrateur** (merge 2-3/2-4), comme demandé. | — |
| Commentaire `// Mode Auto` périmé sur `symmetric` (`fiesta_rules.dart`) | **Signalé à l'orchestrateur** pour 2-2 : la lane ne modifie pas les types de 2-2. | — |

## Mutations rejouées sur `test/providers/fiesta_replay_test.dart`

| Mutation | Résultat |
|----------|----------|
| retirer la restauration dans `_loadFromStorage` | tuée |
| retirer `_pendingFiesta = null` dans `startNewGame` | tuée |
| retirer la garde `allWords` de `restartWithSamePlayers` | tuée |

Tests : toujours **un** fichier de test ajouté par la story (aucun nouveau en r1).
