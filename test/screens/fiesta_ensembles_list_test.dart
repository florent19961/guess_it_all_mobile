import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensembles_screen.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';

import '../helpers/test_prefs.dart';
import 'fiesta_v4_screens_test.dart' show loadFonts, settle;

const _longName = 'Soirée interminable chez Maximilien et ses cousins';

Future<void> pumpList(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await givenPrefs({
    FiestaEnsembleService.storageKey: jsonEncode(wrapWithSchema({
      'ensembles': [
        FiestaEnsemble(id: 'mine', rules: FiestaRules(ensembleName: _longName))
            .toJson(),
      ],
    })),
  });
  await tester.pumpWidget(MaterialApp(
    home: FiestaEnsemblesScreen(onBack: () {}, onNext: (_) {}),
  ));
  await settle(tester);
}

Finder rowOf(String name) => find
    .ancestor(of: find.text(name), matching: find.byType(GestureDetector))
    .first;

void main() {
  setUpAll(loadFonts);

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    testWidgets(
        '${size.width.toInt()} px : chaque ensemble tient sur une ligne, icônes '
        '44 px avec libellé, aucun débordement', (tester) async {
      await pumpList(tester, size);

      expect(find.textContaining('Fourni par'), findsNothing);
      expect(find.textContaining('malus ·'), findsNothing);
      for (final label in ['Voir', 'Dupliquer', 'Modifier', 'Supprimer']) {
        expect(find.text(label), findsNothing, reason: 'icône seule');
      }

      // Ensemble fourni : le nom, Voir, Dupliquer, pas de badge.
      final provided = rowOf('Fiesta classique');
      expect(find.descendant(of: provided, matching: find.byType(IconButton)),
          findsNWidgets(2));
      expect(find.descendant(of: provided, matching: find.byTooltip('Voir')),
          findsOneWidget);
      expect(
          find.descendant(of: provided, matching: find.byTooltip('Dupliquer')),
          findsOneWidget);
      expect(find.descendant(of: provided, matching: find.text('Perso')),
          findsNothing);
      expect(tester.getSize(provided).height, lessThanOrEqualTo(64));

      await tester.scrollUntilVisible(find.text('Perso'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();

      // Ensemble personnel : les 4 actions et le badge.
      final mine = rowOf(_longName);
      for (final label in ['Voir', 'Modifier', 'Dupliquer', 'Supprimer']) {
        final icon = find.descendant(of: mine, matching: find.byTooltip(label));
        expect(icon, findsOneWidget);
        final box = tester.getSize(icon);
        expect(box.width, greaterThanOrEqualTo(44));
        expect(box.height, greaterThanOrEqualTo(44));
      }
      expect(tester.getSize(mine).height, lessThanOrEqualTo(64));
      final text = tester.widget<Text>(find.text(_longName));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull, reason: 'pas de débordement');
    });
  }

  testWidgets('un tap sur la ligne sélectionne, l\'icône ne sélectionne pas',
      (tester) async {
    await pumpList(tester, const Size(412, 915));
    bool selected(String name) => tester
        .widget<Semantics>(find
            .ancestor(of: find.text(name), matching: find.byType(Semantics))
            .first)
        .properties
        .selected!;
    expect(selected('Fiesta classique'), isTrue);
    await tester.scrollUntilVisible(find.text('Perso'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text(_longName));
    await tester.pump();
    expect(selected(_longName), isTrue);
  });
}
