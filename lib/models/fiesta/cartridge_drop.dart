import 'dart:math';

import 'cartridge_gifts.dart';
import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'symmetric_draw.dart';

/// Cartouches qui tombent pendant les tours (D4 des retours du 2026-11-15) :
/// au début d'un tour joué, selon `FiestaRules.dropFrequency`, une cartouche au
/// hasard tombe sur l'équipe qui joue, pour ce tour seulement, sans choix.
///
/// Tout est pur et DÉTERMINISTE par `(gameId, tour, joueur qui fait deviner,
/// tours sautés de son équipe)` : un retour arrière ou une app tuée retrouvent
/// la même cartouche, et le remplaçant d'un joueur qui saute son tour a son
/// propre tirage.

/// La cartouche tombée sur un tour.
class CartridgeDrop {
  final String catalogId;

  /// Devineur bloqué, seulement pour `block_guesser`.
  final String? blockedPlayerId;

  const CartridgeDrop(this.catalogId, {this.blockedPlayerId});

  /// Forme persistée dans `FiestaTurnState` (clé `drop`) : `{catalogId,
  /// blockedPlayer?}`.
  Map<String, dynamic> toJson() => {
        'catalogId': catalogId,
        if (blockedPlayerId != null) 'blockedPlayer': blockedPlayerId,
      };

  /// `null` si illisible ou d'id inconnu : la cartouche est perdue seule, le
  /// tour se relit.
  static CartridgeDrop? tryFromJson(Map<String, dynamic> json) {
    final id = json['catalogId'];
    final blocked = json['blockedPlayer'];
    if (id is! String || modifierById(id) == null || blocked is! String?) {
      return null;
    }
    return CartridgeDrop(id, blockedPlayerId: blocked);
  }
}

/// Le malus tombé [drop] tel qu'il pèse sur le tour de [giverId] (équipe
/// [teamId]) en manche [round], ou `null` : un bonus (il joue comme une charge
/// dépensée), « Interdit de faire deviner » (le piège, il ne pèse sur aucun
/// tour) ou un malus perdu comme le serait un malus reçu (`modifiersForTurn`) :
/// impossible dans la manche, identique ou incompatible avec ce qui pèse déjà
/// ([weighing]). Ne peut arriver que sur la continuation en N+1 : au tirage, le
/// vivier ([dropPool]) a déjà tout écarté.
ModifierInstance? droppedMalus(
  CartridgeDrop drop, {
  required String teamId,
  required String? giverId,
  required int round,
  required List<ModifierInstance> weighing,
}) {
  final def = modifierById(drop.catalogId)!;
  if (def.nature != ModifierNature.malus ||
      def.id == 'block_giver' ||
      !isEligibleForRound(def, round) ||
      weighing.any((w) => w.catalogId == def.id) ||
      !weighing.every((w) => areCompatible(w.catalogId, def.id))) {
    return null;
  }
  return ModifierInstance(
    catalogId: def.id,
    scope: ModifierScope.turn,
    target: ModifierTarget.player,
    teamId: teamId,
    playerId: drop.blockedPlayerId ?? giverId,
    charges: 1,
    nature: ModifierNature.malus,
    round: round,
  );
}

/// Graine d'un tour : chaîne `gameId#drop#giverId#skips#turnIndex`, distincte
/// de celles du tirage de manche et des cartouches au hasard ([drawSeed]).
///
/// [skips] (`FiestaState.skips` de l'équipe qui joue) : un saut ne fait pas
/// avancer `currentTurnIndex`. Sans lui, dans une équipe de 2, A saute, B
/// saute, A revient avec la même graine, retombe sur « Interdit de faire
/// deviner », et ainsi de suite sans fin.
int dropSeed(String gameId, int turnIndex, String giverId, int skips) =>
    drawSeed('$gameId#drop#$giverId#$skips', turnIndex);

/// Vivier d'une cartouche qui tombe, dans l'ordre du catalogue : celui des
/// cartouches au hasard ([randomPool] : hors Toujours, possible en manche
/// [round], ni identique ni incompatible avec [roundRules], ×2 seulement au-delà
/// de [kDoublePointsMinGap] d'écart [gap]), moins ce qui est identique ou
/// incompatible avec un malus [received] qui joue ce tour, ou identique à un
/// bonus [armed]. « Bloquer un devineur » seulement si l'équipe qui joue a au
/// moins 3 joueurs (au moins 2 [guesserIds]).
List<ModifierDef> dropPool({
  required FiestaRules rules,
  required int round,
  required List<ModifierInstance> roundRules,
  required Iterable<String> received,
  required Iterable<String> armed,
  required List<String> guesserIds,
  required int gap,
}) =>
    [
      for (final def in randomPool(
        rules: rules,
        round: round,
        roundRules: roundRules,
        gap: gap,
        includeBlockGuesser: guesserIds.length >= 2,
      ))
        if (received.every((id) => id != def.id && areCompatible(id, def.id)) &&
            !armed.contains(def.id))
          def,
    ];

/// La cartouche qui tombe sur le tour [turnIndex] (`GameState.currentTurnIndex`)
/// de [giverId], ou `null` :
/// réglage à Jamais, tour de continuation ([continuation] : temps reporté de fin
/// de manche), tirage manqué ou vivier vide ([dropPool]). Une seule graine
/// ([dropSeed]) : d'abord la chance du réglage, puis la cartouche (toutes avec
/// la même chance, [drawGift]), puis pour `block_guesser` le devineur bloqué
/// parmi [guesserIds] (dans l'ordre de l'équipe : le tirage en dépend).
/// [roundRules] : TOUTES les règles de la manche (`roundModifiers`, Toujours
/// compris) ; c'est d'elles que vient l'incompatibilité avec un Toujours.
///
/// 🔴 Mêmes entrées, même sortie : l'appelant l'appelle à un moment fixe du
/// tour (après les bonus armés et les malus résolus), ou stocke le résultat.
CartridgeDrop? dropForTurn({
  required FiestaRules rules,
  required String gameId,
  required int turnIndex,
  required String giverId,
  required int skips,
  required int round,
  required List<ModifierInstance> roundRules,
  required Iterable<String> received,
  required Iterable<String> armed,
  required List<String> guesserIds,
  required int gap,
  required bool continuation,
}) {
  final chance = rules.dropFrequency.chance;
  if (chance <= 0 || continuation) return null;
  final random = Random(dropSeed(gameId, turnIndex, giverId, skips));
  if (random.nextDouble() >= chance) return null;
  final pool = dropPool(
    rules: rules,
    round: round,
    roundRules: roundRules,
    received: received,
    armed: armed,
    guesserIds: guesserIds,
    gap: gap,
  );
  if (pool.isEmpty) return null;
  final drawn = drawGift(pool, random);
  return CartridgeDrop(
    drawn.id,
    blockedPlayerId: drawn.id == 'block_guesser'
        ? guesserIds[random.nextInt(guesserIds.length)]
        : null,
  );
}
