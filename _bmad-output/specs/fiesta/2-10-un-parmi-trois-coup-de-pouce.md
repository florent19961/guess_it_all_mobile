---
story: 2-10-un-parmi-trois-coup-de-pouce
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ① machine à états (file de choix entre deux manches)"
collisions: [game_provider.dart, game_state.dart, transition_screen.dart]
depends: [2-6-temps-rattrapage-duree-reelle, 2-9-mot-compte-double]
model: Opus
---

# 2-10 : 1 parmi 3 (Personnalisé) et coup de pouce du catalogue (Auto)

## User story

En tant qu'équipe menée, je veux, entre deux manches, choisir une carte parmi trois : un bonus
pour moi, ou un malus pour l'équipe en tête. En mode Auto, je veux que l'app le fasse pour nous,
selon l'écart.

## Périmètre

Les deux mécanismes partagent tout (écart, force, cible, durée), sauf qui choisit : les joueurs
(Personnalisé) ou l'app (Auto).

- **Écart et classement** à la fin de la manche N, avec la même fonction que le rattrapage de 2-6
  (Q3 pour l'égalité : **ni 1 parmi 3 ni coup de pouce** cette manche-là).
- **Force** (Q7) : table constante par modificateur (légère / moyenne / forte). Seuils de la
  maquette : écart ≤ 3 → légère, ≤ 7 → moyenne, > 7 → forte. Table et seuils dans un seul fichier
  de constantes, commenté « à recalibrer ».
- **Cible et durée** (Q7) : un bonus va à l'équipe qui choisit, un malus va à l'équipe en tête.
  L'effet dure toute la manche N+1. Un bonus à charges (`double_points`, `two_words`) donne
  +charges pour la manche.
- **1 parmi 3 (Personnalisé, si `pick3` est allumé)** :
  - à la fin de M1 et de M2, chaque équipe **non en tête** choisit, en commençant par la
    **dernière** ;
  - 3 offres tirées parmi les modificateurs actifs réglés sur « proposé à l'équipe menée », dont la
    manche de départ est ≤ N+1, avec la force qui correspond à l'écart de **cette** équipe ;
  - exclure ce qui serait incompatible ou dépasserait 2 pour la cible (Q8), compte tenu du tirage
    de N+1, déjà connu (2-5). S'il reste moins de 3 offres, en montrer moins ; s'il n'en reste
    aucune, sauter l'équipe ;
  - graine déterministe `(gameId, round, teamId)`, comme 2-5 ;
  - UI (maquettes `r2` et `pick3`) : carte « Choix 1 parmi 3 » sur la transition, bouton « Passer
    le téléphone à l'Équipe X », écran de choix avec l'ordre (« Verte → Jaune → Bleue · Rose (en
    tête) ne choisit pas »), puis « Valider ce choix ». « Manche suivante » reste désactivé
    (« En attente du choix de X ») tant que la file n'est pas vide.
- **Coup de pouce (Auto, si « Auto-calibrage » est allumé)** : l'app choisit, selon la force, au
  plus un bonus pour chaque équipe menée et un malus pour l'équipe en tête. Mêmes exclusions.
  Carte « Coup de pouce de l'app » sur la transition (maquette `r2`). Personne ne choisit.
- Les malus reçus s'annoncent au début du tour de l'équipe visée, avec l'écran de révélation de
  2-5. `block_guesser` reçu par l'équipe en tête : c'est l'équipe qui l'a choisi qui désigne le
  devineur (flux de 2-8).

## Critères d'acceptation

1. **Étant donné** Personnalisé, 2 équipes, 14–8 après M1, **alors** seule l'équipe à 8 choisit,
   parmi 3 offres de force « moyenne » (écart 6), et « Manche suivante » attend son choix.
2. **Étant donné** 4 équipes, **alors** l'ordre de choix va de la dernière à l'avant-dernière ; le
   leader ne choisit pas. Chaque équipe a des offres dont la force suit **son** écart.
3. **Étant donné** une égalité (Q3), **alors** pas de 1 parmi 3 ni de coup de pouce. Le tirage
   symétrique s'affiche quand même.
4. **Étant donné** un malus choisi (`no_pass` contre la tête), **alors** l'équipe en tête l'a sur
   ses tours de la manche suivante, annoncé au début de son premier tour.
5. **Étant donné** l'app tuée au milieu de la file de choix, **quand** on la rouvre, **alors**
   les choix déjà faits sont gardés, la file reprend à l'équipe suivante, et ses offres sont les
   mêmes.
6. **Étant donné** un retour arrière depuis la transition, puis une revalidation, **alors** les
   offres sont identiques. Les choix sont à refaire : ils sont postérieurs au snapshot, et c'est
   accepté.
7. **Étant donné** Auto avec un écart de 6, **alors** le coup de pouce applique la ligne
   « moyenne » de la table, et la carte de la transition le dit.
8. **Étant donné** Personnalisé avec `pick3` coupé, ou Auto avec l'auto-calibrage coupé,
   **alors** rien de tout cela n'apparaît.

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/providers/game_provider.dart` : fin de manche dans `validateWords` `:912-933` (calcul
  des offres, à côté du tirage de 2-5) ; `nextRound` `:999-1025` (activer les choix, refuser tant
  que la file n'est pas vide) ; `getTeamsSortedByScore` `:1245-1262`.
- `lib/screens/transition_screen.dart:16-18` (manche et classement), `:155-172` (zone des
  cartes), `:225` (bouton « Manche suivante », à conditionner), `:235` (retour arrière).
- Modèle et constantes : `lib/models/fiesta/` (table de force, sélection des offres, fonction
  pure).

## Pièges

- **« Manche suivante » appelle directement `nextRound`** (`transition_screen.dart:225`). La
  garde doit être **dans le provider** (`nextRound` refuse tant que la file n'est pas vide), pas
  seulement un bouton grisé : un double tap ou une reprise d'app contourne un bouton.
- L'écran de choix ne passe pas par le même téléphone en même temps : un écran « Passer le
  téléphone » sépare les équipes, sans révéler les offres de la suivante.
- Après M3, on va aux résultats (`:917-925`) : jamais de file de choix.
- La table de force est « au doigt mouillé » : la garder **petite et lisible**, sans paramètres
  configurables (la configurabilité n'a pas été demandée).

## Tests (règle minimale)

- `test/models/fiesta/offers_test.dart` (pur) : ordre de la file (critère 2), égalité (3),
  exclusions (incompatibilité, plafond de 2 : dériver le prédicat), déterminisme (6).
- Provider : `nextRound` refuse tant que la file n'est pas vide (garde de machine à états), et
  critère 5 (reprise après kill).

## Recette device (Florent, Android + iOS)

1. Personnalisé, 2 équipes : creuser un écart, faire le choix, vérifier l'effet en M2.
2. 3 équipes : l'ordre de choix commence par la dernière ; passer le téléphone.
3. Tuer l'app au milieu de la file, rouvrir : reprise à la bonne équipe.
4. Auto : lire la carte « Coup de pouce de l'app » et constater l'effet en M2.
