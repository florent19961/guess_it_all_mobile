---
name: guessitall-workflow
description: Use when taking a Guess It All user story (or a batch already planned into lanes) from spec through implementation to review and merge; when running a challenge/review gate on a spec or on an implementation diff; when executing work in an isolated git worktree; when deciding how much process a change warrants; or when cutting a store release. Framing, planning a batch of existing stories into lanes (interest per US + prompt-pack), running several lanes, delegated mode and the end-of-epic gate ③ → guessitall-orchestration. To CREATE a brand-new epic's stories → bmad-create-epics-and-stories. Keywords US, story, gate, challenge loop, adversarial reviewer, minimal tests, worktree, pipeline, dev-story, create-story, sprint, retro, release, tag, store.
---

# Guess It All — pipeline projet (par-dessus BMad)

`create-story → dev-story` est le **milieu** de BMad. On l'encadre par un amont (par epic), **un
gate de challenge sur l'implémentation** (gate ②) et un aval (capitalisation), et **on dose selon
le risque**. Les règles projet (`CLAUDE.md`) surchargent ce qui suit en cas de conflit.

## Doser rigueur ↔ risque (anti-cérémonie)

Le dosage décide *si* on lance le pipeline et son gate — **pas** la *forme* du gate quand il
tourne. Trivial (copie, ajout de mots, fix mécanique, 1 fichier) → direct (`bmad-quick-dev` si tu
veux le cadre allégé), zéro gate. Risqué → pipeline complet.

🔴 **Le « tier risqué » de CE projet** (recalibré — il n'y a ici ni money/Stripe, ni RGPD, ni
fidélité PDF) :

1. **Machine à états de la partie** — enchaînement manches/tours/équipes, pool de mots, conditions
   de fin. C'est le cœur : un état incohérent ruine une soirée entière et n'est pas rattrapable.
2. **Scoring** — points par manche/équipe, pénalités de passe, égalités.
3. **Persistance `SharedPreferences`** — tout changement de FORME d'une clé stockée
   (`guessItAll_*`) : une partie en cours ou un historique écrits par la version en store doivent
   rester lisibles, ou être migrés explicitement. ⚠️ **Ici la rétro-compat est RÉELLE** (contrairement
   à un projet pré-prod) : l'app est publiée, les données des joueurs sont sur leurs téléphones.
4. **Sync Firestore / offline-first** — queue `pending_sync`, reprise après coupure, idempotence
   d'upload (ne pas dupliquer une partie).
5. **Intégrité analytics** — les events alimentent les décisions produit (dont la priorisation des
   mots) ; un compteur faux est silencieux et durable.
6. **Timer / cycle de vie** — app backgroundée en plein tour, verrouillage d'écran, appel entrant.

Hors de ces six : UI, thème, écrans, catégories de mots, copy → dosage léger.

**Simplifier bat sur-corriger.** Quand deux+ boucles de revue enfantent à répétition des blockers
autour du **même** mécanisme, il est sur-dimensionné : **retirer/simplifier** la racine bat
empiler des correctifs. Convergence saine = profil des findings qui décroît passe après passe
(structurel → dérivé → périphérique). Dérive = nouveaux trous *structurels* à chaque passe.

## Amont — créer un epic NEUF (1× par EPIC)

**Cadrage AVANT d'écrire quoi que ce soit :** design réellement ouvert → `superpowers:brainstorming`
(divergent) ; puis **grilling SYSTÉMATIQUE avant tout epic (ou US isolée)** — interview
convergente, toutes les questions en un message numéroté (une ligne + une recommandation
chacune), jusqu'à résolution de chaque branche de l'arbre de décision.
C'est le pare-feu contre les epics sous-spécifiés — et la raison pour laquelle le gate ① est sauté
(cf. §Par story 3).

⚠️ **Quelle skill invoquer** : `grilling` (model-invocable). `grill-me` porte
`disable-model-invocation: true` — c'est le raccourci **utilisateur** `/grill-me`, qui délègue à
`grilling`. Un agent qui appelle `grill-me` ne déclenche rien.

