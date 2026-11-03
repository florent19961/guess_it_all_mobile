# Revue r1 — story 2-3 « Ensembles » (tier risqué : ③ schéma persisté, nouvelle clé ; + écrans)

Tu es le reviewer Opus adversarial de la lane B. Tu lis **le patch** `2-3-patch-r1.diff` (même
dossier) — calculé sur `git merge-base feat/fiesta-2-2 HEAD` : la branche est **empilée sur
2-2** (en revue), le patch ne contient donc que le delta de 2-3. Jamais `git diff` toi-même. Tu
lis le code **avant** la spec, puis tu confrontes. Rapport dans `2-3-review-r1.md` (même dossier).

## Objectif de la story

Enregistrer des réglages Fiesta Personnalisé sous un nom, les réutiliser, modifier, dupliquer,
supprimer :

- `lib/services/fiesta_ensemble_service.dart` : clé **`guessItAll_fiestaEnsembles`**, enveloppe
  `persisted_schema` dès la 1re écriture, quarantaine, tolérance par ensemble, borne 10 ;
- `lib/models/fiesta/fiesta_ensemble.dart` (`FiestaEnsemble {id, rules}`, défauts de la
  maquette, `copyWith` en extensions) et `ensemble_validation.dart` (`validateEnsemble`, pure) ;
- `lib/screens/fiesta_ensembles_screen.dart` (liste) et `fiesta_ensemble_editor_screen.dart` ;
- route d'attente dans `lib/app.dart` + `lib/utils/constants.dart`.

Spec : `_bmad-output/specs/fiesta/2-3-ensembles-stockage-editeur.md` (AC 1 à 8 + notes
d'implémentation) ; epic : `_bmad-output/specs/fiesta/epic-fiesta.md` (§ Mode Personnalisé,
Q10, Q13). Maquette (écrans `perso`, `edit`) : https://claude.ai/artifact/N9w6ATfeJnXTkfq74AfAdj.
Types de 2-2 lus mais **non modifiés** : `lib/models/fiesta/{fiesta_rules,modifier_catalog}.dart`.

## Décisions déjà prises (ne pas rouvrir)

- Clé à part (pas dans `guessItAll_settings`), `kCurrentSchemaVersion` reste à 1.
- 10 max, nom obligatoire ≤ 30, doublon « <nom> (copie) » tronqué à 30, pas d'unicité (Q13),
  suppression confirmée, Modifier = sur place (même id, même position).
- `lastUsedId` vit dans cette clé (Q10).
- Tests minimaux : aller-retour, quarantaine, borne 10, validation pure. **Pas de widget test.**

## Interprétations de l'implémenteur (à challenger)

1. Le nom vit **uniquement** dans `rules.ensembleName` (pas de champ `name` séparé).
2. Rattrapage **sans interrupteur** (5 curseurs ; tout à 0 = coupé), car `CatchUpRules` n'a pas
   de champ « actif » et la story dit « 5 curseurs ».
3. Tirage pour tous d'un ensemble = `symmetric` **et** `drawCount > 0` (interrupteur + compteur).
4. Modifications **sérialisées** par une file interne (`_serialized`) ; une lecture en panne fait
   échouer la modification (rien n'est écrit) ; `load()` rend vide sans effacer.
5. Entrée de 2-4 : `FiestaEnsemblesScreen(onBack, onUse)`, `onUse` après `markUsed`.
6. Manche verrouillée à 3 dans l'éditeur pour les modificateurs « manche 3 seulement ».
7. `lib/models/CLAUDE.md` **non mis à jour** (fichier de la lane 2-2 en revue) : les deux
   nouveaux fichiers de modèle y seront ajoutés après le merge de 2-2.

## Questions précises

1. **Règle 7** : trouve un blob plausible (écrit par cette version, abîmé, ou futur) qui fait
   crasher la lecture, efface des ensembles lisibles, ou boucle en échec à chaque ouverture.
   Le `try/on FormatException` autour de `jsonDecode` + `unwrapSchema` couvre-t-il tout ?
2. **Chemins de mutation** (`create`, `update`, `duplicate`, `delete`, `markUsed`) : borne
   contournable ? position / id perdus ? `lastUsedId` orphelin ? La file `_serialized`
   peut-elle se bloquer (erreur qui empoisonne la chaîne) ?
3. **Mutation testing obligatoire** : pour chaque garantie nommée par un test, quelle ligne
   casser pour qu'il tombe ? Déjà tenté par l'implémenteur : file retirée → test borne tombé.
   À tenter au minimum : `prefs.remove` retiré, `wrapWithSchema` retiré, `take`/borne retirée
   dans `duplicate`, chaque règle de `validateEnsemble` neutralisée, `def.round3Only` inversé.
4. **Validation** : une config impossible passe-t-elle ? Une config légitime est-elle refusée
   (ex. défaut de la maquette, modificateur coupé avec réglage incohérent) ?
5. **Écrans** : AC 1, 2, 3, 5, 6 visibles ? Bouton grisé + explication, clavier / zone sûre
   (Android + iOS, aucun `Platform.*`), dialogues via le design system.
6. **Sur-dimensionnement / valeur des tests** : redondant, échafaudage, mécanisme dont la
   racine est un choix de spec ?
7. Docs (`lib/services/CLAUDE.md`, `lib/screens/CLAUDE.md`, `docs/tracking_evolution.md`,
   notes de la story) : disent-elles ce que fait le diff, ni plus ni moins ?

## Format attendu

Par finding : **sévérité** (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne` du patch,
**affirmation vérifiable**, proposition. Termine par un verdict : READY / READY avec MINOR /
NOT READY, et la liste des mutations tentées (tombé / survécu).
