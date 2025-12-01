import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/home_button.dart';
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
                  Text(
                    AppConstants.roundModes[provider.game.currentRound] ?? '',
                    style: AppTextStyles.subtitle(fontSize: 28),
                    textAlign: TextAlign.center,
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
          const HomeButton(),
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
}
