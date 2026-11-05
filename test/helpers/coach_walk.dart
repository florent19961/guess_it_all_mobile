import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/widgets/help/coach_marks.dart';
import 'package:guess_it_all_mobile/widgets/help/help_button.dart';

/// Fait défiler l'aide ouverte par le « ? » de l'écran, jusqu'à « Compris ».
/// Rend les titres des étapes, dans l'ordre. Chaque étape doit percer le voile
/// sur une cible dans l'écran : une clé absente ou hors écran fait échouer ici.
Future<List<String>> walkHelp(WidgetTester tester) async {
  await tester.tap(find.byType(HelpButton));
  return walkOpenHelp(tester);
}

/// Idem, pour une aide déjà ouverte.
Future<List<String>> walkOpenHelp(WidgetTester tester) async {
  await _settle(tester);
  final titles = <String>[];
  final screen = Offset.zero & tester.view.physicalSize;
  for (var guard = 0; guard < 40; guard++) {
    final veil = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is CoachVeilPainter);
    if (veil.evaluate().isEmpty) return titles;
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .toList();
    final counter = texts.lastIndexWhere(RegExp(r'^\d+ / \d+$').hasMatch);
    final title = texts[counter - 1];
    titles.add(title);

    final hole =
        (tester.widget<CustomPaint>(veil).painter as CoachVeilPainter).hole;
    expect(hole, isNotNull, reason: 'étape « $title » : aucune cible');
    // Une cible plus haute que l'écran (longue liste) n'y tient qu'en partie.
    final seen = hole!.intersect(screen);
    expect(
        seen.height, greaterThanOrEqualTo(min(hole.height, screen.height / 2)),
        reason: 'étape « $title » : cible hors écran ($hole)');
    expect(seen.width, closeTo(hole.width, 1),
        reason: 'étape « $title » : cible hors écran ($hole)');

    final last = find.text('Compris');
    await tester
        .tap(last.evaluate().isNotEmpty ? last : find.text('Suivant').last);
    await _settle(tester);
  }
  fail('aide sans fin');
}

/// pump() et non pumpAndSettle() : fonds animés en boucle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