Pour qu'un epic *neuf* dérive d'un tout cohérent, enchaîne ensuite : `bmad-prd` (léger, le
QUOI/POURQUOI) → `bmad-create-architecture` (décisions transverses : forme des états, schéma
persisté, impact analytics) → `bmad-create-epics-and-stories` (découpe). `bmad-correct-course` dès
que le scope bouge en cours de sprint.

⚠️ **Ne PAS confondre** avec planifier l'exécution d'US **déjà existantes** (backlog) → ça, c'est
`guessitall-orchestration` §2.

## La boucle de challenge (gate ②) — forme ALLÉGÉE

Composition actée pour ce projet (Florent, 2026-11-03) : **UN reviewer adversarial spec-aveugle**,
rien d'autre — **pas de Codex, pas de second reviewer Opus en substitut** : les changements sont
simples. On ne la re-négocie pas story par story. La session principale le lance
(`guessitall-orchestration` §3), ou la lane elle-même quand elle travaille seule.

1. **Adversarial spec-AVEUGLE** — 1 agent `general-purpose` + rubrique inline (⚠️ **jamais** en
   `subagent_type` : les `bmad-*` sont des skills, pas des types d'agent). Correctness sur TOUS les
   chemins de mutation d'état + bornes/edge-cases + **mutation testing OBLIGATOIRE** (muter le
   code, vérifier qu'un test tombe). Il ne reçoit **PAS** la spec/ACs — son aveuglement est sa
   valeur.
   - 🔴 **Caveat mutation** : une preuve par mutation valide la propriété qu'elle **mesure**, pas
     celle qui manque. Avant de conclure « prouvé », **énoncer quelles propriétés l'invariant
     porte** et vérifier qu'il n'y en a qu'une ; s'il y en a deux (p. ex. *identité* d'une partie
     ET *fraîcheur* de son état), demander laquelle le test échantillonne.
   - 🔴 **Le test qui NOMME une garantie qu'il n'exerce pas.** Deux formes : (i) le test **énumère
     les cas** au lieu d'asserter la propriété ; (ii) le test **mocke le chemin heureux pour
     prouver un chemin d'erreur**. Règle mécanique : un test « aucun X » doit **dériver** le
     prédicat, jamais lister les variantes ; et toujours le pendant — le cas d'erreur ET le cas
     nominal, sinon on ne distingue pas « discriminé » de « garde neutralisée ».
   - **Valeur des tests** : un test redondant, cosmétique ou d'échafaudage est un finding (règle
     des tests minimaux, §Par story 4).
2. **Tri** — l'implémenteur **re-trace la donnée** de chaque finding : réel / faux-positif /
   résidu assumé. Une sévérité est un claim à tracer, pas un vote. **Un rejet s'ÉCRIT** (sinon un
   finding disparaît en silence).
3. **Corriger** les blockers retenus → **re-run 1→2** sur l'artefact révisé. **Répéter jusqu'à
   `ready`.** Même mécanisme au 3ᵉ round = non-convergence → l'orchestrateur arbitre
   (`guessitall-orchestration` §5).

⚠️ **Escalade** (la seule autorisée) : une sévérité bloquante contestée sur une prémisse →
1 agent adversarial de plus, en re-trace **ciblé sur ce seul finding**. Pas de `bmad-party-mode`
pour de la consolidation de routine (réservé aux carrefours design).

## Par story

1. **Worktree dédié AVANT de toucher au code** — branche + worktree depuis **`origin/main`** :
   ```bash
   cd /home/florent19961/guess_it_all_mobile
   git worktree add /home/florent19961/guess-it-all-<slug> -b feat/<slug> origin/main
   cd /home/florent19961/guess-it-all-<slug> && flutter pub get
   ```
   🔴 **JAMAIS `git checkout <branche>` / `git switch` dans le checkout partagé**
   `/home/florent19961/guess_it_all_mobile` — ça switche la branche de TOUTES les sessions, et le
   commit d'une autre session atterrit alors sur la MAUVAISE branche. Worktree = 1 branche isolée
   par session = zéro collision.
   ⚠️ **Gotcha worktree neuf** : `flutter pub get` est obligatoire (`.dart_tool/` n'est pas
   partagé) — sans lui la baseline de test est faussement rouge.
