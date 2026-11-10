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
  une partie écrite par la version en store se relit sans migration, et `fiesta` n'est jamais
  écrit en Classique (règle 7 ; seul ajout Classique de l'epic : `turnAllottedSeconds`, 2-6). Les stories suivantes ajoutent leurs compteurs *dans* `fiesta`
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

## 2026-11-03 — Fiesta 2-9 : mot compte double

**Quoi.** Une équipe qui a `double_points` (tiré, fixé, plus tard offert) active ×2 sur
l'avant-tour ; les points du tour comptent double (`resolveTurn(pointsMultiplier:)`, pur). Badge
« ×2 Mot compte double » pendant le tour, détail du calcul à la vérification, ligne « Bonus
utilisés » au récap.

**Pourquoi ces choix.**
- **Dépense au départ** (`startTurnTimer`), pas à l'interrupteur : éteindre avant le départ
  ou revenir à la vérification précédente n'a rien à rembourser, le snapshot efface l'armement.
- **État dans `FiestaState`** : armement dans `turn` (survit au kill, vidé à la vraie fin du
  tour) ; dépenses dans `chargesUsed`, une **clé optionnelle** de plus dans le blob Fiesta
  (omise si vide, Classique intact, pas de bump de schéma). Une instance tirée pour tous est
  partagée : le décompte par équipe ne peut pas vivre sur l'instance. Charges de la manche =
  charges des instances − dépenses de CETTE manche : une charge non utilisée est perdue sans
  remise à zéro.
- **Un seul tour (2-8)** : la continuation en N+1 d'un tour joué à ×2 reste à ×2 sans dépenser
  la charge de N+1 ; un tour non activé peut l'activer en continuation (charge de N+1).
- **Q8** : activation refusée si l'équipe a déjà 2 autres modificateurs en jeu.
- **Analytics** : `double_points` n'apparaît dans les `modifiers` d'un mot que si le ×2
  s'applique à ce tour (une charge non activée n'est pas un modificateur en jeu).

## 2026-11-03 — Fiesta 2-10 : 1 parmi 3 et coup de pouce de l'app (câblage)

**Quoi.** Sur la transition après M1 et M2 : Personnalisé (`oneOfThree`) → carte « Choix 1 parmi
3 », chaque équipe non en tête choisit à son tour derrière un écran « Passe le téléphone » ;
Auto (auto-calibrage) → carte « Coup de pouce de l'app ». Les cartes choisies et les cadeaux
entrent dans `fiesta.active` à `nextRound`, à côté du tirage de N+1. Récap : sections « Choix 1
parmi 3 » et « Coup de pouce de l'app ».

**Pourquoi ces choix.**
- **Garde dans le provider** : `nextRound` sort tant que `nextChooserId` n'est pas nul ; le
  bouton grisé n'est qu'un reflet (double tap, reprise d'app).
- **Offres et cadeaux recalculés**, jamais stockés (scores + tirage de N+1 + graine
  `(gameId, manche, équipe)`) ; seuls les **choix** sont persistés : `fiesta.offerChoices`
  (`[{chooserId, modifier}]`), clé optionnelle du blob Fiesta, omise si vide (Classique
  intact, pas de bump de schéma). La file = choix dont `modifier.round` = manche suivante ; un
  kill garde les choix faits, un retour arrière les efface (postérieurs au snapshot, AC6).
- **Qui a choisi** est gardé à côté de l'instance : un malus vise le leader, et c'est l'équipe
  qui a choisi « Bloquer un devineur » qui désigne le devineur (`blockingTeam`).
- **Coup de pouce du récap recalculé** sur les scores cumulés par manche, comme le rattrapage.

**Conséquence.** Les malus reçus passent par la révélation de 2-5 et les tags analytics de 2-7
sans code dédié : ils sont dans `active` comme le tirage.

## 2026-11-03 — Fiesta 2-11 : Deux mots à la fois

**Quoi.** Bonus à charge (1 par équipe et par manche), allumé sur l'avant-tour comme le ×2,
annoncé sur la même carte. Pendant le tour : deux cartes, chacune avec Trouvé / Passer ; la
carte traitée est remplacée par un mot ≠ l'autre, l'autre ne bouge pas ; une seule carte quand
il ne reste qu'un mot. À l'expiration, les deux mots partent à la vérification, chacun avec son
choix.

**Pourquoi ces choix.**
- **Carte B dans `fiesta.turn`** (`secondWord`, puis `secondExpiredWord`), pas dans `GameState` :
  rien de neuf dans le blob Classique, clés absentes = un seul mot, pas de bump de schéma.
  Le retour arrière et l'app tuée les retrouvent sans code dédié (snapshot = `toJson`).
- **Le mot visé est un argument** de `markWordAsGuessed` / `passWord` : un tap sur une carte
  déjà remplacée est ignoré par le provider (en plus du verrou visuel de 0,3 s).
- **`resolveTurn(expiredWords:)`** : N mots expirés, toujours pur ; adaptation mécanique des
  tests existants.
- **Analytics : durée par mot** (`AnalyticsService._shownAt`) au lieu du « dernier mot affiché »,
  qui jetait en silence les événements de l'autre carte. `two_words` dans les `modifiers`.

**Conséquence.** Pas d'indicateur sur `HistoryEntry` (forme d'une clé `guessItAll_*` de premier
niveau) : le tag analytics porte l'information.

## 2026-11-03 — Fiesta, fin d'epic : règle de la continuation, état du tour typé, plan de passage de manche

**Ce qui change.**
- **Continuation** (temps reporté en début de N+1) = même tour que la fin de N : elle joue avec
  les effets de N pour cette équipe (modificateurs de N, ×2 / deux mots dépensés, passes
  gratuites utilisées, `block_guesser` de N et devineur bloqué), **jamais** ceux de N+1 (tirage,
  cadeaux, choix — `block_guesser` choisi pour N+1 compris — et charges), qui commencent au
  premier vrai tour de chaque équipe. Aucune charge ne s'allume sur une continuation : 🔴 cela
  **change l'AC8 de 2-9** (on pouvait allumer la charge de N+1 pendant la continuation). Le test
  AC8 vérifie désormais le refus sur la continuation et la charge de N+1 disponible au premier
  vrai tour (lecture (a), validée par Florent). **Continuation en chaîne** (revue r1) : si la
  continuation vide à elle seule le pool de N+1, son tour logique N se clôt à cette fin de manche
  (`_fiestaAtRoundEnd`) ; la continuation en N+2 ne porte que le contexte de N+1, dont les malus
  se révèlent alors (`malusToReveal` sur la manche logique), **sauf les malus de temps**
  (`kTimeModifierIds`, revue r2) : une continuation joue son temps reporté, sans modificateur de
  temps, donc un « −10 s » n'y est ni annoncé ni appliqué. Les
  instances de N partent à la fin de la continuation. Tous les malus de N+1 se révèlent au
  premier vrai tour (plus de cas particulier `minus_10s`).
- `isContinuation` est **dérivé de l'historique** (l'équipe a joué la dernière entrée de N et
  n'a encore rien joué en N+1), pas de `turnBonusTime`, effacé au départ du chrono : il tient
  pendant le tour, sur la vérification, après un kill et un retour arrière. Rien de persisté.
- `FiestaState.turn` : `Map<String, dynamic>` → `FiestaTurnState` typé, **mêmes clés JSON**,
  écriture conditionnelle, lecture tolérante clé par clé. Il décide ce qui survit
  (`afterRoundEnd`, `empty`).
- `planRoundTransition` (pur) : tirage + cadeaux + choix + rattrapage + ce qui survit. L'aperçu
  de la transition et `nextRound` lisent le même plan.
- ×2 et deux mots : une table `kChargeBonusKeys`, une implémentation dans le provider.

**Pourquoi.** Revues de fin d'epic : une continuation pouvait cumuler ×2 / blocage de N et deux
tirages de N+1 (4 effets, Codex MAJOR-1), et un `block_guesser` choisi pour N+1 contre l'équipe
qui avait fini N était brûlé par sa continuation, parfois de 0 s (Opus M3). Une seule règle
(« la manche logique du tour ») supprime toute la famille de cas particuliers (m1, m2, m3, m8).
Le blob Fiesta n'a jamais été publié : aucune migration.

## 2026-11-03 — Fiesta, fin d'epic : « Évolution des scores » compte les points, pas les mots

**Ce qui change.** `HistoryEntry.pointsScored`, optionnel, écrit **seulement** quand il diffère du
nombre de mots validés (×2). Absent = un point par mot (`HistoryEntry.points`). Le graphe
« Évolution des scores » cumule `points` : son dernier point égale `Team.score`.

**Pourquoi.** Le graphe ajoutait le nombre de mots : un tour à ×2 y valait moitié moins que dans
le score affiché (Codex MAJOR-3). Ajout dans `guessItAll_gameState` approuvé par Florent
(règle 7) : additif, optionnel, lecture tolérante. Une partie Classique n'écrit jamais la clé
(points = mots), et un blob antérieur se relit à l'identique. Pas de migration ni de bump de
schéma.

## 2026-11-03 — Fiesta, fin d'epic : contrat Classique = règle 7, plus l'identité à l'octet

**Ce qui change.** Rien dans le code. La promesse « blob Classique octet pour octet celui
d'avant » est remplacée par la règle 7 telle qu'écrite : ajouts optionnels, absents = défaut,
lecture tolérante, migration explicite seulement si une forme change. `turnAllottedSeconds`,
écrit par toute partie Classique jouée depuis 2-6, est gardé.

