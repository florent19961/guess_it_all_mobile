# agent-memory — mirror de sauvegarde (NE PAS ÉDITER À LA MAIN)

Ce dossier est un **backup versionné** de l'auto-memory de Claude Code.

- **Source canonique** (per-machine, écrite par l'outil mémoire de l'agent) :
  `~/.claude/projects/-home-florent19961-guess_it_all_mobile/memory/`
- **Mirror** (ce dossier) : sauvegardé sur GitHub, résout les `[[liens]]`, et voyage dans les git
  worktrees — un worktree neuf n'a sinon aucune mémoire.

## Usage

```bash
scripts/sync-agent-memory.sh            # backup : ~/.claude → dépôt, puis relire et committer
scripts/sync-agent-memory.sh --push     # backup + commit + push
scripts/sync-agent-memory.sh --restore  # restauration : dépôt → ~/.claude (machine neuve / worktree)
```

Le sync est un `rsync --delete` limité aux `.md` : **éditer ici ne sert à rien**, le prochain
backup écrasera. Pour corriger une mémoire, passer par l'agent (ou éditer la source canonique).
