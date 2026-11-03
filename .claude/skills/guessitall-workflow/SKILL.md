---
name: guessitall-workflow
description: Use when implementing ONE Guess It All user story in a lane — fresh worktree from origin/main, the fewest tests possible, review by tier (trivial none / standard and risky one Opus reviewer), fix loop until READY with a simplify-the-root guard, PR, merge and closeout — when deciding how much process a change warrants, or when cutting a store release. Framing, planning a batch into lanes, running several lanes, delegated mode and the end-of-epic review → guessitall-orchestration. Creating a new epic → bmad-create-epics-and-stories. Keywords US, story, lane, tier, review, Opus reviewer, worktree, minimal tests, fix round, closeout, release, tag, store.
---

# Guess It All — ce que fait UNE lane

Une lane = un agent, une story, un worktree, une PR. La revue est lancée par la session principale
(`guessitall-orchestration`), ou par la lane elle-même quand elle travaille seule. `CLAUDE.md`
prime sur cette skill. **Pas de gates numérotés** (décision Florent 2026-11-03, calquée sur
`wasreal-workflow`) : le tier décide s'il y a une revue, c'est tout.

## 1. Doser : le tier décide de tout

| Tier | Exemples | Implémenteur | Revue |
|---|---|---|---|
| **Trivial** | copie, libellé, ajout de mots, style, doc, board, fix mécanique d'un fichier | Sonnet | aucune |
| **Standard** | écrans, UI, thème, catégories, outillage | Opus | 1 reviewer Codex |
| **Risqué** | les six zones ci-dessous | Opus | 1 reviewer Codex (mutation testing obligatoire) |

Dans le doute, prendre le plus haut. Jamais de PRD ni de party-mode pour un fix de quelques lignes.
**Revue = Codex, jamais de Fable** (décisions Florent 2026-11-03) : implémenteurs Opus (Sonnet pour le trivial), reviewer Codex (agent `codex:codex-rescue`, consigne lecture seule). Pas de second reviewer.

🔴 **Zones risquées de ce projet** :
1. **Machine à états de la partie** — manches, tours, équipes, pool de mots, fin de partie.
2. **Scoring** — points, pénalités de passe, égalités.
3. **Persistance `SharedPreferences`** — toute forme d'une clé `guessItAll_*` (règle 7 : l'app est
   publiée, `upgrader` force la mise à jour → migration explicite, jamais « ça repartira de zéro »).
4. **Sync Firestore / offline** — queue `pending_sync`, idempotence d'upload.
5. **Intégrité analytics** — un compteur faux est silencieux et durable.
6. **Timer / cycle de vie** — `TurnClock`, app backgroundée, appel entrant.

**Deux plateformes, toujours** (règle 8) : une évolution se vérifie Android **et** iOS
(`defaultTargetPlatform`, jamais `Platform.*`) ; une plateforme exclue se dit dans la PR.

## 2. Ouvrir la lane

1. **Worktree neuf depuis `origin/main`** :
   `git fetch origin && git worktree add /home/florent19961/guess-it-all-<slug> -b feat/<slug> origin/main`,
   puis **`flutter pub get`** dedans (SDK `~/development/flutter`, jamais le Flutter Windows du
   `PATH`). Jamais de travail, `checkout` ni `switch` dans le checkout partagé
   `/home/florent19961/guess_it_all_mobile`.
2. Lire la story et ses AC **à la source** (`_bmad-output/specs/…`, board), dans le worktree ou par
   `git show origin/main:<chemin>`.
3. **Committer souvent** (`wip` compris). Stager par chemin, jamais `git add -A`.
4. Pas de sous-agent qui écrit du code ou lance des tests : la lane fait elle-même.

## 3. Le moins de tests possible

- Un test **seulement** s'il garde un invariant d'une zone risquée ou reproduit un bug corrigé —
  écrit avant le code dans ces deux cas. Un AC = au plus le test qui le prouve.
- Après le vert, **retirer l'échafaudage** que le test final subsume. Rien sur du trivial (champ
  de modèle, `copyWith`, constante), **pas de widget test pour de l'UI simple**.
- Les tests obsolètes croisés en chemin se suppriment dans la même PR (couverture portée ailleurs).
- Avant de toucher une fonction exportée, un modèle persisté ou une garde : grep de ses appelants.
- La PR dit combien de tests sont ajoutés et retirés, et pourquoi.

## 4. Tests : quand et comment

- **Tout run passe par `scripts/with-test-slot.sh`** (sémaphore RAM partagé avec WasReal).
- **Dev** : la zone touchée seulement — `scripts/with-test-slot.sh flutter test test/<fichier>`.
- **Avant la PR, une fois** : `scripts/run-full-suite.sh` (format + analyze + test). Docs, board,
  skills seuls → aucun test.
