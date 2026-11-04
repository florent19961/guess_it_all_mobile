# Revue r1 — lane reglages-catalogue (tier risqué)

Lis UNIQUEMENT le patch `reglages-catalogue-patch-r1.diff` (diff sur la merge-base avec
`origin/main`, hors revues) et le code du worktree `/home/florent19961/guess-it-all-reglages`
pour le contexte. Lecture seule : ne modifie rien, écris ton rapport dans
`_bmad-output/reviews/reglages-catalogue/reglages-catalogue-review-r1.md`.

## Objectif (retours Florent 2026-11-04)

1. Paramètres : ordre Joueurs, Équipes, « Mode de jeu » (section titrée, Classique / Fiesta),
   Choix des mots, puis Catégories. Tout tient sans défiler à 390 × 763 et 360 × 740 utiles,
   Classique et Fiesta. Cible d'aide `mode` et tuto Fiesta à la 1re sélection gardés.
2. « Avancés » : tout visible sans défiler (curseurs, Auto / Personnalisé en Fiesta,
   Réinitialiser).
3. Catalogue : famille « Mime » (3 mimes + Dessiner + Mimer sous un drap + Mime de dos), au
   plus UN membre actif à la fois sur tous les chemins (tirage Auto / Personnalisé, fixés,
   1 parmi 3, coup de pouce, éditeur). Nouveau malus « Faire deviner dans une autre langue »,
   jamais en manche 3. Éditeur : sections Malus puis Bonus, sous-catégorie Mimes exclusive.
   Nouvel ensemble : rattrapage coupé, tirage symétrique allumé.

## Décisions prises par la lane

- Règle de famille = `mimeFamily` dans `areCompatible` (remplace les paires mime/mime et la
  règle `kDrawId`/`mime`). Tous les chemins passent par `canAdd` → `areCompatible`.
- `notInRound3` (autre langue) lu par `isEligibleForRound` ; `validateEnsemble` refuse un
  fixé M3 ou une manche de départ 3. « Autre langue » compatible avec tout.
- Nouveaux ids (`mime_under_sheet`, `mime_back_turned`, `other_language`) en FIN de
  catalogue ; ajoutés à `kOfferStrength` (drap forte, dos et langue moyenne).
- Relecture d'un ancien ensemble à plusieurs mimes actifs : `oneMimeAtMost` dans
  `FiestaEnsemble.tryFromJson` garde le 1er FIXÉ (ordre du catalogue), sinon le 1er actif ;
  les autres `active: false`, réglages conservés, même forme JSON. Les règles gelées d'une
  partie en cours (`FiestaRules.tryFromJson`) ne sont PAS normalisées.
- Défaut d'un nouvel ensemble : seul « Dessiner » actif dans la famille (fixé M3).
- `AppSlider.compact` (valeur à droite du libellé) pour « Avancés » ; `AppCounter` à 40 pt.

## Questions précises

1. Règle 7 : une forme persistée change-t-elle au-delà d'un ajout ? `oneMimeAtMost` garde-t-il
   bien le mime que l'ancien code appliquait (fixés avant tirage, `canAdd` dans l'ordre du
   catalogue) ? Ne pas normaliser les parties en cours est-il juste (déterminisme par graine) ?
2. La règle de famille est-elle respectée sur TOUS les chemins de tirage (fixés, symétrique
   Auto et Personnalisé, `pickThreeOffers`, `appBoost`, éditeur) ? Un chemin contourne-t-il
   `canAdd` ? Effet de `areCompatible(x, x) == false` pour un membre de la famille ?
3. `other_language` : peut-il sortir en M3 par un chemin quelconque (offre après M2, fixé,
   tirage) ? Validation de l'éditeur cohérente avec le stepper (max 2) ?
4. Ajout d'ids → listes mélangées par graine plus longues : quel impact sur une partie en
   cours (récap recalculé, offres) ? Est-ce acceptable (Fiesta pas encore en store) ?
5. Hauteurs : mesures (test jetable non committé, vraies polices Bangers / Poppins) — écran
   709 px de contenu (avertissement > 50 mots compris) pour 763 / 740 utiles ; Avancés 402 px
   en Fiesta pour ~541 / ~490 disponibles (`AppModal` 80 % de la hauteur). Les cibles tactiles
   restent ≥ 44 px ? Le titre ne passe-t-il pas sous les boutons du haut ?
6. Mutation testing sur les tests ajoutés / modifiés (`fiesta_catalog_test`,
   `symmetric_draw_test`, `ensemble_validation_test`, `fiesta_ensemble_service_test`, attentes
   épinglées de `offers_test` et `fiesta_pick_three_test`). La lane a muté : règle de famille,
   `notInRound3` dans `isEligibleForRound`, appel de `oneMimeAtMost`, préférence « fixé » —
   tous tués.

## Format attendu

Findings numérotés : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, affirmation,
preuve, correction proposée. Puis verdict READY / NOT READY.
