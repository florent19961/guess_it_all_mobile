---
name: guessitall-pr-closeout
description: Use when merging and closing out a Guess It All story PR to main from a git worktree — covers the squash-merge, pull/push, resolving sprint-status / notes_pour_plus_tard / tracking_evolution, worktree teardown, and deleting the feat branch local + remote. Target = main (the trunk). A store release is NOT a closeout — it is a separate tagged promotion (see guessitall-workflow §Release).
---

# Guess It All — PR closeout (story → `main`, merge → clean)

## Overview

Closing a story PR isn't just "click merge". The work lives in a **git worktree**, and three
**append-only doc files** (`sprint-status.yaml`, `notes_pour_plus_tard.md`,
`tracking_evolution.md`) need resolving. Skipping a step leaves orphan branches, a diverged
local `main`, or a story stuck at `review`.

🔴 **Target branch = `main`** — the trunk. Every story PR has **base `main`** and merges there.

⚠️ **Merger ≠ publier.** Sur mobile il n'y a pas de branche « prod » : ce qui est en store est un
**build soumis**, matérialisé par un **tag `vX.Y.Z+N`**. Un closeout de story ne pousse **jamais**
de tag et ne bump **jamais** `pubspec.yaml`. La release est une étape séparée
(`guessitall-workflow` §Release).

