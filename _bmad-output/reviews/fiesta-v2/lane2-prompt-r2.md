# Revue Fiesta v2 — lane 2 (écran avant le tour, cartouches ciblées) — round 2

**Tier : RISQUÉ.** Lecture seule. Lis `_bmad-output/reviews/fiesta-v2/lane2-delta-r1-r2.diff`
(ce qui a changé depuis r1) puis, pour le contexte, `lane2-patch-r2.diff` (toute la lane 2,
calculé sur `feat/fiesta-v2-modele`) ; jamais `git diff` toi-même. Code du worktree
`/home/florent19961/guess-it-all-fiesta-v2-tour` (branche `feat/fiesta-v2-tour`). Ton rapport
r1 : `lane2-review-r1.md` ; les corrections : `lane2-fix-r1.md`. Écris ton rapport dans
`_bmad-output/reviews/fiesta-v2/lane2-review-r2.md`.

## Ce qui est demandé

Vérifier que les trois findings r1 sont fermés, sans régression, et chercher les nouveaux trous
introduits par les corrections. Le reste du r1 (persistance, annulation, consommation unique,
récap, Classique) a été jugé cohérent : n'y reviens que si le delta le touche.

Arbitrages du lead (à respecter, pas à rediscuter) :
1. BLOCKER : une SEULE résolution des malus reçus, au tour de la cible (`modifiersForTurn`),
   contre les règles de manche actives à ce tour (`always`/`draw` de sa manche logique) et les
   malus déjà retenus ; en double ou incompatible → écarté sans effet, retiré à la fin du tour.
   L'UI d'envoi garde sa vérification actuelle, sans anticiper la manche suivante.
2. MAJOR : pas de défilement ; plancher 36 px (réserve seule jusqu'à 32 px en dernier
   recours) ; « Ce tour » sur 2 rangées si nécessaire ; écran allégé en Fiesta (carte d'équipe
   compacte, titres réduits, envois en puces annulables par un appui) ; rien ne passe jamais sous
   « Commencer le tour » (`ClipRect`). Un cas extrême qui déborde encore est signalé au lead, pas
   « réparé » par un scroll.
3. MINOR : test du coup de pouce Auto (Passe gratuite = une cartouche d'un tour).

## Questions précises

1. `modifiersForTurn` (`lib/models/fiesta/round_transition.dart`) : l'ordre de résolution (ordre
   de `active`, donc d'envoi) est-il stable après un kill et un retour arrière ? Une instance
   d'une continuation (manche logique N) ou d'un coup de pouce Auto (malus non `from`) est-elle
   jugée correctement ? Les bonus en cartouche de la cible sont volontairement hors jugement :
   un trou ?
2. `_fiestaAfterTurn` retire tous les malus infligés à l'équipe à la vraie fin de son tour : avec
   la nouvelle résolution, un malus écarté peut-il survivre ou être appliqué plus tard ?
3. `_fit` / colonnes (`lib/widgets/fiesta/turn_cartridges.dart`) : estimation de hauteur
   cohérente avec le rendu (constantes de texte estimées, pas mesurées) ; cas limites (réserve
   vide, une colonne vide, « Ce tour » vide, beaucoup d'envois). Carte compacte de
   `game_screen.dart` : aides (`_teamKey`, `_previousTurnKey`) et taps conservés ? Classique
   inchangé (grande carte, `Spacer`) ?
4. Le nouveau test Auto fixe le `gameId` en réécrivant l'état sauvegardé : légitime, ou fragile ?
5. Mutation testing sur les deux tests ajoutés (`fiesta_cartridges_test.dart`, tests 5 et 6).

## Format attendu

Par finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, affirmation vérifiable,
scénario de reproduction, correction suggérée (de préférence en simplifiant la racine). Conclure
par READY / NOT READY. Parité Android ↔ iOS à vérifier explicitement.
