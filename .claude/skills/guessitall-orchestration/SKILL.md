---
name: guessitall-orchestration
description: Use when the MAIN Guess It All session frames, plans or drives work — grilling before any story, planning a batch of existing stories (interest per story, conflict graph, lanes, dosage, prompt-pack), running up to 5 lanes, launching the tier review, the 15-minute light probe, delegated mode with an arbitration journal, board updates, persisted-schema ordering between merges, the end-of-epic review and report, opening and closing the session. Triggers — "plan these US", "what's the interest of each", "group / parallelize / sequence these stories", "give me prompts I can paste into separate Claude sessions", "create the lanes", "reprends mon backlog", "avance jusqu'au bout". What happens INSIDE one lane → guessitall-workflow. Full state report → guessitall-etat-des-lieux. Creating a new epic's stories → bmad-create-epics-and-stories. Keywords orchestrator, lanes, parallel, prompt-pack, sonde, délégué, journal d'arbitrages, board, sprint-status, revue d'epic, bilan, passation.
---

# Guess It All — ce que fait la session principale

La session principale **cadre, planifie et orchestre** : elle ouvre les lanes, lance les revues,
tranche, fait merger et tient le board. Elle n'implémente pas et ne relit pas de longs rapports.
Ce qui se passe dans une lane → `guessitall-workflow`. `CLAUDE.md` prime.

## 🔴 Tests minimaux (décision Florent 2026-11-03)

Règle portée telle quelle dans **chaque** prompt de lane :

- On écrit un test **seulement** s'il épingle un invariant du tier risqué (machine à états,
  scoring, schéma persisté / migration, sync Firestore/offline, intégrité analytics,
  timer/cycle de vie) **ou** s'il reproduit un bug corrigé.
- Pas de test exhaustif ni cosmétique, **pas de widget test pour de l'UI simple**.
- En dev : tests ciblés seulement, via `scripts/with-test-slot.sh flutter test test/<fichier>`.
  Suite complète (`scripts/run-full-suite.sh`) **une fois**, avant la PR.

## 0. Ouvrir la session

1. `git -C /home/florent19961/guess_it_all_mobile fetch origin` puis
   `git rev-list --count HEAD..origin/main` : un retard se **signale** à Florent (les instructions
   chargées sont peut-être périmées). **Jamais de reset, merge ni checkout du checkout partagé.**
2. Board, `CLAUDE.md` et skills se lisent sur `origin/main` (`git show origin/main:<chemin>` ou un
   worktree neuf). Les prompts de lane le disent.
3. Reprendre le `note` de l'epic en cours dans `sprint-status.yaml` (passation, §8).

## 1. Cadrer d'abord : `grilling`

Aucune story ne part sans cadrage, sauf US triviale. Skill `grilling` (jamais `grill-me`) :
**toutes les questions en un seul message numéroté**, une ligne chacune, avec sa recommandation.
Les réponses vont dans la story ou l'epic avant toute lane.

## 2. Planifier un lot

Entrée : stories existantes (ids, bloc du board, « reprends mon backlog »). Sortie : un plan, puis
sur go un prompt-pack. **Aucun code ici.**

1. **Résoudre le lot** : lire `sprint-status.yaml` sur `origin/main`, lister les candidats si le
   lot n'est pas explicite.
2. **Intérêt par story — sortie OBLIGATOIRE** : ouvrir les fichiers et lignes cités, **vérifier
   contre le code réel** (citer la valeur vérifiée, jamais celle du board), puis
   `**<id>** — <2 phrases concrètes>`. Une demande centrée sur le plan n'est pas un skip ; seul un
   skip explicite en dispense. Lecture bornée aux citations et fichiers touchés.
3. **Graphe de conflits → lanes** : fichiers touchés par story ; deux stories qui écrivent le même
   fichier ne courent pas en parallèle. **Un seul track à la fois** sur `game_provider.dart`,
   `game_state.dart` / `game_settings.dart`, `storage_service.dart` + clés `guessItAll_*`
   (et `persisted_schema.dart`). `analytics_service.dart` / `firebase_sync_service.dart` = contrat
   d'events, à sérialiser aussi. Les écrans (`lib/screens/*`) sont en général parallélisables.
4. **Dosage** par story (trivial / standard / risqué, `guessitall-workflow` §1) et **pièges** : une
   correction suggérée par le board qui casserait un invariant se signale, elle ne s'applique pas
   au pied de la lettre. Story qui exige de voir l'app tourner → recette device listée pour
   Florent (depuis Windows), jamais simulée.
5. **Sur go seulement, le prompt-pack**, en deux étages :
   - **un fichier par story** dans le scratchpad (`prompt-<id>.md`) : story et ligne de board,
     périmètre et interdits entre lanes, fichiers et lignes vérifiés, pièges, tier et revue,
     **la règle des tests minimaux** (ci-dessus), « suis `guessitall-workflow` » ;
   - **un mini-prompt** auto-suffisant à froid : chemin absolu du fichier, « lis-le et suis-le »,
     identité de lane (worktree `/home/florent19961/guess-it-all-<slug>`, branche `feat/<slug>`
     depuis `origin/main`, `flutter pub get`), modèle (`guessitall-workflow` §1),
     « lis tout sur `origin/main` », « committer souvent, ne pas pusher sans consigne ».

