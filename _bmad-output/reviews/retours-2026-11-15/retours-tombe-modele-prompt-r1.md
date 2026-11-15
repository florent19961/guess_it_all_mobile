# Revue r1 — L-TOMBE-MODÈLE (`feat/retours-tombe-modele`) — tier RISQUÉ (forme persistée des ensembles ③)

Lecture seule. Lis le patch `_bmad-output/reviews/retours-2026-11-15/retours-tombe-modele-patch-r1.diff` (pas
`git diff`), puis le code autour dans le worktree `/home/florent19961/guess-it-all-retours-tombe-modele`. Spec :
section **D4** et en-tête de `_bmad-output/specs/fiesta/retours-2026-11-15.md`. `CLAUDE.md` racine et
`lib/models/CLAUDE.md` priment.

## Objectif (D4, partie modèle et éditeur SEULEMENT)
Le branchement en partie (`game_provider.dart`, avant-tour, « Ce qui t'attend », `FiestaTurnState`, analytics) est
hors périmètre : une autre lane tient ces fichiers. `dropForTurn` n'a aucun appelant de production ici.
- Nouveau champ `FiestaRules.dropFrequency` (enum `DropFrequency` : Jamais / Rarement / Parfois / Souvent ; chances
  nommées 1/6, 1/4, 1/2), défaut Jamais, clé omise à Jamais, absente = Jamais, `format` inchangé (4), hors bornes →
  règles illisibles.
- `settingsKey`, `hasActiveSetting`, résumé / pastilles / page « Voir » (`randomCartridgeLines`), icône
  (`rulesHaveCartridges`), aucun ensemble fourni ne change.
- Éditeur, onglet Cartouches, cadre « Au hasard », sous « À tous, à chaque manche », après un séparateur : ligne
  « Qui tombent pendant les tours » + ⓘ + sous-titre + sélecteur 4 crans ; compteur d'onglet +1 hors Jamais.
- Fonction pure `dropForTurn` (`lib/models/fiesta/cartridge_drop.dart`) : déterministe par graine, null à Jamais et
  en continuation ; vivier `dropPool` = `giftPool` moins identique/incompatible avec un malus reçu qui joue ce tour,
  identique à un bonus armé ; `block_guesser` seulement si l'équipe a ≥ 3 joueurs, devineur bloqué tiré parmi les
  devineurs ; `block_giver` permis.

## Choix d'implémentation à juger
1. Persistance par **index** de l'enum (`_readCount(..., max: values.length - 1)`), pas par nom : même régime que les
   compteurs, ordre des crans déclaré figé. Acceptable vis-à-vis de la règle 7 ?
2. `dropPool` réutilise `giftPool` avec `teamId: ''` et `blockableTeamIds: {'*'}` pour neutraliser son filtre
   `block_guesser` (« une AUTRE équipe peut le recevoir »), puis applique le filtre propre aux drops (≥ 2 devineurs).
   Pour ne pas changer la signature de `giftPool` (3 appels dans `game_provider.dart`, interdit). Lisible / fragile ?
3. Bonus armés : exclusion des **identiques** seulement (la spec ne dit pas « incompatible » pour eux).
4. Une seule `Random(dropSeed)` : chance, puis cartouche, puis devineur bloqué. Graine
   `drawSeed('$gameId#drop#$giverId', turnIndex)`.
5. `hasActiveSetting` : le réglage seul suffit à enregistrer un ensemble (il change des tours). `_firstTab` de
   l'éditeur ouvre Cartouches si le réglage est actif.
6. Texte d'aide de l'onglet Cartouches complété (`help_content.dart`).

## Points précis à vérifier
- Relecture : blob SANS la clé (dont `frozenBlob` de `test/services/fiesta_ensemble_service_test.dart`, inchangé) →
  Jamais ; `GameSetupSnapshot` et règles gelées passent bien par `FiestaRules.toJson/tryFromJson` (aucun autre
  sérialiseur oublié).
- `settingsKey` d'un ensemble existant inchangé à Jamais (pas de faux doublon / faux non-doublon).
- `dropForTurn` : aucune `Random()` sans graine ; null en continuation et à Jamais AVANT tout tirage ; vivier dans
  l'ordre du catalogue ; exclusions de la spec D4 toutes présentes (Toujours et tirée de la manche, malus reçu
  identique/incompatible, bonus armé identique, manche, ×2 sous `kDoublePointsMinGap`, `block_guesser` < 3 joueurs).
- Le contrat écrit dans `lib/models/CLAUDE.md` suffit-il à la lane de branchement (entrées attendues, moment d'appel,
  stockage éventuel dans `FiestaTurnState`) ?
- Éditeur : rendu à 360 px de large (4 libellés dans le sélecteur), compteur de l'onglet, rien d'autre de bougé.
- **Mutation testing obligatoire** sur `test/models/fiesta/cartridge_drop_test.dart` et l'assertion ajoutée au test
  `frozenBlob`. Mutations suggérées : clé émise à Jamais ; `max` de `_readCount` 3 → 4 ; `received` sans
  `areCompatible` ; `armed` retiré ; `guesserIds.length >= 2` → `>= 1` ; continuation ignorée ; graine sans
  `giverId` ; `blockedPlayerId` tiré hors des devineurs ; `chance <= 0` retiré ; seuil du ×2.
- Valeur des tests : redondance avec `cartridge_gifts_test.dart` (filtres de `giftPool` déjà couverts) ?

## Format attendu du rapport
Verdict **READY / NOT READY**, puis findings classés **BLOCKER / MAJOR / MINOR**, chacun avec `fichier:ligne`,
l'affirmation, la preuve et la correction proposée. Section dédiée aux résultats du mutation testing
(mutation → test qui la tue, ou survivante).
