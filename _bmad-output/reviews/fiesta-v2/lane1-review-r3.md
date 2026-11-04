# Revue Codex — lane 1 r3 (2026-11-04)

Verdict : READY

Aucun BLOCKER ni MAJOR.

### MINOR

- `test/providers/fiesta_pick_three_test.dart:125` — résidu accepté : il manque toujours le scénario `pick3Choices: 3` avec kill/reprise après la première rangée. Le code est néanmoins générique : chaque choix persiste sa `row` (`lib/providers/game_provider.dart:1689-1704`), les offres sont recalculées déterministiquement (`:1606-1625`) et la reprise attend toutes les rangées non choisies (`:1656-1679`). Risque de couverture, pas défaut fonctionnel identifié.

### Vérifications r3

- M5 est corrigé. Les brouillons sont maintenant séparés par id d’ensemble, avec une clé distincte pour la création (`lib/screens/fiesta_ensembles_screen.dart:41-49,115-149`). Le scénario brouillon création A → brouillon modification B → reprise de A puis B est couvert par `test/screens/fiesta_ensembles_flow_test.dart:110-163`.  
  Perte encore possible uniquement dans les cas explicitement voulus : abandon d’un brouillon repris, suppression de son ensemble, ou arrêt complet de l’app — les brouillons sont contractuellement en mémoire seulement.

- Les autres MINOR r2 sont corrigés :
  - badge « Deux mots » non dupliqué : `lib/screens/turn_screen.dart:393-396`;
  - `free_pass.perGame` ignoré dans la clé de déduplication : `lib/models/fiesta/fiesta_ensemble.dart:121-125`;
  - persistance `reserve` vérifiée sur aller-retour JSON et exclue des effets : `test/models/game_state_test.dart:279-300`, `lib/models/fiesta/round_transition.dart:104-114`.

- La file du `FiestaEnsembleService` ne reste pas figée après une erreur d’écriture. Une erreur de `_write` est capturée par `_mutate`, qui renvoie `null` (`lib/services/fiesta_ensemble_service.dart:135-145`), et la continuation de file absorbe aussi toute erreur échappée (`:46-49`). Une sauvegarde suivante est donc exécutée.  
  Seul un `Future` de stockage qui ne se résoudrait jamais pourrait bloquer la file, indépendamment d’une erreur ; aucun poison de file après échec n’est présent. Pas de MAJOR.

Revue effectuée en lecture seule ; tests non exécutés.

