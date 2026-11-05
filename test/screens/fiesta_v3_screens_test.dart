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

  group('Transition', () {
    for (final (label, fiesta) in [
      ('Classique', null),
      (
        'Fiesta',
        FiestaRules(mode: FiestaMode.auto),
      ),
    ]) {
      testWidgets(
          '$label : la manche, qui commence, les mots, le bouton ; '
          'ni temps ni modificateurs', (tester) async {
        final provider = await pumpGame(tester, fiesta);
        finishRound(provider);
        await settle(tester);
        expect(provider.game.currentScreen, AppConstants.screenTransition);

        expect(find.text('MANCHE 1 TERMINÉE'), findsOneWidget);
        expect(find.textContaining('Manche 2 :'), findsOneWidget);
        expect(find.textContaining('Commence : ', findRichText: true),
            findsOneWidget);
        expect(find.textContaining('mots devinés'), findsOneWidget);
        expect(find.text('Manche 2'), findsOneWidget);

        expect(find.textContaining('Temps bonus'), findsNothing);
        expect(find.textContaining('25'), findsNothing);
        expect(find.textContaining('Tirage'), findsNothing);
        expect(find.textContaining('Coup de pouce'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets(
      'Avant le tour : un malus reçu se lit dans « Ce tour », aucune alerte '
      'avant le compte à rebours', (tester) async {
    final provider = await pumpGame(
      tester,
      FiestaRules(mode: FiestaMode.custom, drawCount: 0, modifiers: {
        'no_pass': ModifierSetting(
            active: true, rounds: const {1}, mode: ModifierMode.always),
      }),
    );
    expect(provider.game.currentScreen, AppConstants.screenGame);
    expect(find.text('Ce tour'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Commencer le tour'));
    await tester.pump();
    expect(provider.game.currentScreen, AppConstants.screenCountdown,
        reason: 'directement le compte à rebours, sans écran intermédiaire');
    expect(find.text('Compris'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  group('Explosif en manche 3 à 360 × 640', () {
    /// La zone tient dans son `ClipRect`, sans rien couper, et le bouton reste
    /// en dessous.
    void expectFits(WidgetTester tester, GameProvider provider) {
      final bonus = provider.reserve
          .where((c) => c.nature == ModifierNature.bonus)
          .length;
      expect((provider.reserve.length - bonus, bonus), (11, 4));
      final help = find.text('Touche : activer · Appui long : explication');
      final zone = find.byType(FiestaTurnZone);
      expect(tester.getBottomLeft(help).dy,
          lessThanOrEqualTo(tester.getBottomLeft(zone).dy));
      expect(
          tester.getBottomLeft(zone).dy,
          lessThanOrEqualTo(
              tester.getTopLeft(find.text('Commencer le tour')).dy));
      expect(tester.takeException(), isNull);
    }

    testWidgets('11 malus + 4 bonus tiennent, continuation et vrai tour',
        (tester) async {
      final explosive =
          kProvidedEnsembles.firstWhere((e) => e.id == 'provided_explosive');
      final provider = await pumpGame(tester, explosive.rules);
      for (var round = 1; round < 3; round++) {
        finishRound(provider);
        provider.nextRound();
      }
      await settle(tester);
      expect(provider.isContinuation, isTrue);
      expectFits(tester, provider);

      // Bonus allumé : il a quitté la réserve, « Ce tour » se remplit.
      provider.toggleBonus('plus_10s');
      await settle(tester);
      expectFits(tester, provider);
      expect(find.text('Temps bonus : ${provider.turnTime.total}s'),
          findsOneWidget);
      provider.toggleBonus('plus_10s');

      // Continuation chargée : 2 bonus allumés, 3 malus envoyés. L'aide cède sa
      // place, rien n'est coupé.
      provider.toggleBonus('plus_10s');
      provider.toggleBonus('double_points');
      final other =
          provider.teams.singleWhere((t) => t != provider.getCurrentTeam());
      for (final id in ['no_pass', 'reversed', 'mime_no_arms']) {
        expect(provider.inflictMalus(id, other.id), isNull);
      }
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Touche : activer · Appui long : explication'),
          findsNothing);
      expect(
          tester.getBottomLeft(find.textContaining('→').first).dy,
          lessThanOrEqualTo(
              tester.getBottomLeft(find.byType(FiestaTurnZone)).dy));
      for (final m in List.of(provider.sentThisTurn)) {
        provider.cancelSent(m);
      }
      provider.toggleBonus('plus_10s');
      provider.toggleBonus('double_points');

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
      final explosive =
          kProvidedEnsembles.firstWhere((e) => e.id == 'provided_explosive');
      final provider = await pumpGame(tester, explosive.rules);
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
      FiestaRules(mode: FiestaMode.custom, drawCount: 0, modifiers: {
        'plus_10s': ModifierSetting(
            active: true,
            rounds: const {1, 2, 3},
            mode: ModifierMode.cartridge),
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
    testWidgets(
        'bonus, −10 s et blocage : un interrupteur et un compteur, aucun mode '
        'ni manche ; « Une seule réponse » : Toujours et Au tirage seulement ; '
        'les autres malus : les 3 modes', (tester) async {
      await pumpEditor(tester);

      // Passe gratuite (active par défaut, à 2) : compteur directement.
      await scrollToText(tester, 'Passe gratuite');
      final freePass = rowOf('Passe gratuite');
      Finder inside(Finder of, String text) =>
          find.descendant(of: of, matching: find.text(text));
      expect(inside(freePass, 'Cartouches pour la partie'), findsOneWidget);
      expect(inside(freePass, 'Régler'), findsNothing);
      expect(find.text('Toujours'), findsNothing);
      expect(find.text('En stock'), findsNothing);

      // « Une seule réponse » : deux modes.
      await scrollToText(tester, 'Une seule réponse');
      await tester.tap(inside(rowOf('Une seule réponse'), 'Régler'));
      await tester.pump();
      expect(find.text('Toujours'), findsOneWidget);
      expect(find.text('Au tirage'), findsOneWidget);
      expect(find.text('Cartouche'), findsNothing);
      expect(find.text('Manches'), findsOneWidget);

      // Mot à l'envers : les 3 ; en Cartouche, le compteur remplace les manches.
      await scrollToText(tester, 'Mot à l\'envers');
      await tester.tap(inside(rowOf('Mot à l\'envers'), 'Régler'));
      await tester.pump();
      expect(find.text('Cartouche'), findsOneWidget);
      expect(find.text('Manches'), findsNothing);
      expect(inside(rowOf('Mot à l\'envers'), 'Cartouches pour la partie'),
          findsOneWidget);
      await tester.tap(find.text('Au tirage'));
      await tester.pump();
      expect(find.text('Manches'), findsOneWidget);
    });

    testWidgets(
        'allumer un mime n\'éteint pas les autres ; le sous-titre ne parle plus '
        'd\'exclusivité ; un Toujours avec un autre mime est refusé en les '
        'nommant', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField), 'Soirée');
      await tester.pump();
      await scrollToText(tester, 'MIMES');
      expect(find.textContaining('UN SEUL'), findsNothing);

      await scrollToText(tester, 'Mime sans les poings');
      await tester.tap(find.descendant(
          of: rowOf('Mime sans les poings'), matching: find.byType(Switch)));
      await tester.pump();
      await scrollToText(tester, 'Mime sans les bras');
      expect(
          tester
              .widget<Switch>(find.descendant(
                  of: rowOf('Mime sans les bras'),
                  matching: find.byType(Switch)))
              .value,
          isTrue);

      await tester.tap(find.descendant(
          of: rowOf('Mime sans les bras'), matching: find.text('Régler')));
      await tester.pump();
      await tester.tap(find.text('Toujours'));
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      expect(
          find.text('Mime sans les bras est « Toujours » : retire Mime sans '
              'les poings ou change son mode.'),
          findsOneWidget);
    });

    testWidgets(
        'cartouche à 0 sans coup de pouce : refusée avec un message clair',
        (tester) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField), 'Soirée');
      await tester.pump();

      // Passe gratuite à 0 : acceptable tant que le coup de pouce est là.
      await scrollToText(tester, 'Passe gratuite');
      final moins = find.descendant(
          of: rowOf('Passe gratuite'), matching: find.byTooltip('Moins'));
      await tester.tap(moins);
      await tester.pump();
      await tester.tap(moins);
      await tester.pump();
      expect(find.text('Gagnées seulement'), findsOneWidget);

      // Le compteur du coup de pouce, ramené à 0.
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      final boost = find
          .ancestor(
              of: find.text('Coup de pouce à l\'équipe menée'),
              matching: find.byType(Row))
          .first;
      await tester
          .tap(find.descendant(of: boost, matching: find.byTooltip('Moins')));
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      expect(
          find.textContaining('Passe gratuite : 0 cartouche'), findsOneWidget);
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

    await tester.tap(find.text('Voir').first); // Fiesta classique
    await settle(tester);
    expect(find.text('Fiesta classique'), findsOneWidget);
    expect(find.text('TOUJOURS'), findsNothing, reason: 'tout au tirage');
    expect(find.text('AU TIRAGE (1 PAR MANCHE)'), findsOneWidget);
    expect(find.text('CARTOUCHES POUR LA PARTIE'), findsOneWidget);
    expect(find.text('COUP DE POUCE À L\'ÉQUIPE MENÉE'), findsOneWidget);
    expect(
        find.text('1 cartouche au hasard après chaque manche'), findsOneWidget);
    expect(find.text('Bonus de 10 s'), findsOneWidget);
    expect(find.text('Gagnées seulement'), findsWidgets);
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
      'Page « Voir » sans coup de pouce ni cartouche : pas de section '
      'vide', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await givenPrefs();
    await tester.pumpWidget(MaterialApp(
        home: FiestaEnsemblesScreen(onBack: () {}, onNext: (_) {})));
    await settle(tester);

    await tester.tap(find
        .text('Voir')
        .at(kProvidedEnsembles.indexWhere((e) => e.name == 'Droit au but')));
    await settle(tester);
    expect(find.text('TOUJOURS'), findsOneWidget);
    expect(find.textContaining('AU TIRAGE'), findsNothing);
    expect(find.text('CARTOUCHES POUR LA PARTIE'), findsNothing);
    expect(find.textContaining('COUP DE POUCE'), findsNothing);
  });
}
