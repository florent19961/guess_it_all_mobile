# Revue r1 — story 2-6 « Temps du tour : rattrapage, malus de temps, durée réelle »

Reviewer : Opus (adversarial, tier risqué ⑥ timer + ① machine à états). Entrée : `2-6-patch-r1.diff`
(delta sur `ce1dde8`, contient `composeTurnSeconds`). Code lu avant la spec ; mutation testing
fait sur le worktree, chaque mutation annulée (`git status` propre à la fin).

## Verdict : **READY**

Aucun BLOCKER, aucun MAJOR. Une condition de merge : rebaser sur `feat/fiesta-2-5` r2 (le garde
de `nextRound`, voir m4) et relancer les tests ciblés.

## Points vérifiés

1. **Formules** (`lib/models/fiesta/turn_time.dart:253-282`) : les menées ont `min(cap, k × écart avec la tête)` avec `k = b1`
   après M1 et `b2` après M2. Le leader a `−min(malCap, mal × écart avec la 2ᵉ)`, où la 2ᵉ est la
   meilleure non-leader : les co-leaders sont donc tous leaders. Égalité générale : rien. Si tous
   les curseurs sont à 0, les entrées valent 0 s et sont filtrées. Le cas Auto sans
   auto-calibrage rend `null`. Cas à 3 équipes testé. Plancher : `max(10, somme)` hors
   continuation. Une continuation renvoie exactement les secondes reportées.
   **Une seule source de durée** : `startTurn` (`game_provider.dart:570`) et
   `startTurnTimer` (`:581`) lisent tous deux `turnTime`. Entre les deux, rien de ce que lit
   `turnTime` ne change : `turnBonusTime`, `catchUpDue`, l'équipe courante, `fiesta.active` et
   les réglages restent fixes. `MalusReveal` ne modifie rien. Le compte à rebours n'appelle
   `startTurnTimer` qu'une fois par montage (`countdown_screen.dart:70`, garde `mounted`), et
   l'écran quitte ensuite `countdown`. Si l'app est tuée sur le compte à rebours,
   `turnBonusTime` et `catchUpDue` ne sont pas encore touchés, donc la durée recalculée est
   identique.
2. **Classique seconde pour seconde** : `fiesta == null` donne un dû à 0 et aucun
   modificateur, d'où `turnBonusTime ?? max(10, turnDuration)`. Le slider est borné à 20
   minimum (`constants.dart:16`), donc le résultat vaut `turnBonusTime ?? turnDuration`. Une
   continuation à 0 s reste à 0 s, comme avant (pas de plancher sur une continuation).
   `test/providers/turn_time_test.dart` **n'est pas modifié** : il est absent du diff et vert
   (28/28 avec les autres). Le fix `timeSpent` (`:939-941`) est correct : la durée allouée
   moins le reste, la fusion de continuation donne 5 et plus 10. L'horloge et l'affichage du
   chrono sont inchangés. Seul le temps passé par joueur des **Stats**
   (`stats_aggregation.dart:75`) change, et uniquement sur les continuations : c'est le
   comportement voulu par l'AC7, à mentionner dans la PR.
3. **Règle 7** : `turnAllottedSeconds` se relit en `as int?` (`game_state.dart:336`). Un blob de
   la version en store, sans ce champ, donne `null` et retombe sur `turnDuration`. Le test
   « JSON vide » charge sans lever, et l'aller-retour toJson/fromJson inclut le champ. Un blob
   écrit maintenant porte une clé de plus, que les versions antérieures ignorent.
   « Jamais effacé » est sûr : `startTurnTimer` écrit le champ avant tout `validateWords` du
   même tour. Le snapshot de retour arrière embarque la valeur du tour concerné. `startGame`
   repart d'un `copyWith` qui garde une valeur périmée, mais elle est écrasée au premier
   `startTurnTimer`. `catchUpDue` est additif dans `fiesta` uniquement, et `tryFromJson` est
   tolérant (non-Map → `{}`, entrées non `String→int` filtrées).
