import 'package:flutter/material.dart';
import '../../screens/rules_tutorial_screen.dart';
import '../../services/storage_service.dart';

/// Tuto des règles ouvert d'office au premier « Jouer » d'un téléphone neuf
/// (sans historique, cf. `FirstGameHelp.initAtStartup`), sans poser de
/// question : « Passer » le ferme. Un téléphone déjà venu ne voit rien.
class FirstGamePrompt {
  FirstGamePrompt._();

  /// Ouvre le tuto s'il n'a jamais été vu. Rend la main quand l'appelant peut
  /// continuer vers la partie.
  static Future<void> maybeShow(BuildContext context) async {
    if (await StorageService().hasSeenTutorial()) return;
    if (!context.mounted) return;
    await RulesTutorialScreen.show(context);
  }
}
