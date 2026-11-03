# Revue r1 — story 2-5 (tirage symétrique, transition, annonces) — tier risqué ①

Reviewer : Opus, adversarial. Entrée : `2-5-patch-r1.diff` (delta sur `1061923`, contient
`symmetric_draw`). Code lu avant la spec. Lecture seule ; mutations appliquées puis annulées par
édition inverse (`git status` propre à la fin).

## Verdict : **NOT READY** — 0 BLOCKER, 1 MAJOR, 7 MINOR

Le cœur (tirage déterministe, plafond, incompatibilités, passage de manche, Classique) est
correct et bien testé. Le seul point bloquant pour le merge est le double tap sur
« Commencer le tour » pendant une révélation, qui déclenche un `startTurn()` hors séquence
(détail en MAJOR-1). Le correctif tient en 2 lignes.

---

## MAJOR

### MAJOR-1 — Double tap sur « Commencer le tour » : deux révélations empilées, puis `startTurn()` appelé en plein tour
`lib/screens/game_screen.dart` (`_startTurn`, patch `+264..+277`) + `lib/widgets/fiesta/malus_reveal.dart:25-43`

**Ce n'est pas cosmétique.** Le routage de l'app passe par `home: _buildCurrentScreen(currentScreen)`
(`lib/app.dart:48-53`). Les routes `MalusReveal` sont poussées sur le Navigator, **au-dessus** de
`home` : elles survivent au changement d'écran.

Scénario (1 malus, une équipe à son premier tour de la manche, tap doublé, ce qui arrive vite) :
1. Le tap 1 pousse R1, et le tap 2 arrive avant la frame suivante. `AppButton` n'a pas de garde
   (`onTap: widget.onPressed`), et pendant la transition de route l'écran en dessous reste
   touchable. Le tap 2 pousse donc R2 au-dessus.
2. « Compris » sur R2 : la chaîne 2 se termine et appelle `provider.startTurn()`, puis
   `currentScreen = countdown`. `home` passe sur `CountdownScreen`, **sous R1, qui reste affiché**.
3. Le compte à rebours tourne sans être vu, puis `startTurnTimer()` : le tour démarre, le chrono
   tourne et le premier mot est tracé (`_trackWordShown`, analytics ⑤), tout ça caché par R1.
