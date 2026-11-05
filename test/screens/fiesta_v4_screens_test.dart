import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensemble_editor_screen.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensembles_screen.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:guess_it_all_mobile/widgets/common/app_back_button.dart';
import 'package:guess_it_all_mobile/widgets/common/back_button.dart';
import 'package:guess_it_all_mobile/widgets/fiesta/modifier_badge.dart';
import 'package:guess_it_all_mobile/widgets/fiesta/turn_cartridges.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

/// pump() et non pumpAndSettle() : fonds animés en boucle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void givenPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// L'app complète, partie lancée en [fiesta] (nul = Classique), 2 équipes.
Future<GameProvider> pumpGame(WidgetTester tester, FiestaRules? fiesta) async {
  givenPhone(tester);
  await givenPrefs({
    AppConstants.tutorialSeenKey: true,
    AppConstants.fiestaTutorialSeenKey: true,
    AppConstants.firstGameDoneKey: true,
  });
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  for (final name in ['Ana', 'Bob']) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(id, ['mot-$name-0', 'mot-$name-1']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  await tester.runAsync(() => provider.startGame(fiesta: fiesta));
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

void finishRound(GameProvider provider) {
  provider.startTurn();
  provider.startTurnTimer();
  // 25 s reportées : le temps ne doit pas s'afficher sur la transition.
  provider.passWord();
  for (var i = 0; i < 4; i++) {
    provider.markWordAsGuessed();
  }
  final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
  provider.savePreValidationState(guessed);
  provider.validateWords(guessed);
}

/// L'éditeur seul, poussé comme le fait la liste.
Future<void> pumpEditor(WidgetTester tester, {FiestaEnsemble? initial}) async {
  givenPhone(tester);
  await givenPrefs();
  await tester.pumpWidget(MaterialApp(
      home: FiestaEnsembleEditorScreen(others: const [], initial: initial)));
  await settle(tester);
}

Future<void> scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pump();
}

/// La ligne d'un modificateur de l'éditeur (son `Container` le plus proche).
Finder rowOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(Container)).first;

/// Les vraies polices : les tests mesurent la mise en page à 360 × 640, et
/// la police de test (glyphes pleins) la ferait déborder à tort.
Future<void> loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await (FontLoader('Bangers')
        ..addFont(rootBundle.load('assets/fonts/Bangers-Regular.ttf')))
      .load();
  await (FontLoader('Poppins')
        ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf')))
      .load();
}

