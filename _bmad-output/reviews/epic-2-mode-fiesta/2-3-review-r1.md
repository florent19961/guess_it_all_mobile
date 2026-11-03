# Revue r1 : story 2-3 « Ensembles » (tier risqué ③)

Reviewer : Opus, adversarial, read-only. Entrées : `2-3-patch-r1.diff` (delta sur `feat/fiesta-2-2`),
`2-3-prompt-r1.md`, la story, l'epic (§ Mode Personnalisé, Q10, Q13, Q14), la maquette (écrans
`perso` / `edit`, `mkSet`). Le code a été lu avant la spec. L'arbre est rendu propre : `git status`
est vide après les mutations.

## Verdict : NOT READY (1 MAJOR, correctif court), sinon solide

Le service est correct sur tous les chemins que j'ai tracés :
- l'enveloppe est posée dès la 1re écriture ;
- les blobs corrompus et ceux venus du futur sont mis en quarantaine ;
- un ensemble illisible est ignoré seul ;
- la borne est tenue sous concurrence, et la file ne s'empoisonne pas ;
- une lecture en panne fait échouer la modification sans rien écrire ;
- le `lastUsedId` est effacé quand on supprime cet ensemble.

Une course `load()` / `_mutate` sur un blob corrompu ne peut pas effacer un blob fraîchement écrit :
`getString` → `remove` ne contient aucun `await` intermédiaire et le cache de `SharedPreferences`
est synchrone. La validation bloque chaque config impossible listée par la story et accepte le
défaut `mkSet`. Aucun `Platform.*`.

---

## MAJOR

### M1 : compatibilité ascendante. Un ensemble enregistré aujourd'hui peut être effacé en silence par une story future, et aucun test ne fige le format
- **Où** :
  - `lib/services/fiesta_ensemble_service.dart` : `_read`, `.whereType<FiestaEnsemble>()`, puis `_mutate` → `_write` ;
  - le format lui-même vient de `FiestaRules.tryFromJson` (2-2), où chaque champ est **obligatoire** (`symmetric is! bool … → null`).
- **Scénario** :
  1. Une story ultérieure ajoute un champ à `FiestaRules` en suivant le motif actuel (`x is! bool → return null`).
  2. Après la mise à jour forcée (`upgrader`), **tous** les ensembles écrits par cette version donnent `null`. Ils disparaissent de la liste, sans quarantaine et sans message.
  3. Au premier `create`, `markUsed` (« Utiliser ») ou `delete`, `_mutate` réécrit la clé avec la liste filtrée. Les ensembles de l'utilisateur sont alors **perdus définitivement**.

  Le même chemin efface aussi, dès aujourd'hui, un ensemble isolé illisible (et un réglage d'id inconnu) à la première modification. AC7 dit « ignoré », pas « supprimé à la prochaine écriture ». C'est acceptable pour un vrai déchet, pas pour un ensemble valide que le lecteur ne sait plus lire. `kCurrentSchemaVersion` ne protège rien ici : l'epic interdit de l'incrémenter pour Fiesta.
- **Correctif (le plus simple)** : un **test de format figé** dans `test/services/fiesta_ensemble_service_test.dart`. On y colle en dur une chaîne JSON littérale, telle qu'écrite par cette version (enveloppe + 1 ensemble complet + `lastUsedId`), et on vérifie qu'elle se relit en entier. Tout futur champ requis dans `FiestaRules.tryFromJson` fera tomber ce test au lieu d'effacer les données des joueurs. On ajoute une ligne dans le doc de `persisted_schema` ou dans `lib/services/CLAUDE.md` : « champ ajouté à `FiestaRules` = optionnel avec défaut à la lecture ».
- **Optionnel** : conserver les entrées brutes illisibles et les réécrire telles quelles dans `_write`. Cela coûte environ 6 lignes. Ce n'est pas exigé si le test figé est en place.

---

## MINOR

