import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:provider/provider.dart';

import '../helpers/coach_walk.dart';
import 'fiesta_v4_screens_test.dart'
    show finishRound, loadFonts, pumpGame, settle;

const _base = ['C\'est ton tour, ', 'La règle de la manche'];
const _start = 'Commencer le tour';

const _thisTurn = 'Actif pendant votre prochain tour';
const _rules = 'Règles de la manche';
const _received = 'Malus reçu';
const _armed = 'Bonus activé';
const _bonus = 'Réserve : tes bonus';
const _malus = 'Réserve : tes malus';
const _sent = 'Malus envoyés';
const _dimmed = 'Cartouche indisponible';

/// Titres d'étapes propres à ce qui est affiché, sans le socle commun.
Future<List<String>> fiestaSteps(WidgetTester tester) async {
  final titles = await walkHelp(tester);
  expect(titles.first, startsWith(_base[0]));
  expect(titles[1], _base[1]);
  expect(titles.last, _start, reason: 'l\'action finale, après ce qu\'on voit');
  return titles
      .sublist(2, titles.length - 1)
      .where((t) => !t.startsWith('Retour'))
      .toList();
}

/// Relit la partie sur disque, comme après un kill.
Future<GameProvider> pumpGameFrom(WidgetTester tester) async {
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
    value: provider,
    child: const GuessItAllApp(),
  ));
  await settle(tester);
  // L'intro de démarrage (au-dessus de tout) doit finir de s'effacer.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return provider;
}

void main() {
  setUpAll(loadFonts);

  testWidgets('Classique : ni bonus, ni malus, ni étape Fiesta',
      (tester) async {
    await pumpGame(tester, null);
    expect(await fiestaSteps(tester), isEmpty);
  });

  testWidgets('Fiesta sans rien d\'affiché : aucune étape Fiesta',
      (tester) async {
    await pumpGame(tester, FiestaRules(drawCount: 0));
    expect(find.text('Rien pour l\'instant.'), findsOneWidget);
    expect(await fiestaSteps(tester), isEmpty);
  });

  testWidgets('règle de manche seule : zone active + badge, pas de réserve',
      (tester) async {
    await pumpGame(
        tester,
        FiestaRules(drawCount: 0, modifiers: {
          'no_pass': const ModifierSetting(always: true),
        }));
    expect(await fiestaSteps(tester), [_thisTurn, _rules]);
  });

  testWidgets('cartouche de bonus seule : son étape, pas celle des malus',
      (tester) async {
    await pumpGame(
        tester,
        FiestaRules(drawCount: 0, modifiers: {
          'plus_10s': const ModifierSetting(charges: 1),
        }));
    expect(await fiestaSteps(tester), [_bonus]);
  });

  testWidgets('cartouche de malus seule : son étape, pas celle des bonus',
      (tester) async {
    await pumpGame(
        tester,
        FiestaRules(drawCount: 0, modifiers: {
          'no_pass': const ModifierSetting(charges: 1),
        }));
    expect(await fiestaSteps(tester), [_malus]);
  });

  testWidgets('bonus activé et malus envoyé : leurs étapes apparaissent',
      (tester) async {
    final provider = await pumpGame(
        tester,
        FiestaRules(drawCount: 0, modifiers: {
          'plus_10s': const ModifierSetting(charges: 1),
          'no_pass': const ModifierSetting(charges: 1),
        }));
    provider.toggleBonus('plus_10s');
    provider.inflictMalus('no_pass',
        provider.teams.firstWhere((t) => t != provider.getCurrentTeam()).id);
    await settle(tester);
    expect(await fiestaSteps(tester),
        [_thisTurn, _armed, _bonus, _malus, _dimmed, _sent]);
  });

  testWidgets('malus reçu : son étape', (tester) async {
    final provider = await pumpGame(tester, FiestaRules(drawCount: 0));
    final saved = (await tester.runAsync(StorageService().loadGameState))!;
    ((saved['game']['fiesta'] as Map)['active'] ??= []).add(ModifierInstance(
      catalogId: 'no_pass',
      scope: ModifierScope.turn,
      target: ModifierTarget.team,
      teamId: provider.getCurrentTeam()!.id,
      charges: 1,
      nature: modifierById('no_pass')!.nature,
      round: provider.game.currentRound,
      fromTeamId:
          provider.teams.firstWhere((t) => t != provider.getCurrentTeam()).id,
    ).toJson());
    await tester.runAsync(() => StorageService().saveGameState(saved));
    final reloaded = await pumpGameFrom(tester);
    expect(reloaded.receivedThisTurn, isNotEmpty);
    expect(await fiestaSteps(tester), [_thisTurn, _received]);
  });

  testWidgets('temps reporté : son étape, en Classique aussi', (tester) async {
    final provider = await pumpGame(tester, null);
    finishRound(provider);
    provider.nextRound();
    await settle(tester);
    expect(provider.game.turnBonusTime, isNotNull);
    expect(await walkHelp(tester), contains('Temps bonus'));
  });
}
