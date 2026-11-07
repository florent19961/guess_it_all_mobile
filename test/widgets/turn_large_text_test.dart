import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/widgets/common/turn_play_widgets.dart';
import 'package:guess_it_all_mobile/widgets/fiesta/modifier_badge.dart';

/// [child] à la taille de texte système de 200 %.
Future<void> pumpLargeText(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: Material(child: Center(child: child)),
      ),
    ));

void main() {
  for (final (state, onPass, detail) in [
    ('(gratuit)', () {}, '(gratuit)'),
    ('grisé', null, null),
  ]) {
    testWidgets('texte à 200 %, Passer $state : la rangée reste à 114 px',
        (tester) async {
      await pumpLargeText(
          tester,
          TurnActionButtons(
              onPass: onPass, onGuessed: () {}, passDetail: detail));
      expect(tester.getSize(find.byType(TurnActionButtons)).height, 114);
      expect(tester.takeException(), isNull, reason: 'aucun débordement');
    });
  }

  testWidgets('texte à 200 % : l\'émoji reste dans sa boîte', (tester) async {
    await pumpLargeText(tester, const ModifierIcon('mime_no_arms', size: 40));
    // La taille du texte, pas celle du paragraphe que la boîte contraint.
    final emoji = tester.renderObject<RenderParagraph>(find.text('💪'));
    expect(emoji.textSize.height, lessThanOrEqualTo(40));
  });
}
