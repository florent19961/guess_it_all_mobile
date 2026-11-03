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
