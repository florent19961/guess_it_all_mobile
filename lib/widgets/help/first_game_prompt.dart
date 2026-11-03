import 'package:flutter/material.dart';
import '../../screens/rules_tutorial_screen.dart';
import '../../services/storage_service.dart';
import '../common/app_button.dart';
import '../common/app_modal.dart';

/// « Première partie ? » : demandé une seule fois, au premier « Jouer ».
class FirstGamePrompt {
  FirstGamePrompt._();

  /// Pose la question si le tuto n'a jamais été vu, et ouvre le tuto sur
  /// « Oui ». Rend la main quand l'appelant peut continuer vers la partie.
  static Future<void> maybeShow(BuildContext context) async {
    final storage = StorageService();
    if (await storage.hasSeenTutorial()) return;
    await storage.markTutorialSeen();
    if (!context.mounted) return;

    final wantsTutorial = await AppModal.show<bool>(
      context,
      title: 'Première partie ?',
      child: Builder(
        builder: (dialogContext) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'On t\'explique les règles en 4 cartes, 30 secondes chrono.',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Oui, montre-moi',
              variant: AppButtonVariant.primary,
              fullWidth: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Je connais déjà',
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (wantsTutorial == true && context.mounted) {
      await RulesTutorialScreen.show(context);
    }
  }
}
