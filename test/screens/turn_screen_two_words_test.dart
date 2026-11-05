import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/turn_screen.dart';
import 'package:guess_it_all_mobile/widgets/common/turn_play_widgets.dart';
import 'package:guess_it_all_mobile/widgets/fiesta/fiesta_turn_widgets.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

const _bonuses = ['two_words', 'double_points', 'free_pass'];

/// Les vraies polices : Ahem (police de test) fait 1 em par caractère, ses
/// mesures de largeur n'auraient rien à voir avec l'écran.
Future<void> _loadRealFonts() async {
  const fonts = {
    'Bangers': ['Bangers-Regular'],
    'Poppins': ['Poppins-Regular', 'Poppins-SemiBold', 'Poppins-Bold'],
  };
  for (final MapEntry(key: family, value: files) in fonts.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await loader.load();
  }
}

/// Tour « Deux mots » : deux mots longs, et les badges des trois bonus allumés.
Future<GameProvider> _givenLongTwoWordsTurn(WidgetTester tester) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() async {
    await pumpEventQueue();
    for (final name in ['A', 'B', 'C', 'D']) {
      final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, [
        'Anticonstitutionnellement $name',
        'Électroencéphalogramme $name',
        'Oto-rhino-laryngologiste $name',
      ]);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await provider.startGame(
      fiesta: FiestaRules(
        drawCount: 0,
        modifiers: {
          for (final id in _bonuses) id: ModifierSetting(charges: 1),
        },
      ),
    );
  });
  _bonuses.forEach(provider.toggleBonus);
  provider.startTurn();
  provider.startTurnTimer();
  return provider;
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets(
        'Deux mots ${size.width.toInt()}×${size.height.toInt()} : sans carte '
        'ni défilement, rien de coupé ni sous « terminer le tour »',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(_loadRealFonts);
      final provider = await _givenLongTwoWordsTurn(tester);
      expect(provider.secondWord, isNotNull);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: provider,
          child: const MaterialApp(home: TurnScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Un débordement de `RenderFlex` lève ici.
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.textContaining('MOT '), findsNothing);
      expect(find.text(provider.game.currentWord!), findsOneWidget);
      expect(find.text(provider.secondWord!), findsOneWidget);

      final buttons = find.byType(TurnActionButtons);
      expect(buttons, findsNWidgets(2));
      for (final rect in [buttons.first, buttons.last].map(tester.getRect)) {
        expect(rect.height, kCompactTurnButtonsHeight);
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      final endTurn = tester.getRect(find
          .ancestor(
              of: find.byIcon(Icons.fast_forward),
              matching: find.byType(Container))
          .first);
      final remaining = tester.getRect(find.textContaining('restant'));
      expect(tester.getRect(buttons.last).bottom,
          lessThanOrEqualTo(remaining.top));
      expect(remaining.bottom, lessThanOrEqualTo(endTurn.top));

      // Les boutons de la 2ᵉ paire visent bien le 2ᵉ mot.
      final second = provider.secondWord!;
      await tester.tap(find.descendant(
          of: buttons.last, matching: find.byIcon(Icons.check)));
      expect(provider.game.wordsGuessedThisTurn, [second]);

      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Au dernier mot, une seule paire de boutons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TwoWordsLayout(firstWord: 'Dernier')),
    );
    expect(find.byType(FiestaWordCard), findsOneWidget);
    expect(find.byType(TurnActionButtons), findsOneWidget);
  });
}
