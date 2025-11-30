import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_modal.dart';
import '../widgets/effects/shooting_stars.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final hasSuspendedGame = provider.game.isGameSuspended;

    return ShootingStars(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Guess It All',
                style: AppTextStyles.title(fontSize: 64),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (hasSuspendedGame) ...[
                AppButton(
                  text: 'Reprendre',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () => provider.resumeGame(),
                ),
                const SizedBox(height: 16),
              ],
              AppButton(
                text: hasSuspendedGame ? 'Nouvelle partie' : 'Jouer',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                fullWidth: true,
                onPressed: () {
                  if (hasSuspendedGame) {
                    _showNewGameConfirmation(context, provider);
                  } else {
                    provider.resetGame();
                    provider.goToScreen(AppConstants.screenSettings);
                  }
                },
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Règles',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.medium,
                onPressed: () => provider.goToScreen(AppConstants.screenRules),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showClearDataConfirmation(context, provider),
                child: const Text(
                  'Effacer les données',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.gray500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewGameConfirmation(BuildContext context, GameProvider provider) {
    AppModal.show(
      context,
      title: 'Nouvelle partie',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Voulez-vous abandonner la partie en cours et en commencer une nouvelle ?',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Annuler',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Confirmer',
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    provider.resetGame();
                    provider.goToScreen(AppConstants.screenSettings);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context, GameProvider provider) {
    AppModal.show(
      context,
      title: 'Effacer les données',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cette action supprimera toutes les données sauvegardées.',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Annuler',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Effacer',
                  variant: AppButtonVariant.danger,
                  onPressed: () {
                    Navigator.of(context).pop();
                    provider.clearLocalStorage();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
