---
story: 2-11-deux-mots-a-la-fois
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ① machine à états, ② scoring, ⑤ analytics, ⑥ timer (expiration)"
collisions: [game_provider.dart, game_state.dart, turn_resolution.dart, analytics_service.dart, turn_screen.dart, verification_screen.dart]
depends: [2-7-analytics-archive-recap, 2-9-mot-compte-double]
model: Fable
---

# 2-11 : Deux mots à la fois

## User story

En tant qu'équipe qui a une charge « Deux mots à la fois », je veux voir deux mots pendant mon
tour et faire deviner celui que je veux. Un mot trouvé ou passé est remplacé, l'autre reste. Ainsi,
on ne bute plus sur un mot difficile.

## Périmètre

Le bonus casse le modèle « un mot courant / un mot expiré » (`GameState.currentWord` /
`expiredWord`, `resolveTurn(expiredWord:)`). C'est pour ça qu'il est en dernier et en tier
risqué.

- **Charges et activation** : même mécanisme que 2-9 (1 charge par équipe et par manche, ou le
  nombre de l'ensemble). Activation sur l'avant-tour, dépense au départ, refus au-delà de 2
  modificateurs (Q8). Annonce plein écran une fois activé (maquette `two_cd`). Incompatible avec
  `no_pass` (table de 2-2), compatible avec `double_points` et `reversed`.
- **État** : `GameState` garde `currentWord` comme carte A et prend un champ optionnel pour la
  carte B (`secondWord`), plus un champ optionnel pour le second mot expiré. Absent = un seul mot,
  exactement comme aujourd'hui.
- **Pendant le tour** (maquette `two_turn`) :
  - deux cartes, chacune avec Trouvé et Passer. Une carte traitée est remplacée par un mot du pool
    **différent de l'autre carte** ; l'autre carte ne bouge pas ;
  - deux mots trouvés « en même temps » = deux taps ;
  - une carte qui vient d'arriver est verrouillée environ 0,3 s, avec une animation d'apparition
    (évite qu'un double tap valide le mot suivant) ;
  - chaque passe coûte la pénalité normale (ou gratuite sous `free_pass`) ;
  - quand il ne reste qu'un mot dans la manche, **une seule carte**, sans place vide (maquette
    `two_last`) ; passer ce dernier mot alors que le pool est vide le fait revenir, comme
    aujourd'hui (`game_provider.dart:674-677`) ;
  - avec `reversed`, les deux cartes sont à l'envers.
- **Expiration** (maquette `two_end`) : les deux mots à l'écran sont marqués « en cours à
  l'expiration » et partent à la vérification.
- **Vérification** (maquette `two_verif`) : chaque mot expiré a son propre Trouvé / Pas trouvé.
  Un mot non trouvé retourne au pool. `resolveTurn` traite **N** mots expirés, et reste pur.
- **Analytics** : chaque carte a ses propres événements (`shown`, `guessed` ou `passed`,
  `expired`) avec sa durée. Le tour porte un indicateur « deux mots » : `two_words` dans les
  `modifiers` de 2-7, et un indicateur optionnel sur `HistoryEntry`.

## Critères d'acceptation

1. **Étant donné** une partie sans le bonus (Classique ou Fiesta), **alors** tout se comporte
   comme aujourd'hui. Les tests existants de `turn_resolution_test.dart` et `turn_time_test.dart`
   passent ; si la signature de `resolveTurn` change, leur adaptation est **mécanique** et la
   sortie ne change pas.
2. **Étant donné** deux cartes A et B, **quand** A est trouvée, **alors** A est remplacée par un
   mot du pool ≠ B, et B ne bouge pas. Même chose pour une passe.
3. **Étant donné** un pool réduit à A et B, **quand** A est trouvée, **alors** il ne reste que B,
   sur une seule carte. **Quand** B est passée, pool vide, **alors** B revient.
4. **Étant donné** le chrono à 0 avec A et B à l'écran, **alors** la vérification propose A et B
   séparément. Valider A et refuser B donne 1 point (×2 si `double_points`), et B retourne au
   pool.
5. **Étant donné** l'app tuée en plein tour à deux mots, **quand** on la rouvre, **alors** les
   deux mêmes cartes sont à l'écran.
6. **Étant donné** un retour arrière vers la vérification d'un tour à deux mots, **alors** les
   deux mots expirés et leurs choix sont restaurés.
7. **Étant donné** un tour à deux mots, **alors** chaque carte a un `shown` puis un `guessed`,
   `passed` ou `expired`, chacun avec sa durée. Aucun événement de la carte B n'est perdu.
8. **Étant donné** la fin de la manche pendant un tour à deux mots (plus aucun mot), **alors** la
   manche se termine comme aujourd'hui (bonus de temps reporté, `:601-625`).
9. **Étant donné** un double tap rapide sur Trouvé d'une carte qui vient d'être remplacée,
   **alors** le nouveau mot n'est pas validé (verrou).

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/models/game_state.dart` : `currentWord` `:74`, `expiredWord` `:78`, `copyWith` /
  `toJson` / `fromJson`.
- `lib/models/turn_resolution.dart` : `expiredWord` `:31-36`, `allInvalidated` `:57-61`,
  `resolveTurn` `:74-121` (expiré `:90-93`, pool `:97-108`).
- `lib/providers/game_provider.dart` : `markWordAsGuessed` `:561-642` (prochain mot `:627`,
  fin de manche `:583-625`) ; `passWord` `:644-700` (recyclage `:674-677`, prochain mot
  `:679-681`) ; `endTurn` `:702-734` (mot expiré `:709-710`) ; `validateWords` `:820-969` ;
  `effectiveRemainingWordsCount` `:1275-1285` (suppose **un** mot courant : `- 1` à `:1284`) ;
  `_trackWordShown` `:545-559`.
- `lib/services/analytics_service.dart` : `_lastShownTimestamp` / `_lastShownWord` `:32-33`,
  `onWordShown` `:150-178`, garde « mot ≠ dernier affiché » `:238`, remise à zéro `:254-255`.
- `lib/screens/turn_screen.dart` : mot `:326-332`, boutons Passer `:380-430` et Trouvé (`:446`),
  `hasWordsToPassTo` / `canPass` `:257-258`.
- `lib/screens/verification_screen.dart` : listes `:52-56` (filtre `expiredWord`), carte du mot
  expiré `:129-164`, initialisation `:22-33`, validation `:224-225`.

## Pièges

- **La garde analytics `word != _lastShownWord` (`analytics_service.dart:238`) jette en silence**
  tout événement de la carte qui n'est pas la dernière affichée. Avec deux cartes, la moitié des
  événements disparaîtraient sans erreur, et ces compteurs nourrissent la priorisation des mots.
  Il faut un suivi **par mot** (horodatage d'affichage par mot).
- **Le mot courant reste dans `remainingWords`** jusqu'à ce qu'il soit trouvé (`:572-573`). Les
  deux cartes y sont donc. Tirer le remplaçant en excluant l'autre carte, sinon les deux cartes
  affichent le même mot.
- `passedWordsThisTurn` est filtré du mot expiré dans la vérification (`verification_screen.dart:53-54`) :
  filtrer **les deux**.
- `effectiveRemainingWordsCount` (`:1284`) soustrait 1 : avec deux cartes, le bouton Passer se
  désactiverait trop tôt ou trop tard.
- `endTurn` met `expiredWord` à nul si la manche est finie (`:709-710`) : même règle pour la carte B.
- Le verrou de 0,3 s est un état de **widget** (visuel). Il ne doit rien persister ni toucher au
  chrono.

## Tests (règle minimale)

- `test/models/turn_resolution_test.dart` (ajouts) : deux mots expirés, un validé et un refusé,
  donnent le bon pool et le bon score (critère 4), avec et sans multiplicateur.
- Provider : remplaçant ≠ autre carte (critère 2), passage à une seule carte et recyclage
  (critère 3), relecture après kill (critère 5).
- Analytics : critère 7, les deux cartes produisent leurs événements (bug potentiel reproduit sur
  la garde `:238`).
- Pas de widget test pour l'animation.

## Recette device (Florent, Android + iOS)

1. Activer « Deux mots », jouer : trouver A, passer B, trouver les deux d'affilée. La carte
   remplacée s'anime et ne prend pas un tap trop rapide.
2. Jouer jusqu'au dernier mot de la manche : une seule carte. La passer : elle revient.
3. Laisser expirer avec deux cartes : la vérification propose les deux séparément, et le score est
   juste.
4. Combiner avec « Mot compte double » et « Mot à l'envers ».
5. Tuer l'app en plein tour, rouvrir : les deux mêmes cartes.
6. Petits écrans (iPhone SE, petit Android) : deux cartes + chrono + badges tiennent sans
   défilement, zones sûres respectées.
   Refaire le contrôle avec la **taille de texte système au maximum** : les cartes de
   `TwoWordsLayout` (`lib/widgets/fiesta/fiesta_turn_widgets.dart`) ne rétrécissent pas en
   hauteur. Sur `turn_screen`, placer `TwoWordsLayout` dans un `Flexible` /
   `SingleChildScrollView` ; si ça déborde, envelopper le mot de la carte, puis chaque carte,
   dans un `Flexible`.