2. `bmad-create-story` — ancrer sur le code réel, ne pas supposer.
3. 🔴 **Gate ① (revue de spec) — SAUTÉ PAR DÉFAUT.** Ne PAS le proposer, ne PAS demander
   confirmation. **Le pare-feu amont est le `grill-me`**, systématique avant tout epic. Ne le
   relancer que sur demande explicite de Florent, ou si l'implémentation bute sur une spec
   réellement indécidable (le vrai signal : deux lectures mènent à du code différent, et aucune
   n'est déductible du reste du dépôt).
   - ⚠️ **Ce que ça déplace** : les problèmes de spec surgissent en rework d'implémentation au lieu
     d'être attrapés à froid. Acceptable **parce que le gate ② tourne, lui, en entier**. Si tu te
     surprends à sauter AUSSI le gate ②, ce n'est plus du dosage.
4. `bmad-dev-story`, avec **le moins de tests possible** (décision Florent 2026-11-03) : un test
   seulement s'il épingle un invariant du tier risqué (états, scoring, schéma persisté/migration,
   sync, analytics, timer/cycle de vie) ou s'il reproduit un bug corrigé — test écrit avant le
   code dans ces deux cas. Pas de test exhaustif ou cosmétique, pas de widget test pour de l'UI
   simple. En dev, tests ciblés via `scripts/with-test-slot.sh` ; suite complète une fois avant la
   PR. La PR dit combien de tests sont ajoutés/retirés et pourquoi.
5. **Gate ② — challenger l'implémentation** (boucle ci-dessus) jusqu'à `ready`. **Re-lancer aussi
   sur le diff de PR**, pas seulement sur la branche.
6. **`teach-back` AVANT le closeout** (skip auto si trivial, skip sur demande) : Florent doit
   pouvoir reformuler le changement ; un désalignement produit détecté pendant les questions
   **suspend le closeout**. Puis PR depuis le worktree, **base `main`**.
   🔴 **Merge uniquement sur go explicite de Florent** : tout préparer jusqu'à `gh pr create`
   inclus, puis STOP. Sur go → `guessitall-pr-closeout` → US à `done` dans `sprint-status.yaml` →
   `git worktree remove` → alimenter le retro d'epic.

## Tests & plancher déterministe

```bash
scripts/with-test-slot.sh flutter test          # sémaphore RAM — voir ci-dessous
flutter analyze                                 # 0 error exigé
dart format --set-exit-if-changed lib test      # formatage
scripts/run-full-suite.sh                       # gate avant PR : format + analyze + test
```

🔴 **Tout run de tests passe par `scripts/with-test-slot.sh`** (sémaphore machine-global, 3
places, partagé avec les autres projets et worktrees). La machine est contrainte par la **RAM**
(~7 Go sous WSL2), pas par le CPU : deux sessions qui compilent/testent en même temps peuvent
faire tomber la machine par OOM. Le sémaphore borne leur NOMBRE.

**Baseline verte depuis la PR #2** (2026-11-03 : 123 tests, `format` + `analyze` OK — l'ancien
scaffold `test/widget_test.dart` et le `catchError` sans `return` de `firebase_sync_service.dart`
sont réglés). Un rouge sur `origin/main` est une vraie régression : le vérifier là avant d'accuser
ton diff. `run-full-suite.sh` gate sur `error` + `warning` ; les `info` restants sont une dette
assumée (`docs/notes_pour_plus_tard.md`, 2026-08-02). Le dossier gitignoré
`lib/utils/word_categories/backup/` reste exclu via `analysis_options.yaml`.

## Ce qu'on peut lancer depuis WSL (et ce qu'on ne peut pas)

`flutter doctor` : **pas d'Android SDK, pas de Chrome, pas de toolchain Linux desktop**. Donc
depuis ce checkout WSL :

- ✅ écrire du code, `flutter analyze`, `flutter test` (VM Dart pure), tout le pipeline de revue.
- ❌ `flutter run`, `flutter build apk/appbundle/ipa` — **aucun device buildable** (le seul device
  listé est « Linux (desktop) », dont la toolchain manque aussi).

Conséquence pour le gate : la vérification se fait par **tests + analyze**, jamais par une recette
manuelle sur device depuis WSL. Toute story dont l'acceptation exige de VOIR l'app tourner doit
être testée depuis l'environnement Windows — et le dire explicitement dans la story.

## Release store (étape SÉPARÉE — jamais dans un closeout)

