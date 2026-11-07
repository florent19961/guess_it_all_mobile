import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/player.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensemble_editor_screen.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensembles_screen.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/coach_walk.dart';
import '../helpers/test_prefs.dart';
import '../screens/fiesta_v4_screens_test.dart'
    show givenPhone, loadFonts, pumpGame, settle;

/// Élément affiché = une étape ; élément absent = pas d'étape.

Future<void> pumps(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Quitte proprement un écran à minuteries.
Future<void> leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

FiestaRules charges(List<String> ids) => FiestaRules(drawCount: 0, modifiers: {
      for (final id in ids) id: const ModifierSetting(charges: 1),
    });

/// L'app hors partie, 360 × 640, avec [names] joueurs si donnés.
Future<GameProvider> pumpApp(
  WidgetTester tester,
  String screen, {
  List<String> names = const [],
  int teams = 2,
  bool random = false,
}) async {
  givenPhone(tester);
  await givenPrefs({
    AppConstants.tutorialSeenKey: true,
    AppConstants.fiestaTutorialSeenKey: true,
    AppConstants.firstGameDoneKey: true,
  });
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  provider.updateSettings(
    numberOfTeams: teams,
    wordChoice:
        random ? AppConstants.wordChoiceRandom : AppConstants.wordChoiceCustom,
  );
  for (final name in names) {
    final id = (provider.addPlayer(name)['player'] as Player).id;
    provider.updatePlayerWords(id, ['mot-$name']);
  }
  if (names.isNotEmpty) {
    provider.createTeams();
    provider.randomizeTeams();
  }
  provider.goToScreen(screen);
  await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
    value: provider,
    child: const GuessItAllApp(),
  ));
  await settle(tester);
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return provider;
}

