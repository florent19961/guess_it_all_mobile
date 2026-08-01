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
