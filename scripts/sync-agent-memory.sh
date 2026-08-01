#!/usr/bin/env bash
# Mirror the Claude Code auto-memory into the repo so it is backed up to GitHub,
# resolves the CLAUDE.md [[links]], and travels to git worktrees.
#
# Canonical store (per-machine, written by the Claude Code memory tool):
#   ~/.claude/projects/<encoded-main-worktree>/memory/
# Repo mirror (tracked, this is a BACKUP — do not edit by hand):
#   docs/agent-memory/
#
# Usage:
#   scripts/sync-agent-memory.sh           # backup: ~/.claude -> repo, then review & commit
#   scripts/sync-agent-memory.sh --push    # backup: ~/.claude -> repo, THEN commit + push to remote
#   scripts/sync-agent-memory.sh --restore # restore: repo -> ~/.claude (new machine)
set -euo pipefail

MAIN="$(git rev-parse --path-format=absolute --git-common-dir | xargs dirname)"
SRC="$HOME/.claude/projects/$(echo "$MAIN" | sed 's#/#-#g')/memory"
DEST="$MAIN/docs/agent-memory"

if [[ "${1:-}" == "--restore" ]]; then
  mkdir -p "$SRC"
  rsync -a --exclude='README.md' --include='*/' --include='*.md' --exclude='*' "$DEST/" "$SRC/"
  echo "Restored $(ls "$SRC"/*.md 2>/dev/null | wc -l) memory files -> $SRC"
  exit 0
fi

PUSH=0
[[ "${1:-}" == "--push" ]] && PUSH=1

if [[ ! -d "$SRC" ]]; then
  echo "No memory dir at $SRC (nothing to back up)" >&2
  exit 1
fi
mkdir -p "$DEST"
# Mirror only .md, mirror deletions, but never touch this dir's own README.md.
rsync -a --delete --exclude='README.md' --include='*/' --include='*.md' --exclude='*' "$SRC/" "$DEST/"
echo "Synced $(ls "$DEST"/*.md 2>/dev/null | grep -v '/README.md$' | wc -l) memory files -> docs/agent-memory/"

if [[ "$PUSH" == "1" ]]; then
  # Auto-backup to the remote: commit ONLY the mirror dir (never sweeps unrelated
  # working-tree changes) and push the main checkout's current branch. No-op when
  # the mirror is already in sync. Generic commit author on purpose — this is a
  # tooling-generated backup, not a hand-authored change.
  if [[ -n "$(git -C "$MAIN" status --porcelain -- "$DEST")" ]]; then
    git -C "$MAIN" add -- "$DEST"
    git -C "$MAIN" commit -q -m "chore(memory): backup agent-memory mirror -> remote (sync-agent-memory.sh --push)"
    git -C "$MAIN" push
    echo "Committed + pushed memory mirror to remote."
  else
    echo "Memory mirror already in sync — nothing to commit."
  fi
else
  echo "Review: git -C \"$MAIN\" status docs/agent-memory/  then commit (or re-run with --push)."
fi
