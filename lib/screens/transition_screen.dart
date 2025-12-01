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
                  const SizedBox(height: 40),

                  // Round completed badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.success, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Manche $currentRound terminée !',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Scores
                  Text(
                    'Scores',
                    style: AppTextStyles.subtitle(fontSize: 30),
                  ),
                  const SizedBox(height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: sortedTeams.asMap().entries.map((entry) {
                          final index = entry.key;
                          final team = entry.value;
                          final originalIndex = provider.teams.indexOf(team);
                          final teamColor = AppColors.getTeamColor(originalIndex);

                          // Calculer le rang réel en tenant compte des ex æquo
                          int rank = 0;
                          for (int i = 0; i < index; i++) {
                            if (sortedTeams[i].score > team.score) {
                              rank++;
                            }
                          }

                          final medal = rank == 0
                              ? '🥇'
                              : rank == 1
                                  ? '🥈'
                                  : rank == 2
                                      ? '🥉'
                                      : rank == 3
                                          ? '🍫'
                                          : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: teamColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: teamColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                if (medal.isNotEmpty)
                                  Text(
                                    medal,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                if (medal.isNotEmpty) const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    team.name,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: teamColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${team.score}',
                                  style: TextStyle(
                                    fontFamily: 'Bangers',
                                    fontSize: 28,
                                    color: teamColor,
                                  ),
                                ),
                                const Text(
                                  ' pts',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time bonus indicator (only show if not last round)
                  if (provider.game.turnBonusTime != null &&
                      provider.game.turnBonusTime! > 0 &&
                      currentRound < 3) ...[
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
