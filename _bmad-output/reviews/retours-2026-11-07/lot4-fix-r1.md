# Lot 4 : corrections de la revue r1

Commit des corrections : `c988e8a`. Base : `f9ec162` (code revu en r1).
Patch incrémental : `_bmad-output/reviews/retours-2026-11-07/lot4-delta-r1-r2.diff`.

## Findings

| Finding | Décision | Correction | Preuve |
|---|---|---|---|
| MAJOR, tuto ouvert et marqué vu après un retour en Classique | Corrigé | `_setMode` n'ouvre le tuto que si `mounted` et `pendingFiesta != null`, vérifiés après `chooseFiestaMode` et `hasSeenFiestaTutorial` | `lib/screens/settings_screen.dart`, test « Fiesta puis Classique pendant la relecture » |
| MAJOR, validation de Fiesta classique écrasée pendant la relecture | Corrigé | `_pendingChoices`, incrémenté par `setPendingFiesta`, capturé dans `_followLastUsedEnsemble`, donc après le `setPendingFiesta` de `chooseFiestaMode`. Le test `identical` reste | `lib/providers/game_provider.dart`, tests « Fiesta classique validé pendant la relecture » et « attente effacée hors de setPendingFiesta » |
| MINOR, suffixe « (ancienne version) » | Retiré (décision de l'orchestrateur) | Suffixe, `_isCurrentClassic`, comparaison JSON et imports retirés. La ligne compare le nom | `lib/screens/settings_screen.dart`, `_bmad-output/reviews/retours-2026-11-07/journal-arbitrages.md` |

Conséquence du retrait : le repli inventé « Sans nom » disparaît aussi. Un ensemble sans nom (`ensembleName` nul, ancien seulement) n'a pas de ligne, et son nom reste vide dans Avancés.

## Écritures directes de `_pendingFiesta`

Hors `setPendingFiesta` : `_loadFromStorage` (2), `startNewGame`, `restartWithSamePlayers`, `replayFromHistory`, `clearLocalStorage`, `resetGame`. Elles n'incrémentent pas le compteur ; `identical` les détecte quand l'objet change.

Résidu assumé : `startNewGame` peut écrire le même objet Fiesta classique pendant une relecture. La relecture applique alors le dernier ensemble utilisé, qui est aussi ce que `startNewGame` vient de relire : aucun effet visible.

## Tests

3 ajoutés, 1 retiré (la ligne « ancienne version »). Les deux tests de la ligne Ensemble restants sont gardés.

La course se provoque sans retarder la lecture : les appels s'enchaînent dans le même tour synchrone, avant le premier `await` de la relecture.

Rouge avant correction : la validation de Fiesta classique et le tuto. Mutations rouges après correction : retrait du compteur, retrait de `identical`, retrait de la condition du tuto.

Le test « attente effacée hors de setPendingFiesta » était vert avant correction : il garde `identical`, déjà présent, contre son retrait.

## Suite complète

`scripts/run-full-suite.sh` : exit 0, format et analyze passés, `+591: All tests passed!`

La ligne Ensemble garde sa hauteur : le mesurage sans défilement n'a pas été refait, comme convenu.
