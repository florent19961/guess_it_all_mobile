# Revue r1 — L-TOMBE-MODÈLE

Verdict : NOT READY

Revue statique du patch `retours-tombe-modele-patch-r1.diff` et de son
contexte direct. Aucun test ni commande Flutter n'a été lancé.

## Points validés

- La lecture est additive : `dropFrequency` est omise à Jamais, absente =
  Jamais via `readOr`, et une valeur non nulle mal typée ou hors `0..3` rend les
  règles illisibles. C'est le comportement demandé : l'ensemble est ignoré
  seul par `FiestaEnsemble.tryFromJson`, alors qu'une partie Fiesta illisible
  est abandonnée plutôt que relue en Classique.
- Les règles gelées, `FiestaState`, `GameSetupSnapshot` et
  `GameSettings.replayFiesta` sérialisent tous avec `FiestaRules.toJson` et
  relisent avec `FiestaRules.tryFromJson` : aucun sérialiseur parallèle n'est
  oublié. Le blob 1.4.0 sans clé couvre bien la relecture d'un ensemble réel.
- `settingsKey` ne change pas à Jamais et distingue les fréquences actives.
  `hasActiveSetting`, le résumé, les pastilles, l'icône et la page « Voir »
  sont branchés sur la même valeur. Les ensembles fournis restent à Jamais.
- `dropForTurn` ne crée qu'un seul `Random` graîné, retourne avant tout tirage
  à Jamais ou en continuation, et consume la graine dans l'ordre chance,
  cartouche, puis devineur. La graine inclut `gameId`, `turnIndex`, `giverId`
  et le nombre de sauts : elle évite bien le cycle A → B → A d'une équipe de
  deux joueurs bloqués.
- Le vivier conserve l'ordre du catalogue et couvre les exclusions D4 : règles
  de manche, contraintes de manche, ×2 strictement au-delà de 10, malus reçus
  identiques ou incompatibles, bonus armé identique, et `block_guesser` à deux
  devineurs minimum. `block_giver` reste possible. L'éditeur place bien les
  quatre crans dans « Au hasard », sous « À tous, à chaque manche », après le
  séparateur. La construction (`Expanded`, texte sur une ligne avec ellipsis)
  est cohérente avec 360 px ; le rendu visuel n'est pas vérifiable dans cette
  revue statique.

## Findings

### MAJOR — Le chemin « ensemble uniquement avec des chutes » n'est pas protégé par test

**Fichiers :** `lib/models/fiesta/fiesta_ensemble.dart:52`,
`lib/models/fiesta/ensemble_validation.dart:43`.

**Preuve.** Le code est correct, mais aucun test ajouté ou existant ne construit
une `FiestaRules` dont le seul réglage actif est `dropFrequency` et n'exerce à
la fois `hasActiveSetting`, `validateEnsemble` et `settingsKey`. Les tests de
chute appellent seulement `FiestaRules` / `dropForTurn`
(`test/models/fiesta/cartridge_drop_test.dart:70`), et le test analogue des
défis ne couvre que `challenges`
(`test/providers/surprise_challenge_flow_test.dart:442`).

Deux mutations plausibles survivent donc : retirer la condition de
`hasActiveSetting` fait refuser l'enregistrement d'un ensemble « Rarement »
seul ; retirer la clé conditionnelle de `settingsKey` confond deux ensembles
qui ne diffèrent que par leur fréquence. C'est un comportement central de D4,
silencieux et persistant.

**Correction proposée.** Ajouter un test pur ciblé, par exemple dans
`ensemble_validation_test.dart`, qui vérifie pour Rarement seul :
`hasActiveSetting == true`, `validateEnsemble(...)` vide, une `settingsKey`
distincte de Jamais et de Souvent, et l'absence de `dropFrequency` dans la clé
de Jamais. Il tue ces deux mutations sans widget test.

### MINOR — Sentinelles hors domaine pour réutiliser `giftPool`

**Fichier :** `lib/models/fiesta/cartridge_drop.dart:57`.

