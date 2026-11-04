# Revue r1 — lane ensembles-perso (tier risqué)

Patch : `_bmad-output/reviews/ensembles-perso/ensembles-perso-patch-r1.diff` (merge-base
`origin/main`, revues exclues, renommage détecté). Lis le patch, pas `git diff`. Lecture seule ;
écris ton rapport dans `_bmad-output/reviews/ensembles-perso/ensembles-perso-review-r1.md`.

## Objectif

1. **Bug Florent (Chrome)** : « impossible d'enregistrer un ensemble, c'est un cul-de-sac ;
   dans Créer un ensemble je ne peux pas faire Suivant, seulement revenir, et on ne voit pas
   l'ensemble sauvegardé (aucun ensemble au départ) ».
   Cause racine retenue : pas le stockage (créer + relire marche, test). L'éditeur était une
   page poussée (`Navigator.push`) sans « Suivant » ; « Enregistrer » grisé tant que le nom est
   vide ; la seule issue visible, le retour, faisait `pop(false)` et jetait la saisie ; après
   enregistrement on retombait sur une liste où il fallait trouver « Jouer ». Vérifie cette
   analyse sur le code de `origin/main` (`fiesta_ensembles_screen.dart`,
   `fiesta_ensemble_editor_screen.dart`) : y a-t-il une autre cause plausible (stockage web,
   bouton hors écran) que le correctif ne couvre pas ?
2. **Nouveau parcours Personnalisé** : Paramètres → écran « Fiesta personnalisée » → Joueurs →
   Équipes (« Commencer » lance `startGame(fiesta: pendingFiesta)`). Écran unique : ensembles
   prêts à jouer (aucun enregistré → « Fiesta classique » = `defaultEnsembleRules`, jamais
   stocké), tap = sélection visible, éditeur en ligne dessous (enregistré → en haut,
   sélectionné), Modifier (charge dans l'éditeur) / Dupliquer / Supprimer, « Suivant » grisé sans
   sélection → `setPendingFiesta(rules)` + Joueurs.

## Questions précises

- **Règle 7** : la forme de `guessItAll_fiestaEnsembles` change-t-elle ? (attendu : non ;
  `markUsed` toujours appelé au « Suivant » d'un ensemble enregistré, jamais pour l'intégré).
- **Machine à états** : tous les chemins vers `startGame` en Personnalisé ont-ils un
  `pendingFiesta` portant un ensemble (`ensembleName` non nul) ? Chemins : Paramètres « Suivant »
  et « Continuer » (avertissement mots), retour Joueurs → ensembles, Rejouer (fin de partie,
  accueil, historique), bascule Auto/Personnalisé dans Avancés après un aller-retour, reprise
  après kill. Un `FiestaRules(mode: custom)` nu peut-il atteindre `startGame` ?
- **Rejouer** : présélection par égalité JSON des règles avec `pendingFiesta`, sinon
  `lastUsedId`. Cas d'un ensemble modifié/supprimé depuis, d'une archive d'historique.
- **Retour Android** (`PopScope`) → Paramètres ; retour bouton idem ; retour Joueurs → ensembles.
- Sélection après Supprimer / Dupliquer / Modifier (ensemble sélectionné ou en cours d'édition).
- Code mort : ancienne page éditeur, `onUse`, libellé « Suivant » des équipes, aide obsolète —
  reste-t-il des références (docs, CLAUDE.md, WIRING.md, aides) au parcours « après les équipes » ?
- **Mutation testing** sur `test/screens/fiesta_ensembles_flow_test.dart` (écrit avant le
  correctif, rouge sur `origin/main`) : ex. ne plus sélectionner l'ensemble enregistré, renvoyer
  vers Équipes au lieu de Joueurs, ne pas écrire le stockage. Le test exerce-t-il ce qu'il nomme ?
- Deux plateformes (Android, iOS) + Chrome web : rien de `Platform.*` ?
- Grille qualité limitée au diff : sur-dimensionnement, état dupliqué (`_selectedId` vs
  `pendingFiesta`), double tap « Suivant ».

## Format attendu

Findings BLOCKER / MAJOR / MINOR / NIT, chacun avec `fichier:ligne`, scénario concret et
correctif suggéré ; puis verdict READY / NOT READY.
