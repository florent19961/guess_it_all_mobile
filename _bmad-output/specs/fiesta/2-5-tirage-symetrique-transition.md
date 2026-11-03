---
story: 2-5-tirage-symetrique-transition
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ① machine à états"
collisions: [game_provider.dart, game_state.dart]
depends: [2-2-fondation-modele-fiesta]
model: Opus
---

# 2-5 : Tirage symétrique, transition de manche et annonces avant le tour

## User story

En tant que joueurs d'une partie Fiesta, nous voulons découvrir au début de chaque manche les
modificateurs qui s'appliquent à tout le monde, et les voir rappelés avant et pendant chaque tour.
Ainsi, personne ne découvre une règle en plein mime.

## Périmètre

- **Tirage pur** `drawSymmetric({rules, round, teams, alreadyFixed, random}) → List<ModifierInstance>`
  dans `lib/models/fiesta/` :
  - Auto (si « Symétrique » est allumé) : 1 ou 2 au hasard (Q9), dans tout le catalogue ;
  - Personnalisé : `rules.symmetricCount` (0 à 2) parmi les modificateurs actifs réglés sur
    « tiré pour tous » dont la manche de départ est ≤ `round` ;
  - les modificateurs « manche 3 seulement » ne sortent qu'en M3 ;
  - le résultat est compatible avec lui-même et avec les modificateurs **fixés** sur cette
    manche, et respecte le plafond de 2 (Q8) ;
  - s'il n'y a pas assez de candidats, on en tire moins, sans erreur.
- **Fixé sur la manche N** (Personnalisé) : appliqué à toutes les équipes pendant la manche N
  (Q16), en plus du tirage.
- **Moment du tirage** :
  - M1 : dans `startGame`, quand `fiesta` est présent ;
  - M2 et M3 : dans la branche « fin de manche » de `validateWords` (`game_provider.dart:913-931`),
    **pas** dans `nextRound`. La transition (`transition_screen.dart`) doit pouvoir l'afficher
    **avant** que l'on touche « Manche suivante » (`:225`). Le tirage est rangé comme « manche
    suivante » dans `fiesta`, puis devient actif dans `nextRound` (`:999-1025`). Les instances de
    portée manche de la manche finie sont retirées à ce moment-là.
- **Graine déterministe** : `Random(hash(gameId, round))`. Voir le piège « retour arrière ».
- **Affichage** (textes FR de la maquette) :
  - avant la manche 1 (maquette `r1`) : carte « Tirage de la manche 1 » + annonce « Une seule
    réponse » si elle est active, sur `game_screen.dart` quand `isFirstTurnOfGame`
    (`game_provider.dart:1318`) ;
  - transition (maquette `r2`, partie basse) : carte « Tirage de la manche N », « Pas de relance :
    le tirage est définitif » ;
  - avant chaque tour (`game_screen.dart`, maquette `cd`) : carte « Actif ce tour » avec les
    badges de l'équipe qui joue ;
  - pendant le tour (`turn_screen.dart`, maquette `turn`) : badges sous le chrono ;
  - un écran plein de **révélation d'un malus** (maquette `malus`) réutilisable par 2-8 et 2-10,
    affiché au début du tour de l'équipe visée, avant le compte à rebours.
- Un widget `ModifierBadge` + une carte `ModifierCard` dans `lib/widgets/` (nouveaux fichiers).

Hors périmètre : les **effets** (temps → 2-6, passes et annonces → 2-8, ×2 → 2-9, deux mots →
2-11). Ici, un modificateur tiré est affiché et stocké, rien de plus.

## Critères d'acceptation

1. **Étant donné** une partie Classique, **alors** aucun tirage, aucune carte, aucun badge, et
   `validateWords` / `nextRound` produisent exactement l'état d'aujourd'hui.
2. **Étant donné** Auto avec « Symétrique » allumé, **quand** une manche commence, **alors** 1 ou
   2 modificateurs compatibles sont tirés, affichés, et identiques pour toutes les équipes.