**Preuve.** `giftPool` documente `teamId` et `blockableTeamIds` comme des ids
d'équipes ; `dropPool` lui fournit pourtant `''` et `{'*'}` pour forcer le
passage de `block_guesser`. Le résultat est juste avec l'implémentation actuelle
(`id != teamId`), puis le filtre des deux devineurs s'applique correctement,
mais ce contrat simulé cassera silencieusement si `giftPool` utilise un jour
l'appartenance à une équipe réelle.

**Correction proposée.** Extraire le filtre commun catalogue/manche/règles/×2
dans un helper privé paramétré par un booléen ou un prédicat
`canOfferBlockGuesser`. `giftPool` lui passe sa règle « autre équipe » et
`dropPool` sa règle « au moins deux devineurs » ; aucun appelant de production
de `giftPool` n'a alors besoin d'une sentinelle.

### MINOR — Deux composantes explicites de la graine et des probabilités restent non testées

**Fichier :** `test/models/fiesta/cartridge_drop_test.dart:37`.

**Preuve.** Le helper fige `gameId: 'g'`. Retirer `gameId` de `dropSeed` laisse
donc passer tous les tests. De même, le test de monotonicité
(`:103`) tue un échange de constantes, mais pas un déplacement simultané des
trois chances qui conserve leur ordre (par exemple 1/5, 1/4, 1/3).

**Correction proposée.** Permettre au helper de varier `gameId` et comparer un
tirage à une autre partie ; affirmer aussi les trois valeurs nommées
`1/6`, `1/4`, `1/2`. Ce sont des assertions pures, sans alourdir la suite.

### MINOR — Le journal technique décrit une graine incomplète

**Fichier :** `docs/tracking_evolution.md:1505`.

**Preuve.** Il annonce `(gameId, tour, joueur)`, alors que l'implémentation et
le contrat du modèle ajoutent `skips`. Omettre ce dernier masque précisément la
mesure qui empêche la répétition infinie après des tours sautés.

**Correction proposée.** Écrire `(gameId, tour, joueur, sauts de l'équipe)`.

## Mutation testing — lecture statique, non exécutée

| Test / assertion | Mutation plausible tuée par lecture | Limite résiduelle |
|---|---|---|
| `cartridge_drop_test.dart:70` | Émettre la clé à Jamais ; mauvais index ; accepter `-1`, `4` ou `'2'` ; borne max 3 changée à 4 (le `4` ne peut plus produire `null`) | `null` est volontairement traité comme absent par le contrat partagé `readOr`. |
| `:90` | `Random()` non graîné ; retrait de `giverId` ou de `skips` de la graine | Ne varie pas `gameId` (finding MINOR). |
| `:103` | Comparateur de chance inversé ; échange de deux constantes de chance | Ne fixe pas les trois valeurs exactes (finding MINOR). |
| `:118` | Ignorer `continuation` ou Jamais | Ne peut pas observer une consommation de PRNG devenue sans effet. |
| `:127` | Choisir le bloqué hors de `guesserIds`, ou renseigner `blockedPlayerId` pour une autre cartouche | — |
| `:144` | Retirer l'incompatibilité avec les règles de manche, y compris un Toujours | Les filtres communs de `giftPool` restent aussi couverts par `cartridge_gifts_test.dart`. |
| `:153` | Ne garder que l'égalité pour `received` ; retirer le filtre des bonus `armed` | — |
| `:166` | `gap >= 10`, seuil décalé, ou ×2 sans seuil | — |
| `:171` | `guesserIds.length >= 1` ; exclure par erreur `block_giver` | — |
| `fiesta_ensemble_service_test.dart:69`, assertion `:83` | Considérer la clé absente comme illisible pour un vrai blob enregistré par 1.4.0 | Ne vérifie pas à lui seul les autres chemins de sérialisation, qui appellent directement le même `FiestaRules.tryFromJson`. |

Les tests du nouveau vivier ne sont donc pas redondants avec
`cartridge_gifts_test.dart` : ils testent la colle propre aux chutes (chance,
continuation, malus reçus, bonus armés et devineur ciblé). En revanche, le
chemin d'enregistrement D4 doit recevoir le test ciblé ci-dessus avant merge.

## Verdict final

Verdict : NOT READY

BLOCKER : aucun.

MAJOR : test manquant pour l'enregistrement/anti-doublon d'un ensemble dont la
seule règle est `dropFrequency`.