4. **Dû stocké** :
   - Consommé une seule fois : la clé est retirée au `startTurnTimer` du premier tour non
     continuation, et l'appel n'a lieu qu'une fois par tour.
   - Jamais sur une continuation : le prédicat `turnBonusTime == null` (`:584-586`) est le même
     que celui qui court-circuite `composeTurnSeconds`, donc la composition et la consommation
     restent cohérentes.
   - Retour arrière : le snapshot est pris après `startTurnTimer`, donc un dû consommé le reste,
     ce qui respecte l'AC8 (le tour a eu lieu). Depuis la transition, `nextRound` n'a pas tourné
     et il n'y a rien à défaire. Depuis l'avant-tour de M(N+1) vers la vérification de M(N), le
     snapshot porte le `catchUpDue` de M(N), qui est réécrit en entier au `nextRound` suivant.
   - Kill / reprise : `turnAllottedSeconds` et `catchUpDue` sont persistés et relus (testé).
   - `continuation = turnBonusTime != null` est sain : c'est le champ qui fait la durée. En
     pratique, il équivaut à `pendingBonusTurnId` (voir m1).
   - Garde 2-5 r2 : aucun conflit. 2-6 ne touche que `_fiestaForRound`, que le garde protège
     (voir m4).
5. **TurnClock** : `turn_clock.dart` n'est pas modifié. La durée composée entre par
   `durationMs`. Pause, reprise, `suspendGame` et `resumeGame` ne sont pas touchés, et le reste
   gelé après un kill est retrouvé (testé).
6. **Mutation testing** (15 mutants, sur les 3 fichiers de test touchés) : **13 tués**.
   - Tués : `k` inversé, plancher retiré, consommation sur la continuation, `copyWith` qui
     perd `active`, `turnAllottedSeconds` non écrit, `timeSpent` calculé sur le réglage,
     `startTurn` avec l'ancienne formule, modificateurs appliqués à la continuation, pas de
     consommation, co-leader mesuré au minimum, `malCap` ignoré, dû non posé à `nextRound`,
     `catchUpDue` non sérialisé.
   - **Survivants** : le comptage de `minus_10s` qui compte tous les modificateurs, et le
     filtre de types de `tryFromJson` (voir m3).
   - `max(0, ±due)` → `±due` est un mutant **équivalent** : les gardes `> 0` de la composition
     l'absorbent (voir n1).

## BLOCKER

Aucun.

## MAJOR

Aucun.

## MINOR

- **m1 — La justification de l'interprétation 2 décrit un état inatteignable.**
  `docs/tracking_evolution.md` (entrée 2-6, « Le dû est stocké… ») et le commentaire de
  `startTurnTimer` évoquent une « fin de manche avec mots refusés → temps reporté, entrée non
  marquée continuation ». Or `resolveTurn` remet tout mot refusé dans le pool
  (`turn_resolution.dart:96-100`). Des mots refusés impliquent donc un pool non vide, donc la
  branche « milieu de manche », qui **perd** le bonus (`game_provider.dart:1012-1013`). La
  branche fin de manche a toujours `allInvalidatedWords` vide, et `pendingBonusTurnId` y est
  toujours posé. Le design (dû stocké, continuation = `turnBonusTime`) reste bon, mais pour
  d'autres raisons : c'est le champ qui fait la durée, et le retour arrière et le kill sont
  couverts par le snapshot. **Correctif** : reformuler l'entrée de `tracking_evolution` sans le
  cas « mots refusés ».
- **m2 — `MalusReveal` (2-5) précède la continuation, que `minus_10s` ne touche pas.**
  `malusToReveal` se base sur « aucune entrée d'historique de l'équipe dans la manche ». Pour
  l'équipe qui ouvre M(N+1) par une continuation, la révélation de `minus_10s` s'affiche avant
  un tour où le malus ne s'applique pas (Q5). Elle ne réapparaît pas au tour suivant, où il
  s'applique. La carte « Temps du tour » reste juste à chaque fois. C'est cosmétique et ça
  croise 2-5. **Correctif** (optionnel) : accepter et le noter, ou ajouter dans la révélation
  une ligne « s'applique à votre prochain tour complet » pour les modificateurs de temps.
