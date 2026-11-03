---
story: 2-2-fondation-modele-fiesta
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ① machine à états, ③ schéma persisté"
collisions: [game_state.dart, game_provider.dart]
depends: []
model: Fable
---

# 2-2 : Fondation (catalogue, modèle, champs optionnels de `GameState`, gel au lancement)

## User story

En tant que développeur des stories Fiesta suivantes, je veux un catalogue codé en dur, un modèle
de modificateur et un état Fiesta optionnel dans `GameState`, gelé au lancement de la partie. Ainsi,
chaque effet s'ajoute sans retoucher le format persisté, et une partie Classique, ancienne ou
nouvelle, reste identique.

## Périmètre

- `lib/models/fiesta/` (nouveau dossier, fichiers purs, sans dépendance à un service) :
  - **catalogue** : les 10 entrées V1 de l'epic (id, nom FR, description FR, nature bonus/malus,
    portée par défaut manche/tour, cible par défaut, charges par défaut, « manche 3 seulement »),
    plus la **table d'incompatibilités** (Q14 : `no_pass`✗`two_words`, `no_pass`✗`free_pass`,
    `mime_no_arms`✗`mime_eyes_closed`, `mime_no_arms`✗`draw`, `mime_eyes_closed`✗`draw`) ;
  - **`ModifierInstance`** `{catalogId, scope: round|turn, target: both|team|player, teamId?,
    playerId?, charges, nature, round}` avec `toJson` et un `tryFromJson` tolérant ;
  - **`FiestaRules`** : la configuration gelée. Mode (`auto` | `custom`), interrupteurs Auto
    (symétrique, auto-calibrage), et pour Personnalisé : nom de l'ensemble, réglage par
    modificateur (actif, arrivée `draw|offer|fixed`, manche de départ, manche fixée, charges),
    1 parmi 3 oui/non, curseurs de rattrapage (`b1`, `b2`, `cap`, `mal`, `malCap`), nombre tiré
    pour tous (0 à 2). Règles communes (`oneAnswer`, `carryOver`). Les valeurs Auto sont des
    constantes (+3/+5 s, plafond 30 s, −1 s, plafond 15 s) ;
  - fonctions pures : `areCompatible(a, b)`, `canAdd(active, candidate, {maxPerTurn: 2})`.
- `GameState` (`lib/models/game_state.dart`) : **un** champ optionnel `fiesta` (nul = Classique)
  qui porte `rules` (gelées), `active` (instances actives) et un sous-objet d'état de tour vide
  pour l'instant. Les stories suivantes y ajoutent leurs compteurs.
- `GameProvider.startGame` (`game_provider.dart:385-431`) prend un `FiestaRules?` optionnel et
  le gèle dans `_game`. Getter `isFiesta`.

Hors périmètre : écrans, tirage, effets. Aucun effet de jeu dans cette story.

## Critères d'acceptation

1. **Étant donné** un blob `guessItAll_gameState` écrit par la version en store (sans clé
   `fiesta`), **quand** l'app le relit, **alors** `GameState.fiesta` est nul, la partie reprend en
   Classique, et `toJson()` ne produit **pas** de clé `fiesta` (pas de bruit dans le blob
   Classique).
2. **Étant donné** une partie Fiesta en cours, **quand** l'app est tuée puis relancée, **alors**
   `rules` et `active` sont relus à l'identique (aller-retour `toJson`/`fromJson`).
3. **Étant donné** un blob `fiesta` qui contient un `catalogId` inconnu ou une instance mal
   formée, **quand** on le relit, **alors** l'instance est **ignorée** (jamais de valeur par
   défaut inventée, même règle que `WordEvent.tryFromJson`, `word_event.dart:110-120`), et le
   reste de la partie se relit. Un `fiesta` qui n'est pas un objet donne une partie Classique, pas
   un crash.
4. **Étant donné** `kCurrentSchemaVersion` (`persisted_schema.dart:22`), **quand** la story est
   mergée, **alors** il vaut toujours `1`.
5. **Étant donné** `startGame(fiesta: rules)`, **quand** la partie démarre, **alors** `rules` est
   une **copie** gelée. Modifier ensuite l'ensemble source ne change pas la partie.
   `startGame()` sans argument produit exactement l'état d'aujourd'hui.
6. **Étant donné** un snapshot de retour arrière (`savePreValidationState`,
   `game_provider.dart:1334`), **quand** on le restaure (`restorePreValidationState`, `:1355`),
   **alors** `fiesta` revient à la valeur capturée. C'est déjà vrai par construction, puisque le
   snapshot réutilise `GameState.toJson()` : le test l'épingle pour les stories qui ajouteront des
   compteurs.
7. `areCompatible` est symétrique. `canAdd` refuse une 3ᵉ instance pour une même équipe et un
   même tour, et refuse une instance incompatible avec une instance déjà active.

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/models/game_state.dart` : champs `:60-109`, constructeur `:111-145`, `copyWith`
  `:151-244` (ajouter `fiesta` + `clearFiesta`), `toJson` `:246-276`, `fromJson` `:278-325`.
- `lib/providers/game_provider.dart` : `startGame` `:385-431` (le `copyWith` `:406-424` part de
  `_game` : penser à `clearFiesta` quand on lance sans Fiesta, sinon une config d'une partie
  précédente survit) ; `endGameAndGoHome` `:1137`, `startNewGame` `:1147`,
  `restartWithSamePlayers` `:1162` réinitialisent via `GameState.initial()` : rien à faire, mais
  à vérifier.
- `lib/services/persisted_schema.dart:22` : **ne pas toucher**.

## Pièges

- `startGame` fait `_game.copyWith(...)` et non `GameState(...)` : un champ non remis à zéro
  survit d'une partie à l'autre. Lancer en Classique doit **effacer** `fiesta`.
- `toJson` ne doit pas écrire `'fiesta': null` pour une partie Classique (critère 1). L'écrire
  ne casserait rien, mais grossirait chaque snapshot et brouillerait l'invariant « absent =
  Classique ».
- Un `cast<...>()` est paresseux (voir le commentaire de `game_result.dart:40-42`) : utiliser
  `whereType` pour les listes d'instances.
- Le catalogue est du **code**, pas de la donnée persistée : on ne stocke que des ids. Renommer un
  id plus tard casserait la relecture des parties en cours ; les ids sont donc figés ici.

## Tests (règle minimale)

- `test/models/game_state_test.dart` (ajouts) : critère 1 (blob legacy sans `fiesta`), critère 2
  (aller-retour), critère 3 (instance inconnue ignorée, `fiesta` non-objet → Classique).
- `test/models/fiesta/fiesta_catalog_test.dart` : critère 7 (symétrie, plafond de 2).
- Le critère 6 se vérifie dans un test provider existant si c'est bon marché
  (`test/providers/turn_time_test.dart` montre comment monter le provider) ; sinon, le
  laisser au gate ③.

## Recette device (Florent, Android + iOS)

1. Installer **la version en store**, lancer une partie Classique, jouer 2 tours, quitter l'app
   en plein milieu (tuer l'app).
2. Installer le build de cette branche par-dessus, rouvrir : la partie reprend, se termine, le
   score et l'historique sont corrects.
