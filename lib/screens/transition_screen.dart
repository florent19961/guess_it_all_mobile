import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/home_button.dart';

class TransitionScreen extends StatelessWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final currentRound = provider.game.currentRound;
    final isLastRound = currentRound >= 3;
    final sortedTeams = provider.getTeamsSortedByScore();

    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Round completed badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Manche $currentRound terminée !',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Scores
                  Text(
                    'Scores',
                    style: AppTextStyles.subtitle(fontSize: 32),
                  ),
                  const SizedBox(height: 24),

                  ...sortedTeams.asMap().entries.map((entry) {
                    final index = entry.key;
                    final team = entry.value;
                    final originalIndex = provider.teams.indexOf(team);
                    final teamColor = AppColors.getTeamColor(originalIndex);
                    final medal = index == 0
                        ? '🥇'
                        : index == 1
                            ? '🥈'
                            : index == 2
                                ? '🥉'
                                : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: teamColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: teamColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          if (medal.isNotEmpty)
                            Text(
                              medal,
                              style: const TextStyle(fontSize: 24),
                            ),
                          if (medal.isNotEmpty) const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              team.name,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: teamColor,
                              ),
                            ),
                          ),
                          Text(
                            '${team.score}',
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 32,
                              color: teamColor,
                            ),
                          ),
                          const Text(
                            ' pts',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Spacer(),

                  // Next round info
                  if (!isLastRound) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondaryCyan, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Prochaine manche',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.roundModes[currentRound + 1] ?? '',
                            style: AppTextStyles.subtitle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.roundDescriptions[currentRound + 1] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Time bonus indicator
                  if (provider.game.turnBonusTime != null &&
                      provider.game.turnBonusTime! > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Temps bonus conservé: ${provider.game.turnBonusTime}s',
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
                    text: isLastRound ? 'Voir les résultats' : 'Manche suivante',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () => provider.nextRound(),
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
}
