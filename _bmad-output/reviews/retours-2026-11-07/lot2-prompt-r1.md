# Revue lot 2 `retours-reveal` (tier standard), round 1

Lecture seule. Lis le patch `_bmad-output/reviews/retours-2026-11-07/lot2-patch-r1.diff` (ne lance pas `git diff`),
puis le code autour dans le worktree `/home/florent19961/guess-it-all-retours-reveal`, branche `feat/retours-reveal`.

## Objectif

Décision D9 : `/tmp/claude-1000/-home-florent19961-guess-it-all-audit/dc8da8fa-0844-4349-be94-32409786a766/scratchpad/spec-retours-2026-11-07.md`.
Maquette de référence : script en bas de `/tmp/claude-1000/-home-florent19961-guess-it-all-audit/dc8da8fa-0844-4349-be94-32409786a766/scratchpad/retours-7-novembre.html` (`layoutLabels`, `wrap`, `draw`).
Ces décisions sont prises par Florent : ne les re-tranche pas.

- Plus de bulles ni de sons de cartouche. Musique et gong inchangés. `ScoreTimeline.events` retiré.
- Courbes à gauche, colonne réservée à droite, étiquettes jamais à gauche de la tête.
- Étiquette = prénoms de l'équipe, ou noms d'équipes pour TOUTES si une équipe dépasse 5 joueurs.
- Étiquettes poussées, trait fin vers une étiquette éloignée, position lissée de façon déterministe sur `progress`.
- Légende : noms d'équipes. Bouton de la carte de fin : « Suivant ». Celui de `transition_screen.dart` ne change pas.

## Écarts assumés par rapport à la maquette (à challenger)

1. Fenêtre de lissage en part du tracé (0,045, ≈ 0,2 s) et non en nombre de tours (1,02 tour dans la maquette).
2. La fenêtre se resserre en fin de tracé (`min(_smoothWindow, 1 - progress)`), car le contrôleur s'arrête à 1 alors que
   la maquette laissait `t` déborder de 1,5 tour.
3. Grandes polices : la maquette n'en parle pas. Colonne élargie selon l'échelle (au plus la moitié de la largeur), police
   réduite jusqu'à tenir (minimum 9), puis coupe avec ellipse (`_fitLabels`).
4. `_stackLabels` ne garantit plus les bornes si la pile dépasse la hauteur : `_fitLabels` doit l'éviter.

## Questions précises

1. `_stackLabels` : un cas où deux étiquettes se chevauchent alors que la pile tient dans la hauteur ?
2. `_fitLabels` : la dernière étape tient-elle vraiment à 4 équipes dans le graphique minimal (`_minChartHeight` = 100) ?
   Le cache `_fittedFor` peut-il servir des étiquettes périmées (taille, échelle de texte, labels) ?
3. La moyenne de positions peut faire se croiser deux étiquettes ≈ 0,2 s lors d'un changement d'ordre, comme dans la maquette.
   Est-ce conforme à « se poussent pour ne pas se chevaucher », ou y a-t-il une solution simple, déterministe et sans saut ?
4. `RevealSound` : retirer `newPlayer` et `resetForTest` (devenus sans appelant) laisse-t-il un chemin non couvert ?
   Le retrait du contexte audio sans focus est-il sans effet sur la musique, Android et iOS ?
5. `buildScoreTimeline` sans `chargesUsed` : reste-t-il un usage cassé ? `entryOfCharge` garde-t-il sa couverture pour
   les badges de `stats_screen` ? Le récap et les autres usages de `chargesUsed` doivent rester intacts.
6. Valeur des tests : retirés 9, retravaillé 1 (`score_timeline_test.dart`), ajouté 1 (`score_reveal_labels_test.dart`).
   Un test retiré gardait-il un invariant encore vivant ? Le test ajouté détecte-t-il une mutation de `_labelOffset`,
   du tri, de la passe de bornes ou du seuil de 5 ?

## Format attendu

Écris ton rapport dans `_bmad-output/reviews/retours-2026-11-07/lot2-review-r1.md` : verdict READY ou NOT READY, puis les
findings par gravité (BLOCKER, MAJOR, MINOR), chacun avec `fichier:ligne`, le scénario concret et une correction proposée.
Applique la grille `thermo-nuclear-code-quality-review` limitée au diff. Vérifie les deux plateformes.
