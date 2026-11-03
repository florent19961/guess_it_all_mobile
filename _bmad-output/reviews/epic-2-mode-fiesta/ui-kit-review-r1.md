# Revue r1 — lane « kit visuel Fiesta » (tier standard)

Reviewer : Opus, adversarial. Entrée : `ui-kit-patch-r1.diff` (contient `TwoWordsLayout`).
Lu dans l'ordre : le code, puis les specs 2-8 / 2-11 et le prompt de lane.

## Verdict : **NOT READY** (aucun BLOCKER ; 1 MAJOR à corriger avant merge, une ligne par carte)

Le MAJOR est petit et retire une racine (le reverrouillage parasite) au lieu d'ajouter du code. Si
la lane le corrige, la r2 n'a pas besoin d'une nouvelle revue complète : un contrôle du diff suffit.

## Vérifications faites

- `scripts/with-test-slot.sh flutter test test/utils/reversed_word_test.dart` : vert.
- Mutation : `characters.toList()` → `split('')` dans `lib/utils/reversed_word.dart:9`. Le test
  devient **rouge** (`Expected 'EPÉRC'`, `Actual 'EṔERC'`). Mutation annulée, `git status` propre.
  Le cas « Crépe » est bien écrit en forme décomposée (U+0301 dans le source et dans l'attendu).
- Les doublons dans le pool : `words_screen.dart:123-146` refuse les doublons à la saisie, sans
  tenir compte de la casse (« Mot déjà pris par un autre joueur », « Doublon »).
- Pas de `Platform.*` dans le diff. Les couleurs viennent de `AppColors` et `AppTextStyles`, et la
  police est Bangers, comme le mot de `turn_screen.dart:326-348`.

## Points demandés

1. **Inversion** : correcte. `toUpperCase()` avant le découpage, donc « ß » → « SS » n'a aucun
   effet sur les graphèmes. `characters` découpe en grappes étendues : accents combinés, emoji ZWJ
   et drapeaux restent entiers. Les mots composés sont inversés en entier (« SRAW RATS »). La
   mutation montre que le test protège vraiment ce comportement.
2. **Verrou** : correct. `_locked` lit `_entry.isAnimating` **au moment du tap**, pas au build : un
   callback capturé avant le changement est donc bien bloqué. `InkWell.onTap` part au relâchement,
   donc un appui commencé avant le changement de mot et relâché après est aussi ignoré. Le verrou
   ne peut pas rester bloqué. Le contrôleur est libéré dans `dispose`. `forward(from: 0)` relance
   l'animation si les changements s'enchaînent. Un rebuild avec le même mot ne verrouille pas. Si
   la page est cachée (TickerMode coupé, app en arrière-plan), le ticker termine dès la frame
   suivante. Aucun chemin ne laisse `isAnimating` vrai pour toujours.
3. **Clé** : le raisonnement « pas de `ValueKey(word)` à cause des doublons » ne tient pas. Voir
   MAJOR-1.
4. **`null` = désactivé** : vrai (`_locked(null)` → `null` → `_CardButton` gris, `InkWell` sans
   `onTap`). Les widgets ne contiennent aucune logique de jeu : ils ne calculent ni pénalité, ni
   tirage, ni score.
5. **Thème et plateformes** : cohérents. Le petit écran n'est pas vérifiable depuis WSL. Voir
   MINOR-3 : à mettre dans la recette device.
6. **Branchement** : `TwoWordsLayout` se branche simplement pour 2-11. Pour 2-8, voir MINOR-1.
   Nom de la fonction : voir MINOR-2. Il faut **corriger la spec**, pas le code.
7. **Tests et grille thermo-nucléaire** : voir la section « Qualité » plus bas.

## BLOCKER

Aucun.

## MAJOR

### MAJOR-1 — `TwoWordsLayout` : la carte B qui passe en position A se reverrouille et avale un tap légitime

`lib/widgets/fiesta/fiesta_turn_widgets.dart:236-258` (les deux `FiestaWordCard` de
`TwoWordsLayout.build`)

Le pool ne contient plus que A et B, et A est trouvé. L'appelant envoie alors
`firstWord: B, secondWord: null`. Comme les cartes sont identifiées par leur position,
l'emplacement 0 voit son mot passer de A à B (`didUpdateWidget`). La carte que le joueur regardait
déjà se ré-anime, et ses taps sont ignorés pendant 300 ms. Or la recette 2-11 n°1 dit « trouver les
deux d'affilée » : c'est justement le geste rapide qui se fait avaler sur le dernier couple de la
manche. Le critère 9 vise à protéger une carte **qui vient d'arriver**, pas une carte déjà affichée.

L'argument « pas de `ValueKey(word)`, le pool peut contenir des doublons » ne s'applique pas ici :

- une clé doit seulement être unique **entre cartes sœurs**. 2-11 impose que la carte de
  remplacement soit différente de l'autre carte (critère 2), donc A ≠ B à tout instant ;
- de toute façon, `words_screen.dart:123-146` refuse déjà les doublons à la saisie.

**Correctif** (une ligne par carte, et ça supprime la conséquence « assumée ») : dans
`TwoWordsLayout`, passer `key: ValueKey(firstWord)` à la première carte et `key: ValueKey(second)`
à la seconde. Résultat :

- A remplacé par C : nouvelle clé, nouvel état, animation et verrou. C'est le comportement voulu.
- B qui passe seul : Flutter retrouve l'état de B par sa clé. Pas de ré-animation, pas de verrou.

Il faut alors corriger la puce 2 des « Interprétations » dans `lib/widgets/CLAUDE.md`.
`FiestaWordCard` utilisée seule n'a pas besoin de clé : elle garde `didUpdateWidget`.

Il n'est pas utile de demander à l'appelant un « index d'emplacement + compteur de changements ».
La position sert déjà d'index, et le compteur ne couvrirait qu'un cas impossible : un mot remplacé
par une chaîne identique.

## MINOR

### MINOR-1 — `lib/widgets/CLAUDE.md` (diff l.+20) : « `FiestaWordCard` branchée par 2-8 » contredit la spec 2-8

La spec 2-8 limite l'effet `reversed` à `turn_screen.dart:330` (« uniquement »). Le tour à un seul
mot garde son rendu actuel : texte blanc avec ombre rose, boutons Passer rouge et Trouvé cyan.
Brancher `FiestaWordCard` dans 2-8 changerait tout le rendu du tour Fiesta et ajouterait le verrou
de 300 ms à chaque mot. Aucune spec ne demande ça.

**Correctif** : dans le tableau, mettre la colonne « Branché par » de `FiestaWordCard` à
**« 2-11 »**. Ajouter une ligne : « 2-8 n'utilise que `reversedWordDisplay` ». Si on veut au
contraire le style « carte » pour tout le tour Fiesta, c'est une décision produit à trancher
ailleurs, pas dans cette lane.

### MINOR-2 — Nom : spec `reverseForDisplay` contre code `reversedWordDisplay`

`_bmad-output/specs/fiesta/2-8-effets-de-tour-catalogue.md:88`, et
`lib/utils/reversed_word.dart:8`.

**Corriger la spec**, pas le code. Le nom du code vient de la consigne de lane, il est déjà
documenté dans `lib/utils/CLAUDE.md`, et le test l'utilise. Dans la spec, le nom n'apparaît qu'une
fois (section Tests). Le test exigé par la spec existe déjà : 2-8 n'a plus de test pur à écrire.
Il faut le lui signaler.

### MINOR-3 — Petit écran et grande taille de texte : les cartes ne peuvent pas rétrécir en hauteur

`lib/widgets/fiesta/fiesta_turn_widgets.dart:93-148` et `:228-260`

Toutes les `Column` sont en `mainAxisSize.min`, et `AutoSizeText` n'est pas dans un `Flexible`. Le
mot ne s'ajuste donc qu'à la **largeur**. Deux cartes font environ 380-400 px de haut à l'échelle 1,
et les boutons grandissent avec la taille de texte du système. Sur un iPhone SE avec le chrono
(Bangers 64) et les badges, ça risque de déborder (recette 2-11 n°6).

**Correctif minimal** : ne rien changer maintenant, mais l'écrire dans la story 2-11. Sur
`turn_screen`, placer `TwoWordsLayout` dans un `Flexible` / `SingleChildScrollView` et vérifier
le rendu sur iPhone SE et un petit Android, avec la taille de texte système au maximum. Si ça
déborde, envelopper le `Padding` du mot (l.110) dans un `Flexible`, et chaque carte dans un
`Flexible` dans `TwoWordsLayout`.

Note : `wrapWords: false` + `maxLines: 2` + `minFontSize: 24` affiche une ellipse sur un mot très
long à l'envers (« ELLENNOITUTITSNOC… »). C'est le même compromis que `turn_screen.dart:344-347`.
On l'accepte.

### MINOR-4 — `CurvedAnimation` jamais libérée, `Tween.animate` recréé à chaque build

`lib/widgets/fiesta/fiesta_turn_widgets.dart:56-57`, `:83-85`

`CurvedAnimation` a un `dispose()` (elle s'abonne au parent) : le leak tracker de `flutter_test` le
signalera dès que 2-11 écrira un widget test. Les deux `Tween(...).animate(_curve)` créent de
nouvelles animations à chaque build.

**Correctif** : ajouter `_curve.dispose()` dans `dispose`. Optionnel : déclarer
`late final _opacity` et `late final _scale` à côté de `_curve`.

### MINOR-5 — Pendant le verrou, l'`InkWell` affiche quand même son effet d'appui

`lib/widgets/fiesta/fiesta_turn_widgets.dart:171-173`

Un tap ignoré produit quand même l'effet visuel d'appui. Le joueur croit l'avoir validé. C'est la
décision n°3 de la lane : les boutons gardent leur apparence active pendant le verrou. On ne la
rouvre pas, mais c'est à vérifier à la recette. Si ça gêne, passer
`onTap: _entry.isAnimating ? null : …` à l'intérieur d'un `AnimatedBuilder`, ou bien
`IgnorePointer(ignoring: _entry.isAnimating)`, ce qui remplace aussi le wrapper `_locked`.

## Qualité (grille thermo-nucléaire, limitée au diff)

- Taille : 306 + 9 lignes, trois widgets cohérents dans un fichier. Pas de seuil franchi.
- Simplification de fond : MAJOR-1 en est une. Une clé remplace une « conséquence assumée »
  documentée, et le paragraphe correspondant du CLAUDE.md disparaît.
- `label` / `fontSize` de `FiestaWordCard` ne servent qu'à `TwoWordsLayout`. C'est acceptable :
  ce sont des données d'affichage, sans mode ni booléen de comportement.
- `MimeConstraintBanner.icons` reprend une information du catalogue : les ids acceptés sont
  exactement les `round3Only`. On peut le garder (il faut bien associer un id à une icône), mais un
  commentaire « = les `round3Only` du catalogue » éviterait que les deux divergent. Le constructeur
  ne peut pas être `const` à cause de l'`assert` sur une `Map`. C'est sans conséquence.
- Tests : un test pur, à forte valeur, tué par la mutation la plus probable. Le décalage de longueur
  de « ß » ne justifie pas d'ajouter un cas. Aucun widget test, conformément à la décision de lane
  et à la spec 2-11 (« Pas de widget test pour l'animation »). Le verrou n'est donc couvert que
  par la recette device. On l'accepte, parce qu'il ne touche à aucune donnée persistée.
