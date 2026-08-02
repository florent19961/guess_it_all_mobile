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