**Pourquoi.** Codex (BLOCKER-1) l'a relevé : la promesse ne tenait plus depuis 2-6. Florent
garde le champ : il est additif et optionnel, l'ancien lecteur l'ignore, et il corrige le temps
passé par joueur (`timeSpent` mesuré sur la durée réelle du tour). Les mentions « à l'octet »
sont corrigées dans `game_state.dart`, `lib/models/CLAUDE.md`, ce journal et le test du blob figé.

## 2026-11-03 — Fiesta, fin d'epic : récap des modificateurs archivé en faits

**Ce qui change.** `GameResult.modifierRecap` archive des `ModifierRecapItem` (`kind`, manche,
id de catalogue, équipes, secondes), plus des phrases françaises. `formatModifierRecap` forme le
texte à l'affichage (carte des Résultats). Le récap recalcule rattrapage et coup de pouce par
`planRoundTransition`, le même plan que la transition.

**Pourquoi.** Opus m6 : des phrases archivées seraient restées en français pour toujours (i18n
prévue, epic-4). Le format Fiesta de `guessItAll_gameHistory` n'a jamais été publié, donc la
forme change sans migration. Une ligne `{title, detail}` écrite par une build de dev se relit
comme un fait illisible : elle est ignorée seule, sans crash.

## 2026-11-03 — « Rejouer » depuis l'historique, mots aléatoires cachés

**Ce qui change.** Chaque partie archivée garde un `setup` optionnel (`GameSetupSnapshot` :
`GameSettings` + `FiestaRules?`, jamais les mots). « Rejouer » sur une carte de l'historique
(`replayFromHistory`) recrée joueurs et équipes depuis les noms archivés, reprend les réglages,
met les règles Fiesta en attente et termine par `restartWithSamePlayers` : on arrive aux
Paramètres ou au Récap Fiesta, comme le « Rejouer » de fin de partie. Une partie suspendue est
remplacée seulement après confirmation. En mode aléatoire, la carte joueur affiche un badge
« N mots prêts » qu'on ne peut pas toucher : les mots tirés restent cachés.

**Pourquoi.** Règle 7 : c'est un champ additif dans `guessItAll_game_results`, donc ni migration
ni bump de `kCurrentSchemaVersion`. Une archive sans `setup` se rejoue avec ce qu'elle contient
(équipes, joueurs, `totalWords`, `turnDuration`). Le reste vient des réglages courants, en
Classique. Le nombre d'équipes et de joueurs suit toujours les joueurs recréés, et pas un réglage
archivé qui pourrait les contredire. Des règles Fiesta illisibles invalident tout le snapshot,
pour ne pas rejouer en Classique une partie qui était Fiesta.
Revue Codex r1 : bien typé ne suffit pas. Un snapshot hors bornes des curseurs (`Slider` lève),
ou dont le mode de mots est inconnu, est écarté. Les catégories disparues du catalogue sont filtrées
au rejeu. `goToScreen` refuse l'écran des mots en mode Aléatoire.

**Noms d'équipe.** `createTeams` tire maintenant des noms drôles et distincts dans
`kFunnyTeamNames`, à la place de « Équipe N ». Il n'y a pas de bouton pour retirer d'autres noms :
le renommage manuel suffit. Le nom est déjà une chaîne persistée, donc la forme ne change pas
(règle 7). Les sessions existantes gardent « Équipe N ».
## 2026-11-03 — Prise en main : kit d'aide (bouton « ? », coach marks, tutos)

**Quoi.** `lib/widgets/help/` : `HelpButton`, `CoachMarks` (route transparente, voile percé
autour d'une `GlobalKey`, bulle Suivant / Passer), textes par écran, `TutorialPager` ; deux
écrans `RulesTutorialScreen` (4 cartes) et `FiestaTutorialScreen` (3 cartes) ouverts par
`Navigator.push` ; prompt « Première partie ? » sur le premier « Jouer » ; 3 boutons dans Règles.
Trois clés booléennes neuves : `guessItAll_tutorialSeen`, `guessItAll_fiestaTutorialSeen`,
`guessItAll_firstGameDone`.

**Pourquoi.** Retour Florent sur la maquette : pas de voile automatique à la première ouverture
de chaque écran (trop intrusif), un « ? » partout à la place. Seule exception automatique : la
première partie du téléphone, au premier tour de chaque joueur (avant-tour + vérification),
parce que la vérification est l'écran le plus mal compris. Le « déjà vu » par joueur reste en
mémoire (`FirstGameHelp`) : le persister aurait demandé une clé par joueur pour un gain nul.
Tutos en `Navigator.push` plutôt qu'en route `currentScreen` : pas de toucher à `app.dart` ni à
la machine d'écrans. Clés neuves, absentes = `false` : aucune migration (règle 7).

**Conséquence.** Le branchement des autres écrans suit `lib/widgets/help/WIRING.md`.

## 2026-11-04 — Écran entre les manches réduit à l'essentiel

**Quoi.** `transition_screen` ne garde que : « Manche N terminée », une carte sobre « Manche N+1 :
<mode> » + sa règle, qui commence, le temps bonus conservé (formulation d'avant la refonte #23),
« Voir les N mots devinés », le bouton. Retirés : la frise des manches, la tuile « N mots
reviennent dans le chapeau », l'astuce mémoire, l'emoji de fond et l'animation d'entrée. Fiesta :
le 1 parmi 3 reste une carte (il demande une action) ; tirage, rattrapage et coup de pouce
deviennent chacun une ligne (`RoundDrawLine`, `CatchUpLine`, `AppBoostLine`, gabarit
`FiestaInfoLine`) ; `CatchUpCard` et `AppBoostCard` disparaissent.

**Pourquoi.** Retour device de Florent : « Manche 1 terminée, manche 2, c'est ça la règle, et on
clique sur suivant. » Le reste ralentissait la lecture. Les modificateurs restent des pastilles
qu'un tap explique : rien de l'information Fiesta n'est perdu, seulement le texte d'explication
fixe (plafonds du rattrapage, « s'applique à toutes les équipes »).

**Conséquence.** Affichage seul : aucune logique de jeu ni forme persistée touchée.

## 2026-11-04 — Prise en main : retouches de l'aide après la recette device

**Quoi.** Les bulles d'aide passent en bleu nuit, comme les cartes de l'app : le titre est en Bangers avec l'ombre rose, le texte en Poppins blanc, et le bouton est un `AppButton`. La cible est entourée d'un liseré blanc translucide. Le « ? » s'affiche seul, en gris clair, sans rond, et garde une zone tactile de 48×48. Au premier « Jouer » d'un téléphone neuf, le tuto des règles s'ouvre d'office, sans la question « Première partie ? » ; « Passer » permet de le fermer. `FiestaTutorialScreen.show` a maintenant une garde statique contre une double ouverture.

**Pourquoi.** Sur Flutter web, la cible restait voilée. Le voile n'utilise plus `Path.combine(difference)` mais un seul chemin `PathFillType.evenOdd` (écran + cible), qui découpe le trou sans opération booléenne et se rend de la même façon sur tous les moteurs. La question « Première partie ? » ne commandait que le tuto des règles, car les bulles de la première partie étaient déjà automatiques ; elle est donc supprimée. Le critère « téléphone neuf » ne change pas : c'est `guessItAll_tutorialSeen`, posé par `initAtStartup`. Le sens de cette clé ne change pas non plus (revue r1, règle 7) : elle veut dire « onboarding des règles de première partie traité », que la question ait été posée (anciennes versions) ou que le tuto ait été ouvert. Un ancien `true` reste valable : qui a répondu « Je connais déjà » ne revoit rien, et c'est voulu. Un `false` sur un téléphone qui n'a jamais joué ouvre le tuto. Le drapeau s'écrit une fois la route du tuto poussée, pour qu'un kill avant l'affichage ne le saute pas pour toujours. Aucune clé n'est créée, aucune ne change de forme, aucune migration.

## 2026-11-04 — Fiesta : le mode se choisit dans les Paramètres

**Quoi.** Le parcours devient Accueil « Jouer » → Paramètres → Joueurs → Équipes → partie. Un
`AppToggle` « Classique / Fiesta » sous le titre des Paramètres (Classique par défaut) ; en
Fiesta, la fenêtre « Avancés » gagne « Fiesta : Auto / Personnalisé ». En Personnalisé
seulement, « Mes ensembles » s'insère après les équipes et son « Jouer » lance la partie.
Supprimés : écrans « Mode de jeu », « Auto ou Personnalisé », « Mode Auto » et « Récap »
(et `FiestaSetupScaffold`, `FiestaPickCard`, `FiestaCommonRulesCard`). Le tuto Fiesta s'ouvre
au premier passage de l'interrupteur sur Fiesta (même clé `guessItAll_fiestaTutorialSeen`).
« Rejouer » revient aux Paramètres, config Fiesta en attente. Auto = symétrique +
auto-calibrage toujours allumés. « Une seule réponse » n'est plus une règle commune : c'est un
modificateur de toute la partie (`kOneAnswer`), coché dans l'ensemble en Personnalisé, tiré au
lancement en Auto une fois sur 4 (`drawsOneAnswer`, graine du `gameId`) et annoncé avant le
premier tour. « Dessiner » exclut tout mime (règle de groupe `mime` au lieu de trois paires).
Personnalisé : jusqu'à 3 modificateurs par équipe et par manche (`maxModifiersPerTeam`, tirage
réglable de 0 à 3).

**Pourquoi.** Retours device de Florent (maquette « E ») : trois écrans de choix avant même les
réglages, c'était trop. Le choix du mode reste en mémoire (`pendingFiesta`, Q10) : rien de neuf
à persister.

**Conséquence (règle 7).** Aucune forme persistée ne change : `FiestaRules` garde exactement ses
clés. `oneAnswer` garde sa clé et son sens (« une seule réponse en vigueur pendant la partie ») ;
une clé absente se relit toujours `true`, l'ancien défaut. Seuls les nouveaux ensembles partent
décochés (`defaultEnsembleRules`). Un `currentScreen` relu au nom d'un écran
supprimé tombe sur l'accueil (cas par défaut de `app.dart`). Une partie Personnalisé suspendue
avant la mise à jour peut tirer un 3ᵉ modificateur aux manches suivantes (plafond relevé), sans
rien casser. Dans Firestore, `fiestaRules.oneAnswer` d'une partie Auto dit désormais ce qui a
été tiré, et non plus un interrupteur.

**Revue r1 (même jour).** Paramètres et « Mes ensembles » sont l'écran racine du `MaterialApp` :
le retour système d'Android quittait l'app. Un `PopScope` les ramène à la destination de leur
bouton retour (accueil, équipes) — les écrans supprimés le faisaient via `FiestaSetupScaffold`.
« Tout réinitialiser » vide aussi la Fiesta en attente. Ajout demandé par Florent : le bouton
rond « Réinitialiser » quitte le coin haut droit des Paramètres pour le bas de la fenêtre
« Avancés » (« Réinitialiser les paramètres », même confirmation) ; en haut à droite ne restent
que le « ? » et la roue crantée.

## 2026-11-04 — Paramètres sans défilement, famille « Mime », deux nouveautés au catalogue

**Quoi.** Paramètres : ordre Joueurs, Équipes, « Mode de jeu » (section titrée, Classique /
Fiesta), Choix des mots, puis Catégories ; espacements serrés et compteurs à 40 pt pour tenir
sans défiler (mesuré : contenu 709 px, avertissement « partie longue » compris, pour 763 utiles
sur iPhone 390 × 844 et 740 sur Android 360 × 780). « Avancés » : curseurs `compact` (valeur à
droite du libellé) et espaces de 8 px, contenu 402 px en Fiesta. Catalogue : une **famille
« Mime »** (`mimeFamily` : les 3 mimes, « Dessiner », « Mimer sous un drap », « Mime de dos »)
dont deux membres s'excluent toujours, à la place des paires mime/mime et de la règle
Dessiner/mimes ; « Faire deviner dans une autre langue » (malus, `notInRound3` : jamais en
manche 3, compatible avec tout le reste). Éditeur Personnalisé : sections Malus puis Bonus,
sous-catégorie Mimes à choix exclusif ; nouvel ensemble = rattrapage coupé, tirage symétrique
allumé, seul « Dessiner » actif parmi les mimes.

**Pourquoi.** Retours device de Florent. La règle de famille passe par `areCompatible`, donc
par `canAdd` : tirage Auto et Personnalisé, fixés, 1 parmi 3, coup de pouce l'appliquent sans
code propre. Les nouveaux ids sont ajoutés **en fin** de catalogue et dans `kOfferStrength`
(drap : forte ; dos et autre langue : moyenne — au doigt mouillé, comme le reste).

**Conséquence (règle 7).** Aucune forme persistée ne change (ids ajoutés seulement). Un ensemble
enregistré avec plusieurs mimes actifs se relit via `oneMimeAtMost` — normalisation
déterministe : le premier mime fixé dans l'ordre du catalogue, sinon le premier actif dans
l'ordre du catalogue (ce n'est pas forcément le mime tiré auparavant) ; les autres passent
`active: false` en gardant leurs réglages, et le blob est réécrit à la prochaine écriture du
store (« Enregistrer », mais aussi « Jouer » via `markUsed`). Les règles et l'état gelés d'une
partie en cours ne sont PAS normalisés : une partie Fiesta de dev déjà gelée avec deux mimes
les garde et les applique tous les deux (couvert par la rupture pré-release ci-dessous) ; la
règle de famille ne s'applique qu'aux nouveaux tirages.

**Rupture pré-release assumée (revue r1).** La Fiesta n'a jamais été publiée (le dernier tag
store ne contient aucun fichier Fiesta) ; une partie Fiesta suspendue sur une build de dev
peut voir tirages/offres/récap recalculés, car les nouveaux ids allongent les listes de
candidats mélangées par la même graine. Pas de versionnage du catalogue : sur-dimensionné pour
un mode jamais publié. Règle pour l'après-publication → `lib/models/CLAUDE.md`.

