import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/players_screen.dart';
import 'package:guess_it_all_mobile/screens/settings_screen.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

String json(FiestaRules? rules) => jsonEncode(rules?.toJson());

final _classic = json(classicEnsemble.rules);

Future<GameProvider> givenProvider() async {
  await givenPrefs();
  final provider = GameProvider();
  await pumpEventQueue();
  return provider;
}

Future<FiestaEnsemble> givenMine(String name) async =>
    (await FiestaEnsembleService().create(FiestaRules(
      ensembleName: name,
      allCount: 3,
    )))!;

void main() {
  group('passer en Fiesta', () {
    test(
        'pose le dernier ensemble utilisé, sinon Fiesta classique ; supprimé : '
        'Fiesta classique ; jamais des règles vides', () async {
      final provider = await givenProvider();
      await provider.chooseFiestaMode();
      expect(json(provider.pendingFiesta), _classic);

      provider.setPendingFiesta(null);
      final mine = await givenMine('Soirée');
      await FiestaEnsembleService().markUsed(mine.id);
      await provider.chooseFiestaMode();
      expect(json(provider.pendingFiesta), json(mine.rules));

      provider.setPendingFiesta(null);
      await FiestaEnsembleService().delete(mine.id);
      await provider.chooseFiestaMode();
      expect(json(provider.pendingFiesta), _classic);
    });

    test('Classique touché pendant la relecture : reste Classique', () async {
      final provider = await givenProvider();
      final mine = await givenMine('Soirée');
      await FiestaEnsembleService().markUsed(mine.id);

      final choosing = provider.chooseFiestaMode();
      expect(provider.pendingFiesta, isNotNull,
          reason: 'aucun instant sans règles en Fiesta');
      provider.setPendingFiesta(null);
      await choosing;
      expect(provider.pendingFiesta, isNull);
    });
  });

  test(
      'Réinitialiser oublie le dernier ensemble, garde les ensembles créés ; '
      'repasser en Fiesta donne Fiesta classique', () async {
    final provider = await givenProvider();
    final mine = await givenMine('Soirée');
    await FiestaEnsembleService().markUsed(mine.id);
    provider.setPendingFiesta(mine.rules);

    await provider.clearLocalStorage();

    final store = await FiestaEnsembleService().load();
    expect(store.lastUsedId, isNull);
    expect(store.ensembles.map((e) => e.id), [mine.id]);
    expect(provider.pendingFiesta, isNull);

    await provider.chooseFiestaMode();
    expect(json(provider.pendingFiesta), _classic);
  });

  group('retour de la liste sans valider', () {
    test('l\'ensemble en attente modifié ou supprimé dans la liste est suivi',
        () async {
      final provider = await givenProvider();
      final mine = await givenMine('Soirée');
      await FiestaEnsembleService().markUsed(mine.id);
      await provider.chooseFiestaMode();

      await provider.refreshPendingEnsemble();
      expect(json(provider.pendingFiesta), json(mine.rules),
          reason: 'rien n\'a changé dans la liste : rien ne change');

      final edited =
          FiestaEnsemble(id: mine.id, rules: mine.rules.copyWith(allCount: 4));
      await FiestaEnsembleService().update(edited);
      await provider.refreshPendingEnsemble();
      expect(json(provider.pendingFiesta), json(edited.rules));

      await FiestaEnsembleService().delete(mine.id);
      await provider.refreshPendingEnsemble();
      expect(json(provider.pendingFiesta), _classic);
    });

    test('une partie rejouée pas encore lancée garde ses règles gelées',
        () async {
      final provider = await givenProvider();
      final frozen = FiestaRules(ensembleName: 'Ancienne', allCount: 2);
      provider.setPendingFiesta(frozen);
      await provider.restartWithSamePlayers();

      await provider.refreshPendingEnsemble();
      expect(json(provider.pendingFiesta), json(frozen));
    });
  });

  group('ligne Ensemble des Paramètres', () {
    Future<GameProvider> pump(WidgetTester tester, FiestaRules? rules) async {
      tester.view.physicalSize = const Size(700, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await givenPrefs({AppConstants.fiestaTutorialSeenKey: true});
      final provider = GameProvider();
      await tester.runAsync(() => pumpEventQueue());
      provider.setPendingFiesta(rules);
      await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      return provider;
    }

    Finder line() => find.textContaining('Ensemble :');

    testWidgets('Classique et Fiesta classique : aucune ligne', (tester) async {
      await pump(tester, null);
      expect(line(), findsNothing);
      await pump(tester, classicEnsemble.rules);
      expect(line(), findsNothing);
    });

    testWidgets('un autre ensemble : son nom', (tester) async {
      await pump(tester,
          kProvidedEnsembles.firstWhere((e) => e.name == 'Pro Player').rules);
      expect(line(), findsOneWidget);
      expect(find.textContaining('Pro Player', findRichText: true),
          findsOneWidget);
    });

    testWidgets(
        'une partie rejouée aux anciennes règles de « Fiesta classique » se '
        'signale', (tester) async {
      await pump(
          tester,
          FiestaRules(
            ensembleName: classicEnsemble.name,
            allCount: 2,
          ));
      expect(
          find.textContaining('Fiesta classique (ancienne version)',
              findRichText: true),
          findsOneWidget);
    });
  });

  testWidgets(
      'Joueurs : « suivant » au clavier amène chaque champ au-dessus du clavier, '
      'y compris le 20e', (tester) async {
    const screen = Size(360, 740);
    const keyboard = 300.0;
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await givenPrefs();
    final provider = GameProvider();
    await tester.runAsync(() => pumpEventQueue());
    provider.updateSettings(
      numberOfPlayers: AppConstants.maxPlayers,
      wordChoice: AppConstants.wordChoiceCustom,
    );
    await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: PlayersScreen()),
    ));
    await tester.pump();
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();

    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Finder field(int index) =>
        find.byKey(ValueKey('input_${provider.players[index].id}'),
            skipOffstage: false);

    await tester.showKeyboard(
        find.descendant(of: field(0), matching: find.byType(EditableText)));
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetViewInsets);
    await settle();

    for (var i = 1; i < AppConstants.maxPlayers; i++) {
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle();
      final focused = tester
          .widget<EditableText>(find.descendant(
              of: field(i),
              matching: find.byType(EditableText, skipOffstage: false)))
          .focusNode
          .hasFocus;
      expect(focused, isTrue, reason: 'champ $i : le focus doit y arriver');
      expect(tester.getRect(field(i)).bottom,
          lessThanOrEqualTo(screen.height - keyboard),
          reason: 'champ $i caché par le clavier');
    }

    // Liste remontée loin du champ actif : la ligne suivante, hors de vue,
    // reçoit quand même le focus.
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await settle();
    await tester.tap(find
        .descendant(of: field(0), matching: find.byType(EditableText))
        .hitTestable());
    await settle();
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await settle();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle();
    expect(
        tester
            .widget<EditableText>(find.descendant(
                of: field(1),
                matching: find.byType(EditableText, skipOffstage: false)))
            .focusNode
            .hasFocus,
        isTrue,
        reason: 'ligne non construite : requestFocus ne ferait rien');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
