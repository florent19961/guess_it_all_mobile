import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/utils/reversed_word.dart';

void main() {
  test('reversedWordDisplay : majuscules, chaîne entière, graphèmes intacts',
      () {
    expect(reversedWordDisplay('Titanic'), 'CINATIT');
    expect(reversedWordDisplay('Star Wars'), 'SRAW RATS');
    expect(reversedWordDisplay('Tour Eiffel'), 'LEFFIE RUOT');
    expect(reversedWordDisplay('Été'), 'ÉTÉ');
    // « é » en forme décomposée (e + accent combiné) : l'accent reste sur son E.
    expect(reversedWordDisplay('Crépe'), 'EPÉRC');
    expect(reversedWordDisplay('Chat 🐱'), '🐱 TAHC');
  });
}