## 2026-11-04 — « Avancés » : réglage Fiesta visible en Classique, Réinitialiser aéré

**Quoi.** Le réglage « Fiesta : Auto / Personnalisé » de la fenêtre « Avancés » s'affiche aussi
quand le mode est Classique ; le choix est gardé en mémoire de l'écran et appliqué au passage en
Fiesta. 24 px d'air au-dessus de « Réinitialiser les paramètres ». **Pourquoi.** Retours
Florent : voir le réglage dans les deux modes, et le bouton ne respirait pas assez.

## 2026-11-04 — Fiesta Personnalisé : un seul écran « Fiesta personnalisée », avant les joueurs

**Quoi.** L'écran des ensembles vient juste après les Paramètres (Personnalisé seulement), avant
les joueurs ; les Équipes redeviennent « Commencer » et lancent la partie avec `pendingFiesta`.
L'écran réunit, sans page poussée : les ensembles prêts à jouer (aucun enregistré → « Fiesta
classique » fourni par l'app, `defaultEnsembleRules`, jamais stocké), l'éditeur en ligne
(`FiestaEnsembleEditor`, ex-`FiestaEnsembleEditorScreen`) et « Suivant ». Un ensemble enregistré
apparaît en haut, sélectionné. Rejouer repasse par cet écran, l'ensemble précédent présélectionné
(règles égales à `pendingFiesta`, sinon `lastUsedId`). Le « ? » ouvre une aide propre
(`fiestaEnsemblesHelp`) au lieu du tuto Fiesta.

**Pourquoi (bug Florent, Chrome).** « Impossible d'enregistrer un ensemble, c'est un
cul-de-sac. » Le stockage n'était pas en cause (créer + relire marche, test à l'appui) : l'éditeur
était une page poussée sans « Suivant », dont la seule issue visible était le retour, qui
**jetait** la saisie (`pop(false)`) ; « Enregistrer » restait grisé sans nom et, enregistré, ne
menait qu'à une liste où il fallait encore trouver « Jouer ». Sans ensemble, on tournait en rond.
La racine est le parcours, pas un correctif ponctuel : d'où l'écran unique.

**Conséquence (règle 7).** Aucune forme persistée ne change (`guessItAll_fiestaEnsembles`
intact, `lastUsedId` toujours écrit par `markUsed` au « Suivant »). `pendingFiesta` reste en
mémoire seulement.

**Revue r1 (2026-11-04).** Saisie non enregistrée de l'éditeur en ligne : confirmation
« Abandonner les modifications ? » avant de la jeter (Modifier un autre, Annuler, Retour,
Suivant) ; sélectionner pendant une modification referme l'éditeur, pour que l'écran ne montre
jamais autre chose que ce que « Suivant » lancera. Retour système Android branché sur Joueurs,
Équipes et Mots (même motif `PopScope` que Paramètres), destination = bouton retour visible.

## 2026-11-04 — « Une seule réponse » cochée par défaut en Personnalisé

