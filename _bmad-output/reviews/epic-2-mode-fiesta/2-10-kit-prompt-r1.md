# Revue r1 — lane « kit 2-10 » (1 parmi 3 / coup de pouce, tier standard)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-10-kit-patch-r1.diff` (même
dossier), calculé sur la merge-base avec `origin/main` — jamais `git diff` toi-même. Tu lis le
code **avant** la spec, puis tu confrontes. Rapport dans `2-10-kit-review-r1.md` (même dossier).

## Objectif de la lane

Préparer, **sans les brancher**, la moitié parallélisable de 2-10 ; la lane cœur (provider,
transition, persistance) viendra après 2-8 / 2-9 et ne fera que brancher :

1. `lib/models/fiesta/offers.dart` (pur) : table de force + seuils (≤3 légère, ≤7 moyenne,
   >7 forte, « à recalibrer ») ; `Standings` (leader, écart, ordre de choix dernière →
   avant-dernière, leader exclu, vide si égalité Q3) ; `pickThreeOffers` (≤3 offres parmi les
   actifs « proposé » dont la manche de départ ≤ N+1, à la force de l'écart de CETTE équipe,
   exclusions `canAdd` contre le tirage de N+1 + les choix déjà faits, vide = équipe sautée) ;
   `appBoost` (Auto : un bonus par équipe menée + un malus pour le leader, mêmes exclusions).
   Déterministe par `offerSeed(gameId, round, teamId)`.
2. `lib/widgets/fiesta/offer_widgets.dart` : `PickThreeCard`, `PassPhonePanel`,
   `OfferChoiceBody`, `AppBoostCard` — données en entrée, callbacks en sortie, aucun Provider.

Specs : `_bmad-output/specs/fiesta/2-10-un-parmi-trois-coup-de-pouce.md`, epic Q3, Q7, Q8
(`_bmad-output/specs/fiesta/epic-fiesta.md`). Maquettes `r2` et `pick3`.

## Décisions déjà prises (ne pas rouvrir)

- Fichiers interdits : `game_provider`, `game_state`, `game_settings`, services de persistance /
  analytics, tous les écrans existants. Seulement de nouveaux fichiers + lignes de doc CLAUDE.md.
- Tests : un seul fichier pur `test/models/fiesta/offers_test.dart`, aucun widget test.

## Interprétations de l'implémenteur (à challenger)

1. **Force stricte** : seules les offres de la force exacte de l'écart (lecture littérale de la
   spec, « en montrer moins »). Avec 7 modificateurs hors manche 3, une force peut n'avoir qu'1–2
   candidats (forte avant M3 = `block_guesser` seul). Alternative non retenue : compléter avec la
   force voisine.
2. Table : légère = `free_pass`, `minus_10s`, `reversed`, `mime_no_fists` ; moyenne =
   `double_points`, `two_words`, `no_pass`, `draw` (les 3 premières = les offres de la maquette à
   écart 6) ; forte = `block_guesser`, `mime_no_arms`, `mime_eyes_closed`.
3. **Co-leaders** : aucun malus (pas de cible unique), tous les co-leaders sont exclus de la file.
4. Écart du leader (malus Auto) = écart avec la 2ᵉ, comme `computeCatchUp`.
5. Offre = `ModifierInstance` (scope `round`, round N+1, target `team`, ou `player` pour
   `block_guesser` avec `teamId` = leader, `playerId` nul : désigné plus tard, flux 2-8).
   Charges : réglage de l'ensemble (Personnalisé), `defaultCharges` (Auto).
6. `block_guesser` : jamais dans le coup de pouce Auto (personne ne désigne) ; en Personnalisé,
   exclu pour les équipes de `blockImmuneTeamIds` (≤ 2 joueurs, fourni par l'appelant).
7. Graine par `teamId` (spec) plutôt que par index d'équipe (consigne de lane) : `drawSeed`
   réutilisé sur `'$gameId#$teamId'`.
8. Offres d'une équipe dépendantes des choix précédents : après retour arrière (critère 6), la
   1ʳᵉ équipe retrouve ses offres ; les suivantes aussi **si** les choix refaits sont identiques.

## À chercher en priorité

- `canAdd` mal appliqué : plafond par cible, `both` vs `team`, offre bonus jugée sur la mauvaise
  équipe, malus contre un leader absent.
- Non-déterminisme : ordre de `Map`, mélange qui ne part pas de la même liste.
- `Standings` : scores vides / 1 équipe, égalités entre menées, co-leaders, `gapOf` d'un id
  inconnu.
- Widgets : logique de jeu cachée, débordement petit écran, libellés singulier/pluriel.

Verdict attendu : READY ou NOT READY, findings classés (bloquant / important / mineur), chacun
avec fichier:ligne et correctif minimal.
