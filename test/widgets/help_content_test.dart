import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/widgets/help/coach_marks.dart';
import 'package:guess_it_all_mobile/widgets/help/help_content.dart';

void main() {
  test('pénalité de passe : 0 s ne coûte rien, sinon le chrono perd n s', () {
    expect(passPenaltySentence(0), 'Passer ne coûte rien.');
    expect(passPenaltySentence(3), 'Le chrono perd 3 s.');
    expect(passPenaltySentence(5), 'Le chrono perd 5 s.');
  });

  group('turnHelp : les textes suivent l\'état du tour', () {
    List<CoachStep> steps({
      PassState pass = PassState.available,
      bool reversed = false,
    }) =>
        turnHelp(
          timer: GlobalKey(),
          modifiers: GlobalKey(),
          blockedGuesser: GlobalKey(),
          freePasses: GlobalKey(),
          word: GlobalKey(),
          guessed: GlobalKey(),
          pass: GlobalKey(),
          pause: GlobalKey(),
          endTurn: GlobalKey(),
          passPenalty: 5,
          passState: pass,
          reversed: reversed,
        );
    CoachStep titled(List<CoachStep> all, Pattern title) =>
        all.firstWhere((s) => s.title.startsWith(title));

    test('Passer : disponible, bloqué, dernier mot, pas assez de temps', () {
      expect(titled(steps(), 'Passer').text, contains('Le chrono perd 5 s.'));
      final blocked = titled(steps(pass: PassState.blocked), 'Passer');
      expect(blocked.title, 'Passer (bloqué)');
      expect(blocked.text, isNot(contains('Passe-le')));
      expect(titled(steps(pass: PassState.lastWord), 'Passer').text,
          contains('impossible'));
      expect(titled(steps(pass: PassState.notEnoughTime), 'Passer').text,
          contains('moins de temps'));
    });

    test('mot à l\'envers : dit seulement quand il l\'est', () {
      expect(titled(steps(), 'Le mot').text, isNot(contains('envers')));
      expect(titled(steps(reversed: true), 'Le mot').text, contains('envers'));
    });
  });

  group('Résultats et Historique : le texte suit ce qui est affiché', () {
    String statsText(bool played) => resultsHelp(
          podium: GlobalKey(),
          details: GlobalKey(),
          back: GlobalKey(),
          replay: GlobalKey(),
          stats: GlobalKey(),
          hasPlayedCartridges: played,
        ).last.text;

    test('Statistiques : les bonus et malus seulement s\'il y en a eu', () {
      expect(statsText(false), isNot(contains('bonus')));
      expect(statsText(true), contains('bonus et malus joués'));
      expect(statsText(false), contains('Cherry on the cake'));
    });

    List<CoachStep> history(
            {HistoryTrends stats = HistoryTrends.empty,
            bool hasPlayers = true,
            bool hasSetup = true}) =>
        historyHelp(
          trends: GlobalKey(),
          firstGame: GlobalKey(),
          replay: GlobalKey(),
          stats: stats,
          hasPlayers: hasPlayers,
          hasSetup: hasSetup,
        );

    test('Tendances : seules les lignes affichées, sur 10 parties au plus', () {
      final none = history().first.text;
      expect(none, contains('10 dernières parties'));
      expect(none, contains('Points par partie'));
      expect(none, isNot(contains('Meilleur score')));
      expect(none, isNot(contains('Victoires')));
      expect(none, isNot(contains('assidu')));
      final all = history(
        stats: const HistoryTrends(
          gamesPlayed: 1,
          averageScorePerGame: 20,
          bestScore: 12,
          bestScoreTeam: 'Rouge',
          winsByTeam: {'Rouge': 1},
          playerAppearances: [MapEntry('Ana', 1)],
        ),
      ).first.text;
      expect(
          all,
          allOf(contains('Meilleur score'), contains('Victoires'),
              contains('assidu')));
    });

    test('Rejouer : une ancienne archive ne promet pas les mêmes réglages', () {
      expect(history().last.text, contains('mêmes réglages'));
      final old = history(hasSetup: false).last.text;
      expect(old, isNot(contains('mêmes réglages')));
      expect(old, contains('en Classique'));
    });

    test('Une partie : les joueurs seulement s\'ils sont archivés', () {
      expect(history()[1].text, contains('leurs joueurs'));
      expect(
          history(hasPlayers: false)[1].text, isNot(contains('leurs joueurs')));
    });
  });
}
