# Revue r1 — L-PERSONNE (`feat/retours-personne`) — tier RISQUÉ

Tu es reviewer, en LECTURE SEULE. Lis le patch `retours-personne-patch-r1.diff` (même dossier), puis le code
qu'il touche dans le worktree `/home/florent19961/guess-it-all-retours-personne`. Ne lance pas `git diff` toi-même.

## Objectif

Spec `_bmad-output/specs/fiesta/retours-2026-11-15.md` §D1 (lis aussi l'en-tête : règle 7, la 1.4.0 est en store).
Chaque malus envoyé se vise sur une personne (feuille « Sur qui ? ») et pèse sur le prochain tour où cette
personne fait deviner, quelle que soit la manche. Un malus impossible à son tour est perdu, sans affichage ni
remboursement. La transition de manche ne rend plus rien.

## Décisions de la spec (ne pas re-trancher)

- Feuille « Sur qui ? » : pour chaque équipe adverse, son nom puis ses prénoms, rien d'autre ; à 2 équipes aussi.
- Prénom grisé : même malus en attente, ou malus incompatible (`areCompatible`), tous envoyeurs confondus.
  « Bloquer un devineur » : équipe de moins de 3 → tous grisés. « Interdit de faire deviner » n'est grisé que par
  lui-même et ne grise rien d'autre. Toucher un grisé : bulle avec la raison, rien n'est envoyé.
- « Bloquer un devineur » et « Interdit de faire deviner » : résolution inchangée. Les autres malus d'un joueur qui
  saute son tour attendent son prochain vrai tour.
- Persistance : `ModifierInstance.playerId` (clé existante) pour tous les malus envoyés. 🔴 Malus en attente écrit
  par la 1.4.0 sans `playerId` (hors blocages) : ancien comportement (prochain tour de l'équipe). Pas de migration.
- L'affichage des malus reçus dans l'avant-tour de la cible n'est PAS dans cette lane (L-CACHE suit).

## Arbitrages de l'implémenteur (à challenger)

1. « Bloquer un devineur » reste UN par équipe en attente (`_clashOn`), sinon deux blocages sur la même équipe
   tomberaient le même tour et le second serait perdu en silence.
2. Un malus 1.4.0 sans joueur en attente grise tous les prénoms de son équipe (il se résout au tour de l'équipe).
3. `reuseReplacedChoices` ignore un envoi 1.4.0 sans joueur (il ne se renvoie pas ; sa cartouche a déjà été rendue
   par `confirmGiverBlock`).
4. `RoundTransitionPlan.continuingTeamId`, `crossesRules` et `targetsFor` retirés (sans usage) ; `opponents` ajouté.

## Points précis à vérifier

1. `ModifierInstance.resolvesAt` (`lib/models/fiesta/modifier_instance.dart`) est la SEULE règle de résolution,
   partagée par `modifiersForTurn` (`round_transition.dart`) et `_fiestaAfterTurn` (`game_provider.dart`) : un
   malus perdu quitte bien `active` à la fin du tour où il aurait joué, sans remboursement ; un malus visant un
   coéquipier reste.
2. Tous les chemins de mutation d'état : fin de tour normale, fin de manche (`_fiestaAtRoundEnd`, continuation
   qui vide aussi N+1), fin à 0 s (`noCarryOver`), piège `confirmGiverBlock` (le remplaçant ne reçoit ni ne
   consomme les malus du joueur sauté), retour arrière (`restorePreValidationState`), app tuée.
3. Rotation et `skips` : un malus sur un joueur qui saute son tour attend son prochain VRAI tour ; aucun cas où
   il serait consommé au tour du remplaçant ni appliqué deux fois.
4. Règle 7 : relecture d'un malus 1.4.0 sans `playerId` (test `relecture` de `test/providers/fiesta_v4_test.dart`),
   `ReplacedChoices.sent` 1.4.0 sans joueur, aucune forme persistée non additive.
5. `inflictMalus(catalogId, playerId)` : garde-fous (hors avant-tour, cartouche grisée, joueur inconnu ou de
   l'équipe qui joue, « Bloquer un devineur » sur équipe de 2), message de refus détaillé, `ChargeUse.target` =
   équipe du joueur (`withoutSent` / `cancelSent` toujours corrects).
6. `_malusBlock` : malus grisé dans la réserve si personne en face ne peut le recevoir.
7. UI `turn_cartridges.dart` : feuille « Sur qui ? » (`_pickPerson`, `_TeamPeople`, `Tooltip` en tap), Android et
   iOS ; aucun reste de `_pickTarget` / `_TeamButton` / `_TeamPlayers`.
8. Docs mises à jour : `lib/models/CLAUDE.md`, `lib/providers/CLAUDE.md`, `lib/widgets/CLAUDE.md`,
   `lib/screens/CLAUDE.md`, aide `help_content.dart`, `docs/tracking_evolution.md`. Une skill maison décrit-elle
   un comportement que ce diff change ?
9. **Mutation testing obligatoire** sur les 4 tests ajoutés du groupe « Chaque malus se vise sur une personne »
   (`test/providers/fiesta_v4_test.dart`) et les tests réécrits (`zero_carryover_turn_test.dart` « perdu à son
   tour », `cartridge_gifts_test.dart` « devenu impossible »). Mutants déjà essayés par l'implémenteur (tous
   tués) : résolution par équipe, legacy ignoré, grisé par équipe, `block_guesser` par personne. Survivant connu :
   le grisé d'équipe d'un malus 1.4.0 (non testé, arbitrage 2). Valeur des tests : redondant, échafaudage ou
   obsolète = finding.

## Format attendu du rapport

- Verdict : **READY** ou **NOT READY**.
- Findings classés **BLOCKER / MAJOR / MINOR**, chacun avec `fichier:ligne`, le problème, le scénario qui le
  déclenche, et la correction proposée.
- Résultat du mutation testing (mutant, test censé le tuer, tué ou survivant).
