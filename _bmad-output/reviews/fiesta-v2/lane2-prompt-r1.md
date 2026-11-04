# Revue Fiesta v2 — lane 2 (écran avant le tour, cartouches ciblées) — round 1

**Tier : RISQUÉ** (machine à états de la partie, persistance `SharedPreferences`, timer du tour).
Lecture seule. Lis le patch `_bmad-output/reviews/fiesta-v2/lane2-patch-r1.diff`, calculé sur
`feat/fiesta-v2-modele` (la lane 1, pas encore mergée : seule la part lane 2 y figure), jamais
`git diff` toi-même ; lis le code du worktree `/home/florent19961/guess-it-all-fiesta-v2-tour`
(branche `feat/fiesta-v2-tour`) pour le contexte. Écris ton rapport dans
`_bmad-output/reviews/fiesta-v2/lane2-review-r1.md`.

## Objectif

Spec Fiesta v2 §3 (décisions Florent 2026-11-04,
`/tmp/claude-1000/-home-florent19961-guess-it-all-audit/d1dcd342-b34e-4aab-9ecb-60b413049ad8/scratchpad/spec-cartouches.md`),
maquette `cartouches.html` section B, variante (a) :

- Avant-tour sans défilement : « CE TOUR » sur une rangée (règles de manche en cercle neutre,
  malus reçus rouge plein avec « Reçu de l'équipe X » à l'appui long, bonus allumés vert plein ✓ ;
  vide → « Rien ce tour ») ; « RÉSERVE » en deux colonnes Bonus / Malus, cercles ~50 px, pastille
  du nombre restant, grisé si épuisé ou incompatible avec une règle de manche. Toucher =
  activer / infliger, appui long ~500 ms = explication. Une ligne d'aide. Plus de carte « Temps du
  tour » ni de textes d'explication.
- Bonus : touché → monte dans « Ce tour » (~250 ms), retouché → redescend ; consommé au début du
  tour.
- Malus ciblés : 2 équipes → directement à l'autre ; 3+ → « Contre quelle équipe ? ». S'applique
  au PROCHAIN tour de la cible, quel que soit le joueur. Ligne « Envoyé : [icône] → X » annulable
  tant que le tour de l'envoyeuse n'a pas commencé. Collision (message exact) : « Impossible :
  <Malus> est déjà infligé à l'équipe <X> par l'équipe <Y> pour son prochain tour. Choisis un
  autre malus ou attends. », cartouche NON consommée ; deux malus différents compatibles se
  cumulent.
- Branchement lane 1 : malus `stock` (`reserve`) infligeables ; cartes malus du 1 parmi 3 =
  cartouches de celle qui choisit (plus « vise le leader toute la manche ») ; bonus stock/offer
  par la réserve ; Passe gratuite « pour la partie » décomptée et réactivée dans l'éditeur.
- Persistance : envois en attente et cartouches consommées survivent à un kill (règle 7, ajouts
  additifs, relecture tolérante). Classique intouché.

## Décisions prises par l'implémenteur (à challenger)

1. **Un malus infligé = une `ModifierInstance`** de portée tour avec `fromTeamId` (clé `from`),
   `teamId` = cible, dans `fiesta.active`, + un `ChargeUse` avec `targetTeamId` (clé `target`)
   posé TOUT DE SUITE (le décompte « par manche » et « pour la partie » existant marche tel quel).
   Annuler retire les deux. Pas de nouvelle liste dans `FiestaState`.
