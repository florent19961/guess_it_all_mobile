# Revue Codex — Epic 2 « Mode Fiesta »

> Restauré par l'orchestrateur le 2026-11-03 à partir de sa lecture intégrale du rapport
> (le fichier original, non commité, a été supprimé avec le worktree de revue). Contenu inchangé.

## Verdict : **NOT SHIPPABLE**

Revue **strictement statique** du diff cumulatif, du code final, des specs, du
journal d'arbitrages et des revues par story. Aucun programme Flutter/Dart ni
aucun test n'a été exécuté. Le verdict ne préjuge donc pas de la recette
Android/iOS ; il constate des ruptures de contrat démontrables à la lecture.

| Gravité | Sujet |
|---|---|
| BLOCKER | Une partie Classique réécrite prend le nouveau champ `turnAllottedSeconds`, sans migration, contrairement au contrat octet-identique. |
| MAJOR | Une continuation peut cumuler plus de deux modificateurs effectifs après le passage de manche (`×2`/deux mots/block + deux tirages). |
| MAJOR | Après un kill, les analytics perdent les événements terminaux des cartes visibles et écrivent les validations avec un faux contexte. |
| MAJOR | Le graphe « Évolution des scores » ne compte pas le multiplicateur ×2 et diverge du score affiché. |
| MAJOR | Le contrat de sérialisation Fiesta « absent si vide/null » n'est pas tenu par plusieurs sous-champs. |
| MAJOR | `GameProvider` (2 061 lignes, +628 sur l'epic) et `FiestaState.turn` non typé ont déjà produit des invariants croisés difficiles à tenir. Une extraction est requise avant la release. |

## Points vérifiés qui tiennent

- `nextRound()` est bien gardé par l'écran `transition` et par la file `nextChooserId` : un double tap ne rejoue pas le passage de manche, et un choix persistant bloque le passage après kill. Les tirages, cadeaux Auto et choix sont calculés avant la mutation puis appliqués dans une seule écriture (`lib/providers/game_provider.dart:1210-1242`, `:1551-1631`). Le retour arrière restaure le snapshot pré-validation, donc les aperçus sont recalculés sur les scores restaurés.
- La continuation ne consomme pas le rattrapage : `startTurnTimer` teste `turnBonusTime` avant de le vider (`lib/providers/game_provider.dart:583-598`). Les compteurs et états `spent` de ×2/deux mots passent bien la frontière de manche, puis `_fiestaAfterTurn` les vide à la vraie fin (`:1124-1140`, `:1506-1520`).
- Le score canonique est calculé une fois par `resolveTurn(pointsMultiplier:)` puis ajouté simultanément à `Team.score` et `scoreByRound` (`lib/models/turn_resolution.dart:75-123`, `lib/providers/game_provider.dart:1016-1061`). Les chemins free-pass, rattrapage et deux mots n'altèrent pas ce calcul. Le problème de visualisation du score est traité en MAJOR-3.
- Les ajouts analytics et Firestore sont bien absents en Classique : `gameMode`, `fiestaRules`, `WordEvent.modifiers`, `GameResult.mode` et `modifierRecap` sont conditionnels (`lib/models/game_analytics.dart:261-282`, `lib/models/word_event.dart:99-112`, `lib/models/game_result.dart:135-146`). Firestore envoie directement ce JSON (`lib/services/firebase_sync_service.dart:163-177`).
- La nouvelle clé d'ensembles est bien enveloppée/versionnée dès la première écriture (`lib/services/fiesta_ensemble_service.dart:35`, `:147-190`; `lib/services/persisted_schema.dart:18-22`).

## Findings

### BLOCKER-1 — le blob `guessItAll_gameState` Classique change sans migration

- **Emplacements :** `lib/providers/game_provider.dart:646-657`, `lib/models/game_state.dart:83-87`, `:293-298`, `lib/services/persisted_schema.dart:18-22`.
- **Scénario :** une partie Classique existante est relue correctement, puis son prochain `startTurnTimer()` écrit systématiquement `turnAllottedSeconds`. `GameState.toJson()` l'émet alors, même si `fiesta == null`; l'enveloppe de schéma reste à 1 et aucune migration ne borne ce nouveau format. Une partie Classique nouvellement créée l'écrit également. Le test de compatibilité ne fait qu'un aller-retour du littéral hérité, sans passer par le provider/timer (`test/models/game_state_test.dart:154-208`), donc il ne détecte pas cette réécriture.
- **Impact :** cela contredit la règle 7 et le contrat de l'epic (« Classique octet-identique »), ainsi que l'instruction explicite de cette revue : tout changement de forme d'une clé `guessItAll_*` publiée est un BLOCKER. Le journal accepte ce compromis (`journal-arbitrages.md:19`), mais il ne le rend ni migré ni octet-identique.
- **Fix :** choisir explicitement l'un des deux contrats avant release. Pour tenir le contrat actuel, ne persister `turnAllottedSeconds` que dans Fiesta (ou conserver le calcul historique en Classique) et ajouter un test qui fait démarrer un tour à partir du blob Classique figé puis compare le blob complet. Si la correction Classique doit absolument survivre à un kill, introduire une migration/version de schéma explicitement approuvée — ce n'est pas compatible avec la promesse d'identité d'octets, qui doit alors être amendée avant la release.

### MAJOR-1 — le plafond de deux modificateurs est cassé sur une continuation

- **Emplacements :** `lib/providers/game_provider.dart:601-643`, `:1124-1140`, `:1250-1264`, `:1382-1415`, `:1445-1476`; `lib/models/fiesta/symmetric_draw.dart:124-138`.
- **Scénario :** une équipe termine M2 avec du temps reporté après avoir activé `double_points` ou `two_words`, ou après avoir reçu `block_guesser` via le choix de M1. La continuation est le même tour : l'état `fiesta.turn`/l'instance de portée tour est donc correctement conservé. `nextRound()` retire les instances de manche M2 mais `_fiestaForRound()` ajoute jusqu'à deux tirages M3 sans compter cet état survivant. La continuation peut donc jouer avec ×2 (ou deux cartes, ou un devineur bloqué) **et** deux modificateurs M3 : trois effets actifs pour la même équipe et le même tour.
- **Impact :** Q8 (« deux modificateurs actifs au maximum par équipe et par tour ») ne tient plus précisément sur le chemin qui unit 2-8, 2-9, 2-10 et 2-11. Les getters de plafond ne protègent que l'armement futur ; ils ne peuvent pas réparer les effets déjà actifs. L'écran peut aussi afficher trois badges.
- **Fix :** définir dans un unique modèle la composition des effets du *logical turn*, y compris les états `spent`, les deux cartes et les instances de portée tour. Construire le plan de transition contre cet état avant de muter `active`, avec une règle produit explicite pour la priorité du tirage symétrique face à une continuation. La même fonction pure doit alimenter l'aperçu et l'application. Ajouter les scénarios M2→M3 pour ×2, deux mots et `block_guesser`, chacun avec retour arrière, kill et double tap.

### MAJOR-2 — reprise analytics : pertes silencieuses et faux tags après kill

- **Emplacements :** `lib/services/analytics_service.dart:101-112`, `:150-158`, `:167-278`; `lib/providers/game_provider.dart:117-123`, `:669-691`, `:1016-1050`; `docs/ANALYTICS.md:44-66`.
- **Scénario :** après un kill pendant un tour, `resumeGame()` recharge les événements mais efface `_shownAt` et le contexte `_last*`. Les actions sur A ou B déjà affichées font alors sortir `_recordEventWithDuration` sans événement (`:260-278`). Après un kill sur l'écran de vérification, `invalidated` et « validé comme deviné » utilisent `round: 1`, `turn: 1`, équipe vide et `modifiers: null` (`:214-254`). Le cas est documenté, mais cette documentation confirme la donnée silencieusement inexacte ; elle ne la rend pas intègre.
- **Impact :** la garantie 2-7 de tags par modificateur et la garantie 2-11 d'un suivi par carte cessent de tenir sur kill/reprise. Avec deux mots, jusqu'à deux événements terminaux sont perdus; à la vérification, les compteurs par manche/équipe/modificateur sont faux. C'est un risque de tier « intégrité analytics », pas seulement une durée inconnue.
- **Fix :** passer un contexte de tour explicite depuis `GameState` aux événements post-reprise, plutôt que de laisser `AnalyticsService` inventer des défauts. Pour les cartes restaurées, conserver/rehydrater un état « shown sans durée connue » et enregistrer le terminal avec durée nulle/absente plutôt que de l'omettre; ne jamais fabriquer une durée. Ajouter un test de processus réel (`forgetCurrentGame`), pendant le tour avec deux cartes puis sur vérification, qui vérifie événements, round/team et tags.

### MAJOR-3 — le graphe de score ment dès qu'un mot compte double est validé

- **Emplacements :** `lib/screens/stats_screen.dart:327-381`; contraste avec `lib/providers/game_provider.dart:1031-1061` et `lib/models/turn_resolution.dart:72-123`.
- **Scénario :** un tour à ×2 valide deux mots. Le score d'équipe et `scoreByRound` gagnent 4 points, correctement. L'historique ne porte que `wordsGuessed`, et le graphe nommé « Évolution des scores » ajoute `entry.wordsGuessed.length` : il n'ajoute que 2. Une continuation est fusionnée visuellement avec le point précédent mais conserve la même erreur.
- **Impact :** les scores détaillés et le graphe de score divergent pendant une Fiesta, alors que ce dernier affirme représenter les scores. Ce n'est pas une simple métrique de mots : le code et le libellé le présentent comme un score.
- **Fix :** porter un `pointsScored` optionnel dans `HistoryEntry` (omis quand il égale le nombre de mots, lecture tolérante avec fallback historique), puis faire consommer ce champ au graphe. Cela préserve les blobs Classique existants et rend la propriété testable : à chaque point du graphe, la dernière ordonnée doit égaler `Team.score`. Couvrir ×2 + deux mots + continuation + retour arrière.

### MAJOR-4 — le contrat de persistance Fiesta est incomplet

- **Emplacements :** `lib/models/fiesta/fiesta_state.dart:66-126`, `lib/models/fiesta/fiesta_rules.dart:28-55`, `:155-221`, `lib/models/fiesta/modifier_instance.dart:39-85`, `lib/services/fiesta_ensemble_service.dart:180-191`.
- **Scénario :** le lecteur est généralement tolérant, mais l'écrivain émet des clés vides/nulles qui devraient être absentes. Cela augmente inutilement le format qui doit rester évolutif avant la première release Fiesta et rend flou le sens d'absence.
- **Impact :** la règle demandée (« optionnel, omis vide/null, lu tolérant ») n'est pas tenue de bout en bout. Ce n'est pas encore une régression de données Fiesta en store, mais doit être corrigé avant l'unique build afin de ne pas figer ce contrat bancal.
- **Fix :** rendre les sorties conditionnelles et ajouter une matrice de sérialisation figée couvrant les omissions ci-dessous.

| Zone / clé ajoutée | Écriture actuelle | Lecture | Verdict |
|---|---|---|---|
| `GameState.fiesta` | absente si nulle (`game_state.dart:293-298`) | tolérante | conforme |
| `GameState.turnAllottedSeconds` | absent si nul, mais posé aussi en Classique (`game_provider.dart:653`) | tolérante | **BLOCKER-1** |
| `fiesta.rules` | requis pour une Fiesta | tolérante | conforme (structurel) |
| `fiesta.active` | toujours `[]` si vide | tolérante | à omettre vide |
| `fiesta.turn` | toujours `{}` si vide | tolérante | à omettre vide; ses six clés sont elles-mêmes conditionnelles |
| `fiesta.catchUpDue` | toujours `{}` si vide | tolérante | à omettre vide |
| `fiesta.chargesUsed` / `offerChoices` | omis vides | tolérante entrée par entrée | conforme |
| `rules.ensembleName` | écrit `null` en Auto | tolérante | à omettre nul |
| `ModifierSetting.fixedRound` | écrit `null` hors réglage fixed | tolérante | à omettre nul |
| `ModifierInstance.teamId` / `playerId` | écrit `null` quand cible `both` | tolérante | à omettre nuls |
| `guessItAll_fiestaEnsembles` | enveloppe versionnée | tolérante/quarantaine | conforme; `lastUsedId: null` doit être omis |
| Analytics/résultat (`gameMode`, `fiestaRules`, `modifiers`, `mode`, `modifierRecap`) | absents en Classique | tolérants | conforme |

### MAJOR-5 — dette structurelle : provider géant et état de tour magique

- **Emplacements :** `lib/providers/game_provider.dart:1-2061`; `lib/models/fiesta/fiesta_state.dart:16-18`; `lib/models/fiesta/turn_effects.dart:6-25`.
- **Scénario :** l'epic ajoute 628 lignes au provider, qui atteint 2 061 lignes, et concentre maintenant le cycle de vie du jeu, persistance, analytics, résolution, transition de manche, offres, charges et les six clés de `Map<String, dynamic> turn`. La même map encode des compteurs (`int`), des états (`armed`/`spent`) et des mots (`String`). La rupture MAJOR-1 est la conséquence directe : aucun type ne représente l'ensemble des effets actifs d'un même tour.
- **Impact :** c'est un time bomb de maintenance, pas un simple sujet de nommage. Chaque story a ajouté une branche dans le même orchestrateur ; un futur effet devra connaître tous les chemins `startTurnTimer`/`endTurn`/`validateWords`/`nextRound`/undo/kill. La documentation annonce encore « ~1276 lignes » (`lib/providers/CLAUDE.md:7`), donc elle ne signale même plus l'ampleur réelle.
- **Fix :** avant release, extraire un `FiestaTurnState` immuable et typé (compteurs, charges, cartes A/B, expirations, sérialisation conditionnelle) et des fonctions pures de planification/application de transition de manche. Le provider doit redevenir l'orchestrateur des services et de la navigation, pas le propriétaire de chaque règle. Mettre à jour `lib/providers/CLAUDE.md` avec la frontière et la taille réelles.

## Qualité globale des tests (lecture seule)

La suite apporte une vraie valeur locale : les règles pures (tirage, offres, rattrapage, résolution) et plusieurs invariants risqués sont ciblés. Les tests de continuation couvrent séparément les compteurs, ×2 et deux mots; les tests de sérialisation vérifient de nombreuses relectures tolérantes.

Elle ne constitue toutefois pas un filet cumulatif suffisant :

- le test de blob Classique ne traverse pas `startTurnTimer`, d'où BLOCKER-1 ;
- le test « kill » deux mots ne tue pas le singleton analytics, donc ne couvre pas `_shownAt`/`_last*` réels ;
- aucun scénario ne combine continuation M2→M3, deux tirages, puis ×2/deux mots/block ;
- aucun test ne relie les points affichés dans `Team.score` au graphe de scores.

Après les corrections, ces quatre tests de frontière sont nécessaires en plus de la suite complète et des recettes device Android **et** iOS prévues par les stories.

## Refactors before release

1. Remplacer `FiestaState.turn: Map<String, dynamic>` par un modèle immuable typé, avec JSON conditionnel et parsing tolérant.
2. Extraire de `GameProvider` une planification pure de transition (`draw + gifts + choices + catch-up + effets qui survivent`) utilisée tant par l'aperçu que par l'application atomique.
3. Donner à l'historique de tour une représentation explicite des points, afin que les graphes ne reconstruisent pas un score depuis un nombre de mots.
4. Rétablir un contexte analytics explicite après reprise, en séparant « durée inconnue » de « événement absent ».

## Safe to defer

- Le recalibrage produit des forces/seuils de `offers.dart`, après des parties réelles.
- La version logique du tirage déterministe entre deux releases, déjà tracée dans `docs/notes_pour_plus_tard.md:163-180`; la V1 peut rester figée pour ce build.
- « Rejouer » depuis l'accueil après un kill perd encore la configuration Fiesta, comportement explicitement différé par Q10 et sans corruption de partie.
- L'héritage du compteur par une `free_pass` de manche N+1 pendant une continuation est une contrepartie déjà documentée (`docs/tracking_evolution.md:495-501`). Il peut rester différé **uniquement si Florent confirme cette règle produit**; il ne doit pas être confondu avec le dépassement de plafond de MAJOR-1.
