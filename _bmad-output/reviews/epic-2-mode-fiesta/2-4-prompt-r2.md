# Revue r2 — story 2-4 « Choix du mode, écran Auto, récap, Rejouer » (tier standard)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-4-patch-r2.diff` (même
dossier), calculé sur la merge-base avec `feat/fiesta-2-2` (la lane est empilée sur 2-2) —
jamais `git diff` toi-même. Tu lis le code **avant** la spec, puis tu confrontes. Rapport dans
`2-4-review-r2.md` (même dossier).

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

## Ce qui a changé depuis r1

Lire `2-4-review-r1.md` puis `2-4-fix-r1.md` (même dossier) : une décision et une preuve par
finding. En bref :
- **M1** : `_loadFromStorage` remet `_game.fiesta?.rules` en attente. Invariant revendiqué : **en
  partie, `pendingFiesta` = `fiesta?.rules`**. Conséquence : la capture de `endGameAndGoHome` est
  retirée (redondante), l'attente n'y est simplement plus effacée.
- **M2** : tirage du Récap = `symmetric && drawCount > 0`.
- Mineurs : `FiestaHint`, `catchUpSummary`, plus de `?? 3` (« fixé » sans manche si nul), m4 en
  `notes_pour_plus_tard`, m6 en `tracking_evolution`.

## Interprétations toujours en place (r1, à challenger si tu vois mieux)

1. Le retour des Paramètres va au Récap si une config Fiesta est en attente, sinon à l'accueil.
2. « Modifier » du Récap en Personnalisé ouvre la liste des ensembles, pas l'éditeur.
3. `PopScope` sur les nouveaux écrans seulement.
4. Bouchon 2-3 et conflit de constante : traités par l'orchestrateur au merge, hors revue.

## Questions précises

- **L'invariant de M1 tient-il sur TOUS les chemins ?** Cherche un chemin où une partie est en
  cours (ou reprise) alors que `pendingFiesta` diffère de `fiesta?.rules` : écrans de mode
  atteignables en pleine partie, « Nouvelle partie » depuis une partie suspendue, relance sans
  état de jeu mais avec session.
- Rejoue les mutations de `2-4-fix-r1.md` et dis si une survit.

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
