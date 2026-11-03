---
story: 2-9-mot-compte-double
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ② scoring, ① machine à états (charges, retour arrière)"
collisions: [game_provider.dart, game_state.dart, turn_resolution.dart]
depends: [2-8-effets-de-tour-catalogue]
model: Fable
---

# 2-9 : Mot compte double (charges, activation, score ×2, retour arrière)

## User story

En tant qu'équipe qui a une charge « Mot compte double », je veux l'activer juste avant mon tour
pour doubler les points de ce tour. Et si on revient en arrière avant que le tour ait eu lieu, je
veux récupérer ma charge.

## Périmètre

- **Charges** : quand `double_points` est actif pour une équipe dans une manche (tirage, fixé, ou
  plus tard 1 parmi 3), elle a **1 charge pour la manche** (Personnalisé : le nombre de charges de
  l'ensemble). Une charge non utilisée est **perdue en fin de manche** (maquette `two_cd`). Le
  compteur vit dans `fiesta`, par équipe.
- **Activation** sur l'écran d'avant-tour (`game_screen.dart`, maquette `cd`) : interrupteur
  « Activer Mot compte double — 1 charge pour cette manche. Les points du tour seront ×2. »
  On peut l'allumer et l'éteindre librement tant que le tour n'a pas commencé.
  - **Dépense** au démarrage du tour (`startTurnTimer`), pas au toucher de l'interrupteur.
  - Refusée, avec une explication, si l'équipe a déjà 2 modificateurs actifs ce tour (Q8).
- **Score** : `resolveTurn` (`turn_resolution.dart:74-121`) prend un paramètre
  `pointsMultiplier` (défaut 1). Il reste **pur**. `pointsScored = validatedWords.length ×
  multiplier`. `validateWords` (`game_provider.dart:827-861`) le passe.
- **Affichage** : badge « ×2 Mot compte double » pendant le tour ; sur la vérification, le calcul
  « Mots devinés 5 · Mot compte double ×2 · Points du tour 10 points » (maquette `verif`).
- **Récap** (carte de 2-7) : « Bonus utilisés : Mot compte double, Bleue en M2 ».

## Critères d'acceptation

1. **Étant donné** une partie Classique, ou Fiesta sans ×2 actif, **alors** `pointsScored` =
   nombre de mots validés, comme aujourd'hui. Les tests de `test/models/turn_resolution_test.dart`
   passent sans modification.
2. **Étant donné** ×2 activé et 5 mots validés, **alors** l'équipe gagne 10 points, dans
   `Team.score` **et** dans `scoreByRound` de la manche en cours.
3. **Étant donné** une charge activée puis désactivée avant le départ, **alors** la charge est
   toujours disponible.
4. **Étant donné** ×2 activé sur l'avant-tour, **quand** on fait un retour arrière vers la
   vérification du tour précédent (`canGoBackToVerification`), **alors** la charge est rendue et
   l'activation oubliée. C'est le cas « charge dépensée sur un tour annulé » de la décision.
5. **Étant donné** un tour joué à ×2, **quand** on revient de la transition ou du tour suivant
   vers sa vérification, puis qu'on revalide avec d'autres mots, **alors** le score est recalculé
   à ×2, sans double comptage : les scores sont restaurés depuis le snapshot,
   `game_provider.dart:1366-1379`.
6. **Étant donné** une charge non utilisée en fin de manche, **alors** elle disparaît au
   `nextRound`.
7. **Étant donné** l'app tuée entre l'activation et le départ du tour, **quand** on la rouvre,
   **alors** l'interrupteur est dans le même état et la charge n'est pas dépensée.
8. **Étant donné** la continuation de fin de manche, **alors** c'est un tour comme un autre pour
   l'activation : la charge de la **nouvelle** manche peut s'y utiliser.

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/models/turn_resolution.dart:41-42` (`pointsScored`), `:74-121` (`resolveTurn`, score
  `:119`).
- `lib/providers/game_provider.dart` : `validateWords` `:820-969` (appel `:827-833`, score
  `:852-861`) ; `startTurnTimer` `:522-542` (dépense) ; `savePreValidationState` `:1334-1352`
  (`teamScores` y est déjà) ; `restorePreValidationState` `:1355-1392` ; `nextRound` `:999-1025`
  (charges perdues).
- `lib/screens/game_screen.dart:226` (départ), `:240` (retour vers la vérification).
- `lib/screens/verification_screen.dart:224-225` (snapshot puis validation), et la zone du total.

## Pièges

- **Où vit l'activation.** Elle doit être dans `GameState.fiesta`, pas dans l'état d'un widget ni
  dans un champ du provider. C'est ce qui la fait survivre au kill (critère 7) **et** ce qui la
  fait effacer par la restauration du snapshot (critère 4).
- **Quand dépenser.** Si la charge se dépense au toucher de l'interrupteur, le critère 3 exige un
  remboursement à la main, et le critère 4 marche par accident. Dépenser au départ du tour rend
  les deux triviaux.
- `pointsScored` sert au score, mais `HistoryEntry.wordsGuessed` (`:883`, `:900`) reste la liste
  des **mots** : les stats (« mots devinés », `stats_aggregation.dart:40-46`) ne doublent pas. Le
  ×2 vaut pour les points, pas pour les mots.
- `HistoryTrends.averageScorePerGame` (`game_history_service.dart:150-186`) additionne des
  **scores** : il inclura les points doublés, et c'est correct.
- Ne pas glisser le multiplicateur dans `validateWords` : il appartient à `resolveTurn` (variante
  pure, décision).

## Tests (règle minimale)

- `test/models/turn_resolution_test.dart` (ajouts) : multiplicateur 2 sur 5 mots → 10 ; défaut 1
  inchangé ; multiplicateur avec un mot expiré validé.
- Provider : critère 4 (retour arrière → charge rendue) et critère 5 (pas de double comptage
  après restauration). C'est l'invariant que la décision nomme.

## Recette device (Florent, Android + iOS)

1. Activer ×2, jouer, vérifier le total « ×2 » à la vérification et le score sur la transition.
2. Activer ×2 puis faire un retour arrière vers la vérification précédente : revenir, la charge
   est disponible.
3. Activer ×2, tuer l'app avant de démarrer, rouvrir : l'interrupteur est toujours allumé, rien
   n'est dépensé.
