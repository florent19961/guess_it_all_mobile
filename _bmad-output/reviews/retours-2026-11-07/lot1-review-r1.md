# NOT READY

Revue en lecture seule du prompt, du patch et du worktree. Aucun test ni mutation exécutable n'a été lancé, conformément à la consigne de revue.

## BLOCKER

Aucun.

## MAJOR

### M-1 — Une instance historique active réactive l'affichage et les analytics de la carte retirée

**`lib/models/fiesta/round_transition.dart:124`**

Scénario concret : une sauvegarde v4 contient dans `fiesta.active` une instance valide de `two_words` pour la manche courante (avec `scope`, `target`, `nature` et `round` valides), en plus des formes historiques déjà lues (`earned`, `chargesUsed`, règles gelées, etc.). `FiestaState.tryFromJson` la conserve car `modifierById('two_words')` résout désormais l'id retiré. `modifiersForTurn` l'ajoute alors aux règles actives sans vérifier qu'elle appartient encore à `kModifierCatalog`.

Elle est donc exposée par `roundRulesThisTurn`, dessinée dans `FiestaTurnZone` comme « Deux mots à la fois » et incluse dans `_eventContext.modifiers` pour les événements `shown`/`guessed`/`passed`/`expired` du nouveau tour. La cartouche ne tire plus une carte B, mais elle réapparaît à l'écran et fausse les analytics : violation directe de D4 (« rien à l'écran », historique seul) et de l'intégrité des tags.

Correctif suggéré : séparer la lisibilité historique de l'exécutabilité. Conserver `modifierById` pour les récapitulatifs, `earned`, `chargesUsed` et règles gelées, mais filtrer toute instance retirée des chemins runtime (`active` à la relecture, ou au plus tard `modifiersForTurn`/la résolution de tour). Ajouter une régression qui relit cette instance active, traverse avant-tour, chrono et snapshot/restauration, puis vérifie absence de badge et de tag `two_words`.

### M-2 — Les nouveaux tests de tirage ne tuent pas les mutations annoncées de la graine ni ne figent les poids prescrits

**`test/models/fiesta/cartridge_gifts_test.dart:179`**

Scénario concret : remplacer `giftSeed(gameId, finishedRound, teamId)` par une graine qui ignore `teamId`, ou qui ignore `finishedRound`, laisse passer ce test. Il n'observe que l'équipe `b` et uniquement `finishedRound: 1`; il vérifie la variation avec `gameId`, mais jamais que la manche et l'équipe participent à la sortie. Une partie suspendue pourrait alors distribuer le même tirage à toutes les équipes ou répéter celui de la manche précédente, sans être détectée avant la correction de score/rejeu de transition.

Le test de pondération voisin (`:160`) est également trop large pour la valeur normative demandée : il n'asserte pas `kGiftWeights = (3, 1)` et sa borne inclusive commence à `0.25`. Une mutation `byDefault: 4` a un rapport théorique `double_points/autre = 1/4`, donc peut être acceptée par l'échantillon déterministe malgré une calibration contraire à D2.

Correctif suggéré : garder les tests statistiques de comportement, mais ajouter des assertions exactes sur les deux champs de `kGiftWeights`, ainsi que des cas à entrée identique qui changent séparément la manche puis l'équipe (idéalement directement sur `giftSeed`, ou avec des sorties de `roundGifts` à fixture fixe). Ajouter un scénario `planRoundTransition` recalculé après correction : les préfixes déjà dus restent identiques tant que le nombre de cadeaux ne change pas, et l'application unique ne duplique rien.

## MINOR

### N-1 — Le nom du test du catalogue est resté à 18 ids après la suppression

**`test/models/fiesta/fiesta_catalog_test.dart:20`**

Scénario concret : le libellé promet « 18 ids uniques », alors que l'assertion juste dessous attend les 17 ids du catalogue courant. Cela ne fait pas échouer la suite, mais induit la prochaine modification ou revue en erreur et masque précisément l'intention de D4.

Correctif suggéré : renommer le test en « 17 ids uniques ».

## Contrôles sans finding

- Les clés historiques de tour (`twoWords`, `secondWord`, `secondExpiredWord`) sont ignorées à la relecture; avec une carte B dans `remainingWords`, les chemins mot unique (trouvé, passé, expiration, vérification et continuation) ne la retirent qu'une fois. `resolveTurn(expiredWords:)` peut donc rester une liste d'au plus un mot.
- `earned`, `chargesUsed`, les règles gelées et les ensembles enregistrés restent lisibles et nommés par le catalogue de lecture seule. Tous les `modifierById(...)!` recensés résolvent bien `two_words`; le danger est son exécution via `active`, signalée ci-dessus, pas une levée de null.
- `allCount` est relu jusqu'à 10, 11 est refusé, et le stepper « À tous » utilise `kMaxAllCount`; les autres compteurs restent bornés à 5. Les ensembles fournis, leurs résumés et les textes D5 correspondent aux décisions D1/D5.
- Le tirage de cadeaux est avec remise, pondéré, pur par graine et indépendant du score à cardinalité égale. Le retrait de `two_words` ne modifie pas `roundModifiers`, car il était déjà exclu des règles de manche; le plan de cadeaux non persisté peut légitimement être recalculé une fois à la mise à jour, sans double écriture.
- `_shownAt` reste une `Map<String, int>` et le suivi durée par mot demeure cohérent pour le tour à une carte. Les CLAUDE.md touchés décrivent le retrait; aucune skill maison active ne décrit encore le comportement retiré.

## Mutation testing

Exécution non réalisée : la demande de revue interdit explicitement de lancer des tests, donc aucune copie mutée ni commande de test n'a été exécutée.

Analyse statique des tests ajoutés :

- **Tuées par inspection :** retour à un tirage sans remise (le test « avec remise » exige une répétition); suppression de la borne de relecture `allCount = 10`; réintroduction de `two_words` dans `kModifierCatalog` ou `kChargeBonusKeys`.
- **Survivantes par inspection :** suppression de `teamId` ou de la manche de `giftSeed` (M-2); donnée legacy `active: two_words`, snapshot de vérification, et ensemble personnel ne contenant que `two_words` (aucun test ajouté ne les exerce tous; M-1 est actuellement réel).
- **Non verrouillée de façon déterministe :** une valeur de poids par défaut différente telle que 4, car le test de fréquence ne vérifie pas la constante exacte et accepte le rapport théorique 1/4 à sa borne basse.
