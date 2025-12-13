import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class GuessItAllApp extends StatelessWidget {
  const GuessItAllApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Guess It All',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: _buildCurrentScreen(provider.game.currentScreen),
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
      default:
        return const HomeScreen();
    }
  }
}
