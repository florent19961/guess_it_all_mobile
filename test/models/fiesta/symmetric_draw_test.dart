import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';

ModifierSetting setting(ModifierArrival arrival,
        {int startRound = 1, int? fixedRound}) =>
    ModifierSetting(
      active: true,
      arrival: arrival,
      startRound: startRound,
      fixedRound: fixedRound,
      charges: 0,
    );

/// Personnalisé : tout le catalogue en « tiré pour tous » dès M1, sauf
/// `no_pass` fixé sur [fixedNoPassRound] s'il est donné.
FiestaRules customAllDraw({int drawCount = 2, int? fixedNoPassRound}) =>
    FiestaRules(
      mode: FiestaMode.custom,
      drawCount: drawCount,
      modifiers: {
        for (final def in kModifierCatalog)
          // `block_guesser` (cible joueur) fixé lui aussi : ne doit jamais sortir.
          def.id: (def.id == 'no_pass' || def.id == 'block_guesser') &&
                  fixedNoPassRound != null
              ? setting(ModifierArrival.fixed, fixedRound: fixedNoPassRound)
              : setting(ModifierArrival.draw),
      },
    );

final gameIds = List.generate(200, (i) => 'game-$i');

void main() {
  final configs = <String, FiestaRules Function(int round)>{
    'Auto': (_) => FiestaRules(mode: FiestaMode.auto),
    'Personnalisé, tirage 2': (_) => customAllDraw(),
    'Personnalisé, tirage 2 + fixé': (round) =>
        customAllDraw(fixedNoPassRound: round),
  };

  test(
      'pour toute config, manche et graine : plafond de 2, aucune paire '
      'incompatible, rien de « manche 3 » avant M3, résultat déterministe', () {
    configs.forEach((label, rulesFor) {
      for (final round in [1, 2, 3]) {
        for (final gameId in gameIds) {
          final rules = rulesFor(round);
          final mods = roundModifiers(rules, gameId: gameId, round: round);
          final ids = mods.map((m) => m.catalogId).toList();
          final why = '$label, M$round, $gameId : $ids';

          expect(ids.length, lessThanOrEqualTo(2), reason: why);
          expect(ids, isNot(contains('block_guesser')), reason: why);
          expect(ids.toSet().length, ids.length, reason: why);
          for (var i = 0; i < ids.length; i++) {
            for (var j = i + 1; j < ids.length; j++) {
              expect(areCompatible(ids[i], ids[j]), isTrue, reason: why);
            }
          }
          if (label.endsWith('fixé')) {
            expect(ids.first, 'no_pass', reason: why);
          }
          if (round < 3) {
            expect(ids.where((id) => modifierById(id)!.round3Only), isEmpty,
                reason: why);
          }
          // Même graine (retour arrière, app tuée) = même tirage.
          final again = roundModifiers(rules, gameId: gameId, round: round)
              .map((m) => m.catalogId)
              .toList();
          expect(again, ids, reason: why);
        }
      }
    });
  });

  test('Auto : 1 ou 2 tirés, les deux cas arrivent', () {
    final counts = gameIds
        .map((id) => roundModifiers(FiestaRules(mode: FiestaMode.auto),
                gameId: id, round: 1)
            .length)
        .toSet();
    expect(counts, {1, 2});
  });

  test(
      'Personnalisé : tirage à 0 = rien ; seuls les « tiré pour tous » '
      'dont la manche de départ est atteinte sortent', () {
    expect(
      roundModifiers(customAllDraw(drawCount: 0), gameId: 'g', round: 1),
      isEmpty,
    );
    expect(
      roundModifiers(FiestaRules(mode: FiestaMode.auto, symmetric: false),
          gameId: 'g', round: 1),
      isEmpty,
    );

    final rules = FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 2,
      modifiers: {
        'reversed': setting(ModifierArrival.draw, startRound: 2),
        'minus_10s': setting(ModifierArrival.draw),
        'free_pass': setting(ModifierArrival.offer),
      },
    );
    for (final gameId in gameIds) {
      expect(
        roundModifiers(rules, gameId: gameId, round: 1).map((m) => m.catalogId),
        ['minus_10s'],
      );
      expect(
        roundModifiers(rules, gameId: gameId, round: 2)
            .map((m) => m.catalogId)
            .toSet(),
        {'minus_10s', 'reversed'},
      );
    }
  });
}
