# Revue statique r1 — L-CACHE

## Verdict : READY

Revue en lecture seule du patch fourni et de son contexte. Aucun test, aucune
commande Flutter et aucun `git diff` n'ont été lancés.

## Finding

### MINOR — la couleur des règles de manche ne suit pas la maquette de référence

- **Emplacement :** `lib/screens/turn_reveal_screen.dart:21`
- **Preuve :** les lignes de règles sont construites avec `Colors.white`, alors
  que la maquette de référence demande leur cercle jaune. Le cas se produit dès
  qu'une règle « Toujours » ou tirée est active au moment d'une révélation.
- **Correction proposée :** employer la couleur jaune du design system pour
  cette ligne (et son contour), sans modifier la provenance « Règle de la
  manche ».

Il n'y a ni BLOCKER ni MAJOR.

## Conformité D2 et chemins d'état

- Le filtre est à la bonne racine : `currentTeamModifiers`
  (`lib/providers/game_provider.dart:1477`) ne laisse, sur `screenGame` hors
  continuation, que les règles de manche. Les lecteurs de l'avant-tour
  (`receivedThisTurn`, `blockedGuesser`, `turnTime`, réserve et aide) passent
  bien par ce getter. Les accès directs à `fiesta.active` restants servent aux
  mutations, au conflit de cible adverse ou au piège, et n'affichent pas un
  malus reçu au joueur qui va jouer.
- Le passage `startTurn` → `screenTurnReveal` (`game_provider.dart:737`) est
  conditionné par un malus réellement jouable, puis `leaveTurnReveal`
  (`:752`) ne fait que rejoindre le décompte. `startTurnTimer` relit alors la
  durée après que le filtre n'est plus actif (`:767-825`) : le −10 s est caché
  de l'aperçu, mais compté par le chrono.
- Le piège reste prioritaire : `_hasTurnReveal` exclut
  `_pendingGiverBlock` (`:1502-1505`), puis `startTurnTimer` mène au piège
  avant tout départ de chrono (`:771-775`). `confirmGiverBlock` retire seulement
  le blocage et replace le téléphone sur l'avant-tour (`:1610-1646`) ; les
  autres malus du joueur sauté restent actifs.
- Une continuation est explicitement hors révélation (`!isContinuation`) et
  hors masquage (`:1494-1505`). Les malus qui deviennent jouables en manche
  suivante restent donc visibles dans son avant-tour, conformément à
  l'arbitrage D2. Les transitions de manche continuent de conserver les malus
  infligés puis les jugent dans la manche courante
  (`lib/models/fiesta/round_transition.dart:36-42`, `:85-110`).
- Le retour de validation restaure le snapshot en `screenVerification`, jamais
  en avant-tour (`game_provider.dart:2494-2503`) : il ne réouvre pas une voie
  permettant de réarmer après révélation. Les fins de manche gardent leur
  séquencement existant (`validateWords`, `nextRound`).
- L'écran est bien une valeur additive de `currentScreen`, sérialisée par le
  `GameState` générique (`lib/models/game_state.dart:285-322`) et routée dans
  `lib/app.dart:86-87`. Il n'offre ni bouton accueil ni retour système
  (`PopScope(canPop: false)`, `turn_reveal_screen.dart:26-27`). Ces widgets sont
  communs à Android et iOS ; aucune divergence `Platform.*` n'est introduite.
- Le contenu est conforme hors réserve visuelle ci-dessus : une ligne par malus
  jouable reçu, provenance envoyeur, règles et bonus connus séparés, aucune
  duplication possible par les invariants de `modifiersForTurn` (un même id
  reçu est éliminé face à une règle) et de `_conflict` (un bonus déjà en jeu ne
  peut être armé). Le joueur bloqué ne peut pas atteindre l'écran.

## Passe gratuite, incompatibilités et données existantes

- `passBlocked` est exactement `no_pass && !hasFreePass`
  (`game_provider.dart:1514-1539`). Le même prédicat est lu par le bouton et
  par `passWord`; la première passe est à pénalité zéro, incrémente
  `freePassesUsed` (`:953-975`), puis la seconde est refusée avant toute
  mutation. La bulle et le libellé « (gratuit) » en découlent dans
  `lib/screens/turn_screen.dart:301-315`.