4. « Compris » sur R1 : la chaîne 1 fait `provider.startTurn()` **sans aucune garde** (pas de
   `context.mounted`, pas de vérification de l'écran courant). Le tour est remis en compte à
   rebours. Avec `wordsGuessedThisTurn` et `passedWordsThisTurn` vidés, et
   `timeRemaining = turnBonusTime ?? turnDuration`, alors que `turnBonusTime` a déjà été effacé
   par `startTurnTimer`, une **continuation de fin de manche perd son temps bonus** (timer ⑥). Si
   R1 reste ouvert plus longtemps que la durée du tour, `endTurn` part sous la révélation, puis
   « Compris » renvoie de la vérification au compte à rebours sans validation. On sort de la
   machine à états (①).

Avec N malus, la chaîne 2 finit au N-ième « Compris ». Il reste alors N routes de la chaîne 1, et
c'est le même schéma. Sans malus (Classique, ou Fiesta sans malus), le double tap appelle deux
fois `startTurn()` de façon synchrone. C'est idempotent et déjà le cas aujourd'hui, donc pas de
régression.

**Correctif (minimal, aucun état ajouté) :**
```dart
Future<void> _startTurn(...) async {
  // Une révélation déjà poussée = la route du jeu n'est plus au sommet.
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
  final maluses = provider.malusToReveal;
  if (maluses.isNotEmpty) {
    await MalusReveal.showAll(...);
    if (!context.mounted ||
        provider.game.currentScreen != AppConstants.screenGame) return;
  }
  provider.startTurn();
}
```
`Navigator.push` met à jour l'historique de façon synchrone, donc `isCurrent` passe à `false`
dès le premier push. La garde après l'`await` couvre les cas restants : contexte démonté, ou
écran changé pendant la révélation. Validation sur device (Android + iOS) : un double tap rapide
doit donner une seule révélation.

---

## MINOR

### MINOR-1 — `fixedForRound` accepte un modificateur à cible joueur (`block_guesser`) comme « pour toutes les équipes »
`lib/models/fiesta/symmetric_draw.dart:45-60`. `drawSymmetric` exclut `defaultTarget != both`
(interprétation 3), mais pas `fixedForRound`. Un ensemble Personnalisé (2-3) qui met
`block_guesser` en « fixé sur M2 » produit une instance `target: both, scope: round`, ce qui n'a
pas de sens et contredit la règle posée juste en dessous. **Correctif :** appliquer le même filtre
`def.defaultTarget != ModifierTarget.both` dans `fixedForRound`, ou s'assurer que 2-3 interdit
« fixé » pour ce modificateur. Dans les deux cas, le dire au même endroit.
Le même angle mort existe pour un modificateur « manche 3 seulement » fixé sur M1/M2 : il est
ignoré en silence, alors que le Récap affiche « fixé sur M1 ». C'est à verrouiller dans l'UI de
2-3.

### MINOR-2 — Trous de test : 2 mutations survivent
Mutations jouées sur `symmetric_draw_test`, `fiesta_round_draw_test` et `fiesta_freeze_test` :

| Mutation | Résultat |
|---|---|
| `Random()` sans graine | tuée (test provider) |
| filtre `round3Only` retiré | tuée |
| instances de M1 gardées à `nextRound` | tuée |
| `canAdd` sans les fixés | tuée |
| `startRound` ignoré | tuée |
| **filtre `defaultTarget != both` retiré** (`block_guesser` tiré pour tous) | **survit** |
| **`malusToReveal` sans le test « déjà joué dans la manche »** | **survit** |

Le second survivant est le plus gênant : `malusToReveal` est de la logique d'état dérivée de
l'historique (continuations, retour arrière), sans aucun test. **Correctif :** dans le test
existant, ajouter `expect(ids(..).contains('block_guesser@..'), isFalse)` dans la boucle de
config (une ligne). Ajouter aussi un test provider : en Fiesta Personnalisé avec un malus fixé
sur M1, `malusToReveal` n'est pas vide avant le premier tour d'une équipe, puis vide après une
entrée d'historique à son nom dans la manche.

### MINOR-3 — `_fiestaForRound` concatène les survivants sans `canAdd`
`lib/providers/game_provider.dart` (patch `+1063..+1075`). Le tirage ne vérifie `canAdd` que
contre les fixés et contre lui-même, jamais contre les instances survivantes de `active`
(portée tour, interprétation 5). Aujourd'hui, rien d'autre n'écrit dans `active`, donc il n'y a
pas de bug. Mais dès 2-8 et 2-10, une instance survivante (ex. `free_pass` offert) plus
`no_pass` tiré violerait Q14, ou le plafond. **Correctif :** soit documenter l'invariant « aucune
instance de portée tour ne survit à un changement de manche » (2-8 la consomme à la fin du tour),
soit passer les survivants dans `alreadyFixed`. À trancher avant 2-8 et 2-10, pas forcément ici.

### MINOR-4 — Recalculer plutôt que stocker : sûr, à une réserve près (version de l'app)
Réponse à la question 1. Les entrées `(rules, gameId, round)` ne changent pas au sein d'une
partie : `rules` est gelé à `startGame` et seul `startGame` écrit `fiesta.rules`. `gameId` ne
bouge qu'à `startGame`, et le snapshot le restaure à l'identique. Le tirage ne dépend **ni** des
équipes, **ni** de leur ordre, **ni** de leur nombre (cible `both`, pas de paramètre `teams`).
L'ordre des candidats vient de `kModifierCatalog`, pas d'une Map relue. Retour arrière depuis la
transition, retour arrière depuis le jeu de M2 (le snapshot contient `fiesta.active` de M1, et
`_fiestaForRound` refait la même chose) et app tuée donnent donc le même tirage. Le test provider
le prouve pour le retour arrière et l'app tuée.

La réserve : l'aperçu est recalculé **par le code**. Si une mise à jour de l'app (`upgrader`
forcé) change `kModifierCatalog`, l'algorithme ou le `Random` de Dart entre la transition et
« Manche suivante », l'aperçu et le tirage appliqué divergent sans bruit. Le cas est rare (app
tuée + mise à jour sur la transition), mais réel.

Pour 2-10 : une fois posé par `nextRound`, `fiesta.active` **reste la source de vérité**. Les
badges, la révélation et le plafond lisent `active`, jamais un recalcul. Seul l'aperçu de la
transition est dérivé. Les offres de 2-10 devront être stockées, et elles le seront dans
`active` : pas de conflit. **Action :** une ligne dans `notes_pour_plus_tard.md` (signal
déclencheur : tout changement du catalogue ou de `drawSymmetric` = changement de forme
« logique » pour les parties en cours).

### MINOR-5 — `GameScreen` : en Fiesta, le bouton n'est plus collé en bas
`lib/screens/game_screen.dart` (patch `+197..+205`). La Column a déjà deux `Spacer` (flex 1). Le
`Flexible(flex: 3)` est lâche : il réserve 3/5 de l'espace libre mais n'en utilise que la hauteur
de son contenu. Le reste part **sous** le bouton (`MainAxisAlignment.start`), donc le bloc
remonte avec un vide en bas. C'est cosmétique et propre à Fiesta (Classique inchangé : garde
`isFiesta`). **Correctif :** `Flexible(flex: 3)` → `Flexible(flex: 1)`, ou les annonces dans un
`Expanded` avec un `Align(alignment: Alignment.bottomCenter)` à la place du second `Spacer`. À
voir sur device.

