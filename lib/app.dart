import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'theme/app_theme.dart';
import 'providers/game_provider.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/players_screen.dart';
import 'screens/words_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/game_screen.dart';
import 'screens/countdown_screen.dart';
import 'screens/turn_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/transition_screen.dart';
import 'screens/results_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/history_screen.dart';
import 'screens/game_mode_screen.dart';
import 'screens/fiesta_choice_screen.dart';
import 'screens/fiesta_auto_screen.dart';
import 'screens/fiesta_recap_screen.dart';
import 'screens/fiesta_ensembles_screen.dart';

class GuessItAllApp extends StatelessWidget {
  const GuessItAllApp({super.key});

  // Configuration de l'upgrader pour les mises à jour forcées
  static final _upgrader = Upgrader(
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderPlayStore(),
      oniOS: () => UpgraderAppStore(),
    ),
    languageCode: 'fr',
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Guess It All',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: UpgradeAlert(
            upgrader: _upgrader,
            dialogStyle: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                ? UpgradeDialogStyle.cupertino
                : UpgradeDialogStyle.material,
            child: _buildCurrentScreen(provider.game.currentScreen),
          ),
        );
      },
    );
  }

  Widget _buildCurrentScreen(String screen) {
    switch (screen) {
      case AppConstants.screenHome:
        return const HomeScreen();
      case AppConstants.screenSettings:
        return const SettingsScreen();
      case AppConstants.screenRules:
        return const RulesScreen();
      case AppConstants.screenPlayers:
        return const PlayersScreen();
      case AppConstants.screenWords:
        return const WordsScreen();
      case AppConstants.screenTeams:
        return const TeamsScreen();
      case AppConstants.screenGame:
        return const GameScreen();
      case AppConstants.screenCountdown:
        return const CountdownScreen();
      case AppConstants.screenTurn:
        return const TurnScreen();
      case AppConstants.screenVerification:
        return const VerificationScreen();
      case AppConstants.screenTransition:
        return const TransitionScreen();
      case AppConstants.screenResults:
        return const ResultsScreen();
      case AppConstants.screenStats:
        return const StatsScreen();
      case AppConstants.screenCategories:
        return const CategoriesScreen();
      case AppConstants.screenHistory:
        return const HistoryScreen();
      case AppConstants.screenGameMode:
        return const GameModeScreen();
      case AppConstants.screenFiestaChoice:
        return const FiestaChoiceScreen();
      case AppConstants.screenFiestaAuto:
        return const FiestaAutoScreen();
      case AppConstants.screenFiestaRecap:
        return const FiestaRecapScreen();
      case AppConstants.screenFiestaEnsembles:
        return Builder(builder: (context) {
          final provider = context.read<GameProvider>();
          return FiestaEnsemblesScreen(
            onBack: () => provider.goToScreen(AppConstants.screenFiestaChoice),
            onUse: (ensemble) {
              provider.setPendingFiesta(ensemble.rules);
              provider.goToScreen(AppConstants.screenFiestaRecap);
            },
          );
        });
      default:
        return const HomeScreen();
    }
  }
}
