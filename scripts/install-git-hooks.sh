#!/usr/bin/env bash
# Installe le plancher déterministe en pre-commit (à lancer UNE FOIS par clone,
# et une fois par worktree si tu veux la garde dedans aussi).
#
#   scripts/install-git-hooks.sh
#
# Le hook lui-même n'est PAS versionné (git ne versionne pas .git/hooks) — d'où
# ce script, qui l'est. Il tourne sur les fichiers Dart STAGED uniquement :
#   1. dart format --set-exit-if-changed  (refuse un commit mal formaté)
#   2. flutter analyze                    (refuse un commit qui ne compile pas)
#
# Bypass ponctuel : git commit --no-verify
#
# 🔴 GARDE : le hook refuse tout commit si `flutter analyze` est rouge. Tant que la
# baseline du dépôt est rouge (au 2026-08-01 : test/widget_test.dart est le
# scaffold Flutter jamais adapté → `MyApp` n'existe pas), l'installer BLOQUERAIT
# tous les commits, y compris ceux qui viennent réparer la baseline. Ce script
# refuse donc de s'installer tant que ce n'est pas vert. Forcer : --force.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HOOK_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOK_DIR"

if [[ "${1:-}" != "--force" ]]; then
  echo "[install-git-hooks] vérification de la baseline (flutter analyze)…"
  if ! (cd "$ROOT" && flutter analyze --no-pub >/dev/null 2>&1); then
    cat >&2 <<'MSG'
❌ Baseline ROUGE — hook NON installé.

`flutter analyze` échoue déjà sur le dépôt tel quel. Installer le pre-commit
maintenant bloquerait TOUS les commits, y compris ceux qui répareraient la
baseline — un piège, pas un garde-fou.

  → Solde d'abord la dette (cf. docs/notes_pour_plus_tard.md), puis relance.
  → Ou, en connaissance de cause : scripts/install-git-hooks.sh --force
MSG
    exit 1
  fi
fi

cat > "$HOOK_DIR/pre-commit" <<'HOOK'
#!/usr/bin/env bash
# Plancher déterministe — installé par scripts/install-git-hooks.sh
set -euo pipefail

STAGED_DART=$(git diff --cached --name-only --diff-filter=ACM -- '*.dart' || true)
[ -z "$STAGED_DART" ] && exit 0

echo "[pre-commit] dart format…"
if ! echo "$STAGED_DART" | xargs dart format --set-exit-if-changed >/dev/null; then
  echo "❌ [pre-commit] fichiers mal formatés. Lance :" >&2
  echo "     dart format $(echo "$STAGED_DART" | tr '\n' ' ')" >&2
  echo "   puis re-stage. (bypass : git commit --no-verify)" >&2
  exit 1
fi

echo "[pre-commit] flutter analyze…"
if ! flutter analyze --no-pub >/dev/null; then
  echo "❌ [pre-commit] flutter analyze rouge — relance-le pour le détail :" >&2
  echo "     flutter analyze" >&2
  echo "   (bypass : git commit --no-verify)" >&2
  exit 1
fi
HOOK

chmod +x "$HOOK_DIR/pre-commit"
echo "✅ pre-commit installé → $HOOK_DIR/pre-commit"
echo "   (dépôt : $ROOT ; bypass ponctuel : git commit --no-verify)"
