# Revue Codex — lane 1 r1 (2026-11-04)

## Verdict

**NOT READY** — revue strictement en lecture seule, aucun fichier modifié.

Aucun BLOCKER identifié.

## MAJOR

- `lib/providers/game_provider.dart:1406` — `two_words` en mode `always` ou `draw` est traité comme une cartouche activable, alors que ces modes doivent être des règles actives toute la manche, sans décision. Le filtre enlève indistinctement `two_words` de `turnModifiers`.

  Scénario : régler « Deux mots à la fois » sur `Toujours`, M1. Sans appuyer sur « Activer », le premier tour n’affiche qu’un mot ; le joueur doit l’armer pour chaque tour. Auto peut aussi le tirer et produire cette cartouche, contraire à « pas de cartouches en Auto ».

  Correction : distinguer dans l’état l’origine règle-de-manche/cartouche (ou un équivalent) et appliquer automatiquement `two_words` quand l’instance vient de `always`/`draw`. Ajouter un test de tour complet avec `two_words: always` et un test Auto.

- `lib/models/fiesta/symmetric_draw.dart:183` — les malus `stock` sont exclus de `stockForRound`. Leur réglage est bien sérialisé dans les règles, mais aucune cartouche attribuée n’est présente dans `FiestaState.active`, donc elle n’est pas persistée à l’entrée de la manche.

  Scénario : lancer l’ensemble fourni « Explosif ». Les bonus en stock sont actifs, mais aucun malus (`no_pass`, `minus_10s`, etc.) n’existe dans l’état de partie, y compris après kill/reprise. Ce n’est pas seulement le résidu lane 2 « sans effet » : la réserve elle-même n’est pas conservée.

  Correction : créer et persister les instances de stock pour tous les modificateurs ; la lane 2 peut ensuite ne pas les appliquer tant que l’UI de réserve n’est pas livrée. Le test `symmetric_draw_test.dart:199` doit cesser d’encoder « bonus seulement ».

- `lib/providers/game_provider.dart:855` — les passes gratuites consommées ne créent jamais de `ChargeUse`, alors que `stockForRound` déduit le stock « pour la partie » uniquement de cette liste.

  Scénario : `free_pass` en stock, 1 cartouche, M1–M3, « pour la partie » ; une équipe utilise sa passe gratuite en M1. En M2, elle reçoit à nouveau une passe : `freePassesUsed` a été remis à zéro et `chargesUsed` ne contient rien pour `free_pass`.

  Correction : gérer un solde réellement consommable pour `free_pass`, persistant et pris en compte au changement de manche ; à défaut, désactiver l’option « pour la partie » pour cette simplification provisoire.

- `lib/providers/game_provider.dart:2174` — un `preValidationSnapshot` Fiesta v1 peut être restauré comme une partie Classique. La protection d’abandon v1 n’existe que dans `_loadData`, pas dans `restorePreValidationState`.

  Scénario : une partie externe v2 valide contient un snapshot de vérification v1. Après « Retour à la vérification », `GameState.fromJson` met `fiesta` à `null`, puis l’état est restauré et sauvegardé en Classique, au lieu d’être abandonné proprement.

  Correction : centraliser la détection « clé fiesta présente mais FiestaState illisible » et l’appliquer aussi à toute restauration de snapshot ; abandonner la partie ou refuser la restauration sans muter l’état courant. Ajouter ce cas au test v1.

- `lib/screens/fiesta_ensembles_screen.dart:132` — le brouillon statique peut être effacé par l’enregistrement d’un autre ensemble.

  Scénario : créer un brouillon incomplet, revenir (« Brouillon gardé »), puis modifier et enregistrer un ensemble existant. Le brouillon de création n’est pas repris dans le second éditeur mais `EnsembleSaved` met quand même `FiestaEnsemblesScreen.draft = null`.

  Correction : conserver les brouillons par `ensembleId` (avec une clé dédiée au nouveau), ou au minimum ne supprimer que le brouillon effectivement repris/enregistré. Ajouter un test création-brouillon → édition-enregistrement → reprise du brouillon.

- `test/providers/fiesta_pick_three_test.dart:51` — la machine à états multi-rangées n’est pas testée. Tous les parcours provider utilisent `pick3Choices = 1`; seul le générateur pur de rangées est couvert dans `offers_test.dart`.

  Scénario de mutant : faire retourner `_doneChoosing` vrai dès qu’une équipe a choisi une seule carte. La suite actuelle resterait verte, mais avec `pick3Choices: 2` l’équipe pourrait passer en manche suivante après la première rangée, perdant la seconde.

  Correction : couvrir en intégration 2 et 3 rangées : blocage de `nextRound` après la première sélection, reprise après kill, application de toutes les cartes choisies, et impossibilité de choisir deux fois une rangée.

## MINOR

- `test/models/fiesta/ensemble_validation_test.dart:20` — le test annonce vérifier « les 7 ensembles fournis », mais ne vérifie ni le nombre, ni les ids/noms attendus. Supprimer par mutation « Pictionnary » ou « Bilingue » laisserait ce test vert.

  Correction : vérifier les 7 ids dans l’ordre, leurs noms, et les paramètres distinctifs imposés par la spec.

Parité mobile : le bouton de retour et le retour Android passent bien par la même logique `_back`; `PopScope(canPop: false)` bloque le geste de retour iOS natif, mais l’action visible de retour reste commune.

