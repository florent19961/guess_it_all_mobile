# Notes pour plus tard — dettes techniques ASSUMÉES

Journal des décisions techniques **délibérément reportées**. Une entrée = contexte, décision
reportée, raison, **signal déclencheur**, esquisse d'implémentation. Ce n'est pas une TODO list :
ce qui est ici a été vu, pesé, et laissé de côté sciemment.

Format : `## AAAA-MM-JJ — <titre>` puis les cinq rubriques.

---

## 2026-08-01 — Le dépôt n'a aucun test qui tourne (`test/widget_test.dart` = scaffold)

**Contexte.** Le seul fichier de `test/` est le template Flutter généré à la création du projet :
il fait `pumpWidget(const MyApp())` et teste l'incrément d'un compteur. Or la racine réelle est
`GuessItAllApp` (`lib/app.dart`) et il n'y a jamais eu de compteur. `flutter analyze` remonte
`The name 'MyApp' isn't a class` et **`flutter test` échoue à la compilation** — donc aucune
assertion n'a jamais été exécutée sur ce projet.

**Décision reportée.** Écrire une vraie base de tests (au minimum un smoke test qui monte l'app,
et des tests unitaires sur le scoring et la machine à états).

**Raison.** Le fix n'est pas mécanique : monter `GuessItAllApp` exige un `GameProvider` (qui touche
`SharedPreferences`) et de neutraliser `UpgradeAlert` (qui interroge le store → réseau, donc test
lent et flaky). Décider *comment* on isole ces dépendances est un choix d'architecture de test, pas
une correction — il vaut mieux le trancher avec l'audit de code plutôt qu'en marge d'un portage
d'outillage.

**Signal déclencheur.** Le premier ticket du mode Fiesta qui touche le scoring ou la machine à
états. Le pipeline (`guessitall-workflow`) est TDD : sans suite qui compile, le gate ② n'a pas de
témoin et le mutation testing est impossible.

**Esquisse.** (a) Extraire la construction de l'arbre de widgets pour pouvoir injecter un
`GameProvider` de test ; (b) rendre `UpgradeAlert` conditionnel (désactivé sous
`FLUTTER_TEST=true`) ; (c) commencer par les tests *purs* — modèles `copyWith`, calcul de score,
répartition des mots par joueur — qui ne demandent aucun mock et couvrent le tier risqué le plus
coûteux.

---

## 2026-08-01 — `flutter analyze` : exclusion plutôt que suppression du dossier `backup/`

**Contexte.** `lib/utils/word_categories/backup/` contient du code mort qui **ne compile pas**
(4 `error`). Il est gitignoré, donc absent d'un clone neuf — mais `flutter analyze` lit le disque,
pas l'index git : la baseline était rouge chez Florent et verte partout ailleurs.

**Décision reportée.** Supprimer physiquement le dossier.

**Raison.** Il sert manifestement d'archive locale des listes de mots avant réorganisation.
Le supprimer est une décision de contenu qui appartient à Florent, pas au portage d'outillage.

**Signal déclencheur.** Le prochain passage sur les catégories de mots — ou le jour où quelqu'un se
demande pourquoi `word_categories/` a un jumeau.

**Esquisse.** Vérifier que les JSON de `assets/translations/words/fr/` couvrent bien tout ce que
`backup/` contient, puis `rm -rf` et retirer l'exclusion de `analysis_options.yaml`.
