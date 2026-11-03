# Notes pour plus tard — dettes techniques ASSUMÉES

Journal des décisions techniques **délibérément reportées**. Une entrée = contexte, décision
reportée, raison, **signal déclencheur**, esquisse d'implémentation. Ce n'est pas une TODO list :
ce qui est ici a été vu, pesé, et laissé de côté sciemment.

Format : `## AAAA-MM-JJ — <titre>` puis les cinq rubriques.

---

## 2026-08-01 — Le dépôt n'a aucun test qui tourne (`test/widget_test.dart` = scaffold)

**Contexte.** Le seul fichier de `test/` est le template Flutter généré à la création du projet :
il fait `pumpWidget(const MyApp())` et teste l'incrément d'un compteur. Or la racine réelle est
`GuessItAllApp` (`lib/app.dart`) et il n'y a jamais eu de compteur. `flutter analyze` remonte
`The name 'MyApp' isn't a class` et **`flutter test` échoue à la compilation** — donc aucune
assertion n'a jamais été exécutée sur ce projet.

**Décision reportée.** Écrire une vraie base de tests (au minimum un smoke test qui monte l'app,
et des tests unitaires sur le scoring et la machine à états).

**Raison.** Le fix n'est pas mécanique : monter `GuessItAllApp` exige un `GameProvider` (qui touche
`SharedPreferences`) et de neutraliser `UpgradeAlert` (qui interroge le store → réseau, donc test
lent et flaky). Décider *comment* on isole ces dépendances est un choix d'architecture de test, pas
une correction — il vaut mieux le trancher avec l'audit de code plutôt qu'en marge d'un portage
d'outillage.

**Signal déclencheur.** Le premier ticket du mode Fiesta qui touche le scoring ou la machine à
états. Le pipeline (`guessitall-workflow`) est TDD : sans suite qui compile, le gate ② n'a pas de
témoin et le mutation testing est impossible.

**Esquisse.** (a) Extraire la construction de l'arbre de widgets pour pouvoir injecter un
`GameProvider` de test ; (b) rendre `UpgradeAlert` conditionnel (désactivé sous
`FLUTTER_TEST=true`) ; (c) commencer par les tests *purs* — modèles `copyWith`, calcul de score,
répartition des mots par joueur — qui ne demandent aucun mock et couvrent le tier risqué le plus
coûteux.

---

## 2026-08-01 — `flutter analyze` : exclusion plutôt que suppression du dossier `backup/`

**Contexte.** `lib/utils/word_categories/backup/` contient du code mort qui **ne compile pas**
(4 `error`). Il est gitignoré, donc absent d'un clone neuf — mais `flutter analyze` lit le disque,
pas l'index git : la baseline était rouge chez Florent et verte partout ailleurs.

**Décision reportée.** Supprimer physiquement le dossier.

**Raison.** Il sert manifestement d'archive locale des listes de mots avant réorganisation.
Le supprimer est une décision de contenu qui appartient à Florent, pas au portage d'outillage.

**Signal déclencheur.** Le prochain passage sur les catégories de mots — ou le jour où quelqu'un se
demande pourquoi `word_categories/` a un jumeau.

**Esquisse.** Vérifier que les JSON de `assets/translations/words/fr/` couvrent bien tout ce que
`backup/` contient, puis `rm -rf` et retirer l'exclusion de `analysis_options.yaml`.

---

## 2026-08-02 — Les analytics restent dans SharedPreferences

**Contexte.** L'audit reprochait à `SharedPreferences` de porter des blobs qui n'ont rien à y
faire : l'état de partie, l'historique des mots, **et l'historique analytique complet**
(`GameAnalytics`, un événement par mot joué). SharedPreferences relit et réécrit **tout le
fichier** à chaque `setString` — le coût croît donc avec la taille du blob, sur le thread de
plateforme. Le chantier 5 devait alléger le persisté *et* sortir les analytics.

**Décision reportée.** La seconde moitié : déplacer `GameAnalytics` vers un stockage adapté
(fichier JSON Lines en append, ou `sqflite`).

