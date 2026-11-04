import 'package:flutter/material.dart';
import '../../screens/rules_tutorial_screen.dart';
import '../../services/storage_service.dart';

/// Tuto des règles ouvert d'office au premier « Jouer » tant que l'onboarding
/// des règles de première partie n'est pas traité (`guessItAll_tutorialSeen`
/// faux : téléphone sans historique, cf. `FirstGameHelp.initAtStartup`), sans
/// poser de question : « Passer » le ferme. Un `true` déjà écrit (question
/// « Première partie ? » posée par une ancienne version, ou tuto ouvert)
/// reste valable : rien ne s'ouvre.
class FirstGamePrompt {
  FirstGamePrompt._();

  /// Ouvre le tuto si l'onboarding n'est pas traité. Rend la main quand l'appelant peut
  /// continuer vers la partie.
  static Future<void> maybeShow(BuildContext context) async {
    if (await StorageService().hasSeenTutorial()) return;
    if (!context.mounted) return;
    await RulesTutorialScreen.show(context);
  }
}