**Quoi.** `defaultEnsembleRules` crée désormais un ensemble avec « Une seule réponse » **cochée**
(toute la partie), décochable dans l'éditeur. Remplace « les nouveaux ensembles partent
décochés » plus haut. Les ensembles déjà enregistrés gardent leur valeur ; « Fiesta classique »
(ensemble fourni par l'app) suit ce défaut. **Pourquoi.** Décision Florent : coché par défaut.

## 2026-11-04 — Fiesta v2, lane 1 : modes par modificateur, ensembles fournis, éditeur poussé

**Quoi.** Nouveau modèle d'ensemble (`FiestaRules` forme **v2**, `format: 2`). Chaque
modificateur a des manches cochées {1, 2, 3} et UN mode : « Toute la manche, pour tous »
(`always` / `draw`) ou « Cartouche · un tour » (`stock` N par équipe, par manche ou pour la
partie / `offer` 1 parmi 3). Règles de la partie : `drawCount` 0-5, `pick3Choices` 1-3 (rangées de
3 cartes sur le même écran, une carte par rangée), rattrapage. Supprimés : tirage symétrique,
« fixé en manche N » (→ `always` + cases), plafond de 2/3 modificateurs (seules les
incompatibilités limitent, `canAdd` et l'allumage des bonus), « Une seule réponse » comme
réglage global (→ malus `one_answer` du catalogue). Ajouts **en fin de catalogue** : `one_answer`,
`sounds_only` (famille mime, M3). Exceptions « seulement en cartouche » : `block_guesser`,
`double_points`. Auto ré-exprimé (`autoRules`) : tout « Au tirage » (1 ou 2 par manche),
`one_answer` « Toujours » M1-M3 une partie sur 4, coup de pouce inchangé. 7 ensembles fournis
(code, jamais écrits, duplicables), « Fiesta classique » présélectionné ; noms uniques
(casse/espaces ignorés), copie « Nom (2) », doublon de réglages refusé. Éditeur = écran poussé
« Nouvel ensemble » / « Modifier », Enregistrer toujours actif avec erreurs précises après appui,
brouillon en mémoire, « Tu veux l'enregistrer ? », retour Android. Couleurs malus #F87171 /
bonus `AppColors.success` (éditeur, badges, cartes).

**Pourquoi.** Décisions Florent du 2026-11-04 (spec cartouches, maquette `cartouches`). Le bug
« Donne un nom à l'ensemble » avec un nom saisi venait de la validation affichée en permanence :
l'éditeur en ligne repartait vierge après un enregistrement et criait aussitôt l'erreur. Les
erreurs ne s'affichent plus qu'après un appui sur Enregistrer (test qui le reproduisait sur
`origin/main`).

**Conséquence (règle 7).** Fiesta jamais publiée : la forme v1 n'est pas traduite. Ensemble v1
→ illisible, ignoré (réécrit tel quel, jamais détruit) ; partie Fiesta suspendue v1 →
abandonnée au démarrage (accueil, joueurs gardés), jamais reprise en Classique ; archive
d'historique v1 → pas de « Rejouer » (snapshot illisible). `kCurrentSchemaVersion` inchangé
(le marqueur `format` suffit). Classique intouché.

**Résidus assumés jusqu'à la lane 2.** Malus « En stock » : instanciés par équipe en
**réserve** (`ModifierInstance.reserve`, persistés, kill compris), **sans effet en jeu**.
« Passe gratuite » : « par manche » seulement (option « pour la partie » masquée, ses passes ne
laissent pas de `ChargeUse`). Revue r1 : « Deux mots » en règle de manche s'applique d'elle-même
(deux cartes à chaque tour, sans activation ni charge) ; snapshot de retour arrière v1 refusé. Bonus « En stock » = mécanisme de charges actuel (×2 et Deux mots s'allument
avant le tour ; Passe gratuite en stock = N passes gratuites par tour toute la manche). Une carte
1 parmi 3 de malus vise encore le leader pour toute la manche N+1 (la cartouche ciblée d'un tour
arrive avec l'écran « Ce tour / Réserve »).

## 2026-11-04 — Reclassement de mots FR (revue Florent)

Difficulté seule (`assets/translations/words/fr/`), aucune forme persistée touchée.
- Niveau 2 : Shape of You, Vice-Versa, Persil, Accrocher, Nerveux, Lancer franc, Pain, Harpe, Affamé, Sous-sol, Profiterole, Réparateur, Marche rapide, Nausée.
- Niveau 3 : Ampli, Téléski, Mew.
- « Chauffeur de camion » renommé « Chauffeur poids lourd » + niveau 2.
- « Laurent Gerra » supprimé (celebrites).
- « Dedans » laissé en niveau 1.

## 2026-11-04 — Fiesta v2, lane 2 : écran avant le tour « Ce tour / Réserve », cartouches ciblées

**Quoi.** L'avant-tour Fiesta (maquette `cartouches` B, variante a) remplace les cartes
« Actif ce tour », « Bonus » et « Temps du tour » par deux zones, sans défilement : « CE TOUR »
(règles de manche en cercle neutre, malus reçus en rouge plein, bonus allumés en vert plein ;
« Rien ce tour » si vide) et « RÉSERVE » (mes cartouches, colonnes Bonus / Malus, pastille du
nombre restant, grisé si épuisé ou incompatible). Toucher = activer / infliger, appui long =
explication. Une cartouche = UN tour d'UNE équipe :
- **Bonus** (×2, Deux mots, Passe gratuite) : allumé avant le tour, dépensé au départ du chrono
  (`ChargeUse`). Passe gratuite devient une cartouche (`kChargeBonusKeys` : un tour de 2 passes
  gratuites) ; son « pour la partie » est décompté et réactivé dans l'éditeur.
- **Malus** (« En stock », et désormais les cartes 1 parmi 3, qui entrent dans la réserve de
  celle qui choisit au lieu de viser le leader toute la manche) : infligé à une équipe (2
  équipes : directement à l'autre ; 3+ : « Contre quelle équipe ? »), pour SON prochain tour,
  quel que soit le joueur. Dépensé tout de suite, annulable tant que le tour de l'envoyeuse n'a
  pas commencé. Même malus déjà infligé à la cible → refus, cartouche non consommée ; deux malus
  différents se cumulent, sauf deux mimes (un seul mime par tour : traité comme la collision).

**Pourquoi.** Décisions Florent du 2026-11-04 (spec cartouches §3, variante B des malus ciblés).
Le malus infligé est une `ModifierInstance` de portée tour avec `fromTeamId` : il réutilise le
chemin existant des effets du tour (`modifiersForTurn`, `turnTime`, `passBlocked`, devineur
bloqué désigné par l'envoyeuse) au lieu d'un second mécanisme.

**Conséquence (règle 7).** Fiesta jamais publiée ; ajouts **optionnels** à la forme v2 :
`ModifierInstance.from`, `ChargeUse.target`, `fiesta.turn.freePass` (clés omises si absentes,
relues tolérantes). Envois en attente et cartouches dépensées vivent dans `GameState.fiesta`
(kill, retour arrière). Classique intouché, `kCurrentSchemaVersion` inchangé. Récap : « Bonus
utilisés » devient « Cartouches utilisées » (un malus : « X contre Y »).

**Choix et résidus.** Coup de pouce (Auto) : ses bonus passent par l'offre, donc deviennent des
cartouches (une Passe gratuite offerte = un tour, plus toute la manche) ; son malus frappe
toujours le leader toute la manche (personne pour l'infliger). Un malus infligé interdit dans la
manche où la cible rejoue (« Autre langue » envoyé en M2, cible qui rejoue en M3) part sans
effet à la fin de ce tour. Ensembles fournis inchangés (Explosif, L'injustice).

**Revue r1.** Les malus reçus se résolvent au tour de la cible (`modifiersForTurn`, seule
résolution), contre les règles de manche de SA manche et les malus déjà retenus : un malus en
double ou incompatible (ex. « Interdit de passer » envoyé en fin de M1, « Passe gratuite »
Toujours en M2) est écarté sans effet, comme un malus interdit dans la manche. L'avant-tour ne
défile plus : cercles de 50 à 36 px (la réserve seule jusqu'à 32 px en dernier recours),
« Ce tour » sur plusieurs rangées s'il le faut, colonne Bonus à la largeur qui minimise les
rangées. Pour faire la place (arbitrage lead) : en Fiesta, carte d'équipe compacte
(« Équipe · Joueur », mots restants dedans) sous une marge fixe, titres de zone réduits, envois
en puces « [icône] → X » (un appui propose d'annuler). La zone est coupée (`ClipRect`) plutôt que
de passer sous « Commencer le tour ». Rendus locaux : Explosif M1 et M3 chargés (3 malus reçus,
une règle, un bonus allumé, 2 envois), Explosif M3 2 équipes et Fiesta classique tiennent en
360 × 640 et 360 × 740. Le titre de manche rétrécit au lieu de déborder (« Description libre »).

## 2026-11-05 — Fiesta : quatre retours device (fin de tour, Auto / Personnalisé, fiches, Deux mots)

**Fin de tour (bug).** Le chrono à zéro appelait `endTurn` dans un `addPostFrameCallback`, qui ne
demande pas de frame. Pendant la dernière seconde rien ne notifie ni n'anime l'écran : le tour
restait sur « 1s » jusqu'à un toucher. `endTurn` est appelé directement dans le callback du Timer,
qui n'est pas une phase de build. Test sans aucun `pump` après le départ : rouge sur l'ancien code,
vert sur l'ancien code avec une seule frame, vert sur le nouveau.

**Auto / Personnalisé.** Passe d'un champ local de l'écran à `GameSettings.fiestaMode` (clé
`fiestaMode`, optionnelle : absente ou inconnue = Auto, `kCurrentSchemaVersion` inchangé). Rejouer
une Fiesta depuis l'historique aligne le réglage sur son mode ; rejouer une archive Classique, ou
une archive sans cette clé, ne touche pas au choix du joueur (sinon elle le remettrait en Auto).

**Fiches des badges.** Titre `AppTextStyles.subtitle` sans changer la couleur (blanc, ombre rouge).
La couleur reste sur la bordure, « Compris », les pastilles et les cercles.

**Deux mots.** Plus de cartes blanches, d'étiquettes ni de défilement : `TurnWordText` et
`TurnActionButtons` (`widgets/common/turn_play_widgets.dart`) sont factorisés depuis le tour à un
mot, avec une version `compact` de 64 px pour les boutons. Les mots se partagent la hauteur restante
et rétrécissent jusqu'à 16 px. Rendus regardés en 360 × 640 et 390 × 844 avec de longs mots et trois
badges.

**Revue r1.** `endTurn` est idempotent : il ne fait rien hors de `screenTurn`. Le chrono et la
confirmation « Terminer » peuvent se croiser, et un second appel ajoutait un événement `expired`
pour le même mot. Il remettait aussi à zéro le temps reporté d'une manche finie en avance. Les seuls
appelants sont dans `TurnScreen`, monté uniquement sur `screenTurn`, reprise de partie comprise.

## 2026-11-05 — Fiesta v3 : refonte des règles (retours device de Florent)

**Ce qui change.** Plus de « 1 parmi 3 », de rattrapage, de force d'offre ni d'écran de révélation
des malus. Modes `Toujours / Au tirage / Cartouche` (`FiestaRules.format = 3`). Une cartouche vaut
pour TOUTE LA PARTIE, par équipe. Bonus, `minus_10s` et `block_guesser` seulement en cartouche ;
`one_answer` seulement règle de manche. Nouveau bonus `plus_10s`. Coup de pouce à l'équipe menée :
après M1 et M2, chaque équipe non en tête reçoit UNE cartouche au hasard. La continuation joue sous
les règles de N+1. Transition réduite à la manche suivante et à qui commence. Page « Voir » d'un
ensemble.

**Pourquoi ces choix.**
- *Stock = `charges + earned − chargesUsed`*, calculé (`FiestaState.cartridgesLeft`), plutôt que
  des instances « cartouche » dans `active` : une seule source, et plus de décompte par manche.
- *Gagné écrit à `nextRound` seulement* (`fiesta.earned`) : la transition reste un plan recalculé.
  Le retour arrière restaure un état d'avant, l'app tuée recalcule, une correction de vérification
  change le classement donc le cadeau, sans doublon ni perte possibles.
- *Récap relu de `earned`* au lieu de rejouer le plan sur les scores cumulés : plus simple, et c'est
  ce qui a été donné.
- *Format 3 illisible pour une partie v2* : même politique que v1 → v2, Fiesta jamais publiée. Une
  archive d'historique reste lisible : ses faits `catchUp` / `choice` sont ignorés seuls.
- *Aucune cartouche ne se joue sur une continuation* (inchangé : c'est le même tour). Le +10 s y
  serait de toute façon sans effet ; `_conflict` le garde pour la raison affichée.

## 2026-11-05 — Fiesta v3.1 : second lot de retours de Florent

**Ce qui change.** Fiesta classique : tout au tirage. Réserve complète sur l'avant-tour d'une
continuation, cartouches gagnées à l'instant comprises ; `plus_10s` y ajoute 10 s au temps reporté.
Le dernier choix des paramètres survit à l'app tuée et à « Nouvelle partie » (lève Q10). Coup de
pouce : `boostCount` 0-3 remplace `trailingBoost`, cartouches distinctes. Mimes : plusieurs actifs
permis, un « Toujours » exclut les autres à l'enregistrement ; `oneMimeAtMost` retiré, Explosif et
L'injustice incluent tous les mimes.

**Pourquoi ces choix.**
- *Continuation* : la dépense reste au départ du chrono et le stock reste calculé, donc aucun état
  nouveau. Une charge `spent` n'est plus décomptée une seconde fois par `reserve` et affiche
  « déjà en cours ce tour ». `turnTime` ne compte sur un report que le +10 s `armed` : celui dépensé
  avant est déjà dans les secondes reportées.
- *`sentThisTurn` filtré sur la manche d'envoi* : sans ça, l'avant-tour d'une continuation rendrait
  annulable un malus envoyé avant la première partie du tour, déjà annoncé et « parti ».
- *Choix dans `GameSettings`* (`fiestaEnabled`, clé absente = Classique, règle 7) plutôt qu'une clé
  dédiée : même écriture et même relecture que le reste de l'écran. On ne persiste pas les règles :
  en Personnalisé `_rememberedFiesta` résout le `lastUsedId` vers de vraies règles (repli Fiesta
  classique), si bien qu'une app tuée sur Joueurs ou Équipes ne lance jamais un ensemble vide.
- *`boostCount` à la relecture* : absent → ancien booléen, pour les ensembles et les parties en
  cours ; `format` reste 3, `kCurrentSchemaVersion` inchangé. Mélange par la graine plutôt que des
  tirages successifs : distinctes par construction, déterministe. Le cadeau figé d'une graine
  change (`nextInt` → `shuffle`) : sans risque, il n'est recalculé qu'à une transition à venir et
  la Fiesta n'est pas publiée.
- *`_fit`* : 11 malus + 4 bonus tiennent à 360 × 640, temps bonus compris. Sur une continuation
  avec des malus envoyés, la ligne d'aide cède sa place (rappelée par le « ? »). Au-delà de 3 puces
  « Envoyé » sur une continuation à 360 × 640, le bas reste coupé par le `ClipRect` : cas extrême
  assumé, pour ne pas alourdir l'écran.

**Revue r1 et décision de Florent (même jour).**
- *Config rejouée* : `replayFromHistory` et le « Rejouer » gardaient les règles gelées en mémoire
  seulement ; après un kill, `lastUsedId` reconstruisait un autre ensemble. `GameSettings.replayFiesta`
  les garde jusqu'au lancement ou à un choix explicite, plutôt qu'une nouvelle clé `guessItAll_*` :
  même écriture, relecture tolérante. Pas pour Auto, dont les règles sont recalculées.
- *« Toujours ça veut dire toujours »* : un « Toujours » vaut pour toutes les manches où il existe
  (`allowedRounds`), `rounds` n'est plus lu ni jugé, ni compté dans `settingsKey`. La forme JSON ne
  bouge pas : un ensemble au `rounds` partiel se relit et joue sur toutes ses manches possibles.
  L'erreur d'incompatibilité ne nomme plus de manche : elle vaudrait pour chacune.

## 2026-11-05 — Fiesta v4, lot 1 : éditeur en 3 menus, blocages nommés, passage de manche

**Quoi.** Modèle `format: 4` : trois réglages indépendants par modificateur (`always`, `draw`, `charges`),
`drawCount`, `allCount`, `trailingCount`, `balance`. Fin du mode Auto. 8 ensembles fournis, sans règle
cachée. Nouveau malus `block_giver`, `one_answer` possible en cartouche, paire Bruitages / drap
compatible. Blocages nommés à l'envoi, piège d'« Interdit de faire deviner ». Animation entre les
manches, écran fixe après M3.

**Pourquoi ces choix.**
- `lockReason` dans `FiestaRules`, lu par le moteur et l'éditeur : un réglage verrouillé est gardé pour
  être restauré, donc ne doit jamais jouer. `isAlways` / `drawsFrom` / `chargesOf` sont la seule lecture
  en partie.
- Malus rendu dans `RoundTransitionPlan.apply` : c'est le seul moment où une règle nouvelle peut croiser
  un malus en attente, et le plan est recalculé, donc retour arrière et app tuée ne rendent rien deux
  fois. L'équipe qui continue en est exclue : son malus est déjà appliqué.
- Rotation : `fiesta.skips` par équipe, ajouté à l'index de `playerIndexAtTurn`, plutôt que de réécrire
  l'ordre. Alice, ~~Bob~~, Frank, Alice, Bob, Frank sort directement, y compris à 2 joueurs, et le retour
  arrière restaure tout par le snapshot habituel.
- Le piège passe par `startTurnTimer`, seul point qui démarre le chrono : un écran persisté
  (`screenGiverBlocked`), rien de consommé avant « Suivant », donc une app tuée remontre la phrase.
- `sentTurnIndex` sur les malus : un blocage peut attendre plusieurs tours, la manche d'envoi ne suffisait
  plus à dire « envoyé dans CET avant-tour ».
- Vivier : au-delà de sa taille, il repart du début plutôt que de donner moins (« distinctes tant que le
  vivier le permet »).
- Zone de cartouches : `[_fit]` resserre, puis la zone défile en dernier recours (`SingleChildScrollView`
  dans le `LayoutBuilder`), plutôt que le `ClipRect` qui rendait des pastilles « Envoyé » inatteignables,
  donc impossibles à annuler. « Commencer le tour » reste hors de la zone. Les 24 px sous le bouton sont
  retirés en Fiesta : sans eux, Explosif en M3 tient sans défiler à 360 × 640 avec les barres système.

**Conséquence.** Ensembles et parties Fiesta d'un autre format restent illisibles, comme avant (Fiesta
jamais publiée). `kCurrentSchemaVersion` inchangé. L'archivage de fin de partie se fait à « Voir les
résultats ». Les seuils d'équilibrage sont des constantes à recalibrer après des parties réelles.

## 2026-11-05 — Révélation des scores en fin de partie (Fiesta v4, lot 2A)

**Quoi.** Classique et Fiesta : avant l'écran Résultats, inchangé, les courbes de scores se tracent
tour par tour en 4,5 s, sans chiffres, puis le vainqueur. En Fiesta, les cartouches jouées tombent
sur la courbe de l'équipe qui les a jouées. `ChargeUse.turn` (optionnel) date la cartouche ; clé
absente : en fin de manche.

**Pourquoi ces choix.**
- *Aiguillage sur `screenResults` plutôt qu'un écran de plus* : tous les chemins vers les résultats
  (« Voir les résultats » de l'écran fixe après M3, via `nextRound`) restent tels quels, et les
  tests et le bouton accueil qui lisent `screenResults` aussi. Seul un drapeau décide.
- *`GameState.scoreRevealSeen`, clé écrite une fois vraie, gardé à la restauration* : le snapshot de
  retour arrière précède la révélation, une correction du dernier tour ne doit pas la rejouer. Clé
  absente sur résultats ou stats = vue : une partie finie avant cette version ne la joue pas, une
  app tuée pendant la révélation repart sur les résultats. `kCurrentSchemaVersion` inchangé.
- *Une étape par entrée d'historique* : une continuation a sa propre étape dans sa manche, sinon ses
  points tomberaient du mauvais côté du séparateur. Une cartouche se place par (tour, manche) : le
  numéro de tour seul ne distingue pas les deux parties d'une continuation.
- *Effets sans focus audio* : sur Android, un second player qui prend le focus met le premier en
  pause (`WrappedPlayer.onLoss` d'audioplayers), la musique s'arrêterait à la première cartouche.
- *Pas de réglage de son* : l'app n'en a pas, les sons de la révélation jouent toujours, comme les
  autres.
- *Musique maison, décision de Florent* : `scripts/render_reveal_music.py` rend hors ligne la
  composition de la maquette (`music(4.5)`, gong à 4,5 s) et le dépôt public peut la porter. Pas de
  piste d'un reel. Le gong et l'accord final jouent le rôle de l'impact prévu : la révélation
  n'utilise pas `impact-bass-1`, qui reste aux animations de manche.
- *Départ commun* : l'animation attend que `startMusic` rende la main (0,8 s au plus), sinon le
  chargement du fichier décalerait le gong. À la fin normale, pas de fondu : la queue d'environ 3 s
  est déjà un fondu, et le bouton de fin ne la coupe pas. Le fondu ne sert qu'à passer pendant le tracé. Lecture en échec : révélation muette.

**Revue et décision de Florent (même jour) : il n'y a jamais d'égalité.**
- *Règle unique* : à égalité de points, l'équipe qui a commencé à jouer le plus tard gagne.
  `compareFinalRank` (`play_rotation.dart`) la porte seule, pour `getTeamsSortedByScore` et pour
  l'archive. La révélation annonce le premier du classement.
- *`GameResult.playOrder`* : ids des équipes dans l'ordre de jeu, clé additive. L'historique et
  « Victoires » appliquent la règle aux nouvelles parties. Une archive sans cet ordre, ou avec un
  ordre incomplet, garde son affichage « Égalité » et sa victoire à chacune : rien ne permet de la
  départager après coup.
- *Effets coupés à la sortie* : compteur de lecture plutôt qu'un simple `stop`, car un effet en cours
  de préparation partirait après un `stop` déjà passé, donc sur l'écran Résultats.
- *Place qui manque* : carte de fin à la hauteur de la police, texte défilant et bouton fixe. Le
  titre puis la légende cèdent leur place au graphique, les courbes portant déjà les noms.

---

## 2026-11-05 — Fiesta v4, lot 2B : défis surprises entre les manches

**Quoi.** Réglage « Défis surprises » en bas du menu Cartouches. Après M1 et/ou M2 (1 ou 2 fois, tirage
par `gameId`) : animation de manche, défi, écran avant le tour. L'équipe gagnante reçoit une cartouche
tirée dans le vivier du hasard ; passer le défi ne donne rien.

**Pourquoi ces choix.**

- Format 4 et `kCurrentSchemaVersion` inchangés : `rules.challenges` et `fiesta.challenges` sont deux clés
  omises quand elles sont vides, et une clé absente se relit « coupé » / « aucun ».
- Plan recalculé, jamais persisté (`planChallenge`) : joueurs, défi, mot et les 2 cartouches possibles
  sortent de l'état de fin de manche, qui ne bouge pas pendant le défi. Une app tuée retrouve le même.
  Rien n'est écrit avant la fin : elle le rejoue sans rien avoir donné.
- 🔴 Seul point qui ne suit pas la règle « le snapshot restaure tout » : un défi terminé survit au retour
  arrière (`keepingChallengesOf`), sinon on pourrait le rejouer pour gagner une autre cartouche. Sa
  cartouche reste acquise, même si la correction rouvre la manche. Il n'est donné qu'une fois, par manche
  de fin.
- Un défi passé compte comme terminé, pour la même raison.
- « Passer ce défi » reste possible jusqu'à « Continuer » (décision de Florent) : un appui erroné sur la
  mauvaise équipe n'engage rien, car l'issue ne s'écrit qu'à « Continuer ». Après, plus de retour.
- Pas de défi plutôt qu'un défi boiteux : vivier vide d'une des deux équipes, ou téléphone arabe sans mot
  deviné. Le défi n'est pas remplacé, la partie en a alors un de moins.

**Écarts avec la maquette.** Le sous-titre de l'éditeur ne dit pas « les moins rapides » : la spec veut ce
critère jamais affiché. Un seul interrupteur, sans le choix défi par défi de la maquette, absent de la spec.

**Conséquence.** Le joueur le moins rapide compte tous ses tours, y compris sans mot ; un joueur sans temps
de jeu n'est pas mesuré. Les sons restent à écouter sur appareil, Android et iOS.

---

## 2026-11-05 — Audit des statistiques et des résultats

**Quoi.** Relecture de chaque chiffre de Résultats, Statistiques, Historique et de la révélation, avec une
partie Fiesta calculée à la main (`stats_consistency_test`) et, hors commit, 90 parties aléatoires de 2 à
4 équipes, Classique et Fiesta. Scores, manches, mots, temps et archive concordaient déjà. Défauts corrigés :

- Graphique : barre de manche placée au premier tour NORMAL. Une manche jouée toute en continuation perdait
  sa barre, et M3 s'affichait « M2 ». La barre suit maintenant la première entrée de la manche.
- Graphique : le haut de l'axe (51) s'écrivait sur le dernier repère (48), et « 1 » deux fois.
- Graphique : une entrée sans équipe connue faisait tomber l'écran.
- Temps moyen : le plus rapide à 0,0 s avait une barre vide.
- Révélation : une cartouche jouée juste après une continuation tombait sur le tour de l'équipe précédente.
- Historique : couleur donnée par le rang et non par l'équipe ; « Victoires » illisible ou en débordement à
  360 px ; « Les Moulins gagne » ; un champ de mauvais type vidait l'historique, puis l'écrasait.
- Résultats : « 1 pts ».

**Pourquoi ces choix.**

- « Mots devinés par partie » devient « Points par partie » : le chiffre compte les points, et l'archive ne
  garde pas le nombre de mots. La valeur ne change pas, anciennes parties comprises ; seul le libellé change.
- Temps moyen et tours sans mot : exclus comme avant, c'est le choix documenté de `stats_aggregation`.

**Conséquence.** Reste un défaut de jeu, non corrigé ici : voir le rapport de la PR (continuation à 0 s).

### Demande de Florent : modificateurs hors des Résultats, badges sur le graphique

**Quoi.** La carte « Modificateurs de la partie » quitte les Résultats. « Évolution des scores » reçoit un
filtre « Bonus et malus joués », éteint à chaque visite, qui pose les badges des cartouches jouées.

**Pourquoi ces choix.**

- Premier graphique = « Évolution des scores », le seul vrai graphique de l'écran. Il n'avait aucun badge :
  ils viennent de `ChargeUse.turn`.
- Un badge est à la fin du tour de l'équipe qui a joué la cartouche, malus compris, comme à la révélation.
- Filtre absent quand il n'y a rien à poser : Classique, aucune cartouche, partie sans `turn`. Une règle de
  manche tirée n'est pas une cartouche jouée : seule, elle ne fait pas apparaître le filtre.
- Faits archivés gardés (`GameResult.modifierRecap`). `formatModifierRecap` et `provider.modifierRecap` n'ont
  plus d'écran, seulement des tests qui vérifient ces faits.

### Revue de la PR : archive sans équipe

Une entrée sans équipe lisible est ignorée à la lecture, comme les autres entrées illisibles : elle affichait
« — gagne », faussait les tendances et occupait une place de rétention. Aucune partie ne peut s'archiver ainsi.
`GameResult` reste constructible sans équipe : les gardes de `history_screen` restent.

## 2026-11-05 — Retours de test Fiesta v4 : noms gardés, liste des ensembles, décompte, tutos à jour

**Quoi.** Les noms des joueurs restent quels que soient les allers-retours. Un ensemble tient sur une ligne,
icônes seules et badge « Perso ». Le décompte a un seul rythme. Les aides sont revues écran par écran, et
l'avant-tour Fiesta n'explique que ce qu'il affiche.

**Pourquoi ces choix.**

- Noms : une clé à part, `guessItAll_savedPlayerNames`, plutôt que garder `_players` à la nouvelle partie.
  Une nouvelle partie doit repartir de joueurs neufs (ids, mots, équipes, accueil sans « Rejouer »), et la
  session ne connaît pas les noms retirés par le réglage du nombre de joueurs. Liste de chaînes sans
  enveloppe : aucune forme existante ne change, `kCurrentSchemaVersion` reste. Clé absente : reprise des noms
  de la session au démarrage (règle 7).
- Seule une saisie retire un nom, y compris « Réinitialiser les paramètres ». Un joueur effacé laisse sa case
  vide jusqu'à la nouvelle partie : la remplir à nouveau annulerait le geste.
- `clearPlayersData` et `resetGame` n'ont plus aucun appelant : laissés tels quels, ils ne touchent pas la
  liste des noms.
- Décompte : `currentTurnIndex == 0` doublait le temps de chaque chiffre et du « GO ! » au premier tour de
  chaque manche. Un seul couple de durées, dans `AppConstants`. L'aide promettait « 3 secondes » : elle dit
  désormais « un court décompte ».
- Liste : la sélection se lit au cadre, sans cercle à cocher, faute de place à 360 px avec 4 icônes et le
  badge. Le nom d'un ensemble personnel y garde 8 à 10 caractères ; « Voir » le montre en entier.
- Liste sans `ListView` : paresseuse, elle ne montait pas « Créer un ensemble » sous une longue liste, et
  l'aide sautait cette étape.
- Avant-tour : les clés ne sont posées que sur ce qui est affiché, `CoachMarks` saute déjà les autres. Pas de
  condition dupliquée entre l'écran et l'aide. L'aide automatique de première partie reste sans étapes Fiesta
  (décision de Florent, `WIRING.md`).
- Règle générale des aides, écran par écran : élément affiché = une étape, élément absent = pas d'étape, et aucun
  texte n'en parle. L'étape « Passer » reste affichée quand le bouton est désactivé, avec la raison : l'ancienne
  absence de clé sous « Interdit de passer » laissait un bouton sans explication.
- `results_screen` et `history_screen` ne sont pas modifiés (autre lane). Écart connu : récap Fiesta et bouton
  retour des Résultats sans étape.
---

## 2026-11-05 — Plus de tour à 0 s après une fin de manche

**Quoi.** Une manche M1 ou M2 finie avec 0 s à reporter (dernier mot à l'écran quand le chrono tombe, puis
validé) ne donne plus de continuation : plus d'avant-tour « Temps bonus : 0s », plus de chrono à 0, plus de
point offert sur le mot affiché. L'équipe garde ses points, la manche suivante s'ouvre sur l'équipe suivante
avec le joueur suivant. Décision de Florent. Un report d'au moins 1 s reste une continuation.

**Pourquoi ces choix.**

- Le seuil est la seconde affichée (`timeRemaining <= 0`). Il reste 1 s tant qu'il reste 1 ms.
- C'est une vraie fin de tour : ×2, passes gratuites et malus reçus se terminent là (`_fiestaAfterTurn`). Une
  cartouche non jouée reste en réserve, un +10 s n'a donc plus de tour à 0 s où se jouer.
- `isContinuation` regarde maintenant si la manche a déjà une entrée, pas seulement l'équipe : sinon le
  prochain vrai tour de l'équipe qui a fini la manche passait pour une continuation, et son piège d'Interdit
  était ignoré.
- `continuingTeamId` est nul sans report : un malus en attente sur l'équipe suivante, impossible dans la
  nouvelle manche, est rendu à l'envoyeur comme pour toute autre équipe.
- Graphique : une manche ouverte par un tour normal a sa barre au point d'avant ce tour.

**Conséquence.** Une sauvegarde écrite par une version antérieure, déjà sur une fin de manche à 0 s, joue
encore ce tour une dernière fois : rien n'est perdu, et aucun code de reprise n'est gardé pour ce cas.

---

## 2026-11-05 — Liste des ensembles : maquette B2

**Quoi.** Chaque ensemble a une tuile et une icône, un nom sur 2 lignes et une ligne courte. La ligne sélectionnée
se déplie : explication, pastilles, actions en icônes. Les autres n'ont plus d'actions. « Prêts à jouer » disparaît,
le compteur passe dans « Créer un ensemble » ou dans l'alerte de limite. Maquette validée par Florent.

**Pourquoi ces choix.**

- Textes dans `ensemble_summary.dart` : à la main pour les fournis, générés pour les perso, sans stockage ni
  migration. Un test compare les pastilles écrites à la main aux règles que le moteur joue : un texte ne peut pas
  mentir sans le faire tomber.
- « Seul ce qui joue compte » va un peu plus loin que `settingsKey` : un `drawCount` sans rien à tirer (refusé par
  l'éditeur, mais lisible sur le disque) ne donne ni texte de tirage ni dé.
- Ligne courte bornée en longueur, puis « et plus » : le test mesure toutes les combinaisons à 360 px. Le dépliage
  dit le reste.
- Pas de couronne dans Material Icons : la coupe (`emoji_events_outlined`) pour Pro Player et les perso sans tirage
  ni cartouche.
- `gray300` ajouté à `AppColors` : la maquette validée l'utilise pour la ligne courte, les pastilles neutres et les
  actions, et `gray400` y était trop sombre.
- La liste commence sous les boutons du haut, le titre défile avec elle. Avant, liste défilée, le « ? » tombait sur
  le rond de sélection et le retour sur les tuiles.
- Défilement calculé d'un seul geste (`getOffsetToReveal`), pas deux `ensureVisible`. Plus haute que la liste, une
  ligne montre son haut d'abord.
- Pastille de cartouche sans pictogramme : « ×2 Mot compte double ×1 » se lisait mal. Les autres badges ne changent
  pas.
- Dépliage sans animation de taille : une ligne se replie au-dessus au même moment, le calcul du défilement
  devrait attendre la fin de deux animations pour rien.


## 2026-11-06 — Version 1.2.0+11 et envoi TestFlight

**Quoi.** `pubspec.yaml` passe à `1.2.0+11` et le workflow Codemagic `release` envoie l'IPA vers
TestFlight. Google Play reste coupé.

**Pourquoi.** Florent veut tester le mode Fiesta sur iPhone, et un IPA `app_store` ne s'installe que
par TestFlight. `+11` : le suivi du projet impose au moins ce numéro sur les deux stores.

**Conséquence.** Le tag `v1.2.0+11` lance le build. Rien ne part au public sans une action manuelle
dans App Store Connect. Si des corrections suivent, le prochain build prend `+12`.


## 2026-11-07 — Révélation des scores : prénoms à droite des têtes, plus de cartouches

**Quoi.** Le graphique de fin réserve une colonne à droite pour des étiquettes multi-lignes (prénoms de
l'équipe, ou noms d'équipes pour toutes si une équipe dépasse 5 joueurs). Bulles et sons de cartouche
retirés, avec `ScoreTimeline.events` et les effets de `RevealSound`. Légende réduite aux noms d'équipes.
Bouton de la carte de fin : « Suivant ».

**Pourquoi.** Retours de Florent : les noms touchaient les courbes et les bulles chargeaient le graphique.
Position lissée par moyenne sur une fenêtre de progrès plutôt que par un état par image : le painter
reste une fonction pure et rejoue pareil à toute valeur de `progress`. La fenêtre vaut une part fixe du
tracé (≈ 0,2 s), pas un nombre de tours comme dans la maquette : une longue partie aurait sinon perdu le
lissage. Elle se resserre en fin de tracé, car le contrôleur s'arrête à 1 alors que la maquette débordait
au-delà : les étiquettes doivent rejoindre leurs têtes, animations réduites comprises.

**Conséquence.** Quand deux courbes échangent leur place, leurs étiquettes se croisent ≈ 0,2 s, comme dans
la maquette validée : les séparer à chaque image les ferait sauter. `entryOfCharge` reste, pour les badges de
`stats_screen`.

## 2026-11-07 — Retours de Florent : règles Fiesta et retrait de « Deux mots à la fois »

**Quoi.** Spec : `_bmad-output/specs/fiesta/retours-2026-11-07.md`, décisions D1 à D5.

- Ensembles fournis : Fiesta classique = 5 cartouches par manche + équilibrage, sans tirage ; Explosif = 10 ; Les
  derniers = 5. `kMaxAllCount` = 10 borne la relecture et le compteur « À tous » ; les autres compteurs restent à 5.
- Cartouches au hasard : tirage avec remise, pondéré (`kGiftWeights` : 3, `double_points` 1).
- `free_pass.defaultCharges` = 1. `turnLabel` et nouveaux textes au catalogue. Le branchement de l'UI suit (lot 3).
- « Deux mots à la fois » sort du catalogue et du code de jeu : carte B, `TwoWordsLayout`, aide, tuto. `FiestaWordCard` et
  le mode `compact` de `TurnActionButtons` partent avec, ils n'avaient pas d'autre usage.

**Pourquoi.**

- `kMaxCount` bornait la relecture : à 10, `FiestaRules.tryFromJson` aurait refusé les règles d'Explosif, et la partie
  serait retombée en Classique. Pas de changement de `format` : la clé est la même, seule la borne s'élargit.
- `modifierById` répond encore pour `two_words` via une liste privée en lecture seule (règle 7) : l'historique doit
  afficher « Deux mots à la fois », et `tryFromJson` jetterait sinon les entrées de `earned`, `chargesUsed` et
  `active`. Rester hors de `kModifierCatalog` suffit à le sortir de la réserve, du vivier, de l'éditeur et du tirage.
- Partie en cours avec Deux mots : les clés `twoWords`, `secondWord`, `secondExpiredWord` sont simplement ignorées à
  la relecture. La carte B n'a jamais quitté `remainingWords`, elle revient donc seule, sans migration ni perte. Prix
  assumé, seulement pour un tour en cours pile à la mise à jour : la carte B expirée n'est pas proposée à la
  vérification, elle n'est pas comptée mais reste à faire deviner.
- `ReplacedChoices.bonuses` filtre les bonus retirés : `reuseReplacedChoices` aurait rallumé `two_words` dans la zone
  active de l'avant-tour, sans qu'aucune charge ne se dépense jamais.

**Conséquence.**

- Le retrait de `two_words` ne change pas le tirage des règles de manche d'une partie suspendue : il était réservé aux
  cartouches, donc absent des candidats mélangés. Le plan de cadeaux d'une transition suspendue, recalculé et jamais
  persisté avant `nextRound`, change une fois après la mise à jour (vivier et algorithme). Rien n'est doublé ni perdu.
- Une passe gratuite déjà en cours à la mise à jour ne donne plus que 1 passe : `freePassesUsed` à 2 reste relu sans
  erreur.
- `resolveTurn(expiredWords:)` garde sa forme de liste, avec au plus un mot : pas de réécriture du scoring sans gain.
- Réserve d'Explosif en manche 3 : 14 sortes de cartouches tiennent sans défiler à 360 × 640 (test). 15 sortes (moins
  de 1 % des parties, simulation) et 16 (quasi jamais) font défiler la zone.

## 2026-11-07 — Écran de tour et icônes des modificateurs (retours Florent, lot 3)

**Quoi.** `modifierIcon()` collé dans du texte laisse place à un composant unique `ModifierIcon(id, size)` : images
`assets/icons/modifiers/`, émojis `🌍`, `🤐`, `💪` et `👀` (les deux derniers barrés par `slash.png`). Écran de tour :
pastilles icône + `turnLabel`, compteur de passes gratuites et ligne « Bob ne répond pas » retirés (avec leurs étapes
d'aide), bouton Passer grisé réduit à son libellé, bulle au toucher. Puce d'envoi : un toucher annule, sans fenêtre.

**Pourquoi.**

- Un composant plutôt qu'une String : un émoji collé dans du Poppins hérite des métriques de la ligne, d'où le « mal
  centré dans le rond ». Le calage commun (`height: 1`, strut forcée, pas de police héritée) vaut pour toutes les tailles.
- Cercles allumés et reçus de l'avant-tour : fond teinté, plus plein. Les images ne se recolorent pas, et le chrono vert
  de `plus_10s` ou rouge de `minus_10s` disparaîtrait sur sa propre couleur.
- La raison de la bulle se déduit de `PassState` dans `turn_screen.dart`, la même que pour l'aide : le provider ne bouge
  pas, et la bulle ne peut ni agir sur le chrono ni contredire l'aide.
- `AnimationController` plutôt que `Timer` pour la bulle : pas de minuterie à annuler, et les rebuilds du chrono ne la
  relancent pas.

**Conséquence.** `kModifierIcons` reste entier tant que `score_reveal_chart.dart` dessine ses bulles ; il se réduit à
`two_words` une fois le lot `retours-reveal` mergé. Centrage des émojis à vérifier sur iPhone et Android : ni Apple Color
Emoji ni Noto ne tournent dans les tests.

Revue : la rangée des boutons est à 114 px fixes et Passer rétrécit (`FittedBox`), au lieu d'une hauteur intrinsèque
qui étirait la rangée vers 170 % de taille de texte, et l'émoji ignore la taille de texte système, sinon il sort de sa
boîte et de sa barre.

## 2026-11-07 — Retours de Florent : parcours Paramètres et ensembles, autoscroll Joueurs

**Quoi.** Spec : `_bmad-output/specs/fiesta/retours-2026-11-07.md`, décision D8. « Suivant » des Paramètres va
toujours aux joueurs ; la liste des ensembles s'ouvre depuis Avancés (« Changer ») et son bouton « Valider » ramène
aux Paramètres. Passer en Fiesta pose le dernier ensemble, sinon Fiesta classique. Réinitialiser oublie `lastUsedId`.
Ligne « Ensemble : <nom> » hors Fiesta classique. Clavier ouvert sur Joueurs, le champ actif remonte au-dessus.

**Pourquoi ces choix.**

- `chooseFiestaMode` pose Fiesta classique tout de suite, puis le dernier ensemble relu : l'interrupteur reste
  synchrone, et le mode n'attend jamais sans règles, ce qui était un risque nouveau une fois l'écran des ensembles
  devenu facultatif. Un choix fait pendant la relecture l'emporte : un compteur de `setPendingFiesta`, car valider
  Fiesta classique repose le même objet, et `identical` pour les écritures directes de `_pendingFiesta`.
- Une partie rejouée passait par la liste, qui remplaçait des règles gelées sans ensemble correspondant. Elle n'y passe
  plus : les règles gelées sont maintenant jouées telles quelles. La ligne Ensemble ne compare que le nom (D8) : d'anciennes
  règles nommées « Fiesta classique » n'affichent pas de ligne (arbitrage du lot, revue r1).
- Retour de la liste sans valider : l'attente relit le dernier utilisé (`refreshPendingEnsemble`). Sans ça, un ensemble
  modifié ou supprimé dans la liste serait joué dans son ancienne version. Hors règles gelées, l'attente est toujours
  le dernier utilisé, donc pas de comparaison à faire.
- Autoscroll : la liste s'arrête au clavier et le bouton « Suivant » s'efface (il était déjà caché dessous), comme le
  ferait un Scaffold. `EditableText` garde alors seul le champ visible, à la prise de focus et à l'ouverture du
  clavier : aucun calcul de défilement à nous. `AppInput` et `Scrollable.ensureVisible` restent intacts.
  `cacheExtent` garde toutes les lignes construites (20 au plus) : sinon « suivant » ne donnerait pas le focus à une
  ligne éloignée de la zone visible.

**Conséquence.** Aucune forme persistée ne change : `lastUsedId` était déjà facultatif, il disparaît simplement du blob.
Paramètres, mesuré avec les vraies polices (Poppins, Bangers) dans un test temporaire : 732 px au plus (ligne Ensemble
et avertissement « partie longue »), soit 8 px de marge sur 360 × 740 et 31 px sur 390 × 763.

## 2026-11-09 — Cartouches au hasard : tirage sans remise dans la manche

**Quoi.** `roundGifts` (`lib/models/fiesta/cartridge_gifts.dart`) tire les cartouches d'une équipe SANS remise
au sein d'une manche : une équipe ne reçoit plus deux fois la même cartouche lors d'une même distribution. Chaque
manche repart du vivier complet. Les poids (`kGiftWeights`, le ×2 trois fois plus rare) et la graine
`(gameId, manche, équipe)` ne changent pas. Le prix du défi surprise (un seul tirage) n'est pas concerné.

**Pourquoi.** Retour de Florent du 2026-11-07 au soir : recevoir deux fois la même cartouche dans la même manche
appauvrissait le choix. Si une équipe doit recevoir plus de cartouches que le vivier n'en compte (petit vivier en
M3), le vivier est remis en entier : les doublons n'apparaissent que dans ce cas, et le nombre de cartouches reçues
ne change jamais.

**Conséquence.** Aucune forme persistée ne change : les cartouches gagnées sont écrites dans `fiesta.earned`.
Seul effet d'une mise à jour pendant une partie : un passage de manche rejoué après la mise à jour (retour arrière,
correction) tire avec le nouvel algorithme et peut donner d'autres cartouches. C'est rare et sans crash.

## 2026-11-09 — Retours de Florent du 2026-11-07 au soir : malus grisés à l'avance, messages et feuilles

**Quoi.**
- Un malus est grisé dans la réserve dès qu'aucune équipe adverse ne peut le recevoir : trop petite pour « Bloquer un
  devineur » (déjà le cas), ou déjà visée par ce malus ou par un malus qui ne s'y cumule pas (nouveau). Dans « Contre
  quelle équipe ? » et dans la fenêtre des blocages, l'équipe qui le refuserait est grisée, inactive, avec sa raison.
  `GameProvider.targetRefusal` porte la règle ; `inflictMalus` garde son refus détaillé (même helper `_clashOn`).
- Le message d'erreur en bas de l'avant-tour reste 3 s au lieu de 5, et glisser vers le bas le ferme.
- Les 4 feuilles du bas (explication d'une cartouche ou d'un badge, choix d'équipe, blocages) n'ont plus de liseré
  qu'en haut (`SheetTopBorder`).
- Mode aléatoire : le badge « N mots prêts » disparaît de l'écran Joueurs, avec son étape d'aide.
- Formation des équipes : un nom d'équipe long passe sur 2 lignes (18 caractères au plus, inchangé).

**Pourquoi.** Le refus arrivait après le choix d'équipe, avec un long message qu'on ne pouvait pas fermer : griser à
l'avance évite l'essai pour rien. Le refus de `inflictMalus` reste comme garde-fou, il n'est plus atteint depuis l'UI
à 2 équipes.

**Conséquence.** Aucune forme persistée ne change. Recette device (Android + iOS) : grisé et raison, glissement du
message, liseré des feuilles, noms d'équipes sur 2 lignes avec 3 et 4 équipes.

## 2026-11-10 — Version 1.4.0+13

**Quoi.** `pubspec.yaml` passe à `1.4.0+13`. Le tag `v1.4.0+13` lance le workflow Codemagic `release`.
La version embarque les PR #58 (malus grisés d'avance, message d'erreur plus court et fermable, liseré des feuilles du
bas, plus de badge « mots prêts » en Aléatoire, noms d'équipes sur 2 lignes) et #59 (cartouches au hasard sans remise
dans la manche).

**Pourquoi.** Florent veut tester ces retours sur device. 1.4.0 : un lot de fonctionnalités = une version mineure,
comme pour 1.2.0 puis 1.3.0. `+13` : le build number doit strictement augmenter après `+12`.

**Conséquence.** Rien ne part au public sans une action manuelle dans les stores.