3. **Étant donné** Personnalisé avec un tirage à 0, **alors** aucun tirage ; avec 2, au plus 2,
   pris seulement parmi les modificateurs « tiré pour tous » éligibles à cette manche.
4. **Étant donné** M1 ou M2, **alors** `draw`, `mime_no_arms`, `mime_no_fists` et `mime_eyes_closed` ne sortent
   jamais.
5. **Étant donné** la fin de M1, **quand** on arrive sur la transition, **alors** le tirage de M2
   est déjà visible. **Quand** on touche « Manche suivante », **alors** ces modificateurs
   deviennent actifs et ceux de M1 (portée manche) disparaissent.
6. **Étant donné** un retour arrière depuis la transition (`canGoBackToVerification`,
   `transition_screen.dart:235`) puis une nouvelle validation, **alors** le tirage affiché est
   **le même** : pas de relance cachée.
7. **Étant donné** l'app tuée sur la transition, **quand** on la rouvre, **alors** le même tirage
   s'affiche.
8. **Étant donné** la fin de M3, **alors** aucun tirage (aller aux résultats, `:917-933`).

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/providers/game_provider.dart` : `startGame` `:385-431`, fin de manche dans
  `validateWords` `:912-933`, `nextRound` `:999-1025`, `isFirstTurnOfGame` `:1318`,
  snapshot `:1334-1392`.
- `lib/screens/transition_screen.dart` : en-tête de manche `:16`, bloc de temps reporté
  `:155-172` (insérer la carte de tirage à côté), bouton `:225`, retour arrière `:235`.
- `lib/screens/game_screen.dart` : mode de manche `:38-46`, bloc de temps bonus `:193-208`,
  bouton de départ `:226`.
- `lib/screens/turn_screen.dart` : variables `:250-258`, mot affiché `:330`.
- `lib/utils/constants.dart:93-97` (`roundModes`) : pour les libellés de manche.

## Pièges

- **Retour arrière = relance cachée.** Le snapshot est pris **avant** la validation
  (`verification_screen.dart:224-225`). Restaurer puis revalider rejoue la branche « fin de
  manche », donc un tirage neuf, ce que la décision interdit. La graine `(gameId, round)`
  garantit le même résultat. Un « ne tirer que si absent » échouerait, puisque le snapshot ne
  contient pas encore le tirage.
- `validateWords` va directement aux résultats après M3 (`:918`, `:923-925`) : ne pas tirer.
- La continuation de fin de manche (`pendingBonusTurnId`, `:928`) ne change pas d'équipe. Le
  tirage de la nouvelle manche s'applique **aussi** à ce tour (Q5 : seuls les modificateurs de
  temps en sont exclus, voir 2-6).
- `turn_screen.dart` reconstruit sur chaque seconde (`refreshDisplayedTime`, `:808-818`) : les
  badges se calculent à partir de `GameState`, sans aléatoire dans `build`.

## Tests (règle minimale)

- `test/models/fiesta/symmetric_draw_test.dart` : critères 3 et 4, compatibilité et plafond de 2
  (dériver le prédicat : « aucune paire de l'ensemble tiré n'est incompatible », pas une liste
  de cas), et **déterminisme** à graine égale (critère 6).
- Un test provider : critère 5 (le tirage existe dès la transition, il devient actif au
  `nextRound`) et critère 1 (une partie Classique ne porte aucun `fiesta`).

## Recette device (Florent, Android + iOS)

1. Partie Fiesta Auto, 2 équipes : lire le tirage avant M1, puis sur chaque transition. Les badges
   apparaissent avant et pendant chaque tour.
2. Sur la transition M1→M2 : retour arrière vers la vérification, revalider, le tirage n'a pas
   changé.
3. Tuer l'app sur la transition, rouvrir : même tirage.
4. Vérifier que les badges ne masquent pas le mot sur un petit écran (iPhone SE, petit Android).