1. **Garanties d'AC sans test : les mutants survivent.** On peut casser ces comportements sans qu'un test tombe :
   - S7 : `delete` garde `lastUsedId` (AC6) ;
   - S8 : `update` ajoute en fin au lieu de remplacer sur place (AC4, même id / même position) ;
   - S13 : `duplicate` insère en fin au lieu de juste après l'original ;
   - S9 : `copyName` sans troncature (AC5).

   Tous se testent en logique pure du service, en environ 15 lignes au total. Ce sont des chemins de mutation d'une clé persistée en tier risqué. La règle des tests minimaux de la story ne les listait pas, d'où MINOR et pas MAJOR. Recommandé : un seul test « update sur place + delete efface lastUsed + copyName ».
2. **`copyName` peut produire un nom identique à l'original ou casser un emoji** (`fiesta_ensemble_service.dart`, `copyName`).
   - Un nom de 30 caractères donne une copie qui porte **exactement** le même nom : le suffixe disparaît entièrement.
   - Avec 23 à 29 caractères, on obtient « … (co ».
   - `substring` coupe en unités UTF-16 : un emoji en position 30 laisse un surrogate orphelin. Le `maxLength` de `AppInput` compte, lui, en graphèmes.

   C'est conforme à la lettre de Q13 (« tronqué à 30 »), mais le doublon est indiscernable. Proposition : tronquer **le nom de base** à `30 - 8` (en `characters`) puis ajouter « (copie) ». Sinon, documenter le cas.
3. **Rattrapage sans interrupteur, alors que la maquette en a un.** Dans `mkSet`, on a `ratt:{on:true,…}`, un switch « Rattrapage », et le résumé de la liste affiche « rattrapage / sans rattrapage ». L'interprétation 2 (« 5 curseurs ») suit le texte de la story, pas la maquette. Pour couper, il faut amener plusieurs curseurs à 0. Correctif sans changer de schéma : un switch d'interface. Off = tout à 0, on = `CatchUpRules.auto`, affiché « on » si un des 5 curseurs est > 0. Le résumé de la carte reprendrait aussi « sans rattrapage ». À arbitrer par Florent, sinon garder et le noter.
4. **Message trompeur quand l'écriture échoue** (`fiesta_ensemble_editor_screen.dart:97-103`). `create` rend `null` aussi quand la lecture est en panne, et l'écran affiche alors « Limite de 10 ensembles atteinte ». De même, `update` affiche « cet ensemble n'existe plus » pour toute panne. Proposition : un message neutre (« Enregistrement impossible, réessaie »), ou distinguer les deux cas. Le chemin « une lecture en panne n'écrase rien » est lui aussi non testé (mutant S10 survivant). Il est difficile à provoquer : je l'accepte sans test.
5. **Double tap sur « Utiliser »** (`fiesta_ensembles_screen.dart:57-60`). `onUse` peut être appelé deux fois, ce qui donne une double navigation dans 2-4. Proposition : un booléen `_busy`, ou documenter dans le contrat que l'appelant doit être idempotent.
6. **`lib/models/CLAUDE.md` n'est pas à jour** (règle 4, interprétation 7). Le report est justifié par la collision avec 2-2, mais rien ne le trace. Ajouter une ligne dans les notes de la story (ou dans la checklist du closeout) pour ne pas l'oublier au rebase sur `main`.
7. **Avalanche d'erreurs** (`ensemble_validation.dart`, branche `draw`). Couper le tirage sur le défaut produit 7 messages, un par malus tiré, dans une zone de 96 px. Proposition : un seul message agrégé par règle (« Tirage coupé : 7 modificateurs tirés pour tous ne sortiront jamais »). C'est de l'ergonomie : recette device.

## NIT
- `FiestaEnsemble.tryFromJson` accepte `mode: auto`. Un blob forgé passerait alors des règles Auto à `onUse`. Il suffit de rejeter `mode != custom`.
- Un `fixed` avec `fixedRound == null` (impossible par l'interface) échappe au contrôle d'incompatibilité. Pour un modificateur non « M3 seulement », il passe aussi la validation. On pourrait le refuser dans `validateEnsemble`.
- Les extensions `copyWith` sur des types de 2-2 ne savent pas remettre `fixedRound` à `null`. C'est sans effet aujourd'hui. À rapatrier dans `FiestaRules` / `ModifierSetting` après le merge de 2-2 (dette à noter).
- Retour système ou glissement iOS dans l'éditeur : les modifications non enregistrées sont perdues sans confirmation. La maquette ne dit rien sur ce point.

---

## Interprétations de la lane

| # | Interprétation | Avis |
|---|---|---|
| 1 | Nom seulement dans `rules.ensembleName` | **OK.** Une seule source, et le gel par `startGame` est trivial. |
| 2 | Rattrapage = 5 curseurs, tout à 0 = coupé | **Contredit la maquette** (switch `ratt.on`). Conforme au texte de la story. Voir MINOR 3. |
| 3 | Tirage pour tous = `symmetric && drawCount > 0` | **OK.** Identique à la maquette (`s.sym.on && s.sym.n>0`). Il est consigné dans `tracking_evolution` pour 2-5 : la story 2-5 doit lire les deux. |
| 4 | Modifications sérialisées, une lecture en panne fait échouer, `load` rend vide sans effacer | **OK.** C'est le seul moyen de tenir AC2 sous concurrence. La file ne s'empoisonne pas (`onError` avalé, `_mutate` catch). |
| 5 | `FiestaEnsemblesScreen(onBack, onUse)`, `onUse` après `markUsed` | **Sain et documenté** (`lib/screens/CLAUDE.md`, notes de la story). Seul le double tap manque (MINOR 5). |
| 6 | Manche verrouillée à 3 pour les modificateurs « M3 seulement » | **OK.** Identique à la maquette (`<b>3</b>`). La validation reste en filet. |
| 7 | `lib/models/CLAUDE.md` reporté | Acceptable si c'est tracé (MINOR 6). |

## Grille thermo-nucléaire (diff seulement)
- Rien de sur-dimensionné. La file `_serialized` (6 lignes) a une racine réelle (AC2 + écritures asynchrones), et son test la tue.
- `_Stepper` et `_Choices` locaux sont justifiés en commentaire (`AppCounter` trop grand, `AppToggle` limité à 2 options).
- Docs (`lib/services/CLAUDE.md`, `lib/screens/CLAUDE.md`, `tracking_evolution`, notes de la story) : elles décrivent fidèlement le diff, ni plus ni moins.

## Mutation testing (15 tests, `flutter test` des 2 fichiers)

| Mutant | Résultat |
|---|---|
| S1 `prefs.remove` retiré (quarantaine) | tombé |
| S2 `wrapWithSchema` retiré | tombé |
| S3 borne de `duplicate` retirée | tombé |
| S4 borne de `create` retirée | tombé |
| S5 file `_serialized` retirée | tombé |
| S6 un ensemble illisible fait échouer toute la lecture | tombé |
| S7 `delete` garde `lastUsedId` | **survécu** |
| S8 `update` ajoute au lieu de remplacer sur place | **survécu** |
| S9 `copyName` sans troncature | **survécu** |
| S10 lecture en panne → liste vide réécrite | **survécu** |
| S11 `markUsed` sans effet | tombé |
| S12 `lastUsedId` non écrit | tombé |
| S13 `duplicate` insère en fin | **survécu** |
| V1 règle du nom neutralisée / V2 `trim` retiré | tombé / tombé |
| V3 `drawOn` ignore `drawCount` / V4 ignore `symmetric` | tombé / tombé |
| V5 modificateurs inactifs jugés | tombé |
| V6 `offer` sans 1 parmi 3 neutralisée / V7 `offer` dès M1 neutralisée | tombé / tombé |
| V8 `round3Only` inversé / V9 M3 fixé neutralisé / V10 M3 démarrage neutralisé | tombé / tombé / tombé |
| V11 incompatibilités neutralisées / V12 incompatibilités sans tenir compte de la manche | tombé / tombé |

Côté validation, chaque test tue au moins un mutant : aucun n'est redondant ni cosmétique. Les tests
« tirage coupé » et « tirage à 0 » ne se recouvrent pas (V3 et V4). Côté service, les 4 survivants
correspondent tous à MINOR 1, plus S10 accepté (MINOR 4).