void main() {
  setUpAll(loadFonts);

  group('Entre deux manches', () {
    for (final (label, fiesta) in [
      ('Classique', null),
      ('Fiesta', classicEnsemble.rules),
    ]) {
      testWidgets(
          '$label : animation, puis directement l\'écran avant le tour ; aucun '
          'score ni temps', (tester) async {
        final provider = await pumpGame(tester, fiesta);
        finishRound(provider);
        await tester.pump();
        expect(provider.game.currentScreen, AppConstants.screenTransition);
        expect(find.text('Manche 1 terminée'), findsOneWidget);
        expect(find.text('Manche 2 : Un seul mot'), findsOneWidget);
        expect(find.textContaining('Temps bonus'), findsNothing);
        expect(find.textContaining('mots devinés'), findsNothing);

        await tester.pump(const Duration(milliseconds: 1000));
        expect(provider.game.currentScreen, AppConstants.screenTransition);
        await tester.pump(const Duration(milliseconds: 1900));
        await tester.pump();
        expect(provider.game.currentScreen, AppConstants.screenGame);
        expect(provider.game.currentRound, 2);
        expect(find.text('Commencer le tour'), findsOneWidget);
        expect(provider.canGoBackToVerification, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });
    }

    testWidgets('un toucher fait passer, une seule fois', (tester) async {
      final provider = await pumpGame(tester, null);
      finishRound(provider);
      await tester.pump();
      await tester.tap(find.text('Manche 1 terminée'));
      await tester.pump();
      expect(provider.game.currentScreen, AppConstants.screenGame);
      expect(provider.game.currentRound, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('animations réduites : texte fixe, puis la suite',
        (tester) async {
      final provider = await pumpGame(tester, null);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      finishRound(provider);
      await tester.pump();
      expect(find.text('Manche 2 : Un seul mot'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(provider.game.currentScreen, AppConstants.screenGame);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'après M3 : écran fixe, retour, mots du dernier tour, Voir les résultats',
        (tester) async {
      final provider = await pumpGame(tester, null);
      for (var round = 1; round < 3; round++) {
        finishRound(provider);
        provider.nextRound();
        provider.startTurn();
        provider.startTurnTimer();
        provider.endTurn();
        provider.savePreValidationState(const []);
        provider.validateWords(const []);
      }
      finishRound(provider);
      await tester.pump();
      expect(provider.game.currentRound, 3);
      await tester.pump(const Duration(seconds: 5));
      expect(provider.game.currentScreen, AppConstants.screenTransition,
          reason: 'écran fixe');
      expect(find.text('Manche 3 terminée'), findsOneWidget);
      expect(find.textContaining('mots devinés'), findsOneWidget);
      expect(find.byType(GameBackButton), findsOneWidget);
      await tester.tap(find.text('Voir les résultats'));
      expect(provider.game.currentScreen, AppConstants.screenResults);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets(
      'Avant le tour : les nouveaux titres, aucune alerte avant le compte à '
      'rebours', (tester) async {
    final provider = await pumpGame(
      tester,
      FiestaRules(modifiers: {
        'no_pass': const ModifierSetting(always: true),
        'plus_10s': const ModifierSetting(charges: 1),
      }),
    );
    expect(provider.game.currentScreen, AppConstants.screenGame);
    expect(find.text('ACTIF PENDANT VOTRE PROCHAIN TOUR'), findsOneWidget);
    expect(find.text('VOTRE RÉSERVE'), findsOneWidget);

    await tester.tap(find.text('Commencer le tour'));
    await tester.pump();
    expect(provider.game.currentScreen, AppConstants.screenCountdown,
        reason: 'directement le compte à rebours, sans écran intermédiaire');
    expect(find.text('Compris'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Interdit de faire deviner : le joueur se choisit à l\'envoi',
      (tester) async {
    final provider = await pumpGame(
        tester,
        FiestaRules(modifiers: {
          'block_giver': const ModifierSetting(charges: 1),
        }));
    await tester.tap(find.descendant(
        of: find.byType(FiestaTurnZone),
        matching: find.text(modifierIcon('block_giver'))));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Qui ne fera pas deviner ?'), findsOneWidget);
    expect(find.text('Il saute son prochain tour.'), findsOneWidget);
    final target =
        provider.teams.firstWhere((t) => t.id != provider.getCurrentTeam()!.id);
    final name = provider.getPlayerById(target.playerIds.first)!.name;
    await tester.tap(find.text(name).last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(provider.sentThisTurn.single.playerId, target.playerIds.first);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets(
      'le piège : phrase, puis l\'avant-tour du remplaçant avec le lien',
      (tester) async {
    final provider = await pumpGame(
        tester,
        FiestaRules(modifiers: {
          'block_giver': const ModifierSetting(charges: 1),
          'plus_10s': const ModifierSetting(charges: 1),
        }));
    final other =
        provider.teams.firstWhere((t) => t.id != provider.getCurrentTeam()!.id);
    provider.inflictMalus('block_giver', other.id,
        playerId: other.playerIds[0]);
    provider.startTurn();
    provider.startTurnTimer();
    provider.endTurn();
    provider.savePreValidationState(const []);
    provider.validateWords(const []);
    provider.toggleBonus('plus_10s');
    provider.startTurn();
    provider.startTurnTimer();
    await settle(tester);
    expect(find.text('🚫'), findsOneWidget);
    expect(find.textContaining('Passe le téléphone à'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await settle(tester);
    expect(provider.game.currentScreen, AppConstants.screenGame);
    expect(find.textContaining('Reprendre les choix de'), findsOneWidget);
    await tester.tap(find.textContaining('Reprendre les choix de'));
    await settle(tester);
    expect(provider.isBonusArmed('plus_10s'), isTrue);
    expect(find.textContaining('Reprendre les choix de'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'à 360 × 640, 7 malus envoyés : la zone défile, toute pastille reste '
      'atteignable et annulable, Commencer reste visible', (tester) async {
    givenPhone(tester);
    // Barre d'état et barre de navigation d'un vrai téléphone.
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    await givenPrefs({
      AppConstants.tutorialSeenKey: true,
      AppConstants.fiestaTutorialSeenKey: true,
      AppConstants.firstGameDoneKey: true,
    });
    givenFakePlatformPlugins();
    final provider = GameProvider();
    await tester.runAsync(() => pumpEventQueue());
    for (final name in ['Ana', 'Bob', 'Zoé', 'Max', 'Léa', 'Tom']) {
      final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await tester.runAsync(() => provider.startGame(
            fiesta: FiestaRules(modifiers: {
          for (final def in kModifierCatalog)
            def.id: const ModifierSetting(charges: 5),
        })));
    await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const GuessItAllApp(),
    ));
    await settle(tester);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(provider.reserve, hasLength(11));

    final other =
        provider.teams.firstWhere((t) => t.id != provider.getCurrentTeam()!.id);
    for (final (i, id) in ['block_giver', 'block_guesser'].indexed) {
      expect(provider.inflictMalus(id, other.id, playerId: other.playerIds[i]),
          isNull);
    }
    for (final id in [
      'no_pass',
      'reversed',
      'other_language',
      'one_answer',
      'minus_10s',
    ]) {
      expect(provider.inflictMalus(id, other.id), isNull);
    }
    await settle(tester);
    expect(provider.sentThisTurn, hasLength(7));
    expect(tester.takeException(), isNull);

    final zone = find.byType(FiestaTurnZone);
    final start = find.text('Commencer le tour');
    expect(tester.getBottomLeft(zone).dy,
        lessThanOrEqualTo(tester.getTopLeft(start).dy));
    expect(tester.getBottomLeft(start).dy, lessThanOrEqualTo(640));

    // La dernière pastille : on y arrive en faisant défiler la zone.
    final last = find.text(' Envoyé').last;
    expect(tester.getBottomLeft(last).dy,
        greaterThan(tester.getBottomLeft(zone).dy),
        reason: 'le contenu dépasse vraiment de la zone');
    await tester.scrollUntilVisible(last, 40,
        scrollable:
            find.descendant(of: zone, matching: find.byType(Scrollable)));
    await tester.pump();
    expect(tester.getBottomLeft(last).dy,
        lessThanOrEqualTo(tester.getBottomLeft(zone).dy));
    expect(tester.getBottomLeft(start).dy, lessThanOrEqualTo(640));

    await tester.tap(last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Annuler l\'envoi').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(provider.sentThisTurn, hasLength(6));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });

  group('Explosif en manche 3 à 360 × 640', () {
    /// La zone tient dans son `ClipRect`, sans rien couper, et le bouton reste
    /// en dessous.
    void expectFits(WidgetTester tester, GameProvider provider) {
      final bonus = provider.reserve
          .where((c) => c.nature == ModifierNature.bonus)
          .length;
      expect((provider.reserve.length - bonus, bonus), (11, 4));
      final zone = find.byType(FiestaTurnZone);
      // Cas réaliste : tout tient, il n'y a rien à faire défiler.
      expect(
          tester
              .state<ScrollableState>(
                  find.descendant(of: zone, matching: find.byType(Scrollable)))
              .position
              .maxScrollExtent,
          0);
      expect(
          tester.getBottomLeft(zone).dy,
          lessThanOrEqualTo(
              tester.getTopLeft(find.text('Commencer le tour')).dy));
      expect(tester.takeException(), isNull);
    }

    testWidgets('la réserve tient, continuation et vrai tour', (tester) async {
      // Barre d'état et barre de navigation d'un vrai téléphone.
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
      // Le pire cas d'Explosif en M3, fixé : ses 15 cartouches, toutes différentes.
      final provider = await pumpGame(
          tester,
          FiestaRules(modifiers: {
            for (final def in kModifierCatalog)
              if (!const {'other_language', 'mime_no_fists', 'mime_eyes_closed'}
                  .contains(def.id))
                def.id: const ModifierSetting(charges: 1),
          }));
      for (var round = 1; round < 3; round++) {
        finishRound(provider);
        provider.nextRound();
      }
      await settle(tester);
      expect(provider.isContinuation, isTrue);
      expectFits(tester, provider);

      // Bonus allumé : il a quitté la réserve, « Ce tour » se remplit.
      final bonusId = provider.reserve
          .firstWhere((c) => c.nature == ModifierNature.bonus && c.usable)
          .catalogId;
      provider.toggleBonus(bonusId);
      await settle(tester);
      expectFits(tester, provider);
      provider.toggleBonus(bonusId);

      provider.startTurn();
      provider.startTurnTimer();
      provider.endTurn();
      provider.savePreValidationState(const []);
      provider.validateWords(const []);
      await settle(tester);
      expect(provider.isContinuation, isFalse);
      expectFits(tester, provider);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets(
        'sur une continuation, un bonus déjà en cours ne se rend pas à la '
        'réserve au toucher', (tester) async {
      final provider = await pumpGame(
          tester,
          FiestaRules(modifiers: const {
            'double_points': ModifierSetting(charges: 2),
          }));
      provider.toggleBonus('double_points');
      finishRound(provider);
      provider.nextRound();
      await settle(tester);
      expect(provider.isDoublePointsOn, isTrue);

      final circles = find.descendant(
          of: find.byType(FiestaTurnZone),
          matching: find.text(modifierIcon('double_points')));
      await tester.tap(circles.first);
      await settle(tester);
      expect(provider.isDoublePointsOn, isTrue);
      expect(provider.game.fiesta!.chargesUsed, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  testWidgets(
      'Tour : le +10 s allumé a son badge sous le chrono, et le chrono '
      'part de 40 s', (tester) async {
    final provider = await pumpGame(
      tester,
      FiestaRules(drawCount: 0, modifiers: {
        'plus_10s': ModifierSetting(charges: 1),
      }),
    );
    provider.toggleBonus('plus_10s');
    provider.startTurn();
    provider.startTurnTimer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(provider.game.currentScreen, AppConstants.screenTurn);
    expect(provider.game.turnAllottedSeconds, 40);
    final badge = find.byType(ModifierBadge);
    expect(badge, findsOneWidget);
    expect(tester.widget<ModifierBadge>(badge).label, 'Bonus de 10 s');
    expect(tester.widget<ModifierBadge>(badge).icon, '+10');
    expect(tester.getTopLeft(badge).dy,
        greaterThan(tester.getBottomLeft(find.text('40s')).dy));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  group('Éditeur', () {
    Finder inside(Finder of, Finder what) =>
        find.descendant(of: of, matching: what);
    Switch switchOf(WidgetTester tester, String name) =>
        tester.widget<Switch>(inside(rowOf(name), find.byType(Switch)));

    Future<void> tab(WidgetTester tester, String label) async {
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();
    }

    testWidgets('chaque menu n\'affiche que ce qui y est possible',
        (tester) async {
      await pumpEditor(tester);
      await tab(tester, 'Toujours');
      expect(find.text('Modificateur de toute la partie'), findsOneWidget);
      expect(find.text('Passe gratuite', skipOffstage: false), findsNothing);
      expect(find.text('Interdit de faire deviner', skipOffstage: false),
          findsNothing);
      await scrollToText(tester, 'Une seule réponse');
      expect(find.text('Une seule réponse'), findsOneWidget);

      await tab(tester, 'Aléatoire par manche');
      expect(find.text('Modificateur aléatoire de manche'), findsOneWidget);
      expect(find.text('Combien par manche'), findsOneWidget);
      expect(find.text('Passe gratuite', skipOffstage: false), findsNothing);

      await tab(tester, 'Cartouches');
      expect(find.text('Au hasard'), findsOneWidget);
      expect(find.text('Équilibrer la partie'), findsOneWidget);
      expect(find.text('Aux équipes menées'), findsOneWidget);
      expect(find.text('À tous, à chaque manche'), findsOneWidget);
      await scrollToText(tester, 'Interdit de faire deviner');
      expect(find.text('Interdit de faire deviner'), findsOneWidget);
    });

    testWidgets('Équilibrer la partie masque le nombre fixe', (tester) async {
      await pumpEditor(tester);
      await tab(tester, 'Cartouches');
      await tester.tap(inside(
          find
              .ancestor(
                  of: find.text('Équilibrer la partie'),
                  matching: find.byType(Padding))
              .first,
          find.byType(Switch)));
      await tester.pump();
      expect(find.text('Aux équipes menées'), findsNothing);
    });

    testWidgets(
        'Toujours verrouille les 2 autres menus, réglages restaurés au '
        'décochage', (tester) async {
      await pumpEditor(tester);
      await tab(tester, 'Aléatoire par manche');
      await scrollToText(tester, 'Mot à l\'envers');
      await tester.tap(inside(rowOf('Mot à l\'envers'), find.byType(Switch)));
      await tester.pump();
      expect(switchOf(tester, 'Mot à l\'envers').value, isTrue);

      await tab(tester, 'Toujours');
      await scrollToText(tester, 'Mot à l\'envers');
      await tester.tap(inside(rowOf('Mot à l\'envers'), find.byType(Switch)));
      await tester.pump();

      await tab(tester, 'Aléatoire par manche');
      await scrollToText(tester, 'Mot à l\'envers');
      expect(switchOf(tester, 'Mot à l\'envers').onChanged, isNull);
      expect(switchOf(tester, 'Mot à l\'envers').value, isFalse);
      expect(find.text('Actif en Toujours'), findsOneWidget);

      await tab(tester, 'Toujours');
      await scrollToText(tester, 'Mot à l\'envers');
      await tester.tap(inside(rowOf('Mot à l\'envers'), find.byType(Switch)));
      await tester.pump();
      await tab(tester, 'Aléatoire par manche');
      await scrollToText(tester, 'Mot à l\'envers');
      expect(switchOf(tester, 'Mot à l\'envers').value, isTrue,
          reason: 'réglage restauré');
    });

    testWidgets('un mime en Toujours verrouille les autres, sauf la paire',
        (tester) async {
      await pumpEditor(tester);
      await tab(tester, 'Toujours');
      await scrollToText(tester, 'Mimer sous un drap');
      await tester
          .tap(inside(rowOf('Mimer sous un drap'), find.byType(Switch)));
      await tester.pump();
      await scrollToText(tester, 'Bruitages seulement');
      expect(switchOf(tester, 'Bruitages seulement').onChanged, isNotNull);
      expect(switchOf(tester, 'Mime de dos').onChanged, isNull);
    });

    testWidgets('validation : au moins un réglage actif', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField), 'Soirée');
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      expect(find.text('Active au moins un modificateur.'), findsOneWidget);
    });
  });

  testWidgets(
      'Liste : « Voir » ouvre la page d\'un ensemble fourni, en lecture seule, '
      'sans le sélectionner ; toucher la ligne sélectionne toujours ; '
      '« Dupliquer » revient dupliquer', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await givenPrefs();
    FiestaRules? chosen;
    await tester.pumpWidget(MaterialApp(
      home: FiestaEnsemblesScreen(
        onBack: () {},
        onNext: (rules) => chosen = rules,
      ),
    ));
    await settle(tester);

    await tester.tap(find.byTooltip('Voir').first); // Fiesta classique
    await settle(tester);
    expect(find.text('Fiesta classique'), findsOneWidget);
    expect(find.text('TOUJOURS'), findsNothing, reason: 'tout en aléatoire');
    expect(find.text('ALÉATOIRE PAR MANCHE (1 PAR MANCHE)'), findsOneWidget);
    expect(find.text('CARTOUCHES'), findsOneWidget);
    expect(find.textContaining('Équilibrer la partie'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    expect(find.byType(Switch), findsNothing);

    await tester.tap(find.text('Dupliquer'));
    await settle(tester);
    expect(find.text('Fiesta classique (2)'), findsOneWidget);

    await tester.tap(find.text('Pro Player'));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await settle(tester);
    expect(chosen?.ensembleName, 'Pro Player');
  });

  testWidgets(
      'Page « Voir » sans cartouche : pas de section '
      'vide', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await givenPrefs();
    await tester.pumpWidget(MaterialApp(
        home: FiestaEnsemblesScreen(onBack: () {}, onNext: (_) {})));
    await settle(tester);

    await tester.tap(find
        .byTooltip('Voir')
        .at(kProvidedEnsembles.indexWhere((e) => e.name == 'Droit au but')));
    await settle(tester);
    expect(find.text('TOUJOURS'), findsOneWidget);
    expect(find.textContaining('ALÉATOIRE'), findsNothing);
    expect(find.text('CARTOUCHES'), findsNothing);
    // « Toujours » : pas de manches quand c'est toutes.
    expect(find.text('Toutes les manches'), findsNothing);
    expect(find.textContaining('Manche'), findsNothing);
    await tester.tap(find.byType(AppBackButton));
    await settle(tester);

    await tester.tap(find
        .byTooltip('Voir')
        .at(kProvidedEnsembles.indexWhere((e) => e.name == 'Bilingue')));
    await settle(tester);
    expect(find.text('Manches 1 et 2 seulement'), findsOneWidget);
  });
}