**Raison.** Sortir les analytics change le **format d'une donnée déjà installée chez les joueurs**
— et `upgrader` force la mise à jour, donc il n'y a pas de version antérieure vers laquelle
revenir. Ça mérite sa propre story avec sa propre migration, pas un passage en marge d'un lot de
remédiation. Ce qui a été fait à la place et qui suffisait au besoin : le compactage du snapshot
de partie (`clearPreValidationSnapshot`), l'enveloppe de version + quarantaine (`persisted_schema`)
qui rend le format *migrable*, et l'historique des parties écrit dans **sa propre clé** bornée à
10 entrées — donc sans faire grossir le blob analytics.

**Signal déclencheur.** Un joueur régulier qui voit l'app ralentir au fil des parties, **ou** le
premier modificateur Fiesta qui veut journaliser un événement par mot (le mode multiplie
mécaniquement le volume d'événements). Mesure à faire avant de trancher : la taille réelle de
`guessItAll_analytics` après ~30 parties.

**Esquisse.** (a) `AnalyticsService` écrit en append dans un fichier via `path_provider` plutôt que
`prefs.setString` ; (b) borner par nombre de parties, comme `GameHistoryService.maxEntries` ;
(c) la lecture passe par le même `unwrapSchema`/quarantaine que le reste — le contrat de robustesse
est déjà posé, il ne resterait que le support.

---

## 2026-08-02 — Les 66 `info` de `flutter analyze` restent en l'état

**Contexte.** `flutter analyze` sort **non-zero dès le premier `info`**. Le dépôt en a 66,
tous antérieurs au harness, en trois familles : `withOpacity` déprécié (~40 sites d'écrans),
`avoid_print` (loaders de mots, outil de conversion), `use_build_context_synchronously`
(3 sites dans `words_screen.dart`).

**Décision reportée.** Les solder. `run-full-suite.sh` gate donc sur **error + warning** et se
contente d'**afficher** le compte d'infos.

**Raison.** Les trois familles sont de nature différente et deux ne sont pas cosmétiques :
`use_build_context_synchronously` est un vrai risque (utiliser un `BuildContext` après un `await`
sur un widget démonté), tandis que `withOpacity` est une migration mécanique mais qui touche ~40
sites d'écrans sans rapport avec ce lot. Les mélanger dans un lot de remédiation aurait noyé les
changements de comportement sous un diff de style.

**Signal déclencheur.** (a) La montée de version Flutter où `withOpacity` passe de *deprecated* à
*supprimé* — le build casse alors d'un coup ; (b) tout bug d'écran blanc / `setState` après
démontage sur `words_screen.dart`, qui pointerait droit sur les 3 `use_build_context_synchronously`.

**Esquisse.** Traiter `use_build_context_synchronously` **d'abord et séparément** (3 sites, vraie
correction), puis `withOpacity` → `withValues(alpha:)` en un sweep mécanique isolé, puis décider
pour `avoid_print` (un `debugPrint` conditionnel, ou une exclusion assumée dans
`analysis_options.yaml` pour `tools/`). Une fois à zéro, durcir `run-full-suite.sh` en
`--fatal-infos` pour que la baisse soit un cliquet.

---

## 2026-11-03 — « Rejouer » de l'accueil après un kill : la config Fiesta est perdue

**Contexte.** Story 2-4. Après une partie Fiesta, le bouton maison des résultats efface l'état de
jeu (`endGameAndGoHome` → `clearGameState`). La config reste en mémoire seulement (Q10). Si l'app
est tuée ensuite, le « Rejouer » de l'accueil repart en Classique (Paramètres).

**Décision reportée.** Persister la dernière config Fiesta pour « Rejouer ».

**Raison.** Q10 interdit de persister le choix du mode ; le cas exige fin de partie + kill +
Rejouer, et le joueur retrouve la Fiesta en deux écrans. Pas de crash, pas de donnée corrompue.

**Signal déclencheur.** Un retour joueur « Rejouer a perdu mes réglages Fiesta », ou une story qui
persiste déjà quelque chose de voisin (le `lastUsedId` des ensembles de 2-3).

**Esquisse.** En Personnalisé, retrouver l'ensemble via `lastUsedId` (clé des ensembles, déjà
persistée) ; en Auto, les deux interrupteurs dans cette même clé ou dans la session.


