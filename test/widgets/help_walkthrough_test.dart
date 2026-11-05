import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app.dart';
import 'package:guess_it_all_mobile/models/player.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensemble_editor_screen.dart';
import 'package:guess_it_all_mobile/screens/fiesta_tutorial_screen.dart';
import 'package:guess_it_all_mobile/screens/rules_tutorial_screen.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/coach_walk.dart';
import '../helpers/test_prefs.dart';
import '../screens/fiesta_v4_screens_test.dart'
    show finishRound, givenPhone, loadFonts, pumpGame, settle;

const _names = ['Ana', 'Bob', 'Cid', 'Dan'];

/// L'app sur un écran hors partie, en 360 × 640. Mots écrits à la main : le
/// chargement des fichiers de mots ne se termine pas sous l'horloge simulée.
Future<GameProvider> pumpScreen(WidgetTester tester, String screen,
    {bool withPlayers = false}) async {
  givenPhone(tester);
  await givenPrefs({
    AppConstants.tutorialSeenKey: true,
    AppConstants.fiestaTutorialSeenKey: true,
    AppConstants.firstGameDoneKey: true,
  });
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  provider.updateSettings(wordChoice: AppConstants.wordChoiceCustom);
  if (withPlayers) {
    for (final name in _names) {
      final id = (provider.addPlayer(name)['player'] as Player).id;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
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

  testWidgets('Accueil sans partie : le bouton s\'appelle « Jouer »',
      (tester) async {
    await pumpScreen(tester, AppConstants.screenHome);
    expect(await walkHelp(tester), ['Jouer', 'Règles', 'Historique']);
  });

  testWidgets('Accueil avec une session : Rejouer, puis Nouvelle partie',
      (tester) async {
    await pumpScreen(tester, AppConstants.screenHome, withPlayers: true);
    expect(await walkHelp(tester),
        ['Rejouer', 'Nouvelle partie', 'Règles', 'Historique']);
  });

  testWidgets('Accueil, partie suspendue : Reprendre, puis Nouvelle partie',
      (tester) async {
    final provider =
        await pumpScreen(tester, AppConstants.screenHome, withPlayers: true);
    await tester.runAsync(provider.startGame);
    await tester.runAsync(provider.suspendGame);
    await settle(tester);
    expect(await walkHelp(tester),
        ['Reprendre', 'Nouvelle partie', 'Règles', 'Historique']);
  });

  testWidgets('Paramètres', (tester) async {
    await pumpScreen(tester, AppConstants.screenSettings);
    expect(await walkHelp(tester), [
      'Joueurs et équipes',
      'Classique ou Fiesta',
      'Choix des mots',
      'Catégories & Difficultés',
      'Avancés',
    ]);
  });

  testWidgets('Joueurs', (tester) async {
    await pumpScreen(tester, AppConstants.screenPlayers);
    expect(await walkHelp(tester),
        ['Les joueurs', 'Les mots du joueur', 'Suivant']);
  });

  testWidgets('Équipes', (tester) async {
    await pumpScreen(tester, AppConstants.screenTeams, withPlayers: true);
    expect(await walkHelp(tester), ['Les équipes', 'Mélanger', 'Commencer']);
  });

  testWidgets('Liste des ensembles', (tester) async {
    await pumpScreen(tester, AppConstants.screenFiestaEnsembles);
    expect(await walkHelp(tester),
        ['Prêts à jouer', 'Créer un ensemble', 'Suivant']);
  });

  testWidgets('Éditeur d\'ensemble', (tester) async {
    givenPhone(tester);
    await givenPrefs();
    await tester.pumpWidget(
        const MaterialApp(home: FiestaEnsembleEditorScreen(others: [])));
    await settle(tester);
    expect(
        await walkHelp(tester), ['Les 3 menus', 'Cartouches', 'Enregistrer']);
  });

  testWidgets('le tour, la vérification, puis l\'écran fixe après M3',
      (tester) async {
    final provider = await pumpGame(tester, null);

    // Pas de `settle` : `runAsync` laisserait passer l'erreur de la plateforme
    // audio, absente ici.
    Future<void> pumps() async {
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
    }

    provider.startTurn();
    provider.startTurnTimer();
    await pumps();
    expect(await walkHelp(tester), [
      'Le chrono',
      'Le mot',
      'Trouvé',
      'Passer',
      'Pause',
      'Terminer le tour'
    ]);

    provider.endTurn();
    await pumps();
    expect(provider.game.currentScreen, AppConstants.screenVerification);
    expect(await walkHelp(tester),
        ['Vérifie les mots', 'Temps écoulé', 'Valider']);
    provider.savePreValidationState(const []);
    provider.validateWords(const []);

    finishRound(provider);
    provider.nextRound();
    finishRound(provider);
    provider.nextRound();
    finishRound(provider);
    await pumps();
    expect(provider.game.currentScreen, AppConstants.screenTransition);
    expect(await walkHelp(tester),
        ['Mots du dernier tour', 'Retour', 'Voir les résultats']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  Future<int> walkPager(WidgetTester tester, Widget tutorial) async {
    givenPhone(tester);
    await givenPrefs();
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return TextButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => tutorial)),
        child: const Text('ouvrir'),
      );
    })));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    var cards = 1;
    while (find.text('Suivant').evaluate().isNotEmpty) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      cards++;
    }
    await tester.tap(find.text('C\'est parti !'));
    await tester.pumpAndSettle();
    expect(find.text('ouvrir'), findsOneWidget);
    return cards;
  }

  testWidgets('Tuto des règles : les 4 cartes, de bout en bout',
      (tester) async {
    expect(
        await walkPager(tester, const RulesTutorialScreen(passPenalty: 5)), 4);
  });

  testWidgets('Tuto Fiesta : les 3 cartes, de bout en bout', (tester) async {
    expect(await walkPager(tester, const FiestaTutorialScreen()), 3);
  });
}
