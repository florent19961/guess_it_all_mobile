import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';
import 'app_button.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: () => _handleHomePress(context),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.secondaryCyan,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  void _handleHomePress(BuildContext context) {
    final provider = context.read<GameProvider>();
    final currentScreen = provider.game.currentScreen;

    final gameScreens = [
      AppConstants.screenGame,
      AppConstants.screenCountdown,
      AppConstants.screenTurn,
      AppConstants.screenVerification,
      AppConstants.screenTransition,
    ];

    if (gameScreens.contains(currentScreen)) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.backgroundMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.secondaryCyan, width: 2),
          ),
          title: Text(
            'Interrompre la partie',
            style: AppTextStyles.subtitle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'La partie sera mise en pause et sauvegardée automatiquement.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            AppButton(
              text: 'Annuler',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              text: 'Accueil',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                provider.suspendGame();
              },
            ),
          ],
        ),
      );
    } else {
      provider.goToScreen(AppConstants.screenHome);
    }
  }
}
