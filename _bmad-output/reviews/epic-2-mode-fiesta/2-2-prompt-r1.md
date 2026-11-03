# Revue r1 — story 2-2 « Fondation Fiesta » (tier risqué : ① machine à états, ③ schéma persisté)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-2-patch-r1.diff` (même
dossier), calculé sur la merge-base avec `origin/main` — jamais `git diff` toi-même. Tu lis le
code **avant** la spec, puis tu confrontes. Rapport dans `2-2-review-r1.md` (même dossier).

## Objectif de la story

Poser les types dont tout le reste de l'epic Fiesta dépend, sans changer une partie Classique :

- `lib/models/fiesta/` : catalogue V1 (11 ids figés + table d'incompatibilités Q14),
  `ModifierInstance` (+ `tryFromJson` tolérant, `canAdd`), `FiestaRules` (config gelée,
  immuable), `FiestaState` `{rules, active, turn}` ;
- `GameState.fiesta` optionnel : **absent du JSON quand nul**, relecture tolérante ;
- `GameProvider.startGame({FiestaRules? fiesta})` gèle la config ; sans argument, l'efface.

Spec : `_bmad-output/specs/fiesta/2-2-fondation-modele-fiesta.md` (AC 1 à 7) ; décisions de
l'epic : `_bmad-output/specs/fiesta/epic-fiesta.md` (§ Modèle de modificateur, Catalogue V1,
Q14). `kCurrentSchemaVersion` doit rester à `1`.

## Décisions déjà prises (ne pas rouvrir)

- Un seul champ optionnel dans `GameState`, pas de bump de schéma, absent = Classique.
- Relecture : `fiesta` non-objet ou règles illisibles → Classique ; instance ou réglage
  illisible → ignoré **seul**, jamais de valeur par défaut inventée (règle `WordEvent.tryFromJson`).
- Catalogue en code, seuls des ids persistés. Ids figés.
- Gel par immutabilité de `FiestaRules` (collections copiées en lecture seule à la construction).

## Interprétations de l'implémenteur (à challenger)

1. Portée/cible **par défaut** du catalogue : `round` / `both` partout, sauf `block_guesser`
   (`turn` / `player`). Charges par défaut : `free_pass` 2, `double_points` 1, sinon 0.
2. `canAdd` : une instance « pèse » sur une équipe si sa cible est `both` ou si son `teamId`
   est le même. Le plafond et l'incompatibilité se calculent sur les actives qui pèsent sur la
   même équipe que la candidate. Un doublon de `catalogId` n'est **pas** refusé (hors spec).
3. `FiestaRules.tryFromJson` est strict sur sa structure (chaque champ requis, bon type) mais
   tolérant sur les entrées de `modifiers`. `CatchUpRules.auto` est la valeur par défaut de
   `catchUp`, quel que soit le mode.
4. AC6 (retour arrière) : aucune API publique ne mute `fiesta` après le snapshot ; le test
   relance en Classique (`startGame()` efface `fiesta` sans toucher au snapshot) puis restaure.

## Questions précises

1. **Règle 7** : un blob écrit par la version en store se relit-il à l'identique ? Trouve un
   chemin où `toJson()` d'une partie Classique diffère d'avant (clé, ordre, valeur).
2. **Tous les chemins de mutation de `_game`** dans `game_provider.dart` : un `copyWith` qui
   devrait effacer ou conserver `fiesta` et ne le fait pas ? (`startGame`, les 5 remises à
   `GameState.initial()`, `restorePreValidationState`, `goBackToTeams`.)
3. **Mutation testing obligatoire** sur les 3 fichiers de test : pour chaque garantie nommée,
   quelle ligne du code faut-il casser pour que le test tombe ? Un test qui survit à la
   mutation évidente (`Map.unmodifiable` retiré, `clearFiesta` retiré, `'fiesta': null` écrit,
   `whereType` → `cast`, symétrie cassée dans `areCompatible`) est un finding.
4. **Valeur des tests** : redondant, échafaudage, ou invariant non risqué → finding.
5. **Sur-dimensionnement** : un mécanisme du diff dont la racine est un choix de spec, ou qui
   anticipe une story suivante (2-3, 2-5…) au lieu de rester minimal ?
6. **Plateformes** : rien de natif ici, mais vérifie qu'aucun `Platform.*` / `dart:io` n'entre.
7. `lib/models/CLAUDE.md` et `docs/tracking_evolution.md` : décrivent-ils ce que fait le diff,
   ni plus ni moins ?

## Format attendu

Par finding : **sévérité** (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne` du patch,
**affirmation vérifiable** (ce qui casse, comment le reproduire ou quel test le prouverait),
proposition. Termine par un verdict : READY / READY avec MINOR / NOT READY, et la liste des
mutations tentées avec leur résultat (tombé / survécu).