---

## 2026-11-03 — Fiesta : le tirage d'une manche ignore les instances qui survivent au passage de manche

> ✅ **Résolu (epic fix, B1).** Les survivantes (instances de N) ne pèsent que sur la
> continuation, les instances de N+1 que sur les vrais tours (`modifiersForTurn`) : elles ne se
> croisent jamais sur un tour, le plafond n'a plus à les comparer.

**Contexte.** Story 2-5, revue r1 (MINOR-3). `nextRound` garde les instances de portée **tour**
et ajoute les modificateurs de la nouvelle manche (fixés + tirage) sans `canAdd` contre ces
survivantes. Aujourd'hui rien d'autre n'écrit dans `active`, donc aucune n'existe.

**Décision reportée.** Pas de `canAdd` entre survivantes et tirage dans 2-5.

**Raison.** Q8 : le tirage symétrique passe **d'abord** dans le plafond. Le faire dépendre des
survivantes casserait aussi l'aperçu de la transition (`nextRoundModifiers`), qui doit rester une
fonction de `(rules, gameId, manche)` seule. C'est donc à l'écrivain suivant de s'adapter.

**Signal déclencheur.** 2-8 ou 2-10 pose une instance dans `active` qui peut franchir une fin de
manche (charge non consommée, offre de 1 parmi 3 posée avant `nextRound`).

**Esquisse.** Invariant à tenir par 2-8 / 2-10 : une instance de portée tour est consommée à la
fin de son tour. ⚠️ Cas piège : la **continuation de fin de manche**
(`pendingBonusTurnId`) — le tour commencé en manche N se poursuit en N+1 avec la même équipe, donc
une instance de portée tour posée sur ce tour franchit le passage de manche. 2-8 doit la
consommer à la fin du tour de continuation, pas à la fin de la manche. Une offre de fin de manche est posée **après** le tirage (dans `nextRound`, ou
avec `canAdd` contre `nextRoundModifiers`). Sinon, filtrer les survivantes par `canAdd` contre le
tirage (jamais l'inverse).

---

## 2026-11-03 — Fiesta : l'aperçu du tirage est recalculé par le code de l'app

**Contexte.** Story 2-5, revue r1 (MINOR-4). Le tirage de la manche suivante n'est pas stocké :
la transition le recalcule depuis `(rules, gameId, manche)`, et `nextRound` le pose dans
`fiesta.active` (qui reste ensuite la seule source de vérité).

**Décision reportée.** Ne pas stocker l'aperçu.

**Raison.** Le seul écart possible est une mise à jour de l'app (forcée par `upgrader`) entre la
transition et « Manche suivante », avec un catalogue ou un `drawSymmetric` modifié : l'aperçu et
le tirage posé différeraient. C'est rare (app tuée + mise à jour sur la transition) et sans crash.

**Signal déclencheur.** Tout changement de `kModifierCatalog` (ordre, ajout, retrait), de
`drawSymmetric` / `fixedForRound` ou de `drawSeed` : c'est un changement de forme « logique »
pour les parties en cours (règle 7).

**Esquisse.** Soit stocker l'aperçu dans `FiestaState` en fin de manche (champ optionnel,
absent = recalcul), soit versionner l'algorithme dans `FiestaState` et garder l'ancien.

---

## 2026-11-03 — Analytics : le contexte du tour n'est pas restauré après un kill

> ✅ **Résolu (epic fix, A5).** Le provider passe un `WordEventContext` relu de `GameState` à
> chaque événement ; le service ne garde plus de contexte en mémoire.

