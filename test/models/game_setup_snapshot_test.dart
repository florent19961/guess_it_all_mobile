import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/game_settings.dart';
import 'package:guess_it_all_mobile/models/game_setup_snapshot.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

void main() {
  test('round-trip JSON : paramètres et règles Fiesta survivent', () {
    final snapshot = GameSetupSnapshot(
      settings: GameSettings(
        numberOfTeams: 3,
        numberOfPlayers: 6,
        wordChoice: AppConstants.wordChoiceCustom,
        totalWords: 42,
        turnDuration: 45,
        passPenalty: 2,
        selectedCategories: const ['animaux', 'films'],
        selectedDifficultyLevels: const [2, 3],
      ),
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        ensembleName: 'Soirée',
        modifiers: const {
          'no_pass': ModifierSetting(
            active: true,
            arrival: ModifierArrival.fixed,
            startRound: 1,
            fixedRound: 2,
            charges: 1,
          ),
        },
        drawCount: 2,
        oneAnswer: false,
      ),
    );

    // Passe par une vraie chaîne JSON, comme SharedPreferences.
    final back = GameSetupSnapshot.tryFromJson(
        jsonDecode(jsonEncode(snapshot.toJson())))!;

    expect(back.settings.toJson(), snapshot.settings.toJson());
    expect(back.fiesta!.toJson(), snapshot.fiesta!.toJson());
    expect(
      GameSetupSnapshot.tryFromJson(jsonDecode(jsonEncode(
              GameSetupSnapshot(settings: GameSettings()).toJson())))!
          .fiesta,
      isNull,
      reason: 'Classique : pas de clé fiesta, pas de règles relues',
    );
  });

  test('lecture tolérante : tout ce qui est illisible rend null', () {
    final okSettings = GameSettings().toJson();
    for (final raw in <Object?>[
      null,
      'pas un objet',
      <String, dynamic>{},
      {'settings': 'x'},
      {
        'settings': {...okSettings, 'totalWords': 'beaucoup'},
      },
      {
        'settings': {
          ...okSettings,
          'selectedCategories': [1, 2],
        },
      },
      // Bien typé mais injouable : hors bornes des curseurs, enum inconnu.
      for (final bad in <String, Object>{
        'totalWords': 101,
        'turnDuration': 0,
        'passPenalty': -1,
        'wordChoice': 'Inconnu',
        'selectedDifficultyLevels': [5],
        'selectedCategories': <String>[],
      }.entries)
        {
          'settings': {...okSettings, bad.key: bad.value},
        },
      {'settings': okSettings, 'fiesta': 'x'},
      {
        'settings': okSettings,
        'fiesta': {'mode': 'inconnu'},
      },
    ]) {
      expect(GameSetupSnapshot.tryFromJson(raw), isNull, reason: '$raw');
    }
  });
}
