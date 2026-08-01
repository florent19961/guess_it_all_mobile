#!/usr/bin/env bash
# Suite complète de gate — à lancer UNE FOIS avant d'ouvrir la PR, depuis le
# worktree de la story (CLAUDE.md règle #2).
#
# Contenu (dans cet ordre — le moins cher d'abord, on s'arrête au premier rouge) :
#   1. dart format --set-exit-if-changed   (formatage)
#   2. flutter analyze                     (0 error exigé)
#   3. flutter test                        (suite unitaire + widgets)
#
# RÉGULATION MÉMOIRE — deux couches, les deux nécessaires :
#   - flock exclusif (fd 9) par PROJET  : deux suites complètes de ce dépôt
#     s'ATTENDENT au lieu de se superposer.
#   - with-test-slot.sh (fd 8) MACHINE  : borne le NOMBRE de runs concurrents
#     tous projets/worktrees confondus. C'est cette couche-là qui empêche l'OOM
#     quand wasreal teste en même temps.
#
# USAGE :
#   scripts/run-full-suite.sh              # tout
#   scripts/run-full-suite.sh --no-format  # saute l'étape formatage
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SKIP_FORMAT=0
[[ "${1:-}" == "--no-format" ]] && SKIP_FORMAT=1

# --- Couche 1 : verrou exclusif par projet (fd 9, cf. with-test-slot.sh) ------
LOCK=/tmp/guess-it-all-full-suite.lock
exec 9>"$LOCK"
if ! flock --nonblock 9; then
  echo "[full-suite] une autre suite complète tourne sur ce dépôt — attente…" >&2
  flock 9
fi

# --- Couche 2 : place machine-globale ----------------------------------------
# Ré-exec sous le sémaphore si on n'y est pas déjà (garde anti-boucle).
if [[ "${GIA_IN_TEST_SLOT:-0}" != "1" ]]; then
  export GIA_IN_TEST_SLOT=1
  exec scripts/with-test-slot.sh "$0" "$@"
fi

fail() { echo ""; echo "❌ [full-suite] ÉCHEC à l'étape : $1"; exit 1; }

if [[ "$SKIP_FORMAT" == "0" ]]; then
  echo "▶ [1/3] dart format --set-exit-if-changed"
  dart format --set-exit-if-changed lib test tools || fail "dart format (lance \`dart format lib test tools\`)"
else
  echo "⏭  [1/3] format sauté (--no-format)"
fi

echo "▶ [2/3] flutter analyze"
flutter analyze || fail "flutter analyze"

echo "▶ [3/3] flutter test"
flutter test || fail "flutter test"

echo ""
echo "✅ [full-suite] tout est vert."