**End state required:** the feat branch gone (local + remote), worktree removed, local `main` ==
`origin/main`, story `done`, working tree clean (untracked WIP preserved — and any concurrent
session's tracked WIP in the shared checkout left **untouched**).

## Key facts (be aware BEFORE you start)

- 🎓 **Pre-flight : le `teach-back` a-t-il tourné ?** Avant tout merge, la skill `teach-back`
  (compréhension utilisateur) doit avoir tourné — sauf story triviale (skip auto au
  dosage) ou skip explicite de Florent. Pas encore fait → la lancer MAINTENANT.
- 🔴 **Merge uniquement sur go explicite de Florent.** Tout préparer jusqu'à `gh pr create`
  inclus, puis STOP.
- **Pas de CI GitHub sur ce dépôt** (aucun `.github/workflows`) → `mergeStateStatus` sera `CLEAN`
  ou `BLOCKED` pour cause de review, jamais `UNSTABLE`-par-CI. La vraie revue a tourné en local
  (`guessitall-workflow` §5). Si une protection de branche est ajoutée un jour et bloque : `--admin`.
- `gh pr merge --delete-branch` **cannot delete the local branch** while a worktree holds it, and
  in practice may also **skip the remote deletion** → delete the remote branch **explicitly**
  afterward.
- Removing the worktree **changes your cwd** if you're inside it → run teardown from the **main
  checkout** `/home/florent19961/guess_it_all_mobile`.
- ⛔ **NEVER `git reset --hard` (nor `git checkout -f` / `git clean`) the shared main checkout when
  it has TRACKED uncommitted changes.** Another session may be editing **directly in**
  `/home/florent19961/guess_it_all_mobile` (not in a worktree). `reset --hard` **irrecoverably
  destroys** their work — *unstaged* changes were never written to git's object store, so
  `git fsck`/reflog/`git stash` **cannot** bring them back. Resync with `git merge --ff-only`,
  which can never clobber.
- ⚠️ **`pubspec.lock` est un piège de closeout.** Un `flutter pub get` lancé par une session dont
  le SDK Flutter diffère réécrit 30 lignes de versions épinglées-par-le-SDK. Ce diff n'est
  **jamais** un changement de story : si `pubspec.lock` apparaît dans le diff sans qu'une
  dépendance ait été ajoutée/retirée dans `pubspec.yaml`, **le restaurer**
  (`git checkout -- pubspec.lock`) avant de merger.

## Sequence

Run everything from the **main checkout** (`/home/florent19961/guess_it_all_mobile`), on branch
`main`, never from inside the worktree (it gets removed mid-flow). The Bash tool resets cwd there
each call anyway.

```bash
# 0. HARD GATE — the shared checkout must have NO tracked changes before you touch it.
gh pr view <PR#> --json state,mergeable,mergeStateStatus,baseRefName  # baseRefName MUST be "main"
git -C /home/florent19961/guess_it_all_mobile status --short
#   ⛔ ANY line NOT starting with "??" (e.g. ` M`, `MM`, `A `, `D `, `R `) = a CONCURRENT
#      session is editing the shared checkout DIRECTLY. STOP. Do NOT reset/commit here.
#      Resync stays --ff-only (step 3) and do the board flip in a TEMP WORKTREE (see below).
#      Only "??" untracked lines are safe to proceed past.

# 1. MERGE (squash). Project convention = squash. Base = main.
gh pr merge <PR#> --squash --delete-branch
#    → the "failed to delete local branch ... used by worktree" line is EXPECTED.

# 2. Teardown worktree FIRST (frees the branch), THEN delete the local branch.
git worktree remove /home/florent19961/guess-it-all-<slug>   # clean (all committed) → no --force
git branch -D feat/<slug>

# 3. Re-sync local main — NON-DESTRUCTIVE ONLY. NEVER `reset --hard` the shared checkout.
git fetch origin --prune
git switch main
git merge --ff-only origin/main
#   --ff-only fast-forwards if local main is behind and REFUSES (touching nothing) if it
#   diverged → it can NEVER clobber WIP. If it refuses: INVESTIGATE, do NOT `reset --hard`.

# 4. Delete the REMOTE branch explicitly (step 1's --delete-branch often no-ops it).
git ls-remote --heads origin
git push origin --delete feat/<slug>
git fetch origin --prune

# 5. Resolve the board: story → done (see below), commit on main, push.
git push origin main
```

### If the shared checkout is OCCUPIED (step 0 found foreign tracked WIP)

Do the board flip WITHOUT reading/resetting/committing the shared checkout:

```bash
git worktree add --detach /tmp/gia-boardflip origin/main   # isolated, on the squash tip
# edit sprint-status.yaml (+ any docs) THERE, commit, then:
git -C /tmp/gia-boardflip push origin HEAD:main
git worktree remove /tmp/gia-boardflip
```

The shared checkout's foreign WIP is never touched; its local `main` ff-syncs later.

## Resolving the doc files

After merge, fix on `main` in **one small commit**:

- **`_bmad-output/implementation-artifacts/sprint-status.yaml`** — flip the story to `done` (the
  branch left it `review`). `done` = merged **AND** accepted. Keep the existing note, prepend the
  merge fact: `# ✅ MERGÉ PR #<N> (squash <sha>, sur instruction Florent). REVUE CLOSE ...`.
- **`docs/notes_pour_plus_tard.md`** — any review finding triaged as *pre-existing / out-of-scope*
  belongs here as a dated entry. Add it **on the branch** (so it ships with the PR), not after.
- **`docs/tracking_evolution.md`** — one dated entry per significant story (what changed + why).
  Add on the branch.

**Merge conflicts on these three files** (main advanced with another story's edits while the PR
was open): they are **append-only logs / per-story entries** → resolve by **KEEPING ALL entries
from both sides** (never drop the other story's lines). Best avoided by rebasing the branch on
`origin/main` *before* opening/merging the PR.

Commit message convention:
`docs(sprint): <story> → done (PR #<N> mergée squash, sur instruction Florent)` + the
`Co-Authored-By` trailer.

## Final verification (must all hold)

```bash
git branch                         # → * main only (NO feat/)
git branch -r                      # → origin/HEAD, origin/main (no feat)
git ls-remote --heads origin       # → only refs/heads/main
git worktree list                  # → only /home/florent19961/guess_it_all_mobile
git rev-parse --short HEAD origin/main   # → identical (you are on main)
git status --short                 # → only pre-existing untracked WIP
grep "<story>:" _bmad-output/implementation-artifacts/sprint-status.yaml   # → done
git tag --points-at HEAD           # → EMPTY : un closeout ne pose JAMAIS de tag de release
```

## Common gotchas

| Symptom | Cause → fix |
|---|---|
| PR base is not `main` | retarget before merging (`gh pr edit <PR#> --base main`) |
| `failed to delete local branch ... used by worktree` | branch held by worktree → remove worktree first, then `git branch -D` |
| `fatal: Unable to read current working directory` after `worktree remove` | cwd was the removed worktree → run from main checkout |
| local main ahead/behind after merge | resync with `git merge --ff-only origin/main` (NON-destructive). If it refuses, investigate — do NOT `reset --hard` |
| `origin/feat/...` still in `git branch -r` after merge | `--delete-branch` no-op'd remote → `git push origin --delete feat/<slug>` + `--prune` |
| `pubspec.lock` dans le diff sans changement de `pubspec.yaml` | un `pub get` sous un SDK Flutter différent → `git checkout -- pubspec.lock` |
| ⛔ tracked WIP in the shared checkout (` M`/`MM`/`A `…) | a concurrent session edits the main checkout directly → `reset --hard` would **irrecoverably** wipe it. NEVER reset. Resync `--ff-only`; board-flip in a temp worktree. |

## Don't

- ⛔ **Never `git reset --hard` / `git checkout -f` / `git clean` the shared main checkout.**
  Resync with `git merge --ff-only origin/main`. Unstaged changes wiped this way are
  **unrecoverable** (not in git's object store).
- ⛔ **Never chain `git status` and `git reset --hard` in the same command.** Read the status,
  *evaluate it*, and only then resync — and only with `--ff-only`.
- ⛔ **Never bump `pubspec.yaml` `version:` nor push a tag during a closeout.** Release = étape
  séparée (`guessitall-workflow` §Release).
- Don't push a story to `done` before it's merged AND accepted.
- Don't `git checkout <branch>` in the shared checkout beyond the `main` trunk — branch first /
  use the worktree (would switch every session).
