# Revue r1 — story 2-8 « Effets de tour » (tier risqué : timer / pénalité de passe ⑥, scoring indirect ②, machine à états ①)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-8-patch-r1.diff` (même
dossier), calculé contre `git merge-base origin/main HEAD` (`4e548a2`, 2-6 et 2-7 mergées). Ne
lance jamais `git diff` toi-même.
Lis le code **avant** la spec, puis confronte les deux. Écris ton rapport dans
`2-8-review-r1.md` (même dossier). Le **mutation testing est obligatoire** sur les tests ajoutés.

## Objectif de la story

Spec : `_bmad-output/specs/fiesta/2-8-effets-de-tour-catalogue.md` (AC 1 à 8). Epic :
`_bmad-output/specs/fiesta/epic-fiesta.md` (Q5, Q6, Q14, Q15 ; ligne `block_guesser` du
catalogue). Maquette : écrans `turn`, `rev`, `block`.

Les modificateurs tirés changent vraiment le tour :
- `no_pass` : Passer refusé ;
- `free_pass` ×N : N passes gratuites par tour ;
- `block_guesser` : les adversaires choisissent un devineur, puis une annonce ;
- contraintes de mime et de dessin : annoncées ;
- `reversed` : le mot est inversé sur l'écran de tour seulement.

## Décisions déjà prises (ne pas rouvrir)

- Q6 : « Une seule réponse » + « Interdit de passer » = texte seul (« mot grillé jusqu'à la fin
  du tour »).
- Q15 / `block_guesser` : c'est une simple annonce. La rotation reste inchangée. L'effet est
  impossible si l'équipe a 2 joueurs ou moins.
- La pénalité passe par `TurnClock.applyPenalty`, et la classe n'est pas modifiée.
- Une partie Classique doit rester strictement inchangée. Les scores restent dans `Team`.
- Tests au minimum, pas de test de widget. `reversedWordDisplay` est déjà testé par le kit.

## Interprétations de l'implémenteur (à challenger)

1. **Une seule garde** : `GameProvider.canPassWith(secondesAffichées)`. Elle vaut
   `!passBlocked && s >= currentPassPenalty`. `passWord` et le bouton de `turn_screen` la lisent
   tous les deux. Sous `no_pass`, la sortie a lieu avant `onWordPassed`.
2. **Compteurs dans `FiestaState.turn`** : `freePassesUsed` et `blockedPlayerId`. La clé existait
   déjà, avec une relecture tolérante : la forme persistée ne change pas, pas de migration.
   `validateWords` vide les compteurs dans les deux branches. Une continuation de fin de manche
   repart donc à 0 passe gratuite, et le sélecteur s'y rouvre si `block_guesser` s'applique en
   N+1.
3. **Plusieurs `free_pass`** : leurs charges s'additionnent. Une passe gratuite est décomptée même
   si la pénalité réglée vaut 0.
4. **Instances de portée tour** : `validateWords` les consomme pour l'équipe qui joue (cible
   `both` ou `teamId` égal), et seulement dans la branche hors fin de manche. En fin de manche,
   la même équipe poursuit en N+1 : l'instance survit (`_fiestaForRound` la garde déjà) puis tombe
   à la fin de la continuation. Aucun code ne pose encore ce type d'instance (2-10 le fera) :
   le test l'injecte dans l'état persisté.
5. **Devineur bloqué** : il est choisi dans `game_screen._startTurn`, après `MalusReveal`. Le
   sélecteur est un `AppModal` ; s'il est fermé sans choix, on reste sur l'avant-tour et rien ne
   démarre. Le choix est persisté avant l'annonce : après un kill, pas de second choix.
   `setBlockedGuesser` refuse celui qui fait deviner et tout joueur hors de l'équipe.
   Décision (lead) : `block_guesser` n'arrive que par offre (2-10), jamais tiré ni fixé pour
   tous ; Q15 ne s'applique pas. L'effet porte sur toute instance qui vise l'équipe qui joue ;
   le test l'injecte. Ne pas rouvrir.
6. **Contraintes annoncées** : `MimeConstraintBanner` et le texte Q6 apparaissent dans la carte
   d'avant-tour. L'annonce plein écran du mime reste celle de `MalusReveal` (2-5).
7. **À l'envers** : seul l'`AutoSizeText` du tour change. `currentWord`, la vérification et les
   résultats ne sont pas touchés. `FiestaWordCard` n'est pas branché : c'est pour 2-11.

## Questions précises

- **Garde** : existe-t-il un écart entre le bouton (`timeRemaining`) et le provider
  (`displayedSecondsAt(now)`) qui soit nouveau par rapport à avant ? Le libellé
  « gratuit » / « −5s » est-il cohérent avec la passe effectivement appliquée ?
- **Undo** : après `restorePreValidationState`, le compteur et le devineur bloqué valent-ils ceux
  du snapshot ? Une passe gratuite peut-elle être comptée deux fois, ou rendue deux fois ?
- **Portée tour** : un chemin fait-il franchir à une instance de portée tour une fin de tour réel ?
  Pense à une fin de manche avec des mots refusés, à `turnBonusTime` à 0, ou au retour arrière
  depuis la transition. À l'inverse, une instance peut-elle tomber trop tôt ?
- **Sélecteur** : double tap sur « Commencer le tour », retour système pendant le sélecteur ou
  pendant l'annonce, `context.mounted`.
- **Classique** : `passWord`, le bouton et l'état persisté sont-ils identiques octet pour octet
  (aucune clé `fiesta` écrite) ?
- **Valeur des tests** (mutation) : garde `no_pass` retirée, compteur non incrémenté, compteur
  non vidé en fin de tour, `turnOver: true` en fin de manche (vérifié par l'implémenteur : le
  test casse), consommation de portée tour retirée. Chaque assertion mord-elle ?
- Deux plateformes : rien de `Platform.*`. Le sélecteur défile-t-il sur petit écran (6 joueurs) ?

## Format attendu

Pour chaque finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, scénario
concret, correction proposée. Verdict final : READY ou NOT READY.