2. `modifiersForTurn` : un malus infligé pèse sur la cible quelle que soit la manche d'envoi, s'il
   est permis dans la manche LOGIQUE du tour (`isEligibleForRound`) ; `plan.apply` le garde ;
   `_fiestaAfterTurn` le retire à la vraie fin du tour de la cible (même s'il n'a pas pu
   s'appliquer, cas « Autre langue » M2 → M3), et ne le retire pas avec les instances de N à la fin
   d'une continuation. Une continuation (même tour que la fin de N) n'offre ni réserve ni
   annulation.
3. « Annulable tant que mon tour n'a pas commencé » = `sentThisTurn` : envois de l'équipe qui joue,
   seulement dans l'avant-tour d'un vrai tour (`screenGame` et pas continuation). Argument : entre
   deux tours de l'envoyeuse, la cible joue toujours (rotation fixe), donc tout envoi visible à
   l'avant-tour vient de cet avant-tour. À vérifier, y compris fins de manche et retour arrière.
4. **Tous les bonus en cartouche** : `free_pass` rejoint `kChargeBonusKeys` (clé JSON `freePass`) ;
   une cartouche = un tour de `defaultCharges` (2) passes gratuites (`freePasses` = règle de manche
   + 2 si dépensée). Conséquence Auto : une Passe gratuite du coup de pouce = un tour (avant : toute
   la manche). Le malus du coup de pouce (Auto) frappe toujours le leader toute la manche N+1.
5. Offres Personnalisé : malus en `reserve` chez celle qui choisit (`charges` 1), plus de
   dépendance au leader unique ; « Bloquer un devineur » offert seulement si une autre équipe a 3
   joueurs (`canBlock`). `isUsefulOffer` : une réserve ne pèse sur personne ; un malus en réserve
   n'est jugé que contre les règles de manche (la graine figée de la rangée 0 est inchangée).
6. Incompatibilités : bonus grisé si même id déjà en jeu ou incompatible avec une règle de manche,
   un malus reçu ou un autre bonus allumé (`_conflict`) ; malus grisé si même id que, ou
   incompatible avec, une règle de manche, ou sans cible possible. « Un seul mime » (Explosif,
   L'injustice) = refus à l'envoi si la cible a déjà un mime en attente (message dédié, sans
   consommer). Ensembles fournis inchangés.
7. `blockingTeam` = `fromTeamId` du blocage (la boucle sur `offerChoices` est retirée).
8. Récap : « Bonus utilisés » → « Cartouches utilisées » (un malus : « X contre Y »).
9. UI (`lib/widgets/fiesta/turn_cartridges.dart`) : taille des cercles 50 → 32 px calculée
   (`_fit`) pour tenir ; défilement seulement en garde-fou (vu en local : Explosif M1, 3 équipes,
   2 envois, 360 × 740). Snack et animation par `Overlay` (pas de `Scaffold` sur l'écran). Le temps
   reporté d'une continuation s'affiche maintenant aussi en Fiesta (puce Classique). Orphelins
   retirés : `RoundDrawCard`, `TurnTimeCard`, `MimeConstraintBanner`.

## Questions précises

1. Tous les chemins de mutation (`inflictMalus`, `cancelSent`, `toggleBonus`, `startTurnTimer`,
   `validateWords` / `_fiestaAfterTurn` / `_fiestaAtRoundEnd`, `nextRound` / `plan.apply`, retour
   arrière `restorePreValidationState`, app tuée) : un malus peut-il s'appliquer deux fois, jamais,
   ou à l'envoyeuse ? Une cartouche peut-elle être dépensée deux fois ou rendue deux fois ?
2. La décision 3 tient-elle (fin de manche pendant le tour de l'envoyeuse, continuation en chaîne,
   2 équipes, retour arrière depuis l'avant-tour de la cible) ?
3. `_chargesLeft` / `_heldCartridges` / `reserve` : décompte juste pour un bonus allumé, un malus
   annulé, « pour la partie » (`stockForRound` compte désormais les `ChargeUse` de Passe gratuite et
   des malus) ?
4. Persistance : `from`, `target`, `freePass` relus tolérants ; un blob lane 1 (sans ces clés)
   reste lisible ; Classique inchangé.
5. Parité Android ↔ iOS de l'écran (appui long, `showModalBottomSheet`, `Overlay`, safe areas).
6. Tests : valeur et mutation testing (voir ci-dessous). Un test qui nomme une garantie
   l'exerce-t-il ?
7. Sur-dimensionnement : un mécanisme du diff dont la racine est un choix de spec plus simple ?

## Tests

Ajouté : `test/providers/fiesta_cartridges_test.dart` (4 tests : 3 équipes, prochain tour de la
cible, collision au message exact sans consommation, cumul, kill ; annulation, Passe gratuite
dépensée une fois au départ ; un seul mime en M3 ; malus interdit dans la manche de la cible).
Mutants tués en local : collision sautée, retrait du malus infligé en fin de tour, `ChargeUse` non
rendu à l'annulation. Réécrits (vecteur lane 1 « malus du 1 parmi 3 contre le leader » disparu) :
`test/providers/fiesta_pick_three_test.dart` (AC4 → infligé par la menée ; blocage ; M2 → M3
continuation avec blocage infligé ; continuation en chaîne avec blocage infligé en M1 ; double
tap), `offers_test.dart`, `symmetric_draw_test.dart` (Passe gratuite « pour la partie »),
`fiesta_turn_effects_test.dart`, `fiesta_double_points_test.dart` (titre du récap). Aucun
retiré. Pas de widget test (UI simple, consigne). Suite complète verte (238 tests).

## Format attendu

Par finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, affirmation vérifiable,
scénario de reproduction, correction suggérée (de préférence en simplifiant la racine). Conclure
par READY / NOT READY. Parité Android ↔ iOS à vérifier explicitement.
