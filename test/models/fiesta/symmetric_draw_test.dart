import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/round_transition.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';

ModifierSetting setting(ModifierMode mode,
        {Set<int> rounds = const {1, 2, 3},
        int charges = 1,
        bool perGame = false}) =>
    ModifierSetting(
      active: true,
      rounds: rounds,
      mode: mode,
      charges: charges,
      perGame: perGame,
    );

/// Personnalisé : tout le catalogue « Au tirage » sur toutes les manches
/// (les contraintes de manche du catalogue filtrent), sauf `no_pass`
/// « Toujours » si [alwaysNoPass].
FiestaRules customAllDraw({int drawCount = 2, bool alwaysNoPass = false}) =>
    FiestaRules(
      mode: FiestaMode.custom,
      drawCount: drawCount,
      modifiers: {
        for (final def in kModifierCatalog)
          def.id: setting(def.id == 'no_pass' && alwaysNoPass
              ? ModifierMode.always
              : ModifierMode.draw),
      },
    );

final gameIds = List.generate(200, (i) => 'game-$i');

void main() {
  final configs = <String, FiestaRules>{
    'Auto': autoRules(oneAnswer: false),
    'Personnalisé, tirage 2': customAllDraw(),
    'Personnalisé, tirage 5': customAllDraw(drawCount: 5),
    'Personnalisé, tirage 5 + Toujours': customAllDraw(
      drawCount: 5,
      alwaysNoPass: true,
    ),
  };

  test(
      'pour toute config, manche et graine : au plus drawCount tirés (sans '
      'plafond), aucune paire incompatible, au plus un de la famille « Mime », '
      'jamais une exception cartouche, rien de « manche 3 » avant M3 ni de '
      '« pas en M3 » en M3, résultat déterministe', () {
    final seen = <String, Set<int>>{};
    configs.forEach((label, rules) {
      for (final round in [1, 2, 3]) {
        for (final gameId in gameIds) {
          final mods = roundModifiers(rules, gameId: gameId, round: round);
          final ids = mods.map((m) => m.catalogId).toList();
          final why = '$label, M$round, $gameId : $ids';

          final always = label.endsWith('Toujours') ? 1 : 0;
          final max = label == 'Auto' ? 2 : rules.drawCount;
          expect(ids.length, lessThanOrEqualTo(max + always), reason: why);
          (seen[label] ??= {}).add(ids.length);
          expect(ids.where((id) => modifierById(id)!.mimeFamily).length,
              lessThanOrEqualTo(1),
              reason: why);
          expect(ids.where(kCartridgeOnlyIds.contains), isEmpty, reason: why);
          expect(ids.toSet().length, ids.length, reason: why);
          for (var i = 0; i < ids.length; i++) {
            for (var j = i + 1; j < ids.length; j++) {
              expect(areCompatible(ids[i], ids[j]), isTrue, reason: why);
            }
          }
          if (always == 1) expect(ids.first, 'no_pass', reason: why);
          if (round < 3) {
            expect(ids.where((id) => modifierById(id)!.round3Only), isEmpty,
                reason: why);
          } else {
            expect(ids.where((id) => modifierById(id)!.notInRound3), isEmpty,
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
    // Plus de plafond de 3 : un tirage de 5 en sort 5 (sinon le test ne
    // prouve rien).
    expect(seen['Personnalisé, tirage 5'], contains(5));
    expect(seen['Auto'], {1, 2});
  });

  test(
      'tirage figé : une graine donne toujours les mêmes ids (une mise à jour '
      'qui changerait l\'ordre des candidats changerait les tirages)', () {
    expect(
      roundModifiers(customAllDraw(), gameId: 'game-0', round: 1)
          .map((m) => m.catalogId),
      ['one_answer', 'minus_10s'],
    );
  });

  test('M3 : « Dessiner » Toujours, mimes au tirage → aucun autre mime ne sort',
      () {
    final rules = FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 3,
      modifiers: {
        'draw': setting(ModifierMode.always, rounds: {3}),
        for (final def in kModifierCatalog.where((d) => d.mimeFamily))
          if (def.id != 'draw') def.id: setting(ModifierMode.draw, rounds: {3}),
      },
    );
    for (final gameId in gameIds) {
      expect(
        roundModifiers(rules, gameId: gameId, round: 3).map((m) => m.catalogId),
        ['draw'],
      );
    }
  });

  test(
      '« Une seule réponse » en Auto : déterministe par partie, environ 1 '
      'fois sur 4 ; tirée = « Toujours » M1-M3, sinon jamais', () {
    // Graine figée (« manche 0 », distincte des manches 1 à 3) : une app mise
    // à jour retrouve le même tirage pour une partie suspendue.
    expect(drawSeed('game-0', 0), 2787898305);
    expect(drawSeed('game-1', 0), 286747006);
    expect([
      for (var i = 0; i < 12; i++) drawsOneAnswer('game-$i')
    ], [
      true,
      false,
      false,
      true,
      false,
      false,
      false,
      false,
      true,
      false,
      false,
      false
    ]);
    final drawn = gameIds.where(drawsOneAnswer).length;
    expect(drawn, inInclusiveRange(35, 65)); // 200 parties, attendu 50

    for (final round in [1, 2, 3]) {
      expect(
        roundModifiers(autoRules(oneAnswer: true), gameId: 'g', round: round)
            .first
            .catalogId,
        'one_answer',
      );
      for (final gameId in gameIds) {
        expect(
          roundModifiers(autoRules(oneAnswer: false),
                  gameId: gameId, round: round)
              .map((m) => m.catalogId),
          isNot(contains('one_answer')),
        );
      }
    }
  });

  test(
      'Personnalisé : tirage à 0 = rien ; seuls les « Au tirage » cochés sur '
      'la manche sortent', () {
    expect(
      roundModifiers(customAllDraw(drawCount: 0), gameId: 'g', round: 1),
      isEmpty,
    );
    final rules = FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 2,
      modifiers: {
        'reversed': setting(ModifierMode.draw, rounds: {2, 3}),
        'minus_10s': setting(ModifierMode.draw),
        'free_pass': setting(ModifierMode.offer),
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

  test(
      'En stock : une instance par équipe sur les manches cochées, malus en '
      'réserve (sans effet, lane 2) ; « pour la partie » = N moins ce qui '
      'est déjà dépensé, Passe gratuite comprise (lane 2)', () {
    final rules = FiestaRules(
      mode: FiestaMode.custom,
      modifiers: {
        'double_points':
            setting(ModifierMode.stock, rounds: {1, 3}, charges: 2),
        'two_words': setting(ModifierMode.stock, charges: 2, perGame: true),
        'minus_10s': setting(ModifierMode.stock, rounds: {1}, charges: 2),
        'free_pass':
            setting(ModifierMode.stock, rounds: {2}, charges: 3, perGame: true),
      },
    );
    Map<String, int> stock(int round, [List<ChargeUse> used = const []]) => {
          for (final m in stockForRound(rules,
              round: round, teamIds: ['a', 'b'], chargesUsed: used))
            if (m.catalogId != 'minus_10s' && m.catalogId != 'free_pass')
              '${m.catalogId}/${m.teamId}': m.charges,
        };

    expect(stock(1), {
      'double_points/a': 2,
      'double_points/b': 2,
      'two_words/a': 2,
      'two_words/b': 2,
    });
    // Malus en réserve : persistés pour chaque équipe, sans effet en jeu.
    final malus = stockForRound(rules, round: 1, teamIds: ['a', 'b'])
        .where((m) => m.catalogId == 'minus_10s')
        .toList();
    expect(malus.map((m) => (m.teamId, m.charges, m.reserve)),
        [('a', 2, true), ('b', 2, true)]);
    expect(modifiersForTurn(malus, teamId: 'a', logicalRound: 1), isEmpty);
    // Passe gratuite « pour la partie » : 3 − 1 cartouche dépensée en M1.
    expect(
        stockForRound(rules, round: 2, teamIds: [
          'a'
        ], chargesUsed: [
          const ChargeUse(catalogId: 'free_pass', teamId: 'a', round: 1),
        ]).where((m) => m.catalogId == 'free_pass').single.charges,
        2);
    final used = [
      const ChargeUse(catalogId: 'two_words', teamId: 'a', round: 1),
      const ChargeUse(catalogId: 'two_words', teamId: 'a', round: 2),
      const ChargeUse(catalogId: 'double_points', teamId: 'a', round: 1),
    ];
    // M2 : pas de ×2 (manche non cochée) ; Deux mots « pour la partie » :
    // 2 − 1 dépensée en M1 pour a.
    expect(stock(2, used), {'two_words/a': 1, 'two_words/b': 2});
    // M3 : ×2 « par manche » revient à 2 ; Deux mots épuisé pour a.
    expect(stock(3, used),
        {'double_points/a': 2, 'double_points/b': 2, 'two_words/b': 2});
  });

  test(
      'Malus reçus résolus au tour de la cible : en double avec une règle de '
      'manche, ou incompatible avec un malus retenu avant lui (ordre '
      'd\'envoi), il est écarté', () {
    ModifierInstance sent(String id, String from) => ModifierInstance(
          catalogId: id,
          scope: ModifierScope.turn,
          target: ModifierTarget.team,
          teamId: 'b',
          charges: 0,
          nature: ModifierNature.malus,
          round: 3,
          fromTeamId: from,
        );
    final rule = ModifierInstance(
      catalogId: 'minus_10s',
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: ModifierNature.malus,
      round: 3,
    );
    final kept = modifiersForTurn([
      rule,
      sent('minus_10s', 'a'), // doublon de la règle
      sent('mime_no_arms', 'a'),
      sent('draw', 'c'), // second mime : incompatible
      sent('reversed', 'c'),
    ], teamId: 'b', logicalRound: 3);
    expect(kept.map((m) => '${m.catalogId}<${m.fromTeamId}'),
        ['minus_10s<null', 'mime_no_arms<a', 'reversed<c']);
  });
}
