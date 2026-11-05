import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
      bool underWord = false,
      bool second = false,
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
          buttonsUnderWord: underWord,
          secondWordShown: second,
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

    test('Deux mots, puis dernière carte seule : les boutons sont expliqués',
        () {
      expect(titled(steps(underWord: true, second: true), 'Les deux mots').text,
          contains('Chacun a ses boutons'));
      expect(
          titled(steps(underWord: true), 'Le mot').text, contains('dessous'));
    });
  });
}
