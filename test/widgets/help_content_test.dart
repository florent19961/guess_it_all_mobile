import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/widgets/help/help_content.dart';

void main() {
  test('pénalité de passe : 0 s ne coûte rien, sinon le chrono perd n s', () {
    expect(passPenaltySentence(0), 'Passer ne coûte rien.');
    expect(passPenaltySentence(3), 'Le chrono perd 3 s.');
    expect(passPenaltySentence(5), 'Le chrono perd 5 s.');
  });
}
