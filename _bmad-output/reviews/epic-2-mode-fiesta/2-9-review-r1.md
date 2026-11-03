# Revue r1 — story 2-9 « Mot compte double »

**Verdict : NOT READY**

## Finding

### MAJOR — AC8 n'est pas couvert par le test censé le vérifier

- **Fichier :** `test/providers/fiesta_double_points_test.dart:98`
- **Scénario :** le test fait dépenser le ×2 en M1, passe en continuation M2, puis vérifie que
  le ×2 M1 reste appliqué et que la charge M2 est intacte. Il ne met jamais l'interrupteur M2
  sur `armed` pendant cette continuation. Une régression qui empêcherait `startTurnTimer` de
  transformer `armed` en `spent` lorsque `turnBonusTime` est non nul laisserait donc la charge
  M2 non dépensée et le score non doublé, tout en laissant les trois nouveaux tests verts. C'est
  le chemin de machine à états de l'AC8, explicitement requis par cette story.
- **Correction :** ajouter un test provider focalisé : finir M1 sans armer, appeler `nextRound`,
  armer en continuation, démarrer, puis vérifier `isDoublePointsOn`, une entrée
  `chargesUsed` en M2 et le score/`scoreByRound` doublé. Garder le test actuel pour l'invariant
  distinct « ×2 M1 persiste, charge M2 intacte ».

### MINOR — l'annonce pré-tour présente une charge non activée comme un modificateur actif

- **Fichier :** `lib/screens/game_screen.dart:687-726`
- **Scénario :** à partir du deuxième tour, avec `double_points` disponible mais l'interrupteur
  éteint, la carte « Actif ce tour » affiche le badge issu de `currentTeamModifiers`. Le ×2 ne
  s'applique pourtant qu'après le départ (`spent`) et n'est alors ni badge du tour ni tag
  analytics. La carte Bonus permet de corriger l'ambiguïté, mais l'écran affirme d'abord le
  contraire.
- **Correction :** utiliser une liste d'annonce qui exclut `double_points` non dépensé (ou le
  représenter explicitement comme une charge disponible) ; conserver le badge ×2 seulement
  lorsque `isDoublePointsOn` est vrai.

## Vérifications réalisées

- **Score / états.** `startTurnTimer` consomme une seule fois (`armed` → `spent`),
  `validateWords` transmet bien le multiplicateur à la fonction pure et ajoute le même total à
  `Team.score` et à `scoreByRound` (`lib/providers/game_provider.dart:926-968`). Les mots
  refusés ne sont pas dans `validatedWords`; les mots passés ou expirés validés le sont, donc
  tous les chemins de vérification ont le même ×2. Le snapshot emporte `GameState.fiesta` et les
  scores, ce qui restaure à la fois `chargesUsed` et le total avant revalidation.
- **Charges.** Le décompte filtre `catalogId`, équipe et manche
  (`lib/providers/game_provider.dart:1297-1305`), donc une instance `both` attribue une charge
  à chaque équipe, les reliquats M1 disparaissent logiquement en M2, et une continuation M1
  conserve `spent` sans consommer M2. L'armement en continuation est aussi correctement
  branché dans le code actuel. Le plafond Q8 est appliqué côté provider avant l'écriture.
  `chargesUsed` est optionnel à l'écriture et tolérant à l'absence, à une liste non conforme et
  aux entrées mal typées (`lib/models/fiesta/fiesta_state.dart:56-105`).
- **Compatibilité / Classique.** Aucun bump de `kCurrentSchemaVersion` (toujours 1) et aucune
  clé Fiesta n'est écrite pour une partie Classique. Le blob Classique figé demeure couvert par
  `test/models/game_state_test.dart:154-208`. Dans `startTurnTimer`, l'accès à `_teams` est
  conditionné à `fiesta != null` (`lib/providers/game_provider.dart:590-604`), donc la
  correction Classique `5bda897` reste préservée.
- **Analytics.** `double_points` est retiré des modificateurs ordinaires et ajouté une seule fois
  seulement lorsque l'état est `spent` (`lib/providers/game_provider.dart:631-646`). Cela est
  cohérent avec la capture des autres modificateurs au moment de `onWordShown`.
- **Qualité thermo-nucléaire / focus.** Le diff est cohésif : le journal persistant est nécessaire
  à la fois au décompte par équipe des instances `both` et au récapitulatif, et évite deux sources
  de vérité. Il ajoute une soixantaine de lignes à un provider déjà très grand, sans le faire
  franchir le seuil de 1 000 lignes ni introduire une nouvelle couche gratuite. Aucune mécanique
  surconçue dont la racine serait un choix de spec n'a été trouvée.

## Tests et mutation testing

La commande imposée a été tentée depuis ce worktree :

```text
scripts/with-test-slot.sh ~/development/flutter/bin/flutter test test/providers/fiesta_double_points_test.dart
```

Elle ne peut pas démarrer ici : le SDK partagé est monté en lecture seule et Flutter échoue en
écrivant `bin/cache/engine.stamp`. Une copie temporaire du SDK sous `/tmp`, lancée elle aussi via
`scripts/with-test-slot.sh` avec `--no-pub`, atteint bien le chargement du test mais le sandbox
interdit l'ouverture du socket localhost requis par `flutter_tester` (`Operation not permitted`).
La variante sans `--no-pub` est également bloquée par l'accès réseau à `pub.dev`. Aucune mutation
de source n'a donc été appliquée, et les trois exécutions de mutation restent à refaire sur une
machine Flutter normale.

Revue statique des mutants demandés : forcer le multiplicateur à 1 ferait échouer les attentes de
score des lignes 78/114/129 ; supprimer la dépense ferait échouer les lignes 68-69 ; retirer le
filtre de manche ferait échouer la ligne 119. Ces mutants sont bien visés, mais cette conclusion
ne remplace pas leur exécution.
