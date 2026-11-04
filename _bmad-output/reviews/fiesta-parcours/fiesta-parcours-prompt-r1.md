# Revue r1 — lane fiesta-parcours (tier risqué)

Patch : `_bmad-output/reviews/fiesta-parcours/fiesta-parcours-patch-r1.diff` (diff sur la
merge-base `origin/main`, hors fichiers de revue). Lis le patch, puis le code autour dans le
worktree `/home/florent19961/guess-it-all-fiesta-parcours` (lecture seule). Ne lance pas
`git diff` toi-même. Rapport dans `_bmad-output/reviews/fiesta-parcours/fiesta-parcours-review-r1.md`.

## Objectif

Retours device de Florent (2026-11-04, maquette « E ») : choisir le mode dans les Paramètres
au lieu de trois écrans de choix, et retoucher les règles Fiesta.

## Décisions à vérifier (source : Florent)

1. Parcours : Accueil « Jouer » → Paramètres → Joueurs → Équipes → partie. En Fiesta
   Personnalisé seulement, « Mes ensembles » s'insère après Équipes. Écrans « Mode de jeu »,
   « Auto ou Personnalisé », « Mode Auto » supprimés avec leurs routes ; retour de Paramètres →
   accueil.
2. Paramètres : `AppToggle` « Classique / Fiesta » sous le titre, Classique par défaut, sans texte ;
   titre remonté (`SizedBox` 72 → 48).
3. Roue crantée « Avancés » : réglage « Fiesta » = `AppToggle` « Auto / Personnalisé » (Auto par
   défaut), absent en Classique.
4. Premier choix de Fiesta → tuto Fiesta une fois (`guessItAll_fiestaTutorialSeen`) ; aide « ? »
   de Paramètres : étape sur l'interrupteur, et la roue crantée mentionne Auto / Personnalisé.
5. Auto = symétrique + auto-calibrage toujours actifs, sans interrupteur ; 1 ou 2 modificateurs
   par manche (inchangé).
6. « Une seule réponse » : plus une règle commune ; modificateur pour toute la partie. Auto :
   tirée au lancement, probabilité 1/4, annoncée avant le premier tour. Personnalisé : cochée dans
   l'ensemble. Le champ `oneAnswer` reste lu.
7. « Dessiner » jamais avec un mime (tirage Auto, 1 parmi 3, éditeur). Un test épingle
   l'invariant du tirage.
8. Personnalisé : jusqu'à 3 modificateurs par manche.

## Choix de l'implémenteur (à challenger)

- `pendingFiesta` (mémoire) porte le mode : nul = Classique, `FiestaRules(mode: auto)` = Auto,
  `mode: custom` sans ensemble = Personnalisé en attente ; l'ensemble choisi après Équipes le
  remplace et `onUse` lance `startGame`. Rien de neuf n'est persisté.
- Écran « Récap » supprimé aussi (plus de place dans le parcours) ; « Rejouer » (fin de partie et
  historique) revient aux Paramètres. Bouton « Utiliser » des ensembles renommé « Jouer » ;
  « Commencer » des équipes devient « Suivant » en Personnalisé.
- `oneAnswer` garde sa clé ; Auto : `startGame` gèle `drawsOneAnswer(gameId)` (graine
  `drawSeed(gameId, 0)`) ; `restartWithSamePlayers` normalise une config Auto en attente en
  `FiestaRules(mode: auto)` (un « symétrique coupé » d'avant la mise à jour ne se transmet pas).
  `startGame` garde en revanche `symmetric` / `autoCalibrate` reçus (les tests moteur s'en servent).
- « Dessiner » / mime : champ `mime` sur `ModifierDef` + règle de groupe dans `areCompatible`, à la
  place de trois paires. `kOneAnswer` (hors liste par manche) donne nom et description.
- Plafond : `maxModifiersPerTeam(rules)` = 2 en Auto, 3 en Personnalisé, appliqué aux fixés, au
  tirage (`drawCount` borné 0-3, curseur de l'éditeur aussi) et aux cartes de fin de manche.
- Badge « Une seule réponse » passe de la nature bonus à malus (`kOneAnswer.nature`).

## Questions précises

1. **Règle 7** : `FiestaRules` est persisté dans la partie suspendue (`GameState.fiesta`),
   l'historique (`GameResult.setup`), les ensembles (`guessItAll_fiestaEnsembles`) et envoyé à
   Firestore (`fiestaRules`). Le patch change-t-il une forme ? `oneAnswer` (clé absente = `true`,
   défaut du constructeur inchangé, nouveaux ensembles à `false`) garde-t-il un sens lisible pour
   un blob d'avant ? Une partie Personnalisé suspendue avant la mise à jour, relue après (plafond
   relevé à 3) : risque de crash ou d'incohérence entre transition et `nextRound` ?
2. **Routes supprimées** : un `currentScreen` / `suspendedScreen` persisté valant `gameMode`,
   `fiestaChoice`, `fiestaAuto` ou `fiestaRecap` tombe-t-il proprement sur l'accueil ? Reste-t-il
   un lien mort (grep des constantes, des écrans, de la doc) ?
3. **Invariants du tirage** : plafond par mode, « Dessiner » contre tout mime, déterminisme par
   graine (y compris `drawsOneAnswer` qui réutilise `drawSeed` avec la manche 0 : collision avec
   une graine existante ?), 1 parmi 3 et coup de pouce au bon plafond.
4. **Annonce de « Une seule réponse »** : annoncée avant le premier tour (game_screen,
   `isFirstTurnOfGame`) sur les deux plateformes ; suffisant sans toucher `transition_screen` ?
5. **Parcours** : double tap (tuto Fiesta, « Jouer » d'un ensemble), retour système Android sur
   Paramètres et sur « Mes ensembles », « Retour aux équipes » en pleine partie Personnalisé
   (repasse par les ensembles), « Rejouer » d'une partie Personnalisé.
6. **Tests** : ajoutés — tirage (plafond 3 atteint, « Dessiner » fixé + mimes tirés, `drawsOneAnswer`
   déterministe ~1/4), provider (`startGame` gèle le tirage en Auto, garde le choix en
   Personnalisé), coup de pouce Auto au plafond 2 ; adaptés — offres au plafond 3, 1 parmi 3 au
   plafond 3, Rejouer → Paramètres, « Jouer » → Paramètres. Fais du **mutation testing** sur ces
   tests (`maxModifiersPerTeam`, `drawsOneAnswer`, la règle `mime` d'`areCompatible`, l'appel
   dans `startGame`, la normalisation de `restartWithSamePlayers`). Un test redondant ou
   d'échafaudage = finding.

## Format attendu

Verdict (READY / NOT READY), puis findings BLOCKER / MAJOR / MINOR / NIT, chacun avec
`fichier:ligne`, preuve et correction proposée. Grille limitée au diff ; signale un mécanisme
sur-dimensionné si sa racine est un choix de spec.
