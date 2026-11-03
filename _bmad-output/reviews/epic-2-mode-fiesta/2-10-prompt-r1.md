# Revue 2-10 cœur (1 parmi 3 / coup de pouce) — r1

Tier **risqué** ① (machine à états entre deux manches) + ③ (clé optionnelle du blob Fiesta).
Lire `2-10-patch-r1.diff` (base = `8bfdbd5`, sommet de 2-9 rebasé sur `origin/main` : le patch ne
contient que 2-10 cœur ; `origin/feat/fiesta-2-9` n'est pas encore rebasé, sa merge-base avec la
branche tirerait main + 2-9). Kit pur déjà mergé (PR #16) : `lib/models/fiesta/offers.dart`,
`lib/widgets/fiesta/offer_widgets.dart`.

Sources : `_bmad-output/specs/fiesta/2-10-un-parmi-trois-coup-de-pouce.md` (AC1-AC8, pièges),
`epic-fiesta.md` (Q3, Q7, Q8), `journal-arbitrages.md`.

## Interprétations prises (à challenger)

1. **Seuls les choix sont persistés** : `fiesta.offerChoices = [{chooserId, modifier}]`, omise si
   vide. Offres, file et coup de pouce Auto sont **recalculés** (scores actuels, tirage de N+1,
   graine). La file de la transition = choix dont `modifier.round == currentRound + 1`.
2. **Garde** : `nextRound` sort si `nextChooserId != null` (après la garde d'écran de 2-5). Le
   bouton affiche « En attente du choix de X », désactivé.
3. **Prochaine équipe** = 1ʳᵉ de `choosingOrder` sans choix et avec des offres non vides ;
   `choices` passés à `pickThreeOffers` = tous les choix de la transition (forcément ceux des
   équipes d'avant, la file étant séquentielle).
4. **Application** : `_fiestaForRound` ajoute tirage + `appBoostPreview` + choix de la transition,
   lus avant le changement de manche. Instances de portée **manche** (kit), retirées à N+2.
5. **AC6** : un retour arrière efface les choix (postérieurs au snapshot) ; la revalidation
   redonne les mêmes offres. **AC5** : le flux de choix est une route non persistée ; après un
   kill, la transition montre l'équipe suivante.
6. **Malus annoncés** : aucun code dédié, ils sont dans `active` → `malusToReveal` (2-5) et tags
   analytics (2-7) les prennent comme le tirage.
7. **block_guesser** : `blockingTeam` = l'équipe qui a choisi la carte contre l'équipe qui joue
   (manche en cours) ; le sélecteur et l'annonce de 2-8 affichent « X choisit » / « Choisi par
   X » (paramètre optionnel, défaut inchangé).
8. **Récap** : « Choix 1 parmi 3 » relu de `offerChoices` ; « Coup de pouce de l'app » recalculé
   sur les scores cumulés par manche (comme le rattrapage).
9. **Carte 1 parmi 3** affichée si un choix reste à faire ou a été fait (`hasPickThree`) ; sinon
   rien (aucune équipe n'a d'offre).

## Questions précises

- Un chemin permet-il `nextRound` avec une file non vide (reprise, double tap, retour arrière
  puis revalidation, Auto) ? Un choix peut-il être fait hors tour ou en double ?
- `_pendingChoices` lu dans `_fiestaForRound` : bien la manche finie (copyWith évalué avant
  l'affectation) ?
- Restauration du snapshot depuis le jeu de N+1 : `offerChoices` et `active` restent-ils cohérents ?
- Relecture tolérante de `offerChoices` (entrée illisible ignorée seule) ; Classique : aucun
  octet nouveau (test figé `legacy`).
- `blockingTeam` : correct si le leader joue la continuation en N+1 ?
- Mutation testing sur `test/providers/fiesta_pick_three_test.dart` (4 tests). Mutants déjà tués
  localement : garde `nextRound`, `..._pendingChoices.values`, `..._appBoostPreview`, écriture de
  `offerChoices`.

Format attendu : findings BLOCKER / MAJOR / MINOR avec `fichier:ligne`, puis verdict READY / NOT
READY.
