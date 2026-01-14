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
    final hasGameSession = provider.hasGameSession;

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
                style: AppTextStyles.title(fontSize: 72),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Cas 1: Partie suspendue
              if (hasSuspendedGame) ...[
                AppButton(
                  text: 'Reprendre',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () => provider.resumeGame(),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Nouvelle partie',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () => _showNewGameConfirmation(context, provider),
                ),
              ]
              // Cas 2: Session existante (joueurs d'une partie précédente)
              else if (hasGameSession) ...[
                AppButton(
                  text: 'Rejouer',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () async {
                    await provider.restartWithSamePlayers();
                  },
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Nouvelle partie',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () async {
                    await provider.clearLocalStorage();
                    provider.goToScreen(AppConstants.screenSettings);
                  },
                ),
              ]
              // Cas 3: Pas de partie en cours
              else ...[
                AppButton(
                  text: 'Jouer',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () async {
                    await provider.clearLocalStorage();
                    provider.goToScreen(AppConstants.screenSettings);
                  },
                ),
              ],

              const SizedBox(height: 16),
              AppButton(
                text: 'Règles',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.medium,
                onPressed: () => provider.goToScreen(AppConstants.screenRules),
              ),
              const Spacer(),
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
                  text: 'Valider',
                  variant: AppButtonVariant.primary,
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await provider.clearLocalStorage();
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
}
