import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/game_settings.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

void main() {
  group('GameSettings — sérialisation', () {
    test('un aller-retour JSON préserve TOUS les champs', () {
      final original = GameSettings(
        numberOfTeams: 4,
        numberOfPlayers: 12,
        wordChoice: AppConstants.wordChoiceCustom,
        totalWords: 80,
        turnDuration: 45,
        passPenalty: 3,
        selectedCategories: const ['musique', 'marques'],
        selectedDifficultyLevels: const [2, 3, 4],
      );

      final restored = GameSettings.fromJson(original.toJson());

      // Assertion dérivée du JSON plutôt qu'énumérée champ par champ : si un
      // champ est ajouté au modèle sans être ajouté à toJson/fromJson, ce test
      // tombe. Une liste écrite à la main, elle, resterait verte.
      expect(restored.toJson(), equals(original.toJson()));
    });

    test('un JSON vide rend les valeurs par défaut, sans lever', () {
      final settings = GameSettings.fromJson(const {});

      expect(settings.numberOfTeams, AppConstants.defaultNumberOfTeams);
      expect(settings.numberOfPlayers, AppConstants.defaultNumberOfPlayers);
      expect(settings.totalWords, AppConstants.defaultTotalWords);
      expect(settings.turnDuration, AppConstants.defaultTurnDuration);
      expect(settings.passPenalty, AppConstants.defaultPassPenalty);
      expect(settings.selectedCategories, AppConstants.defaultCategories);
      expect(settings.selectedDifficultyLevels, AppConstants.defaultDifficultyLevels);
    });

    test('un JSON partiel ne perd que les champs absents', () {
      final settings = GameSettings.fromJson(const {'turnDuration': 60});

      expect(settings.turnDuration, 60, reason: 'le champ fourni est lu');
      expect(settings.passPenalty, AppConstants.defaultPassPenalty,
          reason: 'les champs absents retombent sur le défaut');
    });
  });

  group('GameSettings — copyWith', () {
    test('ne modifie que le champ demandé', () {
      final base = GameSettings.fromJson(const {});
      final copy = base.copyWith(turnDuration: 50);

      expect(copy.turnDuration, 50);
      expect(copy.passPenalty, base.passPenalty);
      expect(copy.totalWords, base.totalWords);
      expect(copy.selectedCategories, base.selectedCategories);
    });

    test('copie les listes au lieu de les partager', () {
      // Sans cette copie, muter la liste d'une copie muterait aussi l'original :
      // les settings sont partagés entre l'écran de réglages et la partie en cours.
      final base = GameSettings(selectedCategories: ['musique']);
      final copy = base.copyWith();

      copy.selectedCategories.add('marques');

      expect(base.selectedCategories, ['musique'],
          reason: 'la liste de l\'original ne doit pas suivre celle de la copie');
    });
  });
}
