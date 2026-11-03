# Revue r1 — story 2-4 « Choix du mode, écran Auto, récap, Rejouer » (tier standard)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-4-patch-r1.diff` (même
dossier), calculé sur la merge-base avec `feat/fiesta-2-2` (la lane est empilée sur 2-2) —
jamais `git diff` toi-même. Tu lis le code **avant** la spec, puis tu confrontes. Rapport dans
`2-4-review-r1.md` (même dossier).

## Objectif de la story

Spec : `_bmad-output/specs/fiesta/2-4-selection-mode-auto-recap.md` (AC 1 à 7). Epic :
`_bmad-output/specs/fiesta/epic-fiesta.md`, Q10 à Q12. Maquette : écrans `gamemode`, `fiesta`,
`auto`, `recap`.

Accueil « Nouvelle partie » / « Jouer » → **Mode de jeu** → Classique (Paramètres, inchangé) ou
Fiesta → Auto | Personnalisé (liste de 2-3) → **Récap** → Paramètres → Joueurs → Équipes →
`startGame(fiesta: pendingFiesta)`.

## Décisions déjà prises (ne pas rouvrir)

- Q10 : le choix vit en mémoire (`GameProvider.pendingFiesta`), jamais persisté. App tuée avant le
  lancement = choix vide.
- Q11 : le Récap mène aux Paramètres actuels, pas directement aux joueurs.
- Q12 : Rejouer relit la config gelée de la partie finie et passe par le Récap.
- Les types de 2-2 (`FiestaRules`, `startGame({fiesta})`, `GameState.fiesta`) ne sont pas
  modifiés.
- La liste des ensembles appartient à 2-3 (lane parallèle) : ici, un **bouchon**
  (`fiesta_ensembles_stub_screen.dart`, une ligne marquée dans `lib/app.dart`).

## Interprétations de l'implémenteur (à challenger)

1. `endGameAndGoHome` garde `_game.fiesta?.rules` en attente, pour que le « Rejouer » de
   l'**accueil** (après le bouton maison des résultats) repasse aussi par le Récap.
   `restartWithSamePlayers` relit la partie si `allWords` est non vide, sinon garde l'attente.
   Le test couvre résultats → Rejouer, accueil → Rejouer, et une partie Classique lancée alors
   qu'une config Fiesta traînait en attente. Il ne couvre **pas** la ligne de
   `endGameAndGoHome` seule (elle ne compte que si l'app a été tuée puis la partie reprise :
   `pendingFiesta` est alors vide, mais `_game.fiesta` est relu du disque).
2. Le retour des Paramètres va au Récap si une config Fiesta est en attente, sinon à l'accueil
   (comme aujourd'hui). En Classique, il ne revient **pas** au Mode de jeu.
3. Le « Modifier » du Récap en Personnalisé revient à la **liste** des ensembles, pas à
   l'éditeur : 2-3 ouvre l'éditeur par `Navigator.push` depuis la liste.
4. `FiestaRules` n'a pas de booléen « rattrapage actif » : le Récap Personnalisé affiche les
   valeurs du rattrapage, sans Oui/Non.
5. `PopScope` (retour système Android) sur les nouveaux écrans seulement ; les écrans existants
   quittent toujours l'app au geste retour, comme aujourd'hui.
6. Récap sans config en attente (cas qui ne devrait pas arriver) : retour au Mode de jeu après la
   frame.

## Questions précises

- Existe-t-il un chemin où `pendingFiesta` est obsolète au moment de `startGame` (une config
  Fiesta lancée alors que le joueur a choisi Classique, ou l'inverse) ? Pense à « Nouvelle
  partie » depuis une partie suspendue, aux retours arrière, au Rejouer de l'accueil.
- Le chemin « Reprendre » (`isGameSuspended`) traverse-t-il un écran de mode ? (AC6)
- Une partie Classique est-elle **exactement** celle d'aujourd'hui une fois les Paramètres
  atteints (AC1) ?
- Parité Android / iOS : rien de `Platform.*` ; le geste retour iOS n'existe pas sur la route
  racine, `PopScope` ne change rien sur iOS.
- Valeur du test : est-ce que chaque assertion mord (mutation testing sur les deux lignes de
  `restartWithSamePlayers`) ?

## Format attendu

Pour chaque finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, scénario
concret, correction proposée. Verdict final : READY ou NOT READY.
