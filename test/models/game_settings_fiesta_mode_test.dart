import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/game_settings.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/settings_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

void main() {
  test('clé absente ou valeur inconnue → Auto', () {
    expect(GameSettings.fromJson(const {}).fiestaMode, FiestaMode.auto);
    expect(GameSettings.fromJson(const {'fiestaMode': 'x'}).fiestaMode,
        FiestaMode.auto);
    expect(GameSettings.fromJson(const {'fiestaMode': 3}).fiestaMode,
        FiestaMode.auto);
  });

  test('Personnalisé survit à la fin de partie et à l\'app tuée', () async {
    await givenPrefs();
    final provider = GameProvider();
    await pumpEventQueue();
    provider.updateSettings(fiestaMode: FiestaMode.custom);
    await provider.startNewGame();
    expect(provider.settings.fiestaMode, FiestaMode.custom);

    // « App tuée » : un nouveau provider relit ce qui a été écrit.
    final reread = GameProvider();
    await pumpEventQueue();
    expect(reread.settings.fiestaMode, FiestaMode.custom);
  });

  testWidgets('passer en Fiesta part sur le mode sauvegardé', (tester) async {
    await givenPrefs(const {'guessItAll_fiestaTutorialSeen': true});
    final provider = GameProvider();
    await tester.runAsync(() => pumpEventQueue());
    provider.updateSettings(fiestaMode: FiestaMode.custom);
    expect(provider.pendingFiesta, isNull);

    await tester.pumpWidget(
      ChangeNotifierProvider<GameProvider>.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Fiesta'));
    await tester.pump();

    expect(provider.pendingFiesta?.mode, FiestaMode.custom);
    await tester.pumpWidget(const SizedBox());
  });
}