void main() {
  setUpAll(loadFonts);

  group('Écran du tour', () {
    Future<List<String>> turnSteps(WidgetTester tester, FiestaRules? rules,
        {List<String> armed = const []}) async {
      final provider = await pumpGame(tester, rules);
      armed.forEach(provider.toggleBonus);
      provider.startTurn();
      provider.startTurnTimer();
      await pumps(tester);
      final titles = await walkHelp(tester);
      await leave(tester);
      return titles;
    }

    testWidgets('Classique : rien d\'autre que le socle', (tester) async {
      expect(await turnSteps(tester, null), [
        'Le chrono',
        'Le mot',
        'Trouvé',
        'Passer',
        'Pause',
        'Terminer le tour',
      ]);
    });

    testWidgets('malus actif, Passer désactivé : badge et bouton expliqués',
        (tester) async {
      expect(
          await turnSteps(
              tester,
              FiestaRules(drawCount: 0, modifiers: {
                'no_pass': const ModifierSetting(always: true),
              })),
          [
            'Le chrono',
            'Actif pendant ce tour',
            'Le mot',
            'Trouvé',
            'Passer (bloqué)',
            'Pause',
            'Terminer le tour',
          ]);
    });

    testWidgets('Mot compte double : le badge du tour a une étape',
        (tester) async {
      expect(
          await turnSteps(tester, charges(['double_points']),
              armed: ['double_points']),
          contains('Actif pendant ce tour'));
    });

    testWidgets(
        'Joueur bloqué : étape avant le tour ; pendant, sa pastille le nomme',
        (tester) async {
      final provider = await pumpApp(tester, AppConstants.screenHome,
          names: ['Ana', 'Bob', 'Cid', 'Dan', 'Eve', 'Fay']);
      await tester.runAsync(
          () => provider.startGame(fiesta: charges(['block_guesser'])));
      await pumps(tester);
      // Le malus d'une autre équipe, posé sur disque puis relu : un coéquipier
      // de celui qui joue, jamais lui, que le blocage attendrait au tour suivant.
      final team = provider.getCurrentTeam()!;
      final giver = provider.getCurrentPlayer()!.id;
      final saved = (await tester.runAsync(StorageService().loadGameState))!;
      ((saved['game']['fiesta'] as Map)['active'] ??= []).add(ModifierInstance(
        catalogId: 'block_guesser',
        scope: ModifierScope.turn,
        target: ModifierTarget.player,
        teamId: team.id,
        playerId: team.playerIds.firstWhere((id) => id != giver),
        charges: 1,
        nature: ModifierNature.malus,
        round: provider.game.currentRound,
        fromTeamId: provider.teams.firstWhere((t) => t != team).id,
      ).toJson());
      await tester.runAsync(() => StorageService().saveGameState(saved));
      final reloaded = GameProvider();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
        value: reloaded,
        child: const GuessItAllApp(),
      ));
      await settle(tester);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final blocked = reloaded.blockedGuesser!;
      expect(await walkHelp(tester), contains('Joueur bloqué'));

      reloaded.startTurn();
      reloaded.startTurnTimer();
      await pumps(tester);
      expect(find.text('${blocked.name} ne répond pas'), findsOneWidget);
      expect(await walkHelp(tester), contains('Actif pendant ce tour'));
      await leave(tester);
    });
  });

  group('Manches et nombre d\'équipes', () {
    testWidgets(
        'autre langue en M1 et M2, mime en M3 : l\'étape suit ce que la manche '
        'affiche, sans jamais sortir de l\'écran', (tester) async {
      final provider = await pumpGame(
          tester,
          FiestaRules(drawCount: 0, modifiers: {
            'other_language': const ModifierSetting(always: true),
            'mime_no_arms': const ModifierSetting(always: true),
          }));
      for (final round in [1, 2, 3]) {
        expect(provider.game.currentRound, round);
        expect(provider.roundRulesThisTurn.map((m) => m.catalogId),
            [round < 3 ? 'other_language' : 'mime_no_arms']);
        await pumps(tester);
        expect(await walkHelp(tester), contains('Règles de la manche'));
        provider.startTurn();
        provider.startTurnTimer();
        await pumps(tester);
        expect(await walkHelp(tester), contains('Actif pendant ce tour'));
        if (round == 3) break;
        provider.passWord();
        for (var i = 0; i < 4; i++) {
          provider.markWordAsGuessed();
        }
        final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
        provider.savePreValidationState(guessed);
        provider.validateWords(guessed);
        provider.nextRound();
      }
      await leave(tester);
    });

    for (final teams in [3, 4]) {
      testWidgets('$teams équipes : réserve et zone active dans l\'écran',
          (tester) async {
        final provider = await pumpApp(tester, AppConstants.screenHome,
            names: [for (var i = 0; i < teams * 2; i++) 'J$i'], teams: teams);
        await tester.runAsync(() => provider.startGame(
              fiesta: FiestaRules(drawCount: 0, modifiers: {
                'no_pass': const ModifierSetting(always: true),
                'plus_10s': const ModifierSetting(charges: 1),
                'reversed': const ModifierSetting(charges: 1),
              }),
            ));
        await pumps(tester);
        expect(
            await walkHelp(tester),
            containsAll([
              'Règles de la manche',
              'Réserve : tes bonus',
              'Réserve : tes malus',
            ]));
      });
    }
  });

  group('Vérification', () {
    testWidgets('mots passés et double points : leurs étapes', (tester) async {
      final provider = await pumpGame(tester, charges(['double_points']));
      provider.toggleBonus('double_points');
      provider.startTurn();
      provider.startTurnTimer();
      provider.markWordAsGuessed();
      provider.passWord();
      provider.endTurn();
      await pumps(tester);
      final titles = await walkHelp(tester);
      expect(
          titles,
          containsAllInOrder([
            'Mot compte double',
            'Vérifie les mots',
            'Mots passés',
            'Valider'
          ]));
      await leave(tester);
    });

    testWidgets('sans passe ni double : pas d\'étape pour eux', (tester) async {
      final provider = await pumpGame(tester, null);
      provider.startTurn();
      provider.startTurnTimer();
      provider.markWordAsGuessed();
      provider.endTurn();
      await pumps(tester);
      final titles = await walkHelp(tester);
      expect(titles, isNot(contains('Mots passés')));
      expect(titles, isNot(contains('Mot compte double')));
      expect(
          titles.contains('Temps écoulé'), provider.game.expiredWord != null);
      await leave(tester);
    });
  });

  group('Avant le tour', () {
    testWidgets('le retour affiché dit où il mène', (tester) async {
      await pumpGame(tester, null);
      expect(await walkHelp(tester), contains('Retour aux équipes'));
    });

    testWidgets('cartouche épuisée : son étape', (tester) async {
      final provider = await pumpGame(tester, charges(['no_pass']));
      expect(await walkHelp(tester), isNot(contains('Cartouche indisponible')));
      provider.inflictMalus('no_pass',
          provider.teams.firstWhere((t) => t != provider.getCurrentTeam()).id);
      await settle(tester);
      expect(await walkHelp(tester), contains('Cartouche indisponible'));
    });
  });

  group('Paramètres et joueurs', () {
    testWidgets(
        '« partie longue » : étape seulement si l\'avertissement est là',
        (tester) async {
      final provider = await pumpApp(tester, AppConstants.screenSettings);
      expect(await walkHelp(tester), isNot(contains('Partie longue')));
      provider.updateSettings(totalWords: 60);
      await settle(tester);
      expect(await walkHelp(tester), contains('Partie longue'));
    });

    testWidgets('Aléatoire : l\'étape parle des mots prêts, pas de la saisie',
        (tester) async {
      await pumpApp(tester, AppConstants.screenPlayers, random: true);
      await settle(tester);
      expect(await walkHelp(tester), ['Les joueurs', 'Mots prêts', 'Suivant']);
    });
  });

  group('Équipes', () {
    for (final count in [2, 3, 4]) {
      testWidgets('$count équipes : les étapes pointent dans l\'écran',
          (tester) async {
        await pumpApp(tester, AppConstants.screenTeams,
            names: [for (var i = 0; i < count * 2; i++) 'J$i'], teams: count);
        expect(
            await walkHelp(tester), ['Les équipes', 'Mélanger', 'Commencer']);
      });
    }

    testWidgets('équipe incomplète : le message a son étape', (tester) async {
      await pumpApp(tester, AppConstants.screenTeams,
          names: ['Ana', 'Bob', 'Cid', 'Dan'], teams: 4);
      expect(await walkHelp(tester), contains('Équipe incomplète'));
    });
  });

  group('Liste des ensembles', () {
    Future<void> pumpList(WidgetTester tester, int mine) async {
      givenPhone(tester);
      await givenPrefs({
        if (mine > 0)
          FiestaEnsembleService.storageKey: jsonEncode(wrapWithSchema({
            'ensembles': [
              for (var i = 0; i < mine; i++)
                FiestaEnsemble(
                  id: 'e$i',
                  rules: FiestaRules(ensembleName: 'Mien $i'),
                ).toJson(),
            ],
          })),
      });
      await tester.pumpWidget(MaterialApp(
          home: FiestaEnsemblesScreen(onBack: () {}, onNext: (_) {})));
      await settle(tester);
    }

    testWidgets('sans ensemble personnel : ni étape ni mention du badge',
        (tester) async {
      await pumpList(tester, 0);
      await tester.tap(find.text('?'));
      await pumps(tester);
      expect(find.textContaining('Perso'), findsNothing);
      expect(find.textContaining('corbeille'), findsNothing);
      expect(await walkOpenHelp(tester),
          ['Les ensembles', 'Créer un ensemble', 'Suivant']);
    });

    testWidgets('avec un ensemble personnel : son étape', (tester) async {
      await pumpList(tester, 1);
      expect(await walkHelp(tester),
          ['Les ensembles', 'Tes ensembles', 'Créer un ensemble', 'Suivant']);
    });

    testWidgets('liste pleine : l\'étape parle de la limite', (tester) async {
      await pumpList(tester, FiestaEnsembleService.maxEnsembles);
      expect(await walkHelp(tester),
          ['Les ensembles', 'Tes ensembles', 'Limite atteinte', 'Suivant']);
    });

    testWidgets(
        'le crayon et la corbeille se disent derrière une sélection ; la '
        'pastille seulement si la ligne dépliée en a', (tester) async {
      await pumpList(tester, 1);
      await tester.tap(find.text('?'));
      await pumps(tester);
      expect(find.text('Les ensembles'), findsOneWidget,
          reason: 'aide ouverte');
      expect(find.textContaining('pastille'), findsNothing,
          reason: 'Fiesta classique : pastilles neutres, sans explication');
      await walkOpenHelp(tester);

      // L'aide a défilé jusqu'à « Suivant » : on remonte à la ligne.
      await tester.ensureVisible(find.text('Pro Player'));
      await pumps(tester);
      await tester.tap(find.text('Pro Player'));
      await pumps(tester);
      await tester.tap(find.text('?'));
      await pumps(tester);
      expect(find.textContaining('pastille rouge ou verte'), findsOneWidget);
      await tester.tap(find.text('Suivant').last);
      await pumps(tester);
      expect(find.textContaining('Touche un des tiens'), findsOneWidget);
    });

    testWidgets('brouillon en attente : l\'étape dit « Reprendre »',
        (tester) async {
      FiestaEnsemblesScreen.drafts[FiestaEnsemblesScreen.newDraftKey] =
          FiestaRules(ensembleName: 'x');
      addTearDown(FiestaEnsemblesScreen.drafts.clear);
      await pumpList(tester, 0);
      expect(await walkHelp(tester), contains('Reprendre le brouillon'));
    });
  });

  group('Éditeur', () {
    Future<void> pumpEditor(WidgetTester tester, FiestaRules? rules) async {
      givenPhone(tester);
      await givenPrefs();
      await tester.pumpWidget(MaterialApp(
          home: FiestaEnsembleEditorScreen(
        others: const [],
        initial: rules == null ? null : FiestaEnsemble(id: 'x', rules: rules),
      )));
      await settle(tester);
    }

    Future<void> openTab(WidgetTester tester, String tab) async {
      await tester.tap(find.text(tab).first);
      await settle(tester);
    }

    testWidgets('chaque onglet n\'a que l\'étape de son contenu',
        (tester) async {
      await pumpEditor(tester, null);
      for (final (tab, title) in const [
        ('Toujours', 'Toujours'),
        ('Aléatoire par manche', 'Aléatoire par manche'),
        ('Cartouches', 'Cartouches'),
      ]) {
        await openTab(tester, tab);
        await tester.tap(find.text('?'));
        await pumps(tester);
        await tester.tap(find.text('Suivant').last);
        await pumps(tester);
        expect(find.textContaining('défis surprises'),
            tab == 'Cartouches' ? findsOneWidget : findsNothing,
            reason: 'onglet $tab : pas de contenu d\'un autre onglet');
        final titles = await walkOpenHelp(tester);
        expect(titles.first, title);
        expect(titles.last, 'Enregistrer');
      }
    });

    testWidgets('verrouillage : étape seulement dans l\'onglet concerné',
        (tester) async {
      await pumpEditor(
          tester,
          FiestaRules(ensembleName: 'E', drawCount: 0, modifiers: {
            'no_pass': const ModifierSetting(always: true),
          }));
      await openTab(tester, 'Toujours');
      expect(await walkHelp(tester), isNot(contains('Verrouillé')));
      await openTab(tester, 'Aléatoire par manche');
      expect(await walkHelp(tester), contains('Verrouillé'));
    });

    testWidgets('« Rien à tirer » : étape seulement si l\'alerte est là',
        (tester) async {
      await pumpEditor(
          tester,
          FiestaRules(ensembleName: 'E', drawCount: 1, modifiers: {
            'mime_no_arms': const ModifierSetting(draw: true),
          }));
      await openTab(tester, 'Aléatoire par manche');
      expect(await walkHelp(tester), contains('Rien à tirer'));
      await openTab(tester, 'Cartouches');
      expect(await walkHelp(tester), isNot(contains('Rien à tirer')));
    });

    testWidgets('défis : étape seulement cadre ouvert', (tester) async {
      await pumpEditor(tester, null);
      await openTab(tester, 'Cartouches');
      expect(await walkHelp(tester), isNot(contains('Défis surprises')));
      await tester.pumpWidget(const SizedBox());

      await pumpEditor(
          tester, FiestaRules(ensembleName: 'E', challenges: true));
      await openTab(tester, 'Cartouches');
      expect(await walkHelp(tester), contains('Défis surprises'));
    });
  });
}
