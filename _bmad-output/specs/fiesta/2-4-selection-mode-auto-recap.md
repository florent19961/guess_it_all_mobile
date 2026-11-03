---
story: 2-4-selection-mode-auto-recap
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "L (écrans) + GP (lancement, Rejouer)"
collisions: [game_provider.dart, "lib/app.dart + constants.dart (routes)"]
depends: [2-2-fondation-modele-fiesta, 2-3-ensembles-stockage-editeur]
model: Opus
---

# 2-4 : Choix du mode, écran Auto, récap, lancement et « Rejouer »

## User story

En tant que joueur qui lance une partie, je veux choisir entre Classique et Fiesta, puis entre
Auto et Personnalisé, et voir un récapitulatif avant de saisir les joueurs. Ainsi, je sais à quoi
on joue avant de commencer.

## Périmètre

Parcours (Q11, recommandation appliquée par défaut) :

```
Accueil « Nouvelle partie » → Mode de jeu ─ Classique ──────────────────────────────► Paramètres (actuel)
                                          └ Fiesta → Auto | Personnalisé → Récap ──► Paramètres (actuel)
Paramètres → Joueurs (et mots) → Équipes → startGame(fiesta: …)
```

- Écrans neufs (maquette `gamemode`, `fiesta`, `auto`, `recap`) : Mode de jeu, Fiesta (Auto ou
  Personnalisé), Mode Auto (2 interrupteurs : **Continuer désactivé si les deux sont coupés**,
  avec le texte de la maquette ; règles communes, « Une seule réponse » allumée par défaut),
  Récap (mode, réglages, règles communes, réglages de base **lus** dans `GameSettings`, bouton
  Modifier qui revient à Auto ou à l'éditeur de l'ensemble).
- « Personnalisé » ouvre la liste de 2-3. « Utiliser » revient au Récap avec cet ensemble.
- **Choix en mémoire seulement** (Q10) : un `FiestaRules?` en attente dans `GameProvider`, non
  persisté. `teams_screen.dart:79` appelle `startGame()` : il passe la config en attente, que
  2-2 gèle dans `GameState`.
- **Rejouer** (Q12) : `restartWithSamePlayers` (`game_provider.dart:1162-1187`) relit les
  `rules` de la partie qui vient de finir **avant** de remettre `_game` à zéro, les remet en
  attente, puis va au Récap si c'était une partie Fiesta, ou aux Paramètres sinon (comme
  aujourd'hui).
- Libellés : le jeu d'aujourd'hui s'appelle « Classique ». Accueil inchangé, sauf la cible de
  « Nouvelle partie » (`home_screen.dart:76`, `:94`, `:155`).

## Critères d'acceptation

1. **Étant donné** l'accueil, **quand** on touche « Nouvelle partie », **alors** l'écran Mode de
   jeu s'ouvre. Classique mène aux Paramètres actuels, et la partie jouée est **exactement**
   celle d'aujourd'hui (`GameState.fiesta` nul).
2. **Étant donné** Mode Auto avec les deux interrupteurs coupés, **alors** Continuer est
   désactivé et l'explication est visible.
3. **Étant donné** un ensemble choisi par « Utiliser », **quand** on arrive au Récap, **alors**
   son nom et son résumé s'affichent (modificateurs actifs, 1 parmi 3, rattrapage, tirage).
4. **Étant donné** un Récap Fiesta, **quand** on va jusqu'à l'écran Équipes et qu'on lance,
   **alors** `GameState.fiesta.rules` reflète le choix, gelé.
5. **Étant donné** une partie Fiesta finie, **quand** on touche « Rejouer », **alors** on arrive
   au Récap avec la même configuration. Après une partie Classique, rien ne change par rapport à
   aujourd'hui.
6. **Étant donné** une partie suspendue (`isGameSuspended`), **alors** le bouton Reprendre de
   l'accueil (`home_screen.dart:41`) se comporte comme aujourd'hui : il ne traverse **pas** les
   écrans de mode.
7. **Étant donné** que l'app est tuée entre le choix du mode et le lancement, **alors** à la
   relance on repart d'un choix vide (Q10), sans crash.

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/screens/home_screen.dart:41` (Reprendre), `:55-60` (Rejouer), `:65-76` et `:90-94`
  (Nouvelle partie), `:126-155` (dialogue de confirmation qui mène aussi à `screenSettings`).
- `lib/screens/results_screen.dart:47-53` (Rejouer → `restartWithSamePlayers`).
- `lib/screens/teams_screen.dart:79` (`startGame()`).
- `lib/providers/game_provider.dart` : `startGame` `:385` (signature posée par 2-2),
  `restartWithSamePlayers` `:1162-1187` (lire la config avant `GameState.initial()` à `:1183`),
  `startNewGame` `:1147` (efface la config en attente).
- `lib/screens/settings_screen.dart:250` : son bouton retour va à l'accueil. Le faire revenir au
  Récap (ou au Mode de jeu en Classique) **seulement** si c'est trivial ; sinon le laisser et le
  noter.
- Routage : `lib/app.dart:56-92`, `lib/utils/constants.dart:33-47`.

## Pièges

- `restartWithSamePlayers` remet `_game` à `GameState.initial()` (`:1183`) : lire `rules`
  **avant**, sinon « Rejouer » perd la configuration.
- `hasGameSession` (`:1312`) et `isGameSuspended` pilotent l'accueil : ne pas insérer les écrans
  de mode sur le chemin Reprendre.
- `goToScreen` ne sauvegarde que si une partie est en cours (`:1066-1073`). Les écrans de mode
  passent donc **avant** toute persistance : c'est voulu (Q10).
- Parité : les nouveaux écrans utilisent les widgets existants (`lib/widgets/common/`) ; pas de
  `Platform.*`.

## Tests (règle minimale)

- Un seul test provider, sur l'invariant de machine à états : critère 5, « Rejouer » conserve
  `rules` après une partie Fiesta et reste nul après une partie Classique. Pas de widget test
  des écrans.

## Recette device (Florent, Android + iOS)

1. Parcours complet Classique : une partie entière, rien ne change par rapport à la version en
   store.
2. Parcours Fiesta Auto, puis Personnalisé avec un ensemble, jusqu'au lancement. Le Récap est
   juste.
3. Finir une partie Fiesta, Rejouer : on retombe sur le Récap.
4. Bouton retour Android (geste système) sur chaque nouvel écran : il ne sort pas de l'app par
   surprise. Swipe retour iOS : idem.