### MINOR-6 — `MalusReveal` ne défile pas
`lib/widgets/fiesta/malus_reveal.dart:49-128`. La `Column` est centrée sans `SingleChildScrollView`
(icône 96 + titre 34 pt + description + encart + bouton). Sur un iPhone SE ou un petit Android
avec une grande taille de texte d'accessibilité, ça déborde (bandes jaunes), et « Compris »
risque de sortir de l'écran. **Correctif :** envelopper dans
`SingleChildScrollView` + `ConstrainedBox(minHeight)`, ou simplement `Center(child:
SingleChildScrollView(...))`.

### MINOR-7 — Thermo-nuclear (limité au diff)
- `game_provider.dart` : +62 lignes, ciblées (1 ligne `startGame`, 1 ligne `nextRound`,
  `_fiestaForRound` + 3 getters). Pas de `if` éparpillé dans les flux existants. Le fichier
  dépassait déjà 1k lignes (1445 → 1507). Coup de « judo » possible : `_fiestaForRound` est une
  pure transformation de `FiestaState`. Ce serait mieux en
  `FiestaState.enterRound(round, gameId:)` dans `lib/models/fiesta/`, à côté de `roundModifiers`,
  ce qui garderait le provider fin et rendrait la transition testable sans provider. Optionnel.
- `symmetric_draw.dart` : fonctions pures, lisibles. `isSymmetricDrawOn` est utile (définition
  partagée). Rien à retirer.
- `transition_screen.dart` : `.map<Widget>(...).followedBy([...]).toList()` est un peu tordu ;
  un `children: [...sortedTeams...map(...), if (!isLastRound) RoundDrawCard(...)]` est plus
  direct. NIT.

---

## Réponses aux points de la commande

1. **Déterminisme** : prouvé, voir MINOR-4. Aucun chemin intra-partie ne fait varier les entrées.
   La seule dérive possible est une mise à jour de l'app entre l'aperçu et l'application.
   `active` persisté reste la source de vérité.
2. **Plafond et compatibilité** : les fixés passent d'abord, et `canAdd` couvre le plafond et
   Q14. `concernsSameTeamAs` rend `both` commun à toutes les équipes, donc `canAdd` s'applique
   bien par équipe. `round3Only` est exclu en M1/M2 (mutation tuée). `block_guesser` n'est jamais
   tiré (catalogue : `defaultTarget: player`), mais il peut être fixé (MINOR-1). En Personnalisé,
   le tirage est allumé ssi `symmetric && drawCount > 0`. En Auto, le tirage repose sur
   `drawCount = 1` par défaut, ce que `fiesta_auto_screen.dart` ne change pas : OK. 3 fixés sur
   la même manche : au plus 2 gardés (`canAdd`), dans l'ordre du catalogue. Fixés incompatibles :
   le second est ignoré. Résultat sûr.
3. **`nextRound`** : retire `scope == round && round < N+1` et ajoute le tirage de N+1 (mutation
   tuée). Le snapshot restaure `fiesta.active` de la manche N. OK.
4. **Classique** : `copyWith(fiesta: null)` garde `null` (`game_state.dart:251`). La transition
   ajoute un `SizedBox.shrink`. Le jeu est gardé par `isFiesta`, et `turn_screen` retombe sur le
   même `SizedBox(height: 32)`. `_startTurn` appelle `startTurn()` de façon synchrone quand il n'y
   a pas de malus. Aucun changement de comportement.
5. **Révélation** : correcte après un retour arrière (l'historique est restauré), après une app
   tuée (dérivée, ré-affichée si l'app est tuée avant le compte à rebours) et en continuation (la
   continuation de début de manche n'a pas d'entrée dans la nouvelle manche, donc révélation ;
   son entrée `isBonusContinuation` porte le `teamId` de l'équipe, donc plus de révélation
   ensuite). Le double tap est **MAJOR** (MAJOR-1). Retour système Android = « Compris » (voulu
   par la doc). Pas de geste de retour iOS sur un `fullscreenDialog`.
6. **`fiesta_freeze_test`** : changement légitime. `active` contient désormais le tirage de M1
   (`no_pass`, seul « tiré pour tous », `drawCount` = 1 par défaut). La preuve du gel reste portée
   par l'assertion sur `rules.modifiers.keys`.
7. **Mutations** : 5/7 tuées, voir MINOR-2. Thermo-nuclear : MINOR-7.
8. **Petits écrans** : jeu OK (`Flexible` + défilement, mais voir MINOR-5). Transition : carte
   dans la zone défilante, OK. Tour : les badges sont dans la `Column` au-dessus du mot, qui est
   `Flexible`, donc ils ne le masquent pas (ils réduisent sa place, au plus 2 badges + 1). Pas
   d'aléatoire dans `build` (`currentTeamModifiers` est un simple filtre). Révélation : MINOR-6.
   Pas de `dart:io` et pas de code spécifique à une plateforme.

**Hors périmètre (déjà présent avant la story, pour mémoire)** : un double tap sur
« Manche suivante » appelle `nextRound()` deux fois, donc M1 → M3. C'était déjà le cas ; avec
Fiesta, le tirage de M2 serait sauté. À noter dans `notes_pour_plus_tard.md` si ce n'est pas
déjà fait.
