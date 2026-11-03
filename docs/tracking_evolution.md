# Tracking evolution — journal de bord technique

Une entrée **datée** par décision technique ou implémentation significative : ce qui a changé et
**pourquoi ce choix**. C'est la mémoire des raisons, pas un changelog de commits (git le fait déjà).

Format : `## AAAA-MM-JJ — <titre>` puis *Quoi* / *Pourquoi* / *Conséquence*.

---

## 2026-08-01 — Portage du harness agent depuis WasReal

**Quoi.** Mise en place de l'outillage agent du projet, calqué sur celui de WasReal et **adapté au
profil de guess-it-all** :

- `.claude/skills/` — 60 skills BMad + `grill-me`, `grilling`, `challenge-spec`, `teach-back`,
  `thermo-nuclear-code-quality-review`, plus **3 skills projet écrites pour ce dépôt** :
  `guessitall-workflow` (pipeline + gate ② + release store), `guessitall-pr-closeout`,
  `guessitall-epic-intake`.
- `_bmad/` vendored (`project_name` = `guess_it_all_mobile`, module test recalibré :
  `test_framework: flutter_test`, Playwright/browser automation désactivés).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — la colonne vertébrale US → epic → gate.
- `scripts/` — `with-test-slot.sh` (sémaphore RAM), `run-full-suite.sh` (plancher déterministe
  format + analyze + test), `sync-agent-memory.sh` (mirror de l'auto-memory).
- `.codex/skills/` + `AGENTS.md` en **symlinks** (mirror Codex sans duplication).

**Pourquoi ces écarts avec WasReal.**

1. **Branches — `main` = tronc, releases par tag.** WasReal a deux branches longues
   (`staging`/`production`) parce que chaque merge déploie un site. Sur mobile il n'y a rien à
   déployer en continu : ce qui est « en prod » est un **build soumis au store**. La promotion est
   donc matérialisée par un tag `vX.Y.Z+N`, pas par une branche. Un closeout ne bump jamais
   `pubspec.yaml` et ne pousse jamais de tag.
2. **Gates allégés — 1 reviewer adversarial + Codex cross-LLM** (au lieu des 4 couches de WasReal,
   décision Florent). Le profil de risque n'est pas le même : ni money/Stripe, ni RGPD, ni fidélité
   d'impression. Le « tier risqué » a été **recalibré sur ce produit** : machine à états de la
   partie, scoring, schéma `SharedPreferences`, sync Firestore/offline, intégrité analytics, cycle
   de vie (app backgroundée en plein tour).
3. **La rétro-compatibilité redevient une vraie contrainte.** WasReal est pré-prod et assume de
   détruire les formats (règle #8 « pas de rétro-compat »). Ici l'app est **publiée**, et `upgrader`
   force la mise à jour : les données écrites par la version en store sont sur les téléphones des
   joueurs. Tout changement de forme d'une clé `guessItAll_*` doit être migré explicitement.
4. **Sémaphore de tests partagé avec WasReal** (`/tmp/wasreal-test-slots`, volontairement le même
   chemin). Le budget RAM est celui de la **machine** (~7 Go sous WSL2), pas d'un projet : donner à
   guess-it-all ses propres places rétablirait exactement le scénario d'OOM que le sémaphore existe
   pour empêcher.

**Conséquence.** Le pipeline est en place mais **le TDD est bloqué tant que la suite ne compile
pas** (cf. `notes_pour_plus_tard.md`, entrée du même jour) : le dépôt n'a aucun test qui tourne.
C'est la première dette à solder avant l'epic « mode Fiesta ».

---

## 2026-08-01 — Flutter local aligné sur le canal stable

**Quoi.** Le SDK Flutter de `~/development/flutter` est passé de **3.24.5** (nov. 2024) à la stable
courante.

**Pourquoi.** Le projet vivait auparavant sous `/mnt/c/.../Documents/Python Scripts/` avec un
Flutter Windows en **3.38.3** ; `pubspec.lock` avait donc été résolu par un SDK bien plus récent
que le Flutter Linux. Chaque `flutter pub get` depuis WSL réécrivait ~30 lignes de versions
épinglées-par-le-SDK — un diff parasite qui pollue tous les futurs diffs de PR.

**Conséquence.** `pubspec.lock` se re-résout une fois proprement. Gotcha inscrit dans
`guessitall-pr-closeout` : un `pubspec.lock` qui apparaît dans un diff **sans** changement de
`pubspec.yaml` est un artefact de SDK, pas un changement de story → le restaurer.

---

## 2026-08-02 — Remédiation de l'audit : 6 chantiers + réglages persistés + historique

**Quoi.** Le lot issu de l'audit du 2026-08-02 (`_bmad-output/reviews/audit-code-2026-08-02.md`),
livré en 8 commits sur `feat/audit-remediation`. Il transforme un dépôt à zéro test en une base
testée (97 tests), et pose les invariants dont le mode Fiesta a besoin.

**Les décisions structurantes, et pourquoi.**

1. **`runApp()` avant tout réseau** (`app_bootstrap.dart`). Le démarrage `await`-ait Firebase et la
   sync avant de peindre quoi que ce soit : sur un réseau capricieux, l'app restait sur l'écran
   noir de lancement. La distinction posée est **local (attendu) vs réseau (fire-and-forget)** —
   pas « init rapide vs lente » : c'est la *nature* de la dépendance qui décide, une init locale
   lente reste bloquante parce que l'UI en dépend.

2. **Un seul propriétaire du temps** (`turn_clock.dart` + `GameProvider`). Le temps restant vivait
   en trois exemplaires : une deadline dans le widget, un `pausedTimeRemaining` dans l'état, un
   `Timer` local. Ouvrir un dialogue gelait l'affichage mais **pas** la deadline — le joueur perdait
   les secondes passées dans la confirmation. `TurnClock` est immuable et rend `_endMs` et
   `_frozenMs` **mutuellement exclusifs** : il n'existe plus d'état où « en cours » et « gelé »
   sont vrais en même temps, donc plus de désynchronisation possible à réconcilier.
   Corollaire : `didChangeAppLifecycleState` met en pause quand l'app passe en arrière-plan —
   auparavant le chrono continuait de tourner pendant un appel entrant.

3. **Enveloppe de version + quarantaine** (`persisted_schema.dart`). L'app est **publiée** et
   `upgrader` force la mise à jour : un blob écrit par une version future ou corrompu ne doit ni
   crasher au boot, ni se rejouer à chaque ouverture. Un blob **sans** `schemaVersion` est le
   format actuellement en production et se lit tel quel — ce n'est pas une corruption.
   Règle dure : une panne de la *couche de stockage* n'efface rien ; seule une donnée
   effectivement illisible est mise en quarantaine.

4. **Machine à états extraite en fonctions pures** (`turn_resolution.dart`, `play_rotation.dart`).
   La résolution d'un tour et la rotation des joueurs étaient enfouies dans un provider de
   ~1 500 lignes, donc non testables sans monter l'app. `teamIndexAtTurn`/`playerIndexAtTurn`
   remplacent un ordre de jeu pré-calculé et stocké : c'est le pré-requis du mode Fiesta, qui
   devra insérer des tours bonus sans réécrire l'ordre.
   ⚠️ Précondition documentée : le cycle de base doit être une **permutation** des équipes.

5. **Les réglages survivent au démarrage d'une partie.** `startNewGame()` remplace
   `clearLocalStorage()` sur les trois entrées « Jouer / Nouvelle partie ». L'ancien chemin
   réécrivait `GameSettings.initial()` sur le disque : le joueur reperdait ses réglages avancés à
   chaque partie. Le bug ne vivait pas dans le provider (les tests provider passaient **avant
   comme après** le fix) mais chez l'appelant — d'où un test **widget** sur l'écran d'accueil.
   La remise à zéro explicite reste offerte par le bouton « Réinitialiser » des réglages.

6. **Historique des 10 dernières parties** (`game_result.dart`, `game_history_service.dart`,
   `history_screen.dart`). `GameAnalytics` ne portait ni scores, ni équipes, ni joueurs : la donnée
   n'existait pas, elle est **archivée à la fin de partie** (les deux chemins de fin y mènent).
   Elle est écrite dans sa **propre clé**, bornée à 10 entrées, et stocke les **noms** des joueurs
   plutôt que leurs ids — un id ne survit pas à la partie qui l'a créé. Dédoublonnage par `gameId`,
   parce que la fin de partie est atteignable plusieurs fois (retour arrière, reprise).

7. **Un dialogue de confirmation au lieu de six copies** (`app_confirm_dialog.dart`,
   `game_dialogs.dart`). `AppConfirmDialog.show()` rend un `bool` et **jamais `null`** : fermer en
   tapant à côté vaut refus. Sans ce défaut, un appelant écrivant `if (confirme)` sur un `bool?`
   abandonnerait une partie sur un tap malencontreux.

**Ce qui a été volontairement laissé de côté.** La sortie des analytics hors de
`SharedPreferences` — voir `notes_pour_plus_tard.md` (2026-08-02).

**Effet de bord sur la doc.** Deux fichiers d'instructions agent affirmaient des choses fausses et
ont été corrigés : `lib/theme/CLAUDE.md` décrivait une palette inexistante (noir `#0A0A0A`, rose
`#FF3B7F`, cyan `#00E5FF`) là où le code est en ardoise / rose poudré / vert d'eau ; et
`docs/word-categories.md` annonçait des comptes de mots inventés ainsi que **deux IDs de catégorie
qui n'existent pas** (`arcade`, `metro` — au lieu de `univers_arcade`, `metro_parisien`).
Les deux pointent désormais vers la commande qui re-mesure, plutôt que de recopier des valeurs qui
dérivent en silence.

---

## 2026-08-02 — Gate ② : la pause rendait du temps, et une entrée abîmée vidait l'historique

**Quoi.** Le lot de remédiation a été passé au gate ② (relecture adverse + Codex en
cross-LLM). Cinq défauts en sont sortis, tous vérifiés à la main dans le code avant
correction, tous couverts par un test qui échoue sur le code d'avant.

**Les deux qui comptent, et ce qu'ils apprennent.**

1. **Une correction peut survivre… dans le chemin de persistance.** Le chantier 2 avait
   tué le motif « arrondir le reste puis ré-ancrer la deadline dessus » sur la pénalité de
   passe. Le même motif est resté intact dans l'aller-retour disque : `_withClock`
   persistait le temps gelé arrondi **à la seconde supérieure**, et le getter `turnClock`
   le relisait comme des millisecondes. Une pause à 29 001 ms repartait à 30 000 ms —
   **le joueur gagnait jusqu'à 999 ms par pause, autant de fois qu'il ouvrait un
   dialogue**. Et `suspendGame`/`resumeGame` aggravaient le cas en écrivant les champs
   d'horloge à la main, alors que le commentaire du provider affirme qu'on passe toujours
   par `_withClock`. Ils y passent désormais : il n'existe plus qu'un seul écrivain.
   ⚠️ `pausedTimeRemaining` est en secondes et c'est **le format en production** : on ne
   peut pas changer son unité. D'où un champ `pausedRemainingMs` qui fait autorité, avec
   repli sur l'ancien pour les parties héritées.

2. **Un invariant affirmé en commentaire n'est pas un invariant.** `load()` de
   l'historique porte « une seule entrée abîmée ne doit pas effacer tout l'historique ».
   Or `GameResult.tryFromJson` castait `teams` en dur : un objet là où un tableau est
   attendu levait, l'exception remontait hors du `.map()` (paresseux), tombait dans le
   `catch` générique, `load()` rendait vide **sans quarantaine** — et le `record()` suivant
   réécrivait la clé avec la seule partie nouvelle. Toutes les parties saines détruites.
   Même famille dans `TeamResult.fromJson`, où `.cast<int>()` est paresseux et ne levait
   qu'au **rendu**, pas au parsing.

**Les trois autres.** Un blob de forme invalide (`[]`) dans l'historique des mots était
classé « panne transitoire » et non « corruption », ce qui armait `_degraded` à vie sans
jamais nettoyer la clé ; le test de reprise du chrono n'assertait que la seconde
*affichée*, donc il ne pouvait pas voir le défaut n°1 ; et `TurnClock.fromJson`
contournait l'invariant de sa propre classe en passant les deux champs bruts au
constructeur privé.

**Méthode retenue.** Les gates sortent leurs meilleurs findings sur les chemins de
**reprise** et de **persistance**, pas sur la boucle nominale — c'est cohérent avec le
reste du projet. Et un finding « le test ne prouve rien » vaut un finding de code : c'est
lui qui explique pourquoi le défaut avait survécu au chantier qui devait le tuer.

---

## 2026-08-02 — Les trois `[major]` d'audit que les 6 chantiers ne couvraient pas

**Quoi.** En construisant la table de couverture de l'audit, trois findings `[major]` se
sont révélés orphelins. Ils sont traités.

1. **Le tracking analytics n'était jamais réhydraté.** Après un kill, la partie reprenait
   mais `isTracking` restait faux, donc `endGame()` sortait en early-return — or c'est lui
   qui appelle `incrementWords()`. L'impact n'est pas de la télémétrie : la priorisation
   « mots jamais vus » ne s'appliquait plus, donc **les mêmes mots ressortaient à la partie
   suivante**. `AnalyticsService.resumeGame()` recharge la partie depuis le disque, et
   **refuse une partie déjà clôturée** — la rouvrir rejouerait son `endGame()`, donc un
   second comptage sur les mêmes mots. Les analytics sont sauvegardés à chaque **fin de
   tour**, pas à chaque `_saveGameState()` (qui part au moindre changement d'écran).

2. **Tirer un mot scannait tout le corpus.** `_fillAllEmptyWords` bouclait jusqu'à 100 fois
   *par champ vide* : jusqu'à 1 000 scans des ~5 800 entrées sur l'isolate de l'UI, sans
   frame intercalée. Le générateur accepte désormais un paramètre d'exclusion, donc un
   appel unique suffit — et les deux boucles à 100 tentatives disparaissent, y compris le
   copier-coller de `players_screen`.

3. **`stats_screen.dart` : 987 → 573 lignes.** Quatre builders identiques à l'octet près
   au titre et à deux tailles de police. Le filtre « manche N » était le seul axe de
   variation : il devient un paramètre `int? round` sur deux fonctions **pures**, les
   premières du dépôt à porter des règles de classement testables.

## 2026-11-03 — Orchestration : skill de session principale, gate ② à un reviewer, tests minimaux

**Quoi.**

- Nouvelle skill **`guessitall-orchestration`** (adaptée de `wasreal-orchestration`) : ce que fait
  la session principale — cadrage `grilling`, planification d'un lot, jusqu'à 5 lanes bornées par
  le graphe de conflits, sonde légère (`free -m` + PR ouvertes), mode délégué avec journal
  d'arbitrages (`_bmad-output/reviews/<epic>/journal-arbitrages.md`), renumérotation de
  `kCurrentSchemaVersion` entre deux merges, gate ③ conditionnel, passation dans le `note` de
  l'epic de `sprint-status.yaml`.
- **`guessitall-epic-intake` supprimée**, absorbée dans `guessitall-orchestration` §2 (intérêt
  par US vérifié dans le code, graphe de conflits → lanes, dosage, prompt-pack à deux étages).
- Nouvelle skill **`guessitall-etat-des-lieux`** (portée de WasReal) avec une table *Release* :
  dernier tag, commits sur `main` depuis, schéma persisté touché ou non.
- **Gate ② = un seul reviewer adversarial spec-aveugle.** Codex retiré (workflow, orchestration,
  teach-back, `CLAUDE.md`), sans second reviewer Opus en substitut. Gate ③ = un reviewer sur le
  diff cumulé, seulement si ≥ 2 stories ont été sérialisées sur un point de collision ou le tier
  risqué.
- **Tests minimaux** : un test seulement s'il épingle un invariant du tier risqué ou reproduit un
  bug corrigé ; plus de TDD strict ni de widget test pour l'UI simple.
- `grilling` : toutes les questions en un message numéroté, une ligne et une recommandation
  chacune (texte de WasReal).
- `.codex/skills/` : symlinks ajoutés pour les nouvelles skills et `grilling`, retiré pour
  `epic-intake` ; `CLAUDE.md` ne prétend plus qu'il n'y a « rien à re-synchroniser ».

**Pourquoi (décision Florent).** Les changements de ce dépôt sont simples : une revue cross-LLM
coûte plus qu'elle ne trouve, un reviewer adversarial suffit. Le moins de tests possible, parce
que chaque test est une maintenance et que seuls les invariants du tier risqué (données joueur en
store, partie en cours) justifient ce coût. L'empreinte des tests GIA est légère : pas de plafond
machine dédié aux lanes, le sémaphore `with-test-slot.sh` suffit.

**Conséquence.** Une seule skill de session principale, une seule skill de lane. Une décision
sur la forme d'une clé `guessItAll_*` ne s'arbitre jamais en mode délégué : elle remonte à
Florent (`CLAUDE.md` règle 7).

## 2026-11-03 — Builds cloud Codemagic, publication désactivée

**Quoi.** `codemagic.yaml` à la racine avec deux workflows sur `mac_mini_m2` : `dry-run`
(manuel) et `release` (tag `v*`, garde « tag = `v` + version pubspec »). Les deux font pub get →
analyze → test → AAB signé (keystore `gia-android-signing`, `google-services.json` depuis le
groupe `gia-firebase`) → IPA en signature automatique (`gia_asc_key`), et gardent les artefacts
(dont `ios/Podfile.lock`). `android/app/build.gradle.kts` ne crée la signature release que si
`key.properties` existe.

**Pourquoi.** Le build iOS exigeait un Mac branché ; un clone propre doit suffire. Le cast
`as String` sans garde faisait planter **tout** build Gradle sans `key.properties` (debug compris) :
désormais release non signé + warning, comportement inchangé sur le poste Windows. Choix « non
signé » plutôt que « signé debug » : un AAB signé debug pourrait partir au store par erreur, un
non signé est refusé tout de suite. **Publication présente mais commentée** : décision Florent,
une seule release après le mode Fiesta.

**Conséquence.** Florent crée les secrets listés dans `docs/releases-stores.md` §Codemagic, lance
un 1er `dry-run`, commite le `Podfile.lock` produit. Points incertains jusque-là : `xcode: latest`
vs Flutter 3.44, chemin de l'export plist iOS, et le build Gradle lui-même (non compilable depuis
WSL).

## 2026-11-03 — Mode Fiesta : epic et 10 stories écrites, cadrage figé

**Quoi.** Le cadrage du mode Fiesta (grilling 2026-08-02 puis 2026-11-03) est transformé en un
epic et 10 stories prêtes au dev : `_bmad-output/specs/fiesta/epic-fiesta.md` et
`_bmad-output/specs/fiesta/2-2-…` à `2-11-…`. Le jeu d'aujourd'hui devient **Classique** ;
Fiesta a deux modes, **Auto** (tirage symétrique et/ou auto-calibrage) et **Personnalisé**
(ensembles de règles enregistrés, 10 max par téléphone). Board : `epic-2-mode-fiesta` passe à
`ready-for-dev`, `2-1-fiesta-cadrage` à `done`. Ajout de `epic-4-i18n` et `epic-5-pubs`
(`deferred`) et de `epic-6-release-cloud` (`review`, PR #4).

**Pourquoi ces choix de structure.**

1. **Tout l'état Fiesta vit dans `GameState`, en champs optionnels, sans incrémenter
   `kCurrentSchemaVersion`.** Absent = Classique : une partie en cours écrite par la version en
   store se relit telle quelle (`CLAUDE.md` règle 7). Et le snapshot de retour arrière réutilise
   déjà `GameState.toJson()` : un état rangé là est restauré gratuitement, y compris une charge
   dépensée sur un tour annulé.
2. **Une seule nouvelle clé, `guessItAll_fiestaEnsembles`**, sur le modèle de
   `GameHistoryService` (enveloppe versionnée + quarantaine). `GameSettings` ne change pas : un
   ensemble ne contient que des règles Fiesta.
3. **Une lane séquentielle** sur `game_provider.dart` / `game_state.dart` : 9 stories sur 10 y
   passent. Seuls les ensembles (2-3) courent en parallèle.
4. **Analytics avant les effets** (2-7 avant 2-8 à 2-11) : le champ « modificateurs actifs » des
   événements est posé une fois, et 2-11 n'a plus qu'à rendre le suivi « par mot ».
5. **Tirages et offres à graine `(gameId, manche)`** : un retour arrière depuis la transition
   rejoue la fin de manche ; sans graine, il relancerait le tirage, ce que la décision interdit.
6. **Correctif inclus** : `timeSpent` (`game_provider.dart:869`) se calcule sur la durée réglée,
   donc faux pour les continuations ; 2-6 stocke la durée réellement allouée au tour.

**Conséquence.** 16 questions ouvertes, chacune avec une recommandation appliquée par défaut,
sont listées dans l'epic pour arbitrage par Florent ; les plus structurantes : Q1 (report de temps
= tour de continuation, la maquette `cd2` est à corriger), Q3 (définition de l'égalité à 3-4
équipes), Q4 (plancher de 10 s), Q11 (place de l'écran Paramètres dans le parcours).

---

## 2026-11-03 — Workflow de lane calqué sur WasReal : plus de gates numérotés, 5 agents max

**Quoi.** `guessitall-workflow` est réécrit sur la structure de `wasreal-workflow` (8 sections :
tier, ouverture de lane, tests minimaux, quand tester, revue, boucle de correction, PR/closeout,
release). Les gates ①②③ disparaissent du vocabulaire (`CLAUDE.md`, orchestration, teach-back,
closeout, board, epic Fiesta). Le tier décide seul : **trivial → aucune revue ; standard et
risqué → 1 reviewer Opus** (mutation testing obligatoire en risqué), boucle jusqu'à READY avec la
garde « simplifier la racine ». **Au plus 5 agents en parallèle**, sous la sonde de 15 min.

**Pourquoi.** Florent : « on s'emmerde pas à faire mille gates 1 et 2 ». La cérémonie numérotée
coûtait plus qu'elle ne rapportait sur des changements simples ; WasReal a déjà convergé vers ce
modèle par tier. Différence assumée avec WasReal : pas de jambe Codex en risqué (décision du même
jour).

---

## 2026-11-03 — Fiesta 2-2 : `GameState.fiesta` optionnel, catalogue en code, gel au lancement

**Quoi.** Nouveau dossier `lib/models/fiesta/` : catalogue V1 (11 ids figés + table
d'incompatibilités Q14), `ModifierInstance`, `FiestaRules` (immuable), `FiestaState`
`{rules, active, turn}`. `GameState` gagne **un** champ optionnel `fiesta`, absent du JSON quand
nul. `GameProvider.startGame({FiestaRules? fiesta})` gèle la config ; sans argument il l'efface.

**Pourquoi ces choix.**
- **Un seul champ optionnel, pas de bump de `kCurrentSchemaVersion`** : absent = Classique, donc
  une partie écrite par la version en store se relit sans migration, et le blob Classique ne
  change pas d'un octet (règle 7). Les stories suivantes ajoutent leurs compteurs *dans* `fiesta`
  (`turn`), jamais à la racine de `GameState`.
- **Relecture tolérante à deux niveaux** : `fiesta` structurellement illisible → Classique (la
  partie reste jouable) ; une instance ou un réglage illisible → ignoré seul, jamais de valeur
  par défaut inventée (même règle que `WordEvent.tryFromJson`). Les ids sont donc figés : en
  renommer un rendrait invisibles les instances en cours. `nature` est persistée avec
  l'instance (exigé par la spec) : une instance dont la nature est illisible tombe, elle aussi.
- **Catalogue en code** : seuls des ids, réglages et instances sont persistés ; nom et description
  se relisent depuis le code courant, donc un libellé se corrige sans migration.
- **Gel par immutabilité** plutôt que par copie profonde à chaque `startGame` : `FiestaRules`
  copie ses collections en lecture seule à la construction, le test de 2-2 le prouve en mutant
  la map source après le lancement.
- **`CatchUpRules.auto`** porte les constantes du mode Auto (+3/+5 s, plafond 30 s, −1 s,
  plafond 15 s) et est la valeur par défaut de `FiestaRules.catchUp` : 2-6 lit un seul champ,
  quel que soit le mode.
- **Champ absent = défaut, champ mal typé = illisible** (`readOr`, revue r1) : après la 1ʳᵉ
  release Fiesta, une story qui ajoute un champ à `FiestaRules` ne doit pas faire retomber en
  Classique les parties Fiesta en cours au moment de la mise à jour. Seule une valeur présente
  et mal typée invalide le blob. Un `mode` inconnu reste bloquant : c'est la clé de structure.

---

## 2026-11-03 — Fiesta 2-4 : choix du mode en mémoire, Rejouer par le Récap

**Quoi.** « Nouvelle partie » ouvre **Mode de jeu** : Classique va aux Paramètres comme avant ;
Fiesta → Auto ou Personnalisé → **Récap** → Paramètres. Le choix est un `FiestaRules?` en attente
dans `GameProvider` (`pendingFiesta`), passé par `TeamsScreen` à `startGame`. « Rejouer »
(résultats et accueil) remet la config gelée de la partie finie en attente et passe par le Récap.

**Pourquoi ces choix.**
- **En mémoire, pas persisté** (Q10) : aucune clé `guessItAll_*` ne change ; une app tuée avant le
  lancement repart d'un choix vide. `startNewGame` efface l'attente.
- **Invariant : en partie, `pendingFiesta` = `fiesta?.rules`.** `startGame` reçoit l'attente, et
  `_loadFromStorage` la restaure depuis la partie reprise après un kill (sans ça, « Retour aux
  équipes » + « Lancer » repartait en Classique). `endGameAndGoHome` n'efface pas l'attente, donc
  le « Rejouer » de l'accueil la retrouve. `restartWithSamePlayers` relit la partie si elle a été
  jouée (`allWords` non vide), sinon garde l'attente.
- **Retour des Paramètres** : vers le Récap si une config Fiesta est en attente, sinon vers
  l'accueil comme avant (pas vers Mode de jeu en Classique : la story ne l'exigeait que si
  trivial, et ça garde le parcours Classique identique).
- **Retour système Android** géré par `PopScope` sur les nouveaux écrans seulement : les écrans
  existants gardent leur comportement.
## 2026-11-03 — Fiesta 2-3 : ensembles sur une clé versionnée, validation pure, liste et éditeur

**Quoi.** Nouvelle clé `guessItAll_fiestaEnsembles` (`FiestaEnsembleService`), enveloppe
`persisted_schema` dès la première écriture, `kCurrentSchemaVersion` inchangé (clé neuve). Un
ensemble = `{id, rules}` : le nom vit dans `rules.ensembleName` (une seule source), donc
l'ensemble choisi se gèle tel quel. `validateEnsemble(FiestaRules)` (pure) bloque
l'enregistrement. Écrans « Mes ensembles » et éditeur.

**Pourquoi.**
- **Borne de 10 dans le service, modifications sérialisées** : les écritures sont asynchrones ;
  sans file, deux taps rapides liraient 9 et passeraient la borne, ou l'un écraserait l'autre.
- **Une lecture en panne fait échouer la modification** au lieu de réécrire une liste vide par
  dessus des ensembles qu'on n'a pas pu lire ; `load()` seul rend vide sans effacer.
- **Interrupteur de rattrapage d'interface seulement** (revue r1, maquette) : `CatchUpRules` n'a
  pas de champ « actif » ; off = les 5 curseurs à 0, on = `CatchUpRules.auto` ; « actif » =
  un curseur > 0 (`catchUpOn`). **Tirage pour tous d'un ensemble = `symmetric` ET
  `drawCount > 0`** (interrupteur + compteur de la maquette) : 2-5 doit lire les deux.
- `copyWith` posés en **extensions** dans `fiesta_ensemble.dart` : les types de 2-2 ne changent
  pas.
- **Un ensemble illisible n'est jamais détruit** (revue r1) : ses entrées brutes sont réécrites
  telles quelles à chaque modification d'un autre ; un **blob figé** en test garantit que le
  format de cette version se relit en entier.

## 2026-11-03 — Fiesta 2-5 : tirage symétrique recalculé, jamais stocké

**Quoi.** `lib/models/fiesta/symmetric_draw.dart` calcule les modificateurs « pour toutes les
équipes » d'une manche : les **fixés** sur cette manche (Personnalisé, Q16), puis le **tirage**
(Auto : 1 ou 2, Q9 ; Personnalisé : `drawCount` parmi les « tiré pour tous » éligibles), avec
`canAdd` pour le plafond de 2 et les incompatibilités. Graine `drawSeed(gameId, manche)`.
`startGame` pose ceux de M1 dans `fiesta.active` ; `nextRound` retire ceux de la manche finie et
pose ceux de la nouvelle. La transition montre `nextRoundModifiers`, le jeu « Actif ce tour »,
le tour des badges sous le chrono, et `MalusReveal` révèle les malus au premier tour de chaque
équipe dans la manche (dérivé de l'historique).

**Pourquoi ces choix.**
- **Recalculer plutôt que stocker la « manche suivante »** : la story proposait de ranger le
  tirage dans `fiesta` dès la fin de manche. Mais le snapshot du retour arrière est pris avant
  la validation, et la graine rend le résultat identique de toute façon : stocker n'apportait
  rien et aurait exigé un champ de plus dans `FiestaState` (type public de 2-2). Aucune forme
  persistée ne change.
- **FNV-1a et pas `String.hashCode`** : `hashCode` n'est pas garanti stable d'une exécution à
  l'autre ; une app tuée doit retrouver le même tirage.
- **Fixés avant le tirage** dans le plafond : la story demande un tirage compatible avec les
  fixés. Q8 (« le tirage d'abord ») vise les offres et cadeaux, qui viennent après.
- **`block_guesser` jamais tiré pour tous** : il vise un joueur choisi par les adversaires, une
  cible « toutes les équipes » n'a pas de sens.

## 2026-11-03 — Fiesta 2-6 : une seule source pour la durée du tour, rattrapage, durée réelle

**Quoi.** `lib/models/fiesta/turn_time.dart` (pur) : `composeTurnSeconds` rend la durée de
départ d'un tour et son détail (base + rattrapage − malus du leader − 10 s × `minus_10s`,
plancher 10 s ; une continuation garde exactement ses secondes reportées) ; `computeCatchUp`
rend le rattrapage dû par équipe à la fin d'une manche (menée : `min(cap, k × écart avec la
tête)`, leader : `−min(malCap, mal × écart avec la 2ᵉ)`, co-leaders tous en tête, égalité =
rien). `GameProvider.turnTime` est la **seule** source de la durée : `startTurn` (aperçu) et
`startTurnTimer` (chrono) la lisent tous deux. `nextRound` pose le dû dans
`FiestaState.catchUpDue` ; `startTurnTimer` le consomme au premier tour non-continuation de
l'équipe et écrit `GameState.turnAllottedSeconds`, sur lequel `timeSpent` se mesure désormais.
Cartes « Temps du tour » (avant-tour, Fiesta) et « Rattrapage » (transition).

**Pourquoi ces choix.**
- **Le dû est stocké, pas dérivé de l'historique.** C'est ce que la story prescrit, et c'est
  plus simple et plus robuste que de reconstruire « consommé » depuis l'historique : la
  consommation est un retrait explicite au `startTurnTimer`, le snapshot du retour arrière et
  la partie persistée l'embarquent tel quel, et le principe est celui de `turnBonusTime`
  (consommé une fois, effacé). Champ **additif** dans `fiesta` seulement : le blob Classique ne
  change pas de forme.
- **Posé à `nextRound`, pas à `validateWords`.** Les scores ne bougent pas entre les deux, la
  transition montre un aperçu recalculé (`catchUpPreview`, comme `nextRoundModifiers`), et le
  retour arrière depuis la transition n'a rien à défaire.
- **Continuation = `turnBonusTime` posé**, pas `pendingBonusTurnId` : c'est le champ qui fait
  la durée du tour (en pratique les deux coïncident : en fin de manche, les mots refusés
  retournent au pool, donc la branche fin de manche pose toujours les deux).
- **Révélation des malus** (2-5) : `minus_10s` se révèle au premier tour **non-continuation**
  de l'équipe, pas avant une continuation où il ne s'applique pas.
- **`turnAllottedSeconds` écrit en Classique aussi** : le bug `timeSpent` (une continuation de
  7 s finie à 2 s comptait 28 s) touche le mode Classique. Champ nullable, relu en `as int?` ;
  absent sur une partie reprise d'une version antérieure → comportement d'avant.
- **Plancher appliqué dans la composition** (`max(10, somme)`), sans cas spécial Classique : la
  base est ≥ 20 s (`minTurnDuration`), donc la durée Classique est la base, seconde pour seconde.
- **Co-leaders sans départage par l'ordre de jeu** (Q3) : `getTeamsSortedByScore` départage
  pour l'affichage, pas pour le rattrapage — à égalité en tête, personne n'est « menée ».

## 2026-11-03 — Fiesta 2-7 : modificateurs dans les analytics, l'archive et les résultats

**Quoi.** `WordEvent.modifiers` (ids actifs pour l'équipe qui joue), `GameAnalytics.gameMode` /
`fiestaRules`, `GameResult.mode` / `modifierRecap` : champs **additifs**, clé absente en Classique.
Carte « Modificateurs de la partie » sur l'écran Résultats (Fiesta) : tirage par manche,
rattrapages. Les sections 1 parmi 3, bonus utilisés et joueurs bloqués arrivent avec leurs
stories.

**Pourquoi ces choix.**
- **Clé absente, pas `null`, en Classique** : le blob `guessItAll_analytics_*` (non enveloppé),
  l'historique et le document Firestore d'une partie Classique sont ceux d'avant. Lecture
  tolérante (`is List` / `is String` / `is Map`), aucun cast dur ajouté. `kCurrentSchemaVersion`
  inchangé.
- **Modificateurs = contexte du TOUR, pas du mot** : mémorisés à côté de `_lastRound`, jamais
  remis à zéro par `_recordEventWithDuration`, donc `invalidated` (vérification, après le tour)
  garde l'étiquette. Le provider les relit de l'état persisté à chaque mot : après un kill, le mot
  suivant est ré-étiqueté. Le bloc « mot affiché » du service est isolé et son contrat (un seul mot
  à l'écran) écrit : 2-11 le remplace sans toucher au reste.
- **Liste vide ≠ absente** : `[]` = Fiesta sans modificateur ce tour, distinguable du Classique
  pour le recalibrage.
- **Récap recalculé, pas journalisé** : le tirage vient de la graine `(gameId, manche)` (comme
  `nextRoundModifiers`), le rattrapage des scores cumulés en fin de manche (= ce que la transition
  a montré). Pas de `HistoryEntry.modifiers` ni d'autre champ dans `GameState` : rien à persister,
  aucune nouvelle forme sur la clé de partie en cours. Limite assumée : le récap montre le
  rattrapage **accordé**, même si l'équipe n'a pas joué dans la manche suivante.
- **Archivé tel qu'affiché** (`ModifierRecapLine` = titre + détail formés), comme les scores de
  `GameResult`.

---

## 2026-11-03 — Fiesta 2-8 : effets de tour (passe bloquée ou gratuite, devineur bloqué, à l'envers)

**Quoi.** `no_pass` (Passer désactivé, `passWord` refuse), `free_pass` ×N (N premières passes
du tour à 0 s, compteur « Passes gratuites : k / N »), `block_guesser` (les adversaires
choisissent un devineur avant le tour, annonce « X ne répond pas »), `reversed` (mot en
MAJUSCULES inversé sur l'écran de tour seulement), contraintes de mime / dessin et texte Q6
annoncés avant le tour. Règles pures dans `models/fiesta/turn_effects.dart`.

**Pourquoi ces choix.**
- **Une seule garde** (`GameProvider.canPassWith`) sur la pénalité **effective**, lue par
  `passWord` et par le bouton : sinon le bouton s'affiche actif et le provider refuse. Sous
  `no_pass`, sortie **avant** `onWordPassed` : aucune passe fantôme dans les analytics.
- **Compteurs dans `FiestaState.turn`** (`freePassesUsed`, `blockedPlayerId`) : la clé existait
  déjà (map vide, relue tolérante), donc **aucun changement de forme** de `guessItAll_*`. Persistés
  (survivent à un kill) et restaurés par le retour arrière (snapshot `GameState`).
- **Une seule définition du tour** (revue r1, m1) : le tour de fin de manche ET sa continuation
  en N+1 forment UN tour. Compteurs et instances de portée tour vivent jusqu'à sa vraie fin, où
  `validateWords` vide les uns et consomme les autres (invariant noté par 2-5). Sinon un
  `block_guesser` rouvrait le sélecteur en continuation et une `free_pass` de portée tour
  rendait ses passes. Contrepartie acceptée : une `free_pass` de **manche** N+1 hérite du
  compteur de N. Personne ne pose encore d'instance de portée tour (2-10) : testé avec une
  instance injectée.
- **Devineur bloqué choisi au début du tour**, pas au tirage : celui qui fait deviner tourne.
  Sélecteur fermé sans choix → on reste sur l'avant-tour, le tour ne démarre pas. Le choix est
  persisté APRÈS l'annonce : une app tuée pendant l'annonce redemande le choix (r1, m2).
  Décision : `block_guesser` n'arrive QUE par offre (1 parmi 3 et coup de pouce Auto, 2-10),
  jamais tiré ni fixé pour tous (`isForAllTeams`, 2-5) ; Q15 ne s'applique pas. L'effet se
  déclenche sur toute instance qui vise l'équipe qui joue : c'est la couture que 2-10 utilisera.

**Conséquence.** Une partie Classique ne voit aucune différence : sans modificateur, pénalité
effective = pénalité réglée, garde identique.