## 3. Faire tourner les lanes

- 🔴 **Au plus 5 agents en parallèle** (lanes + reviewers + sous-agents de lecture, décision
  Florent 2026-11-03), bornés en plus par le graphe de conflits (§2.3), **sous la sonde de §4**.
  Tout run de test passe par `scripts/with-test-slot.sh` (sémaphore partagé avec WasReal).
- **Un agent neuf par story**, qui repart du board et des fichiers. L'implémenteur reste joignable
  (SendMessage) pour les corrections de sa story.
- **Les sous-agents ne testent pas et n'écrivent pas de code** : lecture, exploration, revue.
- **Revue** (standard et risqué, `guessitall-workflow` §5) : la session principale lance le
  reviewer sur le patch préparé par la lane, lit le verdict et les BLOCKER/MAJOR, transmet à
  l'implémenteur. Trivial : aucune revue.
- Depuis WSL : ni `flutter run` ni `flutter build`. Les recettes device vont dans la liste de
  Florent.
- **Jamais un 2ᵉ agent sur le worktree d'une lane qui paraît stallée** : la stopper (TaskStop) ou
  prouver qu'elle est morte, puis un seul propriétaire reprend.

## 4. Sonde légère, toutes les 15 minutes

Cron de session (`CronCreate`, `*/15 * * * *`) tant qu'une lane travaille ; supprimé
(`CronDelete`) dès que rien ne tourne, et à la clôture.

```bash
free -m                                                    # RAM « available » WSL
gh pr list --base main --state open --json number,title,mergeable
```

- WSL < 1,5 Go disponible → mettre en pause la lane la plus récente (committer, plus de test) et
  n'en ouvrir aucune autre.
- Rien n'a bougé → **une ligne** (« sonde HH:MM : RAM x Go, PR n — rien à faire »). Sinon agir
  sur l'écart : lane muette (relancer une fois, puis bloquée), revue finie (transmettre), PR prête
  (closeout si délégué, sinon demander le go).

## 5. Mode délégué

Seulement sur délégation explicite (« avance jusqu'au bout, prends les arbitrages »).

- La session principale **décide** et fait merger entre les stories via `guessitall-pr-closeout`
  (base `main`). **Jamais de tag, jamais de bump `pubspec.yaml`.**
- Chaque décision prise sans Florent va au fil de l'eau dans
  `_bmad-output/reviews/<epic>/journal-arbitrages.md`, une ligne :
  **date · story · question · choix · raison · état** (`appliqué`, `à valider`, `À TRANCHER`).
- 🔴 **Un changement de forme d'une clé `guessItAll_*` ne s'arbitre jamais seul** : `À TRANCHER`,
  la story attend Florent (`CLAUDE.md` règle 7).
- Même mécanisme au 3ᵉ round de revue = non-convergence : l'orchestrateur arbitre (simplifier,
  réduire la spec, accepter un résidu nommé) et l'inscrit au journal ; hors délégation, il
  remonte à Florent.
- Teach-back et recettes device reportés au bilan : le dire.

## 6. Board et schéma persisté

- **Board** (`sprint-status.yaml`) : jamais édité dans le checkout partagé. Worktree temporaire
  depuis `origin/main`, édition, commit, `git fetch` juste avant `git push origin HEAD:main`
  (rebase si refus), suppression du worktree. Relire le bloc au moment d'écrire.
- **`kCurrentSchemaVersion`** (`lib/services/persisted_schema.dart`) : si deux lanes l'ont
  incrémenté depuis la même valeur, **le second merge renumérote** (version et migration chaînée
  après celle déjà mergée) et rejoue le test de migration avant de merger.

## 7. Fin d'epic : revue d'epic puis bilan

**Revue d'epic**, seulement si **≥ 2 stories ont été sérialisées** sur un point de collision ou un
invariant du tier risqué : **un reviewer** (même rubrique que `guessitall-workflow` §5) sur le **diff cumulé** de
l'epic depuis la merge-base de la première story, centré sur les invariants transverses
(« la garantie posée par A tient-elle encore après le chemin ajouté par B ? »). Sinon, sauté.

**Bilan proposé à Florent**, non bloquant : teach-back de l'epic, journal d'arbitrages
(`À TRANCHER` en tête), stories et PR, tests ajoutés et retirés, **recettes device à faire**
(Android + iOS). `guessitall-etat-des-lieux` peut être lancé.

## 8. Clôturer la session

1. `git worktree list` : aucun worktree orphelin, aucune `feat/*` mergée restante, aucun
   non-commité perdu. Le checkout partagé se lit, il ne se nettoie jamais de force.
2. Journaux : `docs/tracking_evolution.md` (décisions), `docs/notes_pour_plus_tard.md` (reports).
3. Mémoire : consignes et pièges nouveaux, puis `scripts/sync-agent-memory.sh`.
4. **Passation dans le `note` de l'epic** (`sprint-status.yaml`, pas de nouveau fichier) : mergé,
   en vol (worktree, PR, dernier commit), ce qui attend Florent.
5. Supprimer le cron de sonde.