- **m3 — Deux survivants de mutation et un fallback non testé.**
  - (a) `game_provider.dart:561` : remplacer `where(catalogId == 'minus_10s').length` par
    `currentTeamModifiers.length` survit, parce que le test Fiesta n'active **que**
    `minus_10s`. **Correctif** : ajouter un second modificateur sans effet sur le temps (par
    exemple `no_pass` fixé en M2) dans `turn_time_fiesta_test.dart`. Le total 26 tue alors ce
    mutant.
  - (b) `fiesta_state.dart:131` : le filtre `e.key is String && e.value is int` n'est pas
    testé. **Correctif** : ajouter une ligne dans `game_state_test` (groupe Fiesta) avec
    `catchUpDue: {'a': 'x', 'b': 3}` → `{'b': 3}`, et `catchUpDue: [1]` → `{}`.
  - (c) Le fallback `?? _settings.turnDuration` (`:940`) n'est exercé par aucun test, puisque
    `startTurnTimer` écrit toujours le champ. Il est trivial, mais c'est le seul chemin règle 7
    du diff. **Correctif** (optionnel) : un test provider qui charge un blob en plein tour
    sans `turnAllottedSeconds`.
- **m4 — Ordre de merge : le garde de `nextRound` manque dans la base `ce1dde8`.** Le correctif
  2-5 r2 `617b73d` (« Manche suivante » idempotent) n'est pas encore sous 2-6. Sans lui, un
  double tap sur « Manche suivante » relance `nextRound` depuis l'écran de jeu de M2.
  `_fiestaForRound` repose alors `catchUpDue` calculé avec `b2` sur les scores de M2, et la
  partie saute une manche. 2-6 aggrave un bug existant sans le créer. **Correctif** : rebaser 2-6
  sur `feat/fiesta-2-5` r2 (`48958e8`) avant la PR, puis relancer
  `turn_time_fiesta_test.dart`. Le test appelle `nextRound` depuis la transition, il doit donc
  rester vert.

## NIT (grille thermo-nucléaire, limitée au diff)

- **n1** — `turnTime` découpe le dû signé en `max(0, due)` et `max(0, -due)`, puis
  `composeTurnSeconds` le recombine à travers deux paramètres et deux gardes `> 0`. Un seul
  paramètre signé `catchUpSeconds`, avec un libellé choisi selon le signe, supprimerait le
  mutant équivalent et un paramètre.
- **n2** — `startTurnTimer` recalcule `_teams[_game.currentTeamIndex].id` à deux endroits
  (`:586`, `:601`), en plus de `turnTime`. Un `final teamId` local suffit.
- **n3** — `TurnTimeCard` distingue la ligne de base avec `line == time.lines.first`, par
  identité d'objet, à deux reprises. C'est fragile si `TurnTimeLine` gagne un jour un `==`
  par valeur. Un index (`for (final (i, line) in time.lines.indexed)`) serait plus direct.
- **n4** — `game_provider.dart` passe de 1507 à 1564 lignes. La croissance est raisonnable et la
  logique pure est bien sortie dans `turn_time.dart`. Rien à faire.
- **n5** — Une continuation à 0 s reste un « tour » de 0 s. C'est le comportement Classique
  existant, préservé, et hors périmètre.

## Plateformes

Pas de `Platform.*`. La carte « Temps du tour » est dans le `Flexible` + `SingleChildScrollView`
existant (`game_screen.dart:200-205`), donc elle défile sur un petit écran. La carte
« Rattrapage » est dans la zone défilante de la transition. La recette sur device reste à faire
par Florent, sur Android et iOS.
