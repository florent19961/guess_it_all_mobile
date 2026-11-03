import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:guess_it_all_mobile/utils/team_names.dart';

void main() {
  test('noms d\'équipe : le bon nombre, distincts, jamais vides', () {
    expect(kFunnyTeamNames.toSet(), hasLength(kFunnyTeamNames.length));
    expect(kFunnyTeamNames.length, greaterThanOrEqualTo(AppConstants.maxTeams));
    for (var i = 0; i < 50; i++) {
      final names = drawTeamNames(AppConstants.maxTeams);
      expect(names, hasLength(AppConstants.maxTeams));
      expect(names.toSet(), hasLength(names.length));
      expect(names.every((n) => n.trim().isNotEmpty), isTrue);
    }
  });
}