- La suppression de `kModifierIncompatibilities` laisse la seule incompatibilité
  de famille Mime (`modifier_catalog.dart:263-270`). La clause spéciale de
  `FiestaRules.lockReason` a été supprimée : `chargesOf('free_pass')` reste
  donc disponible sous `no_pass` Toujours, et le vivier utilise la même
  compatibilité (`lib/models/fiesta/cartridge_gifts.dart:66-72`).
- Aucune forme persistée ne change. Pour une partie 1.4.0 suspendue avec
  `no_pass` Toujours et des charges `free_pass`, le stock est volontairement
  recalculé par `FiestaState.cartridgesOwned` depuis les règles gelées
  (`fiesta_state.dart:54-67`) : les cartes deviennent jouables, comme demandé.
  Les gains et résultats déjà écrits restent dans `earned`/`challenges`; seul
  un passage de manche encore non appliqué peut tirer avec le nouveau vivier.
  Ce tirage n'avait pas encore été écrit, donc aucun tirage persisté n'est
  re-dérivé ni remplacé.

## Valeur des tests et mutations — lecture statique

| Test / assertion | Mutant plausible | Verdict attendu par lecture |
|---|---|---|
| `fiesta_turn_reveal_test.dart:14-40` | supprimer le filtre `_receivedHidden`, le faire lire au chrono, ou ne plus router `startTurn` vers la révélation | **Tué** : malus, devineur bloqué, durée d'aperçu, écran de révélation et durée réelle sont tous vérifiés. |
| `fiesta_turn_reveal_test.dart:43-71` | retirer la garde `_pendingGiverBlock`, ou montrer une révélation sans malus | **Tué** : le joueur piégé doit passer par le décompte puis `screenGiverBlocked`; le cas sans malus doit aller directement au décompte. |
| `fiesta_turn_reveal_test.dart:73-86` | ne pas persister `currentScreen` lors de `startTurn` | **Tué** : la relecture doit retrouver `screenTurnReveal` et son malus. **Non couvert seul :** retirer le `case screenTurnReveal` de `app.dart`; le provider serait persistant mais l'UI retomberait sur l'accueil. Le routage présent est correct à la lecture. |
| `fiesta_continuation_cartridges_test.dart:155-176` | enlever `!isContinuation` du masquage ou faire passer une continuation par la révélation | **Tué** : le malus est encore visible avant le départ de la continuation, et le départ attendu reste `screenCountdown`. |
| `fiesta_turn_effects_test.dart:126-151` | `passBlocked = _has('no_pass')`, ne pas incrémenter `freePassesUsed`, ou laisser `passWord` muter après blocage | **Tué** : première passe gratuite, chrono intact, puis blocage et JSON inchangé sont vérifiés. |
| `cartridge_gifts_test.dart:103-107`, `fiesta_catalog_test.dart:50-54`, `ensemble_validation_test.dart:114-123` | rétablir la paire incompatible ou le verrou éditeur | **Tué** : le vivier, `areCompatible`, `lockReason` et `chargesOf` exigent tous la coexistence. |
| `turn_time_fiesta_test.dart:148-156`, `preturn_help_test.dart:122-141`, `help_conditional_test.dart:139-185` | lire les malus reçus directement dans l'aperçu ou l'aide | **Tué** : l'aperçu reste à 30, l'aide ne propose pas les étapes reçues avant le départ, puis l'effet est visible pendant le tour. |
| Ajouts de `startTurn()` dans les tests de cartouches et Fiesta v4 | mutation des effets post-révélation | **Ne créent pas une garantie supplémentaire à eux seuls** : ils déplacent simplement les assertions existantes après le nouveau seuil de révélation. Les assertions d'effet qu'ils conservent restent utiles. |

La persistance route/UI et le verrouillage du retour sont vérifiés ici par
lecture statique, pas par exécution : cette revue respecte la contrainte de ne
lancer aucun test.

## Verdict final

**READY** — BLOCKER : aucun ; MAJOR : aucun.