Il n'y a pas de branche « prod » : ce qui est publié est un **build soumis**, matérialisé par un
tag sur `main`.

1. `main` vert (full suite) et toutes les US du lot à `done`.
2. Bump `pubspec.yaml` → `version: X.Y.Z+N` (**le build number `+N` doit STRICTEMENT augmenter** —
   les stores refusent un build déjà soumis).
3. Commit `chore(release): vX.Y.Z+N`, tag `git tag -a vX.Y.Z+N -m "..."`, `git push --follow-tags`.
4. Le push du tag lance le workflow Codemagic **`release`** (`codemagic.yaml`) : garde tag =
   version pubspec, puis AAB + IPA signés en artefacts. 🔴 **Publication désactivée** jusqu'à la
   1re release post-Fiesta (go Florent) — d'ici là, soumission manuelle des artefacts. Secrets,
   `dry-run` et activation : `docs/releases-stores.md` §Codemagic.
5. Entrée datée dans `docs/tracking_evolution.md`.

⚠️ **`upgrader` force la mise à jour** des clients depuis les stores : une version publiée devient
la version que TOUT LE MONDE aura. Un bug de persistance embarqué dans une release est donc
irrattrapable côté données déjà écrites → le tier 3 (persistance) se traite comme du money sur un
projet e-commerce.

## Aval

- **`sprint-status.yaml`** (`_bmad-output/implementation-artifacts/`) maintenu = colonne
  vertébrale US→epic→gate ; `bmad-sprint-status` surface les risques.
- **Gate ③ — revue cross-story** : conditions et forme dans `guessitall-orchestration` §7 (un
  reviewer sur le diff cumulé, seulement si ≥ 2 stories sérialisées sur un point de collision ou
  le tier risqué).
- **`/simplify`** — phase de POLISH appliquée **APRÈS le dernier gate qui s'applique**, sur du code
  déjà correct (pas une cible mouvante). Dosage : M+/structurel, **skip sur diff trivial**.
  - ⚠️ `/simplify` **modifie le code** et est **quality-only (ne chasse PAS les bugs)** → son diff
    est une affirmation NON PROUVÉE. Le faire suivre de : **(1)** une vérif par le reviewer
    adversarial du gate ② sur le diff `/simplify` SEUL — *behavior-preserving ? une garde retirée « au nom de la
    simplicité » ?* — **sauf** si le delta ne touche que des commentaires/docs (0 ligne exécutée) ;
    **(2)** re-run `scripts/run-full-suite.sh` (toujours dû).
  - 🔴 **Un finding `/simplify` peut avoir un raisonnement JUSTE et une conclusion FAUSSE** :
    « cette garde est inatteignable, retire-la » — inatteignable *tant que* tous les appelants
    propagent la condition ; un futur appelant qui l'oublie rouvre le trou **en silence**.
- **`bmad-retrospective`** après chaque epic → réinjecter les leçons dans `CLAUDE.md`,
  `_bmad-output/project-context.md` et les skills projet.

## Agents-rôles & débat multi-agents

- Rôles **solo** : `bmad-agent-ux-designer` (Sally) = écrans/flow/copy ; `bmad-agent-architect`
  (Winston) = décisions transverses (forme des états, schéma persisté, perf) ;
  `bmad-agent-pm` (John) = découpe epic / priorisation ; `bmad-agent-analyst` (Mary) = requirements
  flous.
- `bmad-party-mode` = vrais subagents indépendants. Usages : **carrefours design** (éclater un
  epic, trade-off de règles de jeu) et **escalade** de gate quand les verdicts s'opposent. **PAS**
  pour exécuter du code ni pour la consolidation de routine.

## Parallélisme (plusieurs blocs en vol)

**Décider QUELLES US paralléliser (graphe de conflits → lanes) = `guessitall-orchestration` §2,
pas ici.** Cette section ne porte que l'*exécution* d'une lane décidée. Chaque session dans son
worktree dédié (§Par story 1) ; **choix de modèle par lane** : Fable pour les lanes
complexes/risquées (machine à états, persistance, sync), Opus pour le standard. Un seul track à la
fois sur `game_provider.dart` et sur le schéma `SharedPreferences` — ce sont les deux points de
collision structurels du dépôt.
