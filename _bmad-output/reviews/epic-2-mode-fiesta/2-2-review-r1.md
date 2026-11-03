# Revue r1 — story 2-2 « Fondation Fiesta » (reviewer Opus, adversarial)

Patch : `2-2-patch-r1.diff` (merge-base 51c0b78, contient `class FiestaState`). Code lu avant la spec.
Tests ciblés exécutés via `scripts/with-test-slot.sh` ; baseline des 3 fichiers : 17/17 verts.
Arbre laissé intact (md5 des 6 fichiers source vérifiés après chaque mutation, `git status` propre).

## Verdict : NOT READY

Un seul MAJOR, mais il porte sur un livrable explicite de l'AC7 (`canAdd`). Le correctif est petit.
Les règles 7 et 8 sont respectées, `kCurrentSchemaVersion` est intact (à juste titre) et le gel est correct.

---

## MAJOR

### M-1 — `canAdd` compte « par candidate », pas « par équipe » : une candidate `both` est refusée alors qu'aucune équipe n'atteint le plafond
`lib/models/fiesta/modifier_instance.dart` (patch l.599-607), avec `concernsSameTeamAs` (l.540-545).

`sameTeam = active.where(candidate.concernsSameTeamAs)` additionne toutes les instances qui touchent
*au moins une* des équipes de la candidate. Pour une candidate `both`, ça fait la somme sur toutes les
équipes, alors que le plafond de l'epic est « **2 modificateurs actifs au maximum par équipe et par tour** »
(epic l.98, Q8).

**Reproduit** (sonde temporaire, depuis supprimée) : `active = [reversed@team A, minus_10s@team B]`,
`canAdd(active, two_words@both)` renvoie `false`. Or A et B passeraient chacune à 2 : c'est autorisé. Le code
refuse donc une **2ᵉ** instance, pas une 3ᵉ. Avec 3 ou 4 équipes qui ont chacune une offre ou un cadeau, tout
tirage « pour tous » ultérieur est bloqué. Q8 ordonne bien « tirage symétrique d'abord », mais une charge ou
un `fixed` en Personnalisé peut arriver après. 2-5, 2-9 et 2-10 appelleront cette fonction telle quelle.

**Trou de test associé** : la mutation M8b (dans `concernsSameTeamAs`, ne plus regarder
`other.target == both`, c'est-à-dire le cas « l'instance *active* est pour tous ») **survit**. Le cas
« un tirage pour tous est actif, on propose à l'équipe B un modificateur incompatible » n'est pas testé.

