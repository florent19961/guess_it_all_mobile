import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/home_button.dart';
import '../widgets/common/back_button.dart';
import '../widgets/effects/shooting_stars.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final currentTeam = provider.getCurrentTeam();
    final currentPlayer = provider.getCurrentPlayer();
    final teamColor = AppColors.getTeamColor(provider.game.currentTeamIndex);

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Round info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondaryCyan, width: 2),
                    ),
                    child: Text(
                      'Manche ${provider.game.currentRound}/3',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryCyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Round mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppConstants.roundModes[provider.game.currentRound] ?? '',
                        style: AppTextStyles.subtitle(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showRulesDialog(context, provider.game.currentRound),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gray600,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Team and player info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: teamColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: teamColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentTeam?.name ?? '',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 24,
                            color: teamColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentPlayer?.name ?? '',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Words remaining
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.style, color: AppColors.gray400, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.game.remainingWords.length} mots restants',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Scores
                  _buildScoresRow(provider),

                  const Spacer(),

                  // Time bonus indicator
                  if (provider.game.turnBonusTime != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Temps bonus: ${provider.game.turnBonusTime}s',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  AppButton(
                    text: 'Commencer le tour',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () => provider.startTurn(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const HomeButton(alignRight: true),
          // Back button conditionnel
          if (provider.isFirstTurnOfGame)
            GameBackButton(
              onPressed: () => _showBackToTeamsDialog(context, provider),
            )
          else if (provider.canGoBackToVerification)
            GameBackButton(
              onPressed: () => _showBackToVerificationDialog(context, provider),
            ),
        ],
      ),
    );
  }

  void _showBackToTeamsDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.gray500, width: 2),
        ),
        title: Text(
          'Retour aux équipes',
          style: AppTextStyles.subtitle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Voulez-vous revenir à la composition des équipes ?',
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
            text: 'Retour',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.goBackToTeams();
            },
          ),
        ],
      ),
    );
  }

  void _showBackToVerificationDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.gray500, width: 2),
        ),
        title: Text(
          'Modifier la validation',
          style: AppTextStyles.subtitle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Voulez-vous revenir à l\'écran de vérification pour corriger les mots validés ?',
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
            text: 'Retour',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.restorePreValidationState();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoresRow(GameProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: provider.teams.asMap().entries.map((entry) {
        final team = entry.value;
        final teamColor = AppColors.getTeamColor(entry.key);
        final isCurrentTeam = entry.key == provider.game.currentTeamIndex;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentTeam ? teamColor.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentTeam ? teamColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                team.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: teamColor,
                ),
              ),
              Text(
                '${team.score}',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 24,
                  color: teamColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showRulesDialog(BuildContext context, int round) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.secondaryCyan, width: 2),
        ),
        title: Text(
          AppConstants.roundModes[round] ?? '',
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 24,
            color: AppColors.secondaryCyan,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          AppConstants.roundDescriptions[round] ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Compris !',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryCyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
