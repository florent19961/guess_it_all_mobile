# Revue r1 — story 2-6 « Temps du tour : rattrapage, malus de temps, durée réelle » (tier risqué : timer ⑥ + machine à états ①)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-6-patch-r1.diff` (même
dossier), calculé contre `ce1dde8` (pointe de `feat/fiesta-2-5`, sur laquelle la lane est
empilée) — jamais `git diff` toi-même. Tu lis le code **avant** la spec, puis tu confrontes.
Rapport dans `2-6-review-r1.md` (même dossier). **Mutation testing obligatoire** sur les tests
ajoutés.

## Objectif de la story

Spec : `_bmad-output/specs/fiesta/2-6-temps-rattrapage-duree-reelle.md` (AC 1 à 9). Epic :
`_bmad-output/specs/fiesta/epic-fiesta.md`, Q1 à Q5 et « Risque connu dans le code ».

À la fin d'une manche, l'équipe menée gagne du temps à son premier tour de la manche suivante
(+3 s × écart après M1, +5 s après M2, plafond 30 s), le leader en perd (−1 s × écart avec la
2ᵉ, plafond 15 s). Le modificateur `minus_10s` (tiré par 2-5) retire 10 s par instance.
Plancher 10 s. La continuation de fin de manche garde exactement ses secondes. Le temps passé
d'un tour (`HistoryEntry.timeSpent`) se mesure sur la durée réelle de départ, plus sur le
réglage. Pas d'analytics (2-7).

## Décisions déjà prises (ne pas rouvrir)

- Q1 : la continuation reste un tour court séparé ; le rattrapage tombe sur le tour suivant.
- Q2 : malus du leader mesuré sur la 2ᵉ, appliqué au premier tour **non-continuation**.
- Q3 : égalité = toutes les équipes au même score → rien ; co-leaders tous « en tête » (malus
  mesuré sur la meilleure non-leader), les autres menées.
- Q4 : plancher 10 s après tous les malus. Q5 : aucun modificateur de temps sur une continuation.
- Personnalisé : les 5 curseurs de `FiestaRules.catchUp` (tous à 0 = éteint) ; Auto :
  `autoCalibrate` allume `CatchUpRules.auto`.
- 🔴 Une partie **Classique** garde sa durée seconde pour seconde ; `test/providers/turn_time_test.dart`
  passe **sans modification**.
- Tests au minimum, pas de test de widget.

## Interprétations de l'implémenteur (à challenger)

1. **Seule source de la durée** : `GameProvider.turnTime` (→ `composeTurnSeconds`), lue par
   `startTurn` (aperçu) et `startTurnTimer` (chrono). Classique : `turnBonusTime ?? turnDuration`
   par construction (pas de branche spéciale : plancher = `max(10, base)` avec base ≥ 20).
2. **Continuation = `turnBonusTime` posé**, pas `pendingBonusTurnId` : c'est le champ qui fait
   la durée, et il couvre la fin de manche avec mots refusés (temps reporté, entrée non marquée
   continuation).
3. **Le dû est stocké** dans `FiestaState.catchUpDue` (id → secondes signées), champ additif
   Fiesta seulement, posé par `nextRound` (via `_fiestaForRound`) sur les scores de la manche
   finie, **consommé** (retiré) par `startTurnTimer` au premier tour non-continuation. La spec
   disait « rangé dans `fiesta` comme dû » ; 2-5 avait préféré recalculer — ici dériver
   « consommé » de l'historique rate le cas des mots refusés (point 2).
4. **Transition** : `catchUpPreview` recalculé sur les scores (comme `nextRoundModifiers`), rien
   de stocké avant `nextRound`. Retour arrière depuis la transition : les scores sont restaurés,
   l'aperçu disparaît, revient identique.
5. **`turnAllottedSeconds`** écrit à chaque `startTurnTimer`, Classique compris (le bug
   `timeSpent` est Classique). Jamais effacé : écrasé au tour suivant. Nul (partie d'une version
   antérieure) → `turnDuration`.
6. **`minus_10s`** : nombre d'instances actives qui pèsent sur l'équipe (`currentTeamModifiers`),
   sans consommer de charge (2-8).
7. Carte « Temps du tour » dans `_FiestaAnnouncements` (Fiesta seulement) ; le bloc Classique
   « Temps bonus » est masqué en Fiesta (la ligne « Temps reporté » le remplace). Carte
   « Rattrapage » dans la zone défilante de la transition.
8. Nouveau fichier de test provider (`turn_time_fiesta_test.dart`) plutôt qu'un ajout dans
   `turn_time_test.dart`, dont le helper n'a ni joueurs ni équipes.

## Questions précises

- **Divergence aperçu / chrono** : existe-t-il un chemin où `startTurn` et `startTurnTimer`
  lisent un état différent (retour arrière entre les deux, app tuée sur le compte à rebours,
  `MalusReveal` avant `startTurn`) ?
- **Double consommation ou non-consommation** : `startTurnTimer` appelé deux fois ? Continuation
  à 0 s (`turnBonusTime == 0`) : est-elle bien une continuation ? Fin de manche avec mots
  refusés : le tour suivant de cette équipe consomme-t-il ?
- **Retour arrière** (AC8) : le snapshot de `savePreValidationState` est pris APRÈS
  `startTurnTimer` ; `catchUpDue` restauré est-il le bon dans tous les cas (retour depuis le
  jeu de M2 vers la vérification de fin de M1, puis revalidation + `nextRound`) ?
- **Kill / reprise** (AC9) : `turnAllottedSeconds` et `catchUpDue` relus ; `suspendGame` hors
  tour pose un reste gelé égal à `timeRemaining` — interaction avec `turnTime` ?
- **Scores** : `computeCatchUp` lit `Team.score` (total). Un score négatif (pénalités) ? À 3 ou
  4 équipes, `second` = meilleure non-leader : correct avec des co-leaders ?
- **Classique byte-for-byte** : `validateWords` écrit désormais `timeSpent` sur
  `turnAllottedSeconds` — le seul changement voulu en Classique est la continuation (AC7). Un
  autre chemin change-t-il ?
- **Valeur des tests** (mutation) : `max(0, due)` ↔ `due`, plancher retiré, `k` inversé entre
  M1 et M2, consommation sur la continuation, `turnAllottedSeconds` non écrit, `copyWith` de
  `FiestaState` qui perd `active`. Chaque assertion mord-elle ?
- `FiestaState.tryFromJson` : `catchUpDue` illisible (liste, valeurs non entières) → ignoré
  sans lever ?
- Les deux plateformes : rien de `Platform.*` ; la carte « Temps du tour » défile sur petit écran ?

## Format attendu

Pour chaque finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, scénario
concret, correction proposée. Verdict final : READY ou NOT READY.
