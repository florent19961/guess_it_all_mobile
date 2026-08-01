#!/usr/bin/env bash
# Sémaphore de places pour les runs de TESTS, partagé par toutes les sessions et
# tous les worktrees de la machine.
#
# POURQUOI — la contrainte de cette machine est la RAM, pas le CPU : 16 vCPU
# pour ~7 Go (WSL2, ~5 Go réellement disponibles). Un run `flutter test` ou
# `flutter analyze` fait tourner un analysis server Dart + une VM ; deux ou trois
# en parallèle (souvent depuis des projets DIFFÉRENTS) s'additionnent jusqu'à
# l'OOM — et c'est la MACHINE qui tombe, pas un test qui rougit.
#
# CE QUE ÇA FAIT — au-delà de N runs simultanés, le suivant ATTEND au lieu de se
# superposer. La garantie est tenue par construction, pas par la vigilance de
# chaque session.
#
# 🔴 SLOT_DIR EST VOLONTAIREMENT PARTAGÉ AVEC WASREAL (/tmp/wasreal-test-slots).
# Le budget est celui de la MACHINE, pas celui d'un projet. Donner à guess-it-all
# ses propres places rétablirait exactement le scénario qui a fait tomber la
# machine : deux projets qui se croient seuls et additionnent leurs runs. Ne pas
# « nettoyer » ce nom en un chemin propre à ce dépôt sans changer les DEUX côtés.
#
# USAGE (depuis n'importe quel worktree) :
#   scripts/with-test-slot.sh flutter test
#   scripts/with-test-slot.sh flutter analyze
#   GIA_TEST_SLOTS=2 scripts/with-test-slot.sh <cmd>     # override ponctuel
#
# `run-full-suite.sh` prend une place lui aussi.
#
# ROBUSTESSE — les verrous sont des `flock` sur descripteurs : si un run est tué
# (OOM, Ctrl-C, agent qui meurt), le noyau libère la place à la fermeture du
# descripteur. Aucun verrou fantôme à nettoyer à la main.
set -euo pipefail

SLOTS="${GIA_TEST_SLOTS:-${WASREAL_TEST_SLOTS:-3}}"
SLOT_DIR=/tmp/wasreal-test-slots
mkdir -p "$SLOT_DIR"

if [ "$#" -eq 0 ]; then
  echo "[with-test-slot] usage: $0 <commande...>" >&2
  exit 64
fi

waited=0
while true; do
  for i in $(seq 1 "$SLOTS"); do
    # ⚠️ fd NUMÉRIQUE explicite, jamais la forme `{var}>` : bash marque les
    # descripteurs auto-alloués close-on-exec, ils seraient donc refermés par le
    # `exec` final — le verrou serait relâché AVANT même que la commande démarre,
    # et le sémaphore ne régulerait rien tout en ayant l'air de fonctionner.
    # fd 8 et NON 9 : `run-full-suite.sh` tient son verrou exclusif projet sur le
    # fd 9 puis nous `exec`. Réutiliser 9 ici le refermerait — deux suites
    # complètes pourraient se superposer alors que tout a l'air correct.
    exec 8>"$SLOT_DIR/slot.$i"
    if flock --nonblock 8; then
      exec "$@"
    fi
  done
  if [ "$waited" -eq 0 ]; then
    echo "[with-test-slot] $SLOTS places occupées — attente d'une place libre…" >&2
    waited=1
  fi
  sleep 2
done
