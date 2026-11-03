# Revue r2 — story 2-2 « Fondation Fiesta » (reviewer Opus, adversarial)

Patch : `2-2-patch-r2.diff` (merge-base 51c0b78). Corrections lues dans `2-2-fix-r1.md` puis confrontées au
code. Les 3 fichiers de test ciblés passent : 20/20 verts. Arbre laissé intact : md5 des 6 fichiers source
vérifiés après chaque mutation, `git status` sans changement.

## Verdict : READY

Le MAJOR M-1 est corrigé et sa mutation survivante tombe désormais. `readOr` tient la règle 7 dans les deux
sens. Les correctifs n'introduisent ni BLOCKER ni MAJOR. Il reste 2 NIT.

---

## Vérification des corrections

### M-1 `canAdd` par équipe : corrigé
`modifier_instance.dart` `canAdd`. La charge d'une équipe vaut `forAll + perTeam[teamId]`, et une candidate
`both` est jugée sur `forAll + heaviest`. J'ai rejoué les arrangements à 3 et 4 équipes à la main :

| Actives | Candidate | Attendu | Résultat |
|---|---|---|---|
| `[A, B]` | `both` | autorisé | `true` |
| `[both, A]` | `both` | refusé (A passerait à 3) | `false` |
| `[both, A, A]` | `team C` | autorisé | `true` |
| `[no_pass@both]` | `two_words@B` | refusé (incompatible) | `false` |
| `[no_pass@A]` | `two_words@B` | autorisé (équipes disjointes) | `true` |

La compatibilité est contrôlée sur toutes les actives qui partagent une équipe avec la candidate, ce qui est
juste. Je n'ai trouvé aucun arrangement qui sur-compte ou qui laisse passer une incompatibilité. M8b et
quatre nouvelles mutations sur `canAdd` (N1 à N4) **tombent**.

### m-1 `readOr` : règle 7 tenue dans les deux sens
- **Clé absente → défaut.** Testé (`carryOver`, `catchUp.malCap`), et les mutations N6, N8 et N9 tombent.
- **Présente mais mal typée → `null`, donc partie Classique, sans exception.** Testé (`carryOver: 'oui'`), et
  N7 tombe.
- **Pas de crash.** Aucun cast dur n'a été ajouté : `readOr<Map>` puis `Map<String, dynamic>.from` sur des
  clés venant de `jsonDecode`.
- **`mode` reste bloquant.** Un `null` explicite est traité comme une clé absente, ce qui est acceptable.
- **Effet de bord accepté.** Un blob réduit à `{rules: {mode: 'auto'}}` se relit désormais en Fiesta Auto
  avec les valeurs par défaut. Ce n'est pas une corruption plausible : `jsonDecode` ne tronque pas des clés
  isolées.

### Autres corrections vérifiées
- **m-2** : `assert` dans le constructeur `const` (évalué à la compilation, OK) et rejet dans `tryFromJson`.
- **m-3** : le littéral legacy contient bien les 27 clés de `GameState.toJson()` au 51c0b78.
- **m-4** : la liste littérale des 11 ids est en place.
- **m-5, m-6, m-7** : les documents décrivent maintenant le code, ni plus ni moins.

### Résidus assumés : justifiés
- **m-8** (`turn` non typé) : c'est un choix de spec, et la recommandation est écrite pour les stories d'effets.
- **NIT `copyWith`, NIT M12, NIT bornes de `drawCount`** : sans enjeu pour 2-2. Les bornes appartiennent bien
  à l'éditeur (2-3) et à l'écran Auto (2-4).
- **N5** (rejet `teamId` dans `tryFromJson`) survit, faute de test. C'est acceptable : aucune version
  n'écrit d'instance aujourd'hui, et l'`assert` couvre le développement.

---

## NIT

### n-1 — Valeurs par défaut écrites deux fois
`fiesta_rules.dart`, appels `readOr` dans `FiestaRules.tryFromJson` et `ModifierSetting.tryFromJson`. Les
fallbacks recopient les défauts du constructeur (`true`, `false`, `1`, `0`). N10 (`startRound` → 0) et N11
(`drawCount` → 0) survivent. Aujourd'hui c'est sans effet, puisque rien n'est publié et qu'aucune clé ne
manque. Il faut retenir pour plus tard que le fallback doit garder la valeur **historique** si le défaut du
constructeur change. Aucune action demandée.

### n-2 — `ModifierInstance.tryFromJson` reste strict, sans `readOr`
Aucun champ n'y est optionnel aujourd'hui, donc c'est correct. La règle « champ ajouté = `readOr` » de
`lib/models/CLAUDE.md` vaut aussi pour ce type, et une story qui y ajoute un champ devra l'appliquer. La
formulation actuelle (générique) le couvre déjà.

---

## Mutations r2

| # | Mutation | Résultat |
|---|---|---|
| M8b | `concernsSameTeamAs` ignore `active.target == both` | tombé |
| N1 | plafond `<` → `<=` | tombé |
| N2 | `heaviest` → somme des équipes (comportement r1) | tombé |
| N3 | `forAll` ignoré | tombé |
| N4 | contrôle de compatibilité retiré | tombé |
| N5 | contrat `teamId` retiré de `tryFromJson` | survécu (résidu assumé) |
| N6 | `readOr` : absent → `null` | tombé |
| N7 | `readOr` : mal typé → fallback | tombé |
| N8 | fallback `malCap` faux | tombé |
| N9 | fallback `carryOver` faux | tombé |
| N10 | fallback `startRound` faux | survécu (n-1) |
| N11 | fallback `drawCount` faux | survécu (n-1) |
