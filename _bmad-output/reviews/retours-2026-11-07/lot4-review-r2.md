# Revue lot 4 — round 2

Portée : relecture statique du correctif `c988e8a`, de son delta R1 → R2 et de ses seuls chemins d'exécution. Aucun test, build ou fichier de production n'a été modifié.

## BLOCKER

Aucun finding.

## MAJOR

Aucun finding.

### Fermeture vérifiée — validation explicite de Fiesta classique pendant la relecture

**Emplacements :** `lib/providers/game_provider.dart:73`, `lib/providers/game_provider.dart:77`, `lib/providers/game_provider.dart:117`, `lib/providers/game_provider.dart:138`, `lib/providers/game_provider.dart:142`, `test/screens/retours_parcours_test.dart:69`.

**Scénario concret :** `chooseFiestaMode()` pose l'objet singleton de Fiesta classique et lance la lecture du dernier ensemble. Pendant cet `await`, le joueur ouvre Avancés, sélectionne puis valide explicitement Fiesta classique : le même objet est donc reposé. `setPendingFiesta` incrémente alors `_pendingChoices`; la continuation a capturé la valeur précédente et ne peut plus remplacer ce choix par le dernier ensemble. Le garde `identical(_pendingFiesta, expected)` reste en place pour les écritures directes qui remplacent l'objet : le scénario `resetGame()` pendant l'attente est bien verrouillé par `test/screens/retours_parcours_test.dart:83`.

### Fermeture vérifiée — tutoriel après retour immédiat en Classique

**Emplacements :** `lib/screens/settings_screen.dart:81`, `lib/screens/settings_screen.dart:87`, `lib/screens/settings_screen.dart:92`, `test/screens/retours_parcours_test.dart:96`.

**Scénario concret :** le joueur touche Fiesta, puis Classique avant la fin de la relecture. Après les deux attentes, l'ouverture du tutoriel exige désormais que le widget soit monté et que `pendingFiesta` soit toujours non nul. Le tutoriel ne peut donc ni s'ouvrir ni écrire son marqueur lorsque l'état final est Classique. Le test couvre à la fois l'absence de `FiestaTutorialScreen` et l'absence de la clé persistée.

## MINOR

Aucun finding.

### Fermeture vérifiée — retrait du suffixe et du repli « Sans nom »

**Emplacements :** `lib/screens/settings_screen.dart:186`, `lib/screens/settings_screen.dart:669`, `lib/screens/settings_screen.dart:456`, `lib/app.dart:101`, `lib/app.dart:110`, `lib/screens/fiesta_ensembles_screen.dart:123`, `lib/screens/fiesta_ensembles_screen.dart:251`, `lib/screens/teams_screen.dart:107`.

**Scénario concret :** des règles en attente historiques sans `ensembleName` rendent la seconde ligne d'Avancés vide (`''`), mais la tuile complète conserve son geste, son libellé « Changer » et sa flèche. Son ouverture passe ces règles à la liste; l'absence de correspondance sélectionne un ensemble valide (dernier utilisé ou Fiesta classique). « Valider » appelle `setPendingFiesta` avec les règles nommées de cet ensemble, puis « Commencer » les transmet directement à `startGame`. Aucun de ces chemins ne requiert un nom non vide : le joueur peut donc changer d'ensemble et lancer la partie sans erreur. L'absence de nom visible est la conséquence intentionnelle de l'arbitrage, non une régression fonctionnelle.

## Verdict

**READY**
