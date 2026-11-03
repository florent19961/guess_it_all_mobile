# Revue r2 — story 2-5 (tier risqué ①)

Reviewer : Opus, même posture qu'en r1. Entrées : `2-5-fix-r1.md`, `2-5-prompt-r2.md`, et le
delta de code r1 → r2 (`ce1dde8..48958e8`, limité à `game_screen`, `malus_reveal`,
`symmetric_draw`, `nextRound`, deux tests et `notes_pour_plus_tard`, conforme au fix-r1). Les
mutations ont été rejouées puis annulées par édition inverse ; `git status` est propre.
`flutter analyze` sur les fichiers touchés ne remonte rien de nouveau : `withOpacity` et l'import
`foundation` de `game_provider.dart:3` étaient déjà là.

## Verdict : **READY** (0 BLOCKER, 0 MAJOR, 1 MINOR, 2 NIT)

## 1. MAJOR-1 : fermé

`game_screen.dart` `_startTurn` (`:277-297`) :
- **Avant le push**, la garde `ModalRoute.of(context)?.isCurrent` suffit. `Navigator.push` met à
  jour l'historique de façon synchrone, donc le second tap du double tap trouve `isCurrent ==
  false` et ne fait rien. Il n'y a jamais deux chaînes de révélations.
- **Après l'`await`**, la garde `context.mounted && currentScreen == screenGame` ferme les cas
  restants : contexte démonté, ou écran changé sous la révélation.
- Avec N malus, le retour système Android ferme la révélation en cours, comme « Compris ». La
  chaîne continue, puis un seul `startTurn()`. Sur iOS, un `fullscreenDialog` n'a pas de geste de
  retour.
- **Faux positifs : aucun.** Les dialogues de `GameScreen` (règles, équipe, scores) et le popup
  `upgrader` couvrent le bouton tant qu'ils sont ouverts, et `isCurrent` repasse à `true` dès leur
  fermeture. Après une reprise, `home` garde la même route : seul son enfant change. Il n'y a pas
  de route résiduelle possible, puisqu'une seule chaîne existe désormais.
- **Absence de test : justification acceptable.** Le défaut vit dans la pile de routes, pas dans
  le provider, et la lane exclut les tests de widget. La recette sur device (double tap rapide =
  une seule révélation, Android et iOS) doit figurer dans la PR.

## 2. `nextRound` idempotent (617b73d) : correct

- `nextRound()` n'a **qu'un appelant** : `transition_screen.dart:235`. La fin de M3 va aux
  résultats par `validateWords` (`:955-957`), sans passer par `nextRound`. La branche
  `nextRoundNumber > 3` est de toute façon inatteignable depuis la transition.
- Retour arrière : `restorePreValidationState` mène à la vérification. Une nouvelle validation
  repasse par la transition, puis `nextRound` fonctionne. Avec une suspension suivie d'une reprise
  sur la transition, `suspendedScreen` restaure `screenTransition` et `nextRound` fonctionne.
  En Classique, le test est Classique.
- **Aucun chemin légitime n'est bloqué.**
- Le test « double tap » reproduit bien le bug : deux appels à `nextRound` finissent en M2 sur
  `screenGame`. Mutation « garde retirée » : **tuée**.

## 3. `block_guesser` : filtré dans le tirage et dans les fixés, les mutants sont tués

`isForAllTeams` (`symmetric_draw.dart:28-30`) est appliqué aux fixés (`:61`) et au tirage (`:96`).

| Mutation | Résultat |
|---|---|
| `isForAllTeams` → `true` | tuée |
| filtre retiré des fixés seulement | tuée |
| filtre retiré du tirage seulement | tuée |
| `malusToReveal` sans le test « déjà joué » | tuée |
| `nextRound` sans la garde de transition | tuée |
| **`alreadyPlayed` sans le filtre `h.round == currentRound`** | **survit** (MINOR-1) |

## 4. MINOR-3 (survivantes sans `canAdd`) : décision tenable

C'est cohérent avec Q8 (le tirage passe d'abord) et cela garde l'aperçu de transition
fonction de `(rules, gameId, manche)`. L'entrée de `notes_pour_plus_tard.md` donne un signal
déclencheur précis et un repli (filtrer les survivantes, jamais le tirage). Elle suffit pour
2-8 et 2-10. Une nuance est ajoutée en NIT-1.

## 5. Mise en page : rien de nouveau

- `Expanded(flex: 3)` + `Align(bottomCenter)` + `SingleChildScrollView` : le scroll view est
  borné par l'`Expanded`, donc rien ne déborde. Le bloc colle au bouton et l'espace libre passe
  au-dessus. En Classique, rien ne change : le bloc est sous `if (provider.isFiesta)`.
- `MalusReveal` : `Center` + `SingleChildScrollView` + `Column(min, stretch)`. La largeur est
  bornée par l'écran et la colonne défile en hauteur, donc rien ne déborde, même avec une grande
  police.

---

## MINOR-1 — `malusToReveal` : le filtre de manche n'est pas couvert

`game_provider.dart` (`malusToReveal`, `h.round == _game.currentRound`). Si on retire ce
filtre, aucun test ne casse, car le nouveau test reste en M1. Le scénario du mutant : dès M2,
plus aucune équipe ne voit la révélation des malus de la nouvelle manche, puisqu'elles ont
toutes une entrée en M1. **Correctif :** dans le test « révélation des malus », fixer aussi
`minus_10s` sur M2 (ou passer par une manche entière), puis vérifier qu'après `nextRound`,
`malusToReveal` n'est pas vide pour la première équipe. Trois lignes. Non bloquant.

## NIT-1 — Note MINOR-3 : préciser le cas de la continuation de fin de manche

Une instance de portée tour est « consommée à la fin de son tour ». Or le tour qui finit la
manche N se prolonge en continuation (`pendingBonusTurnId`) au début de N+1, et le `turn` reste
le même. 2-8 devra trancher : la continuation hérite-t-elle de l'instance de portée tour ? Si
oui, elle survit au passage de manche, ce qui est exactement le cas de la note. Une phrase à
ajouter dans l'esquisse.

## NIT-2 — Petits écrans : la zone d'annonces est plafonnée à 3/5 de l'espace libre

Sur un iPhone SE, la carte « Tirage de la manche 1 » (2 cartes) peut demander un défilement
dans une zone d'environ 70 pt, sans indice visuel de défilement. Ce n'est pas une régression :
r1 avait le même plafond. À regarder pendant la recette sur device.
