# Revue r1 — kit 2-10 (1 parmi 3 / coup de pouce), tier standard

Reviewer : Opus, adversarial. Lecture du patch `2-10-kit-patch-r1.diff`, du code existant
(`modifier_catalog`, `modifier_instance.canAdd`, `symmetric_draw`, `turn_time.computeCatchUp`), de
la story 2-10, de l'epic (Q3, Q7, Q8, Q15), des specs 2-8 / 2-9 et de la maquette (écrans `r2`,
`pick3`). Je n'ai rien modifié. Une sonde temporaire et 12 mutations ont été lancées, puis
annulées (`git status` propre, `offers.dart` identique à l'original, vérifié par `cmp`).

`flutter test test/models/fiesta/offers_test.dart` : 5/5 au vert. `flutter analyze` sur les 3
fichiers : aucun problème.

## Verdict : NOT READY

Le modèle est propre, petit et déterministe, et la plupart des AC tiennent. Trois points
importants bloquent le passage en l'état : des cartes sans effet, aucune aide pour un gros écart
(il faut l'arbitrage de Florent), et des tests qui ne protègent ni `appBoost` ni la graine.

## Constats

### MAJOR 1 : des offres ou des cadeaux sans effet (doublons du même modificateur sur la même cible)

- **Où** : `lib/models/fiesta/offers.dart:174` (`_pick`). Le test fige ce comportement à
  `test/models/fiesta/offers_test.dart:96`.
- **Scénario** : `no_pass` est tiré pour tous en M2. Bleue, menée, se voit proposer « Interdit de
  passer contre Rose ». `areCompatible('no_pass', 'no_pass')` est vrai et le plafond le permet,
  donc la carte passe. Si Bleue la prend, elle gaspille son choix : Rose ne pouvait déjà plus
  passer. Le même problème vaut pour `reversed`, `two_words`, les `mime_*`, `draw`, et pour un
  doublon venant du choix d'une équipe précédente. En Auto, la sonde trouve un cadeau identique
  à un modificateur tiré dans **39 parties sur 200** (écart de 6, après M1). La carte annonce
  alors un malus qui ne change rien.
- **Correctif minimal** : dans `_pick`, exclure aussi les candidats dont un modificateur de même
  `catalogId` touche déjà la cible :
  `canAdd(taken, c) && !taken.any((t) => t.catalogId == c.catalogId && t.concernsSameTeamAs(c))`.
  Corriger aussi l'attente du test `:96` (`['double_points']`). Si Florent veut que les bonus à
  charges se cumulent (« +charges », Q7), garder l'exception `c.charges > 0`. C'est la seule
  nuance possible, et le plus simple reste de tout exclure.

### MAJOR 2 : avec un écart > 7, l'équipe menée ne reçoit jamais de bonus, et en Auto avant M3 elle ne reçoit rien du tout (arbitrage Florent)

- **Où** : la table `offers.dart:19-31` (aucun bonus classé `heavy`), combinée à la force stricte
  (décision 1) et au refus de `block_guesser` en Auto (décision 5, `:236`).
- **Scénario (sonde)** :
  - Auto, 20–10 après M1 : `appBoost` → `[]`. La carte « Coup de pouce » disparaît. Les
    candidats `forte` sont `mime_no_arms` et `mime_eyes_closed` (M3 seulement) et
    `block_guesser` (interdit en Auto), et il n'existe aucun bonus fort.
  - Auto, 3 équipes 20/18/5 : Bleue (écart 2) reçoit `free_pass`, mais l'équipe à 15 points
    d'écart ne reçoit rien.
  - Personnalisé, écart > 7 après M1 : une seule offre (`block_guesser` contre la tête). Si la
    tête a 2 joueurs ou moins, l'équipe est sautée.

  Résultat : plus une équipe est loin derrière, moins elle reçoit d'aide. C'est l'inverse du
  but de Q7 (« la force suit l'écart »). Je ne remets pas en cause la force stricte (décision 1).
  Le défaut vient du **contenu de la table**, qui était l'interprétation 2 de l'implémenteur, et
  de son interaction avec les décisions 1 et 5.
- **Correctif (à arbitrer)** :
  - (a) Le plus petit : quand la force exacte n'a **aucun** candidat, essayer la force juste en
    dessous. Cela se fait en une boucle dans `_pick`/`give`, AC1 ne bouge pas, et le cas
    « moins de 3 » reste accepté.
  - (b) Revoir la table pour avoir au moins un bonus par force. Avec 3 bonus seulement, on casse
    vite les 3 offres « moyennes » de AC1 (`double_points`, `two_words`, `no_pass`).

  Recommandation : (a), en Auto au minimum.

### MAJOR 3 : les tests ne protègent ni `appBoost` ni la graine (7 mutants survivants sur 12)

- **Où** : `test/models/fiesta/offers_test.dart` en entier, et `:116-128` (déterminisme).
- **Mutations** (appliquées puis annulées) :

  | Mutation | Résultat |
  |---|---|
  | M1 seuil `<= 3` → `< 3` | tuée |
  | M2 ordre de file inversé | tuée |
  | M3 bonus donné au leader | tuée |
  | M4 suppression du filtre `canAdd` | tuée |
  | M12 suppression de la garde « le leader ne choisit pas » | tuée |
  | **M5 graine sans `teamId`** (`drawSeed(gameId, round)`) | **survit** |
  | **M6 `startRound` ignoré** | **survit** |
  | **M7 `arrival != offer` ignoré** | **survit** |
  | **M8 `appBoost` renvoie `[]`** | **survit** |
  | **M9 co-leaders : le premier devient la cible** | **survit** |
  | **M10 `block_guesser` autorisé en Auto** | **survit** |
  | **M11 immunité `blockImmuneTeamIds` ignorée** | **survit** |

  - Le test de déterminisme compare deux appels dans le même processus. Il ne peut échouer que
    si quelqu'un introduit `Random()` sans graine. Il ne fige pas la formule de la graine. Or un
    changement de formule entre deux versions casserait AC5 (partie tuée, app mise à jour, offres
    différentes à la reprise) sans qu'aucun test ne le voie.
  - `appBoost` (AC7, décision 5) n'est couvert par **aucun** test, alors qu'il alimente le score
    par la suite.
- **Correctif minimal (2 tests, pas plus)** :
  1. Dans le test de déterminisme, remplacer `run() == run()` par une **valeur figée** :
     `expect(ids(pickThreeOffers(... gameId: 'g', round: 1, 14–8, 'bleue')), [<liste actuelle>])`.
     Ce test tue M5 et protège la reprise après une mise à jour.
  2. Un test `appBoost`, Auto, 14–8 après M1 : un bonus `medium` pour Bleue et un malus `medium`
     pour Rose (AC7). Avec 3 équipes 20/18/5 après M2 : aucun `block_guesser` dans les cadeaux
     (tue M10). Ajouter une ligne `Standings({'a': 9, 'b': 9, 'c': 2}).leaderId == null` (tue
     M9).
  3. Optionnel, une ligne : dans la fixture, régler un id en `draw` et un autre avec
     `startRound: 3`, puis vérifier qu'ils sont absents des offres après M1 (tue M6 et M7).

### MINOR

1. **Les choix ne portent pas l'équipe qui a choisi** (contrat pour la lane cœur,
   `offers.dart:154-161`). Un malus choisi a `teamId` = leader, et rien ne dit qui l'a choisi.
   Or 2-10 exige que « l'équipe qui l'a choisi désigne le devineur » (`block_guesser`), et la
   reprise (AC5) doit savoir où en est la file quand des équipes ont été sautées. Pas de rework
   du kit, mais la lane cœur doit persister `Map<chooserTeamId, ModifierInstance>` et non une
   simple liste. La prochaine équipe est alors la première de `choosingOrder` absente de la map
   dont les offres ne sont pas vides, recalculées avec `taken` = `roundModifiers(N+1)` + les
   choix déjà présents. À écrire dans la doc de `pickThreeOffers`.
2. **`blockImmuneTeamIds: allTeams` (`:236`) est un détournement « magique »** pour dire « jamais
   de `block_guesser` en Auto ». Il vaut mieux l'écrire directement dans `_candidates` :
   `if (toPlayer && (!custom || blockImmuneTeamIds.contains(targetTeam))) continue;`, et retirer
   `allTeams`.
3. **`Standings` duplique la lecture top/2ᵉ de `computeCatchUp`** (`turn_time.dart:115-127`).
   C'est acceptable dans ce kit (le fichier `turn_time` était interdit). Noter pour la lane cœur
   que `computeCatchUp` pourrait consommer `Standings`.
4. **L'ordre de la `Map` de `Standings` départage les menées à égalité** (`:51-95`). La lane cœur
   doit construire la map **dans l'ordre des équipes** (liste `teams`), jamais depuis une map
   relue et triée. C'est documenté, mais facile à rater.
5. **`gapOf` d'un id inconnu lève une exception** (`:76`, `!`). Un appelant incohérent fait
   planter un widget (`PickThreeCard`). C'est acceptable en l'état, mais il faut le savoir.
6. **Scope de `block_guesser` offert** : `ModifierScope.round` (`:154`), alors que le catalogue
   indique `turn` (« pour un tour »). C'est cohérent avec Q7 (« toute la manche N+1 »), mais 2-8
   doit savoir s'il faut bloquer un devineur à **chaque** tour de la manche. À trancher avec 2-8.
7. **`two_words` a `defaultCharges: 0`** dans le catalogue, alors que 2-11 et la maquette parlent
   d'une charge. En Auto, le cadeau `two_words` part donc avec 0 charge. L'origine est dans le
   catalogue, pas dans le kit, mais c'est le kit qui le propage.
8. **Widgets** :
   - `_OfferCard` utilise un `GestureDetector` nu (`offer_widgets.dart:285`) : aucune sémantique
     bouton ni « sélectionné » pour les lecteurs d'écran. Il faut l'envelopper dans
     `Semantics(button: true, selected: selected)`. La cible tactile (≥ 68 px) est correcte.
   - `_name` et `_color` (`:14-24`) retombent silencieusement sur l'id ou sur la couleur 0.
   - Le sous-titre écrit toujours « Menée de N points ». La maquette à 4 équipes dit
     « Dernière, à 9 points de Rose ». C'est cosmétique.
   - Pour le reste, conforme à la maquette : textes, file « · Rose (en tête) ne choisit pas »,
     « Choisis une carte » / « Valider ce choix », bouton cyan, pastille « Pour vous / Contre X ».
     Les widgets sont stateless, sans Provider, avec des callbacks seulement.
   - Remarque : la maquette `r2` en Auto affiche `free_pass` / `minus_10s` (léger) sous une
     étiquette « moyenne ». C'est l'implémentation qui est juste, pas la maquette.

## Ce qui est correct (vérifié)

- Force par l'écart de **cette** équipe (`:197`), seuils 3 / 7 bien placés.
- File : de la dernière à l'avant-dernière, départage stable, tous les co-leaders exclus, file
  vide en cas d'égalité, avec 1 équipe ou avec 0 équipe.
- Bonus pour l'équipe qui choisit, malus pour l'unique leader, aucun malus pour des co-leaders
  (décision 3).
- Éligibilité : `arrival == offer`, `startRound ≤ N+1`, `round3Only` via `isEligibleForRound(N+1)`.
- `canAdd` évalué contre `taken` = tirage N+1 + choix déjà faits. Un candidat `team` est jugé sur
  sa cible seule plus les modificateurs « pour tous ». Les incompatibilités entre un bonus pour
  Bleue et un malus pour Rose ne se gênent pas, ce qui est correct.
- Déterminisme : candidats dans l'ordre du catalogue, mélange par `Random(offerSeed)`, filtre
  `canAdd` appliqué **après** le mélange. La permutation ne dépend donc pas de `taken`, et les
  offres de la 1ʳᵉ équipe sont stables après un retour arrière (AC6).
- Gating AC8 (`isPickThreeOn` / `isAppBoostOn`, rien après M3).
- Sur-ingénierie : aucune notable. Le fichier fait 249 lignes, la table est lisible et sans
  configurabilité.