- Baseline **verte** depuis la PR #2 : un rouge sur `origin/main` est une vraie régression ; un
  rouge hors périmètre du diff se rejoue seul (vert seul = flake, le noter).
- Ne jamais piper une commande de test dans `grep`/`tail` (le pipe rend l'exit du filtre).
- **Depuis WSL : ni `flutter run` ni `flutter build`** (pas d'Android SDK, pas de Xcode). Une story
  qui exige de voir l'app tourner liste ses **recettes device** pour Florent (Windows / téléphone).

## 5. La revue (standard et risqué)

La lane prépare `_bmad-output/reviews/<epic>/<story>-patch-rN.diff`, calculé sur la merge-base
(`git diff $(git merge-base origin/main HEAD)`), et `<story>-prompt-rN.md` (objectif, décisions
de l'epic, questions précises, format attendu). La session principale lance **un reviewer Codex**
(`general-purpose` + rubrique inline), qui lit le patch (jamais `git diff` lui-même) et écrit son
rapport dans un fichier :
- conformité aux AC, **sur les deux plateformes** ;
- correctness sur **tous les chemins de mutation d'état**, code lu avant la spec ;
- **mutation testing** sur les tests ajoutés (obligatoire en risqué) ; un test qui nomme une
  garantie doit l'exercer ;
- **valeur des tests** : redondant, échafaudage ou obsolète = finding ;
- grille `thermo-nuclear-code-quality-review` **limitée au diff** ; le finding le plus utile est
  souvent « ce mécanisme est sur-dimensionné, sa racine est un choix de spec » ;
- une skill maison décrit-elle un comportement que ce diff change ? Sa mise à jour (et le symlink
  `.codex/skills/` si une skill naît ou meurt) fait partie de la PR.

Chaque finding est une **affirmation à vérifier** : l'implémenteur la re-trace dans le code.

## 6. Corriger : boucler jusqu'à READY

- Le fix revient à **l'implémenteur de la story** (SendMessage). Il écrit `<story>-fix-rN.md` : par
  finding, décision (corrigé / faux positif / résidu assumé) et preuve (`fichier:ligne` ou test).
- Revue → correction des BLOCKER et MAJOR retenus → nouvelle revue, jusqu'à READY.
- **Même mécanisme qui revient** : on ne corrige plus par-dessus, on **simplifie la racine**. Dès le
  2ᵉ finding sur un mécanisme, le fichier de correction le justifie ; au 3ᵉ round, la lane
  s'arrête et l'orchestrateur arbitre (`guessitall-orchestration` §5).

## 7. PR, merge, closeout

1. `teach-back` avant le closeout, sauf story triviale, skip demandé ou mode délégué (le dire).
2. PR depuis le worktree, **base `main`**. Corps : tier, revue jouée, tests ajoutés et retirés,
   plateformes exclues, forme persistée changée (règle 7), skills mises à jour, recettes device.
3. **Merge sur go explicite de Florent** (« closeout » vaut go), ou délégation explicite du lot.
4. Closeout : `guessitall-pr-closeout` (squash, board `→ done`, journaux). Worktree et branche
   supprimés au merge. Jamais de tag ni de bump `pubspec.yaml`.
5. **`kCurrentSchemaVersion`** : si une autre lane l'a incrémenté depuis la création de la branche,
   celui qui merge en second renumérote sa migration et rejoue son test.
6. Branche très en retard : intégrer `origin/main` et rejouer la suite avant le merge.

## 8. Release store (étape SÉPARÉE — jamais dans un closeout)

Pas de branche « prod » : ce qui est publié est un **build soumis**, matérialisé par un tag.

1. `main` vert (`scripts/run-full-suite.sh`) et toutes les US du lot à `done`.
2. Bump `pubspec.yaml` → `version: X.Y.Z+N` — **`+N` strictement croissant** (derniers builds en
   store : board, `epic-6-release-cloud`).
3. Commit `chore(release): vX.Y.Z+N`, `git tag -a vX.Y.Z+N`, `git push --follow-tags`.
4. Le tag lance le workflow Codemagic **`release`** (`codemagic.yaml`) : garde tag = version
   pubspec, puis AAB + IPA. 🔴 **Publication désactivée** jusqu'à la 1re release post-Fiesta (go
   Florent). Secrets, `dry-run`, activation : `docs/releases-stores.md` §Codemagic.
5. Entrée datée dans `docs/tracking_evolution.md`.

⚠️ `upgrader` force la mise à jour : une release atteint tout le parc. Un bug de persistance
embarqué est irrattrapable côté données déjà écrites.
