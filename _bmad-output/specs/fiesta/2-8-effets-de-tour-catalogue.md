---
story: 2-8-effets-de-tour-catalogue
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ⑥ timer (pénalité de passe), ② scoring indirect"
collisions: [game_provider.dart, game_state.dart, turn_screen.dart]
depends: [2-5-tirage-symetrique-transition, 2-7-analytics-archive-recap]
model: Opus
---

# 2-8 : Effets de tour (interdit de passer, passe gratuite, bloquer un devineur, contraintes annoncées, mot à l'envers)

## User story

En tant que joueurs, nous voulons que les modificateurs tirés changent vraiment le tour : le
bouton Passer bloqué ou gratuit, un devineur réduit au silence, un mime sans les bras, un mot
affiché à l'envers. Sinon, Fiesta n'est qu'une liste de badges.

## Périmètre

Six entrées du catalogue. Elles arrivent par le tirage (2-5), et plus tard par 1 parmi 3 ou par le
coup de pouce Auto (2-10) : l'effet ne dépend pas de la façon dont le modificateur est arrivé.

| Id | Effet | Où |
|---|---|---|
| `no_pass` | `passWord` refuse ; le bouton Passer est désactivé et affiche « Passer (bloqué) » | `game_provider.dart:644-700`, `turn_screen.dart:258`, `:382-430` |
| `free_pass` ×N | les N premières passes du tour coûtent 0 s ; compteur « Passes gratuites : k / N » ; ensuite, la pénalité normale | idem + compteur dans l'état de tour de `fiesta` |
| `block_guesser` | au début du tour de l'équipe visée, les adversaires choisissent un **devineur** (tous les joueurs de l'équipe sauf celui qui fait deviner). Écran d'annonce « X ne répond pas » (maquette `block`). Simple annonce, la rotation ne change pas | `game_screen.dart` + écran d'annonce de 2-5 |
| `mime_no_arms`, `mime_eyes_closed`, `draw` | annonce seule : texte de la maquette, badge, révélation | 2-5 les affiche déjà ; ici les textes et l'annonce plein écran |
| `reversed` | pendant le tour, le mot s'affiche en MAJUSCULES et à l'envers, chaîne entière (« TITANIC » → « CINATIT », « STAR WARS » → « SRAW RATS ») ; vérification et résultats en clair | `turn_screen.dart:330` uniquement |

Plus le texte de « Une seule réponse » sous « Interdit de passer » (Q6) : « Mauvaise réponse : le
mot est grillé jusqu'à la fin du tour. »

## Critères d'acceptation

1. **Étant donné** `no_pass` actif pour l'équipe qui joue, **quand** on touche Passer, **alors**
   rien ne change (ni temps, ni mot, ni événement `passed`). Le bouton est visiblement désactivé.
2. **Étant donné** `free_pass` ×2 et une pénalité de 5 s, **quand** on passe 3 fois, **alors** le
   chrono perd 0, 0, puis 5 s. Le compteur affiche 1/2, 2/2, puis la pénalité normale.
3. **Étant donné** `free_pass` avec 2 s affichées et une pénalité de 5 s, **alors** la passe
   gratuite est autorisée : la garde de `:657` porte sur la pénalité **effective**.
4. **Étant donné** l'app tuée après 1 passe gratuite, **quand** on la rouvre, **alors** le
   compteur vaut toujours 1/2. **Étant donné** un nouveau tour, **alors** il repart à 0.
5. **Étant donné** `block_guesser` sur une équipe de 3 joueurs ou plus, **quand** son tour
   commence, **alors** les adversaires choisissent un devineur parmi ses coéquipiers (jamais celui
   qui fait deviner), et l'annonce s'affiche. **Étant donné** une équipe de 2 joueurs, **alors**
   rien ne se passe pour elle.
6. **Étant donné** `reversed` et le mot « Tour Eiffel », **alors** le tour affiche « LEFFIE
   RUOT ». La vérification affiche « Tour Eiffel ».
7. **Étant donné** une partie Classique, **alors** `passWord` et l'écran de tour se comportent
   exactement comme aujourd'hui.
8. **Étant donné** un retour arrière vers la vérification, **alors** le compteur de passes
   gratuites et le devineur bloqué reviennent à leur valeur du snapshot (ils vivent dans
   `GameState`).

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/providers/game_provider.dart` : `passWord` `:644-700` (garde `:657`, pénalité `:665`,
  événement `:660`) ; `startTurnTimer` `:522-542` (remise à zéro du compteur) ;
  `getCurrentPlayer` `:1229-1238` (celui qui fait deviner, à exclure du choix).
- `lib/models/turn_clock.dart:98-113` (`applyPenalty`) : appeler avec la pénalité effective (0
  pour une passe gratuite), sans modifier la classe.
- `lib/screens/turn_screen.dart` : `passPenalty` `:256`, `canPass` `:258`, bouton Passer
  `:382-430` (libellé de pénalité `:418-420`), mot `:330`.
- `lib/screens/game_screen.dart:226` (départ du tour : y brancher le choix du devineur bloqué).
- `lib/widgets/common/app_modal.dart` pour le sélecteur de joueur.

## Pièges

- La garde `:657` et `canPass` (`turn_screen.dart:258`) font **le même calcul en deux endroits**.
  Les faire porter sur une seule fonction de pénalité effective, sinon le bouton s'affiche actif
  et le provider refuse (ou l'inverse).
- `analytics.onWordPassed` (`:660`) s'appelle **avant** la mutation. Sous `no_pass`, sortir
  **avant** cet appel, sinon on enregistre une passe qui n'a pas eu lieu.
- À l'envers : inverser par **graphèmes** (`String.characters`, exporté par
  `package:flutter/widgets.dart`), pas par unités de code, pour ne pas casser un accent combiné
  ni un emoji. Mettre en majuscules d'abord.
- Le devineur bloqué se choisit au **début du tour**, pas au tirage : le joueur qui fait deviner
  n'est connu qu'à ce moment-là, et il tourne d'un tour à l'autre (`play_rotation.dart:44-62`).
- Bouton retour système pendant le sélecteur : le tour ne doit pas démarrer sans choix (le
  dialogue n'est pas annulable, ou l'annulation revient à l'écran d'avant-tour).

## Tests (règle minimale)

- Provider, pénalité de passe (tier ⑥) : critères 1, 2 et 3, plus le Classique inchangé (7).
  Dans `test/providers/turn_time_test.dart` ou à côté.
- `reverseForDisplay` : un test pur avec « Tour Eiffel », un accent (« Été » → « ÉTÉ »), et
  un emoji. C'est une transformation de chaîne au comportement non évident, d'où ce test.
- Pas de widget test.

## Recette device (Florent, Android + iOS)

1. Forcer chaque modificateur par un ensemble Personnalisé « fixé sur la manche N », puis jouer :
   Passer bloqué ; passes gratuites (compteur, puis pénalité) ; sélecteur du devineur bloqué
   (équipe de 3) ; aucun sélecteur pour une équipe de 2 ; mot à l'envers lisible.
2. Mot à l'envers avec un mot long (« Tour Eiffel », « Star Wars ») : pas de débordement sur un
   petit écran.
3. Passe gratuite, puis verrouillage de l'écran, puis retour : le compteur est conservé.
