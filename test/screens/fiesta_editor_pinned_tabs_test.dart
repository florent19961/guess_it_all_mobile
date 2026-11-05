import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensemble_editor_screen.dart';

const _tabs = ['Toujours', 'Aléatoire par manche', 'Cartouches'];

/// Tous les réglages visibles : assez de contenu pour défiler.
Future<void> _pumpEditor(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: FiestaEnsembleEditorScreen(
      others: const [],
      draft: FiestaRules(ensembleName: 'Duels', allCount: 1),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

ScrollableState _pageScrollable(WidgetTester tester) =>
    tester.stateList<ScrollableState>(find.byType(Scrollable)).reduce((a, b) =>
        a.position.maxScrollExtent >= b.position.maxScrollExtent ? a : b);

Future<void> _scrollToEnd(WidgetTester tester) async {
  final scrollable = _pageScrollable(tester);
  // Plusieurs fois : le contenu paresseux allonge la page en se construisant.
  for (var i = 0; i < 5; i++) {
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
  }
  expect(scrollable.position.pixels, greaterThan(200));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('Bangers')
          ..addFont(rootBundle.load('assets/fonts/Bangers-Regular.ttf')))
        .load();
    await (FontLoader('Poppins')
          ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf')))
        .load();
  });

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('$label, page défilée : boutons et onglets sans chevauchement',
        (tester) async {
      await _pumpEditor(tester, size);
      await _scrollToEnd(tester);

      final back = tester.getRect(find.byIcon(Icons.chevron_left));
      final help = tester.getRect(find.text('?'));
      for (final tab in _tabs) {
        final rect = tester.getRect(find.text(tab));
        expect(rect.overlaps(back), isFalse, reason: '$tab / retour');
        expect(rect.overlaps(help), isFalse, reason: '$tab / aide');
        expect(find.text(tab).hitTestable(), findsOneWidget, reason: tab);
      }
      expect(find.byIcon(Icons.chevron_left).hitTestable(), findsOneWidget);
      expect(find.text('?').hitTestable(), findsOneWidget);
    });

    testWidgets('$label, changer d\'onglet après l\'épinglage : début du menu',
        (tester) async {
      await _pumpEditor(tester, size);
      await _scrollToEnd(tester);
      final pinned = tester.getTopLeft(find.text('Toujours')).dy;

      await tester.tap(find.text('Toujours'));
      await tester.pump();

      expect(tester.getTopLeft(find.text('Toujours')).dy, pinned);
      final head = find.text('Modificateur de toute la partie');
      expect(head.hitTestable(), findsOneWidget);
      final tabsBottom = tester.getBottomLeft(find.text('Toujours')).dy;
      expect(tester.getTopLeft(head).dy - tabsBottom, inInclusiveRange(0, 60));
    });

    testWidgets('$label, changer d\'onglet avant l\'épinglage : page immobile',
        (tester) async {
      await _pumpEditor(tester, size);
      final scrollable = _pageScrollable(tester);
      scrollable.position.jumpTo(50);
      await tester.pump();

      await tester.tap(find.text('Toujours'));
      await tester.pump();
      expect(scrollable.position.pixels, 50);
    });

    testWidgets('$label, changer d\'onglet sans défiler : page immobile',
        (tester) async {
      await _pumpEditor(tester, size);
      final top = tester.getTopLeft(find.text('Toujours')).dy;
      await tester.tap(find.text('Toujours'));
      await tester.pump();
      expect(_pageScrollable(tester).position.pixels, 0);
      expect(tester.getTopLeft(find.text('Toujours')).dy, top);
    });

    testWidgets('$label, page non défilée : titre à sa place', (tester) async {
      await _pumpEditor(tester, size);
      expect(tester.getTopLeft(find.text('Nouvel ensemble')).dy, 72);
    });
  }
}
