# Revue lot 4 `retours-parcours` : round 1

Tier standard (avec une petite touche sur la persistance). Lecture seule : ne modifie rien, ne lance pas `git diff`.

- Patch à lire : `_bmad-output/reviews/retours-2026-11-07/lot4-patch-r1.diff` (par rapport à `origin/feat/retours-regles`, lot 1 encore en revue).
- Worktree pour lire le code autour : `/home/florent19961/guess-it-all-retours-parcours`, branche `feat/retours-parcours`.
- Spec : `_bmad-output/specs/fiesta/retours-2026-11-07.md`, décision **D8** uniquement. Ces décisions sont celles de Florent : signale un écart, ne les rediscute pas.
- Rapport à écrire dans `_bmad-output/reviews/retours-2026-11-07/lot4-review-r1.md`.

## Objectif

« Suivant » de Paramètres va toujours aux joueurs. L'ensemble se change dans Avancés (« Changer ›»), l'écran des ensembles valide par « Valider » et ramène aux Paramètres. Passer en Fiesta pose le dernier ensemble ou Fiesta classique, jamais `FiestaRules()`. Réinitialiser oublie `lastUsedId` et garde les ensembles créés. Ligne « Ensemble : <nom> » seulement hors Fiesta classique. Sur Joueurs, le champ actif remonte au-dessus du clavier.

## Mécanismes à examiner

1. `GameProvider.chooseFiestaMode` : pose `classicEnsemble.rules` de façon synchrone, relit, puis remplace si `identical(_pendingFiesta, attendu)`.
2. `GameProvider.refreshPendingEnsemble` (appelé par `onBack` de `app.dart`) : suit l'ensemble en attente modifié ou supprimé. Sorti si `ensembleName` nul, si `replayFiesta` existe, ou si `_game.allWords` n'est pas vide. Son hypothèse : hors ces cas, l'attente est toujours le dernier utilisé.
3. `_isCurrentClassic` et `_ensembleName` de `settings_screen.dart` : comparaison JSON, suffixe « (ancienne version) ».
4. `players_screen.dart` : `SizedBox(height: keyboard)` à la place du bouton clavier ouvert, plus de `viewInsets` dans le padding de la liste, `cacheExtent`.

## Questions précises

1. **Tous les chemins de `pendingFiesta`** (Rejouer de fin de partie et de l'accueil, `replayFromHistory`, reprise au lancement, `goBackToTeams` puis retour jusqu'aux Paramètres, partie rejouée pas encore lancée, ensemble supprimé, Réinitialiser) : un chemin peut-il démarrer une partie Fiesta sans règles, ou contredire l'hypothèse du point 2 ?
2. **Changement de comportement** : une partie rejouée ne passe plus par la liste, qui remplaçait des règles gelées sans ensemble correspondant. Elles sont maintenant jouées telles quelles. Une règle gelée ancienne (`draw` en Toujours, `two_words`, compteurs) peut-elle casser `startGame` ou le jeu ?
3. **Course** : `clearLocalStorage` attend `forgetLastUsed` via la file `_serialized` ; `chooseFiestaMode` lit via `load`, hors file. Un `markUsed` puis un retour rapide peuvent-ils relire une valeur périmée ?
4. **Autoscroll, Android et iOS** : `MediaQuery.padding.bottom` vaut-il bien 0 clavier ouvert (sinon le `SizedBox` ajoute la zone sûre en trop) ? Le retrait du bouton et de `_nextKey` clavier ouvert gêne-t-il l'aide (« ? ») ou un `setState` en cours ? Le `viewInsets` animé crée-t-il un saut visible ?
5. **`cacheExtent`** est déprécié depuis 3.41 (`scrollCacheExtent`). Le code reste dessus car le Flutter Windows des recettes est en 3.38.3, le CI et le dev en 3.44.8. D'accord ?
6. **Règle 7** : `forgetLastUsed` ne fait que retirer `lastUsedId` du blob, déjà facultatif, en gardant les entrées illisibles. Confirme qu'aucune forme ne change.
7. **Tests** (mutation testing, `test/screens/retours_parcours_test.dart`) : les mutations déjà jouées sur chaque garde sont rouges. Y a-t-il un test redondant, ou une garantie nommée sans être exercée ? Les 3 tests de la ligne Ensemble sont des widget tests : valent-ils leur coût face à la règle « pas de widget test pour de l'UI simple » ?
8. **Simplification** : ce diff est-il sur-dimensionné ? En particulier `refreshPendingEnsemble`, et le suffixe, qui est un texte joueur absent de la spec.

## Vérifié par l'implémenteur, à contre-vérifier si possible

Paramètres sans défilement : test temporaire (non committé) avec les vraies polices chargées par `FontLoader`, `maxScrollExtent` = 0 et contenu = 732 px dans le pire cas (ligne Ensemble + « partie longue »), sur 360 × 740 et 390 × 763. Modal Avancés : `maxScrollExtent` = 0 avec la ligne Ensemble, sur les deux tailles.

## Format attendu

Par finding : gravité (BLOCKER, MAJOR, MINOR), `fichier:ligne`, scénario concret de reproduction, correction proposée. Conclure par READY ou NOT READY. Rien à signaler sur un point : le dire en une ligne.
