import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/widgets/common/app_confirm_dialog.dart';

/// Monte un écran avec un seul bouton qui ouvre le dialogue, et retourne une
/// fonction lisant le verdict rendu (en vérifiant que le futur s'est résolu).
Future<bool? Function()> _harness(WidgetTester tester) async {
  bool? verdict;
  bool appele = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              verdict = await AppConfirmDialog.show(
                context,
                title: 'Terminer le tour ?',
                message: 'Les secondes restantes seront perdues.',
                confirmText: 'Terminer',
              );
              appele = true;
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );

  return () {
    expect(appele, isTrue, reason: 'le futur doit s\'être résolu');
    return verdict;
  };
}

void main() {
  testWidgets('confirmer rend true', (tester) async {
    final lire = await _harness(tester);

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(lire(), isTrue);
  });

  testWidgets('annuler rend false', (tester) async {
    final lire = await _harness(tester);

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(lire(), isFalse);
  });

  testWidgets('fermer en tapant à côté rend false, jamais null',
      (tester) async {
    // 🔴 C'est LA raison d'être du `?? false`. `showDialog` rend `null` quand la
    // barrière est touchée. Les appelants écrivaient `if (goHome == true)`, mais
    // il suffisait qu'un seul écrive `if (confirme)` sur un `bool?` — ou pire,
    // `!confirme!` — pour qu'un tap à côté abandonne une partie en cours.
    final lire = await _harness(tester);

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // On tape en haut à gauche : hors du dialogue, donc sur la barrière.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Terminer le tour ?'), findsNothing,
        reason: 'le dialogue doit bien s\'être fermé');
    expect(lire(), isFalse);
  });

  testWidgets('barrierDismissible: false empêche la fermeture par la barrière',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppConfirmDialog.show(
                context,
                title: 'Choix obligatoire',
                message: 'Il faut trancher.',
                confirmText: 'OK',
                barrierDismissible: false,
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Choix obligatoire'), findsOneWidget);
  });
}
