---
name: guessitall-epic-intake
description: Use when you have a SET of EXISTING Guess It All user stories (backlog ids, a pasted board block, or "remind me what's in my backlog") and want to plan how to implement them — BEFORE opening any single story. Triggers — "plan these US", "what's the interest of each", "group / parallelize / sequence these stories", "give me prompts I can paste into separate Claude sessions", "create the lanes". NOT for creating a brand-new epic's stories (→ bmad-create-epics-and-stories) nor for implementing one story (→ guessitall-workflow).
---

# Guess It All — epic intake (planifier un lot d'US existantes)

## Overview

**Entrée = un lot d'US qui existent déjà** (backlog/board). **Sortie = un plan d'exécution + un
prompt-pack copier-coller.** C'est l'altitude **(b)**, entre créer un epic (a, `bmad-*`) et
implémenter une US (c, `guessitall-workflow`). Tu ne touches **aucun** code ici — tu produis de
quoi lancer l'implémentation, souvent **plusieurs invites Claude fraîches en parallèle**.

Principe : **grounder sur le vrai code, pas sur le texte du board** (les citations du backlog
vieillissent), **doser**, et livrer des prompts **auto-suffisants à froid**.

## Quand l'utiliser / quand non

- ✅ « Donne-moi l'intérêt de ces US + comment les répartir + les prompts. »
- ✅ « Je reviens sur mon backlog, rappelle-moi ce qu'il y a et fais les lanes. »
- ❌ Créer les US d'un epic neuf depuis une idée produit → `bmad-prd` → `bmad-create-architecture`
  → `bmad-create-epics-and-stories`.
- ❌ Prendre UNE US (ou un lot déjà planifié) et l'implémenter spec→gate→merge →
  `guessitall-workflow`.

## Le flux (4 étapes)

1. **Résoudre le lot.** Depuis des ids / un bloc collé / « lis mon backlog » → lire
   `_bmad-output/implementation-artifacts/sprint-status.yaml` et **lister les candidats** pour que
   l'humain choisisse.
2. **Grounder + expliquer.** Pour CHAQUE US : ouvrir les lignes citées, **vérifier les claims
   contre le code réel** (citer la valeur *vérifiée*, jamais celle du board). Puis rendre
   **l'intérêt en 2 phrases FR concrètes/US** — c'est un **élément de sortie OBLIGATOIRE**, pas une
   étape optionnelle. Exemption **uniquement** sur skip **explicite** (« skip les explications ») —
   ⚠️ **une demande centrée sur le plan ou les prompts n'est PAS un signal de skip**. Le grounding
   n'est jamais sautable.
3. **Graphe de conflits → lanes + dosage.** Tracer les **fichiers touchés par US** → deux US qui
   écrivent dans le même fichier ne peuvent **pas** courir en //.
   🔴 **Points de collision structurels de CE dépôt** (à vérifier en premier, ils concentrent
   presque tous les conflits) :
   - `lib/providers/game_provider.dart` — le provider unique qui porte la logique de partie ET le
     tracking. Deux US qui y touchent = **séquentiel**, toujours.
   - `lib/models/game_state.dart` / `game_settings.dart` — la forme de l'état ; un champ ajouté
     par une lane casse le `copyWith` de l'autre.
   - `lib/services/storage_service.dart` + les clés `guessItAll_*` — **un seul track à la fois**
     sur le schéma persisté.
   - `lib/services/analytics_service.dart` / `firebase_sync_service.dart` — le contrat d'events.
   - Les écrans (`lib/screens/*`) sont en général **parallélisables** entre eux.

   Pour chaque US : **doser** (ajout de mots / copy / 1 écran → lane légère, **no gate** ; machine
   à états, scoring, persistance, sync, analytics, cycle de vie → gate ② plein + Codex, cf.
   `guessitall-workflow` §Doser). **Surfacer les pièges** — une correction suggérée par le board
   qui casse un invariant existant ne se prend pas au pied de la lettre.
4. **Sur go → émettre le prompt-pack (deux étages).** NE PAS générer les prompts avant que l'humain
   valide le plan.

## Ce que tu RENDS, dans l'ordre

1. **Intérêt par US** — un bloc `**<id>** — <2 phrases FR concrètes, grounded>` pour CHAQUE US du
   lot. **OBLIGATOIRE** ; exemption uniquement sur skip **explicite**.
2. **Plan de lanes** — graphe de conflits → lanes (// vs séquentiel) + dosage/US + pièges.
3. **Sur go seulement** — le prompt-pack deux étages ci-dessous.

## Contrat de sortie — prompt-pack (deux étages)

Le mini-prompt est la **seule** chose qui atterrit dans une invite Claude **fraîche** (zéro
contexte de la session de planif), souvent **lancée en parallèle**. Donc :

- **Fichier tmp, 1 par US** (`scratchpad/prompt-<id>.md`) = la profondeur : story + ligne board,
  **périmètre + interdits inter-lanes**, fichiers/lignes **vérifiés**, pièges, dosage/process
  gate, « suis `guessitall-workflow` par story ».
- **Mini-prompt, 1 par US** = le *loader* court, **auto-suffisant à froid** : chemin **absolu** du
  tmp + « lis-le et suis-le » + **identité de lane/worktree** (branches distinctes → invites //
  sans collision) + rappel conventions (CLAUDE.md).

Exemple de mini-prompt :

```
Prends les US 2-3 puis 2-5 EN SÉQUENCE (elles partagent game_provider.dart → même worktree).
Lis et suis /tmp/.../scratchpad/prompt-2-3.md, mène-la au bout, puis prompt-2-5.md.
Conventions projet (CLAUDE.md) applicables.
```

## Common mistakes

| Erreur | Fix |
|---|---|
| Sauter l'**intérêt en 2 phrases/US** parce que le prompt est centré-plan | Slot de sortie OBLIGATOIRE ; seul un skip **explicite** l'exempte |
| **Recopier les chiffres du board** (nb de mots, durées, seuils) | Lire le code, citer la valeur vérifiée — les citations vieillissent |
| **Sur-gater** une US « ajout de mots » ou « copy » | Doser depuis la ligne board : contenu/UI → no gate |
| Mini-prompt qui **suppose le contexte** de la planif | Auto-suffisant à froid : chemin absolu + lane + conventions |
| Paralléliser deux US qui touchent `game_provider.dart` | C'est LE point de collision du dépôt → séquentiel, même worktree |
| Oublier `flutter pub get` dans le prompt de lane | Worktree neuf = `.dart_tool/` absent → baseline faussement rouge |

## Cross-refs

- Exécuter une lane = **1 worktree par lane depuis `origin/main`** (branches `feat/` distinctes ;
  **jamais** `git checkout` dans le checkout partagé) → mécaniques complètes (gate, closeout) →
  **`guessitall-workflow`**.
- Créer un epic neuf → **`grill-me` → `bmad-prd` → `bmad-create-architecture` →
  `bmad-create-epics-and-stories`**.