**Contexte.** Story 2-7, revue r1 (MINOR-4). `AnalyticsService.resumeGame` relit la partie mais
remet à zéro le contexte du tour (`_lastRound`, `_lastTurn`, `_lastTeamId`, `_lastPlayerId`,
`_lastModifiers`). Une vérification faite juste après un kill, sans nouveau `shown`, écrit donc
ses événements avec `round` 1, `teamId` '' et sans `modifiers`.

**Décision reportée.** Ne pas restaurer ce contexte dans 2-7 (défaut antérieur pour
`round`/`turn`/`teamId`, documenté dans `docs/ANALYTICS.md`).

**Raison.** Scénario rare (kill entre la fin du tour et la validation), sans effet sur le jeu ni
sur `WordHistoryService` ; seule la ventilation par manche/équipe/modificateur de ces quelques
événements est fausse ou absente.

**Signal déclencheur.** Une analyse par manche ou par modificateur qui montre des événements
`invalidated` en manche 1 / équipe vide, ou 2-11 qui retouche `resumeGame`.

**Esquisse.** Dans `resumeGame`, reprendre le contexte du dernier événement relu
(`round`, `turn`, `teamId`, `playerId`, `modifiers`), sans toucher au bloc « mot affiché ».

---

## 2026-11-03 — `GameProvider` : extraction du modèle de lecture Fiesta (`FiestaView`)

**Contexte.** Revues de fin d'epic Fiesta (Opus M5, Codex MAJOR-5). `game_provider.dart` est à
~2 020 lignes ; ~400 sont des getters Fiesta dérivés de `(fiesta, teams, currentTeamIndex,
currentRound, history, currentScreen, gameId)`, mêlés aux mutations. L'epic fix a déjà sorti
l'état du tour typé (`FiestaTurnState`), le plan de passage de manche (`planRoundTransition`) et
les effets d'un tour (`modifiersForTurn`), et factorisé ×2 / deux mots.

**Décision reportée.** Pas d'extraction `FiestaView` avant la release Fiesta.

**Raison.** Refactor à comportement constant, rien de persisté ; le risque (≈400 lignes
déplacées juste avant le build store) dépasse le gain immédiat.

**Signal déclencheur.** Un nouveau modificateur ou une nouvelle règle Fiesta qui ajoute des
getters au provider, ou le provider qui dépasse ~2 100 lignes.

**Esquisse.** `lib/models/fiesta/fiesta_view.dart` : classe pure construite sur
`(GameState, teams, settings)`, qui porte `isContinuation`, `currentTeamModifiers`, passes,
charges, devineur bloqué, offres, file de choix, récap. Le provider garde les mutations et
délègue ses getters ; tests purs sans provider.

---

## 2026-11-03 — Analytics : ignorer les durées nulles dans le plus dur, le plus rapide et les classements

**Contexte.** Depuis l'epic fix (A5), un mot déjà à l'écran au moment d'un kill a un événement
terminal avec `durationMs` nul : la durée est inconnue, jamais inventée. Plusieurs calculs
comptent cette durée nulle comme 0 ms :
- `WordRoundStats.totalTimeMs` et `PassEvent` ;
- `GameAnalytics.hardestWord` / `fastestWord` ;
- `AnalyticsService.getHardestWords` / `getFastestWords` / `getStatsByCategory` /
  `getStatsByDifficulty`.

Un mot sans durée peut donc sortir « le plus rapide ». Aucune moyenne ne lit ces durées : le
« Temps moyen par mot » de l'écran Stats repose sur `HistoryEntry.timeSpent`.

**Décision reportée.** Pas de changement maintenant (arbitrage orchestrateur, B6).

**Raison.** Aucun de ces calculs n'est lu par l'interface aujourd'hui. Firestore reçoit les
événements bruts, avec la durée nulle conservée.

**Signal déclencheur.** Un écran qui affiche l'un de ces classements, ou qui calcule une moyenne
sur `durationMs`.

**Esquisse.** Ignorer les événements à `durationMs` nul dans le plus dur / le plus rapide, les
classements et toute moyenne. Garder les totaux tels quels, ou les marquer « partiels ».
