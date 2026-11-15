# Revue r1 — L-CACHE (`feat/retours-cache`) — tier RISQUÉ

Tu es reviewer, en LECTURE SEULE. Lis le patch `retours-cache-patch-r1.diff` (même dossier), puis le code
qu'il touche dans le worktree `/home/florent19961/guess-it-all-retours-cache`. Ne lance pas `git diff` toi-même.
La branche est empilée sur `feat/retours-personne` (L-PERSONNE) : le patch est calculé par rapport à elle.

## Objectif

Spec `_bmad-output/specs/fiesta/retours-2026-11-15.md` §D2 (lis aussi l'en-tête : règle 7, la 1.4.0 est en store).
L'avant-tour ne montre plus les malus reçus par le joueur qui va jouer ; après « Commencer le tour », l'écran
« Ce qui t'attend » les révèle (seulement s'il y en a), puis le décompte. Passe gratuite + Interdit de passer :
une passe gratuite, puis Passer bloqué, partout (moteur, éditeur, vivier du hasard).

## Décisions de la spec (ne pas re-trancher)

- Aucune fuite d'un malus reçu avant « Commencer le tour » : aperçu de durée (le −10 s), ligne « X ne répond pas »,
  grisés, aide, pastilles. Le chrono réel compte le −10 s.
- « Ce qui t'attend » : « On vient de t'infliger » (icône, nom, « Prénom · Équipe ») ; « Déjà activé » (règles de la
  manche, bonus) ; « C'est parti ». Rien en double, aucune autre phrase. Pas d'écran s'il n'y a rien de reçu.
- « Interdit de faire deviner » : cycle inchangé, le joueur piégé ne voit jamais « Ce qui t'attend ».
- Écran persisté : une app tuée y revient (nouvelle valeur d'écran, ajout additif).

## Mécanisme choisi

- Une seule racine : `GameProvider.currentTeamModifiers` retire les malus reçus (`fromTeamId != null`) quand
  `_receivedHidden` (écran `screenGame` et pas une continuation). Tous les lecteurs de l'avant-tour passent par lui.
  `_modifiersThisTurn` = l'ancien calcul, non filtré.
- `startTurn` → `screenTurnReveal` si `_hasTurnReveal` (pas de piège en attente, pas une continuation, un malus reçu
  joue), sinon `screenCountdown`. `leaveTurnReveal` (gardé par l'écran) → décompte.
- `passBlocked` = `no_pass && !hasFreePass` ; `canPassWith` et la bulle de `turn_screen` en découlent.
- `kModifierIncompatibilities` (dont la seule paire était `no_pass`/`free_pass`) retirée ; clause `no_pass` de
  `FiestaRules.lockReason` retirée.

## Arbitrages de l'implémenteur (à challenger)

1. Continuation de fin de manche : malus reçus visibles dans son avant-tour, pas d'écran de révélation. Un malus
   devenu jouable en N+1 (mime reçu en M2, perdu en M2 et jouable en M3) apparaît dans cet avant-tour sans écran.
2. Ligne « Bloquer un devineur » : « Bob ne répond pas » plutôt que le nom du malus.
3. Règles de manche en cercle blanc (comme la zone « Actif »), la maquette dit jaune.
4. Clause retirée dans `fiesta_rules.dart`, fichier aussi touché par L-TOMBE (conflit possible au merge).

## Points précis à vérifier

1. Fuites : tout lecteur de l'avant-tour qui contournerait `currentTeamModifiers` (`fiesta.active` lu directement,
   `_clashOn`, `targetRefusal`, `_malusBlock`, `reserve`, `_conflict`, `fitsIn`/`_fit` de `turn_cartridges.dart`,
   aide `fiestaPreTurnHelp`, `game_screen.dart`). Le `timeRemaining` écrit par `startTurn` (aperçu sans −10 s)
   est-il lu quelque part avant que `startTurnTimer` le réécrive ?
2. Le gate dépend de l'écran : `startTurnTimer` lit `turnTime` sur `screenCountdown` (−10 s compté) ; analytics
   (`_eventContext`, `_trackWordShown`) lisent après le passage à `screenTurn`. Un chemin où l'écran est
   `screenGame` alors que le tour tourne (suspension / reprise, `resumeGame`, retour arrière
   `restorePreValidationState`, `confirmGiverBlock`) ?
3. Piège : `startTurn` du joueur bloqué → décompte → piège → `confirmGiverBlock` → remplaçant. Ses autres malus
   restent en attente et cachés ; le remplaçant n'a l'écran que pour SES malus.
4. Persistance (règle 7) : `turnReveal` relu après kill ; aucune autre forme persistée changée. Une partie 1.4.0
   suspendue sous `no_pass` en Toujours avec `free_pass` en cartouche : `chargesOf` change (cartouches rendues
   jouables) ; tirages du hasard / défis recalculés différents. Acceptable ? Rien de persisté re-dérivé ?
5. Pas de retour depuis « Ce qui t'attend » (`PopScope(canPop: false)`, pas de `HomeButton`), Android et iOS.
6. `turn_screen.dart` : sous `no_pass` + passe gratuite, bouton « Passer (gratuit) », puis grisé avec la bulle
   « Interdit de passer ce tour ».
7. Docs : `lib/models/CLAUDE.md`, `lib/providers/CLAUDE.md`, `lib/screens/CLAUDE.md`, `help/WIRING.md`, aide,
   `docs/tracking_evolution.md`. Une skill maison décrit-elle un comportement que ce diff change ?
8. **Mutation testing obligatoire** sur les tests ajoutés : `test/providers/fiesta_turn_reveal_test.dart` (3) et
   « Passe gratuite + Interdit de passer » de `test/providers/fiesta_turn_effects_test.dart`, et les assertions
   réécrites (`turn_time_fiesta_test.dart` aperçu 30 puis 20, `preturn_help_test.dart`,
   `help_conditional_test.dart`). Mutants suggérés : gate retiré, gate sans `!isContinuation`, garde
   `_pendingGiverBlock` retirée de `_hasTurnReveal`, `passBlocked` sans `!hasFreePass`, paire remise. Valeur des
   tests : redondant, échafaudage ou obsolète = finding (beaucoup de tests existants ont reçu un `p.startTurn()`
   avant leurs assertions de malus reçus).

## Format attendu du rapport

- Verdict : **READY** ou **NOT READY**.
- Findings classés **BLOCKER / MAJOR / MINOR**, chacun avec `fichier:ligne`, le problème, le scénario qui le
  déclenche, et la correction proposée.
- Résultat du mutation testing (mutant, test censé le tuer, tué ou survivant).