**Correctif proposé** : raisonner par équipe concernée. Pour une candidate `team`/`player`, compter les actives
qui touchent son `teamId`. Pour une candidate `both`, vérifier le plafond et la compatibilité **pour chaque
équipe** (la fonction doit alors recevoir les ids d'équipes, ou bien on borne : « max sur les équipes de la
somme `both` + spécifiques à l'équipe »). Ajouter deux cas au test `canAdd` : `[A1, B1] + both → true`, et
`[no_pass@both] + two_words@team B → false`. Ce second cas tue M8b.

---

## MINOR

### m-1 — `FiestaRules.tryFromJson` strict : tout champ ajouté plus tard fait perdre la Fiesta des données déjà écrites
`fiesta_rules.dart` (patch l.230-252). Sonde : retirer `carryOver` du JSON donne `tryFromJson → null`.
Aujourd'hui sans risque, car rien n'est publié (publication désactivée jusqu'à la 1ʳᵉ release post-Fiesta).
Après cette release, en revanche, une story qui ajoute un champ à `FiestaRules` aurait deux effets. Toute
partie Fiesta en cours au moment de la mise à jour reprendrait **silencieusement en Classique**, ce qui n'est
pas « invalidée proprement » au sens de la règle 7. Et si 2-3 réutilise ce `tryFromJson` pour les ensembles
enregistrés, ils disparaîtraient. **Proposé** : écrire dès maintenant, dans `lib/models/CLAUDE.md`, la règle
« un champ ajouté après la 1ʳᵉ release Fiesta se lit *clé absente = défaut documenté* ; seule une valeur
présente et mal typée invalide ». C'est de la migration, pas une « valeur inventée ».

### m-2 — Contrat `teamId` non posé pour les cibles `team` / `player`
`modifier_instance.dart` l.540-545 : `teamId == other.teamId` vaut `true` pour `null == null`. Une instance
`block_guesser` (cible `player`) construite avec seulement `playerId` serait comptée dans « la même équipe »
que toute autre instance sans `teamId`, et jamais dans celle de son vrai joueur. **Proposé** : documenter, ou
`assert`, que `target != both` implique `teamId != null`.

### m-3 — Le test « blob legacy » ne fige pas le blob de la version en store
`test/models/game_state_test.dart` (patch l.854-866). Le « legacy » est fabriqué par le `toJson()` **courant** ;
`..remove('fiesta')` ne fait rien et la 3ᵉ assertion est redondante avec `equals`. Le test tue bien la mutation
« écrire `fiesta: null` » (M3), mais il ne détecterait aucune autre dérive du blob Classique, par exemple une
clé renommée. **Proposé** : un littéral JSON figé (forme de la version en store), retirer `remove` et
l'assertion redondante.

### m-4 — « Ids figés » n'est gardé par aucun test
`fiesta_catalog_test.dart` l.744-756 vérifie 11 ids uniques, pas *lesquels*. Renommer `no_pass` laisse le test
vert. **Proposé** : remplacer le compte par l'égalité avec la liste littérale des 11 ids. C'est le seul test du
catalogue qui protège une garantie de persistance.

### m-5 — `docs/tracking_evolution.md` contredit le code sur `nature`
Patch l.28-29 : « nom, description et **nature** se relisent depuis le code courant ». Or `ModifierInstance`
**persiste** `nature` (exigé par la spec), et un `nature` illisible fait tomber l'instance. **Proposé** :
corriger la phrase (seuls nom et description), ou expliquer pourquoi `nature` est dupliquée.

### m-6 — `lib/providers/CLAUDE.md` non mis à jour (règle 4)
`startGame({FiestaRules? fiesta})` et le getter `isFiesta` n'y figurent pas (l.14 liste `startGame` sans
nuance). Ajouter une ligne : « `startGame(fiesta:)` gèle, `startGame()` efface ».

### m-7 — Piège pour 2-3 / 2-4 : le seul appelant relance en Classique
`teams_screen.dart:79` appelle `provider.startGame()` sans argument. `goBackToTeams` conserve `fiesta`, mais
relancer depuis l'écran équipes **l'efface**. Correct pour 2-2. Pour la story qui branchera l'UI, en revanche,
la config doit vivre côté écran ou provider, pas seulement dans `_game.fiesta`. À noter dans la story 2-3 ou
2-4, ou dans `lib/models/CLAUDE.md`.

### m-8 — `turn: Map<String, dynamic>`, un sac non typé dans un schéma persisté
`fiesta_state.dart` l.302-316, l.339-344. Ce choix vient de la spec (« sous-objet vide »), donc ce n'est pas un
défaut d'implémentation. Mais la copie n'est profonde que d'un niveau, rien n'est validé à la relecture, et
chaque story devra revalider ses clés à la main, à l'opposé de la discipline `tryFromJson` du reste. Pour 2-3
et suivantes, mieux vaut un petit type par compteur (ou des champs typés dans `FiestaState`) qu'enrichir la map.

---

## NIT

- `FiestaState` et `ModifierInstance` n'ont pas de `copyWith`, alors que la convention du module en exige un.
  Ne pas l'ajouter de façon spéculative : la story qui décrémente des charges l'ajoutera.
- `fiesta_freeze_test.dart` l.984 : `expect(active, isEmpty)` est cosmétique.
- La mutation M12 (retirer `List.unmodifiable(active)`) survit. C'est sans enjeu aujourd'hui ; pas de test à ajouter.
- Ni `drawCount ∈ [0, 2]` ni « au moins un interrupteur Auto allumé » ne sont validés à la relecture. C'est à
  porter par l'écran de config (2-3), pas ici.

---

## Points vérifiés OK

- **Règle 7** : le blob Classique est identique octet pour octet (clé `fiesta` ajoutée en queue et seulement si
  non nulle, ordre des clés inchangé). Un blob sans `fiesta` se relit en `fiesta == null`. `fiesta` non-objet,
  `{}` ou règles illisibles donnent une partie Classique sans exception.
- **`kCurrentSchemaVersion` = 1, intact, et c'est juste** : l'ajout est une clé optionnelle. Une app plus
  ancienne ignorerait la clé (reprise en Classique), ce qui est acceptable sous `upgrader` forcé.
- **Aller-retour réel** (sonde `jsonEncode`/`jsonDecode`, y compris un snapshot de retour arrière imbriqué après
  un kill) : identique, et `snapshot['game']` reste `Map<String, dynamic>`, donc le garde de
  `restorePreValidationState` passe.
- **Chemins de mutation de `_game`** : tous les `copyWith` conservent `fiesta`. `startGame` l'efface ou le pose.
  Les 5 `GameState.initial()` le remettent à nul. `restorePreValidationState` le restaure depuis le snapshot.
  `goBackToTeams` le garde (voir m-7). `_withClock` le garde.
- **Plateformes** : aucun `Platform.*` ni `dart:io` dans le diff (règle 8 OK).
- `cast` paresseux évité (`whereType`), conformément au piège de la spec.

## Mutations tentées

| # | Mutation | Résultat |
|---|----------|----------|
| M1 | `Map.unmodifiable` retiré de `FiestaRules` | tombé |
| M2 | `clearFiesta: fiesta == null` retiré de `startGame` | tombé |
| M3 | écrire toujours `'fiesta': fiesta?.toJson()` | tombé |
| M4 | `whereType<Map>` → `cast<Map>` | tombé |
| M5 | `areCompatible` dans un seul sens | tombé |
| M6 | `canAdd` `>=` → `>` | tombé |
| M7 | `canAdd` sans contrôle d'incompatibilité | tombé |
| M8 | `concernsSameTeamAs` ignore `candidate.target == both` | tombé |
| **M8b** | `concernsSameTeamAs` ignore `active.target == both` | **survécu** (voir M-1) |
| M9 | `ModifierInstance.tryFromJson` accepte un id inconnu | tombé |
| M10 | `FiestaRules.tryFromJson` accepte un réglage d'id inconnu | tombé |
| M11 | `restorePreValidationState` avec `clearFiesta: true` | tombé |
| M12 | `FiestaState.active` non `unmodifiable` | survécu (NIT) |
| M13 | règles illisibles → Fiesta par défaut au lieu de Classique | tombé |
| M14 | `ensembleName` perdu à la relecture | tombé |
