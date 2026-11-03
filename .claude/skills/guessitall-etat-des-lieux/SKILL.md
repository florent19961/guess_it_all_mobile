---
name: guessitall-etat-des-lieux
description: Use ONLY when Florent asks for a full state report of the Guess It All project ("état des lieux", "où on en est", "fais le point complet") or at the end-of-batch / end-of-epic report of guessitall-orchestration. Builds short tables — machine memory, worktrees and orphans, open PRs and recent merges, release (last tag, commits since, persisted schema changed?), board, active agents, half-done framings, upcoming work with blockers and parallelism, Florent's own tasks, other local Claude sessions. NOT for the 15-minute light probe (→ guessitall-orchestration §4).
---

# Guess It All — état des lieux complet

Lecture seule : rien n'est modifié, aucun worktree supprimé, aucune session tuée. Les écarts se
signalent, Florent décide. Tout ce qui vient du dépôt se lit sur **`origin/main`**
(`git fetch origin` d'abord, puis `git show origin/main:<chemin>`), jamais dans le checkout partagé.

## Ce qu'on relève

1. **Machine** : `free -m` (RAM « available », swap). Seuils : < 1,5 Go disponible, swap > 75 %.
2. **Worktrees** : `git worktree list --porcelain`. Pour chacun : branche, dernier commit (date),
   `git status -s` vide ou non, PR (`gh pr list --head <branche> --state all`). **Orphelin** =
   branche mergée ou PR fermée, dossier absent (`prunable`), ou rien depuis 3 jours sans PR.
3. **PR** : `gh pr list --base main --state open --json number,title,headRefName,mergeable,updatedAt`
   et les 10 derniers merges (`--state merged --limit 10`). Retard du checkout partagé :
   `git rev-list --count HEAD..origin/main`.
4. **Release** :
   ```bash
   T=$(git describe --tags --abbrev=0 origin/main)          # dernier tag
   git rev-list --count "$T"..origin/main                   # commits depuis
   git diff --quiet "$T" origin/main -- lib/services/persisted_schema.dart lib/services/storage_service.dart \
     || echo "schéma persisté touché"                       # → règle 7 à vérifier avant release
   ```
5. **Board** : `git show origin/main:_bmad-output/implementation-artifacts/sprint-status.yaml` ;
   stories `in-progress`, `review`, `ready-for-dev`, `needs-decision`, `needs-design`, `blocked`,
   le prochain `backlog` de chaque epic ouvert, et le `note` de passation de l'epic en cours.
6. **Agents actifs** : `ListAgents` ; croiser avec les worktrees (lane sans agent, agent sans
   worktree).
7. **Cadrages en suspens** : epics `needs-decision` / `needs-design`, `À TRANCHER` dans les
   stories, journaux `_bmad-output/reviews/*/journal-arbitrages.md` avec des lignes `à valider` ou
   `À TRANCHER`.
8. **À venir** : prochaines stories, ce qu'elles attendent (cadrage, go, autre story, recette
   device) et avec quoi elles sont parallélisables (aucun point de collision commun,
   `guessitall-orchestration` §2.3).
9. **Tâches de Florent** : go de merge en attente, `À TRANCHER`, `needs-decision`, bilans non lus,
   recettes device (Android + iOS) à faire, release à couper.
10. **Autres sessions Claude locales** : `~/.claude/sessions/*.json` (pid, cwd, état) avec
    `kill -0 <pid>`, et `pgrep -af claude` ; signaler les sessions mortes dont le fichier traîne
    et les sessions vivantes dans le checkout partagé.

## Ce qu'on rend

Des tableaux courts, un par rubrique, dans cet ordre, sans prose autour :

| Rubrique | Colonnes |
|---|---|
| Machine | WSL dispo · swap |
| Worktrees | chemin · branche · dernier commit · sale ? · PR · orphelin ? |
| PR | n° · titre · mergeable · âge |
| Derniers merges | n° · titre · date |
| Release | dernier tag · commits depuis · schéma persisté touché ? |
| Board | epic · en cours · en revue · prêtes · bloquées |
| Agents | nom · tâche · état · worktree |
| Cadrages en suspens | epic · ce qui manque |
| À venir | story · attend quoi · parallélisable avec |
| Tâches de Florent | tâche · depuis quand · lien |
| Sessions Claude | pid · cwd · état · vivante ? |

Terminer par trois lignes au plus : ce qui est urgent (mémoire, orphelins, go en attente).
