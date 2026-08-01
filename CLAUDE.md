# CLAUDE.md — Guess It All

Jeu mobile multijoueur de devinettes de mots en équipe (inspiré de « Time's Up »). Flutter,
publié sur l'App Store et le Play Store. Les joueurs forment des équipes et font deviner des mots
sur 3 manches aux règles différentes.

## ⚠️ Working directory

```bash
cd /home/florent19961/guess_it_all_mobile
flutter pub get      # une fois — et OBLIGATOIRE dans chaque worktree neuf
```

SDK Flutter = `~/development/flutter` (Linux natif, **3.44.8 / Dart 3.12.2**). Un `flutter` Windows
traîne aussi dans le `PATH` (`/mnt/c/Users/flore/flutter`, **3.38.3**) : **ne pas l'utiliser depuis
WSL** — deux SDK de versions différentes réécrivent `pubspec.lock` à tour de rôle.

⚠️ **Depuis WSL on code et on teste, on ne BUILD pas.** `flutter doctor` : pas d'Android SDK, pas
de Chrome, pas de toolchain Linux desktop. Donc `flutter analyze` et `flutter test` ✅ ;
`flutter run` / `flutter build apk|appbundle|ipa` ❌. Les builds et les recettes sur device se font
depuis Windows. Une story dont l'acceptation exige de voir l'app tourner doit le dire.

## Branches — `main` = tronc, release = **tag**, pas branche

- **Toute PR de story/feature/fix → base `main`** (squash-merge).
- Il n'y a **pas de branche de prod** : ce qui est publié est un **build soumis au store**,
  matérialisé par un tag `vX.Y.Z+N` posé sur `main`. Un closeout ne bump **jamais**
  `pubspec.yaml` et ne pousse **jamais** de tag.
- Runbook de release → skill **`guessitall-workflow` §Release** + `docs/releases-stores.md`.

## Posture de travail

**Socle générique → `~/.claude/CLAUDE.md`** (toujours chargé, tous projets) :
Réfléchir avant de coder · Simplicité d'abord · Changements chirurgicaux ·
Exécution dirigée par l'objectif.

Prolongements **process/revue** propres à ce projet (skill `guessitall-workflow`) : « doser
rigueur ↔ risque » (ne pas sur-cérémonialiser) et « simplifier bat sur-corriger » (retirer la
racine plutôt qu'empiler des fixes en revue).

## Skills — cycle de vie d'une évolution

**La méthodologie vit dans les skills, pas ici.** La liste exhaustive est injectée par le harness à
chaque session ; les règles projet ci-dessous surchargent les skills en cas de conflit.

1. **Idée / design ouvert** → `superpowers:brainstorming` (divergent — jamais pour une pile de fixes).
2. **Cadrage — SYSTÉMATIQUE avant d'écrire un epic (ou une US isolée)** → `grilling` : interview
   convergente, question par question, jusqu'à résolution de chaque branche de décision.
   ⚠️ La skill **model-invocable** est `grilling`. `grill-me` porte
   `disable-model-invocation: true` : c'est le raccourci **utilisateur** (`/grill-me`), qui délègue
   à `grilling` — un agent qui tente d'invoquer `grill-me` ne déclenche rien.
3. **Écrire l'epic + ses US** → `bmad-create-epics-and-stories`.
4. **Planifier l'exécution du lot** → `guessitall-epic-intake` : intérêt/US, graphe de conflits →
   lanes, dosage, prompt-pack.
5. **Implémenter chaque lane** → un worktree par lane, en suivant **`guessitall-workflow`** : TDD,
   puis **gate ②** (1 reviewer adversarial spec-aveugle + Codex cross-LLM + consolidation).
   **Pas de gate ①** — cf. garde-fous.
6. **Teach-back puis closeout** → `teach-back` (gate de compréhension avant merge — skip auto si
   trivial) puis `guessitall-pr-closeout` (PR base `main`) — **merge uniquement sur go explicite de
   Florent**.

Hors cycle : bug / test rouge / comportement inattendu → `bmad-investigate` ; artefact externe
(RFC/plan d'un autre LLM) à distiller → `bmad-spec`.

**Garde-fous** (mécanique complète dans `guessitall-workflow`) :

- **Dosage** : trivial (ajout de mots, copy, 1 écran) → direct, zéro cérémonie. **Tier risqué** →
  pipeline complet : ① machine à états de la partie, ② scoring, ③ schéma `SharedPreferences`,
  ④ sync Firestore/offline, ⑤ intégrité analytics, ⑥ timer & cycle de vie. Le dosage décide *si* un
  gate tourne, **jamais** sa forme quand il tourne.
- 🔴 **Gate ① (revue de spec) SAUTÉ par défaut** — ne pas le proposer, ne pas demander
  confirmation. Le pare-feu amont est le **`grill-me` systématique** avant tout epic. Contrepartie :
  le gate ② tourne **en entier**.
- ⚠️ `bmad-*` = skills (Skill tool), **pas** des `subagent_type`. Les reviewers de gate se spawnent
  en `general-purpose` + rubrique inline.

## Règles projet

1. **Lire avant de modifier** — jamais de modification à l'aveugle.
2. **Tests — ciblé en dev, complet au gate.** En dev : `scripts/with-test-slot.sh flutter test test/<fichier>`.
   **Suite complète une seule fois avant la PR** : `scripts/run-full-suite.sh` (format + analyze +
   test). 🔴 **Tout run de tests passe par `scripts/with-test-slot.sh`** — la machine est contrainte
   par la **RAM** (~7 Go sous WSL2), pas par le CPU, et le sémaphore est **partagé avec WasReal** :
   sans lui, deux projets qui testent en même temps font tomber la machine par OOM.
   ⚠️ **Baseline actuellement ROUGE** : `test/widget_test.dart` est le scaffold Flutter jamais
   adapté → aucun test ne tourne sur ce dépôt. Détail + coût réel : `docs/notes_pour_plus_tard.md`.
3. **Pas de fichiers .md** sauf si demandé explicitement. Emplacements autorisés : specs BMad dans
   `_bmad-output/specs/`, reviews dans `_bmad-output/reviews/`, docs projet dans `docs/`.
4. **Maintenir les CLAUDE.md à jour** — après ajout/suppression d'écran, service, modèle ou
   dépendance, mettre à jour le `CLAUDE.md` du module concerné (`lib/*/CLAUDE.md`) ET ce fichier si
   un invariant bouge. Les CLAUDE.md sont des fichiers d'**invariants + pointeurs** : le détail vit
   dans `docs/`, pas ici.
5. **Maintenir `docs/tracking_evolution.md`** — après chaque décision technique significative, une
   entrée datée : ce qui change et **pourquoi ce choix**.
6. **Maintenir `docs/notes_pour_plus_tard.md`** — quand une décision est délibérément reportée :
   contexte, décision, raison, **signal déclencheur**, esquisse.
7. 🔴 **Rétro-compatibilité des données joueur — RÈGLE DURE.** L'app est **publiée** et `upgrader`
   **force** la mise à jour : les données écrites par la version en store sont sur les téléphones
   des joueurs, et une release atteint tout le parc. Tout changement de **forme** d'une clé
   `guessItAll_*` (`SharedPreferences`) exige une **migration explicite** — jamais un « ça repartira
   de zéro ». Une partie en cours au moment d'une mise à jour doit rester lisible ou être invalidée
   proprement, pas crasher.
8. **Parité Android ↔ iOS** — toute évolution qui sort du déjà-implémenté se vérifie sur **les deux
   plateformes**. Points d'attention : `dart:io` `Platform.*` (utiliser `defaultTargetPlatform`),
   permissions, popup `upgrader` (Cupertino vs Material), safe areas. Si une plateforme est
   **délibérément** exclue, le dire explicitement dans la story/PR — jamais de divergence en
   silence.

## Stack & architecture

- **Framework** : Flutter (Dart) · **State** : Provider (`GameProvider`, unique) ·
  **Stockage local** : `shared_preferences` · **Cloud** : Firebase Firestore (sync analytics,
  offline-first) · **Polices** : Bangers, Poppins.
- **Architecture** : `Provider → Screens → Widgets`, services **singletons** →
  `SharedPreferences`/Firebase, modèles **immuables** avec `copyWith()`, persistance automatique
  après chaque modification d'état.
- **Arborescence détaillée + rôle de chaque fichier** → les `CLAUDE.md` par module :
  `lib/CLAUDE.md`, `lib/models/`, `lib/providers/`, `lib/screens/`, `lib/services/`,
  `lib/widgets/`, `lib/theme/`, `lib/utils/`.

🔴 **Points de collision structurels** (un seul track à la fois dessus, cf.
`guessitall-epic-intake`) : `lib/providers/game_provider.dart`, `lib/models/game_state.dart`,
`lib/services/storage_service.dart` + les clés `guessItAll_*`.

## Flux de jeu

1. **Configuration** — nombre d'équipes, joueurs, nombre total de mots (20-100, défaut 40), durée
   du tour, pénalité de passe.
2. **Inscription joueurs** — saisie des noms.
3. **Formation des équipes** — manuelle ou aléatoire (composition mise en cache et persistée ; si
   le nombre de joueurs change, les nouveaux sont ajoutés aléatoirement).
4. **Saisie des mots** — répartition dynamique selon `totalWords` ; les premiers joueurs ont 1 mot
   de plus si la division n'est pas entière (ex. 40 mots / 6 joueurs = 7+7+7+7+6+6).
5. **Partie** — 3 manches, tous les mots remis dans le pool à chaque manche.
6. **Résultats** — scores par équipe et par manche.

> Un seul mode existe aujourd'hui (**mode libre**). Le **mode Fiesta** (modificateurs de jeu) est
> en cadrage — cf. `_bmad-output/implementation-artifacts/sprint-status.yaml`.

## Conventions de code

- Langue du **code** : anglais. Langue des **messages UI** : français.
- Provider pour l'état global ; modèles immuables + `copyWith()`.
- Persistance automatique après chaque modification d'état.

## Docs de référence

| Document | Contenu |
|----------|---------|
| `docs/ANALYTICS.md` | Système analytics : modèles, events, services, flux de tracking, exemples |
| `FIREBASE.md` | Setup Firebase/Firestore de bout en bout (FlutterFire, règles, Android/iOS) |
| `docs/word-categories.md` | Les 13 catégories, leur contenu, et la priorisation des mots jamais vus |
| `docs/releases-stores.md` | Identifiants stores, `upgrader`, modèle de release par tag |
| `docs/tracking_evolution.md` | Journal des évolutions techniques et raisons des choix |
| `docs/notes_pour_plus_tard.md` | Journal des dettes techniques **assumées** |
| `docs/SUPPORT.md` | Page support publiée |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` | Colonne vertébrale US → epic → gate |
| `docs/agent-memory/` | **Backup mirror** de l'auto-memory Claude Code (canonical = `~/.claude/`) — sync via `scripts/sync-agent-memory.sh` (`--restore` pour repeupler) |

## Outillage agent

`AGENTS.md` (lu par Codex) est un **symlink vers ce fichier** ; `.codex/skills/` est un mirror en
symlinks de `.claude/skills/` — il n'y a donc **rien à re-synchroniser à la main**.

```bash
scripts/run-full-suite.sh          # plancher déterministe (format + analyze + test)
scripts/with-test-slot.sh <cmd>    # sémaphore RAM machine-global (obligatoire)
scripts/sync-agent-memory.sh       # backup de l'auto-memory vers docs/agent-memory/
```
