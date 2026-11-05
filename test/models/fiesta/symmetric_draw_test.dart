import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/round_transition.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';

ModifierSetting setting(ModifierMode mode,
        {Set<int> rounds = const {1, 2, 3}}) =>
    ModifierSetting(active: true, rounds: rounds, mode: mode);

/// Personnalisé : tout le catalogue « Au tirage » sur toutes les manches (les
/// contraintes de manche du catalogue filtrent, le mode Cartouche seule exclut
/// les cartouches seulement), sauf `no_pass` « Toujours » si [alwaysNoPass].
FiestaRules customAllDraw({int drawCount = 2, bool alwaysNoPass = false}) =>
    FiestaRules(
      mode: FiestaMode.custom,
      drawCount: drawCount,
      modifiers: {
        for (final def in kModifierCatalog)
          if (canBeRoundRule(def))
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
    // Pas de plafond : un tirage de 5 sort tout ce qui peut l'être, 4 depuis que
    // bonus et −10 s ne sont plus que des cartouches (sinon le test ne prouve
    // rien).
    expect(seen['Personnalisé, tirage 5'], contains(4));
    expect(seen['Auto'], {1, 2});
  });

  test(
      'tirage figé : une graine donne toujours les mêmes ids (une mise à jour '
      'qui changerait l\'ordre des candidats changerait les tirages)', () {
    expect(
      roundModifiers(customAllDraw(), gameId: 'game-0', round: 1)
          .map((m) => m.catalogId),
      ['other_language', 'no_pass'],
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
        'no_pass': setting(ModifierMode.draw),
        'free_pass': setting(ModifierMode.cartridge),
      },
    );
    for (final gameId in gameIds) {
      expect(
        roundModifiers(rules, gameId: gameId, round: 1).map((m) => m.catalogId),
        ['no_pass'],
      );
      expect(
        roundModifiers(rules, gameId: gameId, round: 2)
            .map((m) => m.catalogId)
            .toSet(),
        {'no_pass', 'reversed'},
      );
    }
  });

  test(
      'Auto : le −10 s et les bonus (cartouches seulement) ne sont jamais '
      'tirés, ni par un blob qui les mettrait « Au tirage »', () {
    final forced =
        FiestaRules(mode: FiestaMode.custom, drawCount: 5, modifiers: {
      for (final id in kCartridgeOnlyIds) id: setting(ModifierMode.draw),
    });
    for (final gameId in gameIds) {
      for (final round in [1, 2, 3]) {
        final auto = roundModifiers(autoRules(oneAnswer: false),
                gameId: gameId, round: round)
            .map((m) => m.catalogId);
        expect(auto.where(kCartridgeOnlyIds.contains), isEmpty);
        expect(roundModifiers(forced, gameId: gameId, round: round), isEmpty);
      }
    }
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
      catalogId: 'no_pass',
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: ModifierNature.malus,
      round: 3,
    );
    final kept = modifiersForTurn([
      rule,
      sent('no_pass', 'a'), // doublon de la règle
      sent('mime_no_arms', 'a'),
      sent('draw', 'c'), // second mime : incompatible
      sent('reversed', 'c'),
    ], teamId: 'b', round: 3);
    expect(kept.map((m) => '${m.catalogId}<${m.fromTeamId}'),
        ['no_pass<null', 'mime_no_arms<a', 'reversed<c']);
  });
}
