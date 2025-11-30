import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/effects/shooting_stars.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final sortedTeams = provider.getTeamsSortedByScore();

    return ShootingStars(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                'Résultats',
                style: AppTextStyles.title(fontSize: 48),
              ),
              const SizedBox(height: 32),

              // Podium
              _buildPodium(provider, sortedTeams),

              const SizedBox(height: 32),

              // Detailed scores
              _buildDetailedScores(provider, sortedTeams),

              const SizedBox(height: 32),

              // Action buttons
              AppButton(
                text: 'Rejouer',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                fullWidth: true,
                icon: const Icon(Icons.replay, color: Colors.white),
                onPressed: () => provider.restartWithSamePlayers(),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Nouvelle partie',
                variant: AppButtonVariant.secondary,
                fullWidth: true,
                onPressed: () {
                  provider.resetGame();
                  provider.goToScreen(AppConstants.screenSettings);
                },
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Accueil',
                variant: AppButtonVariant.ghost,
                onPressed: () {
                  provider.resetGame();
                  provider.goToScreen(AppConstants.screenHome);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(GameProvider provider, List<dynamic> sortedTeams) {
    if (sortedTeams.isEmpty) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (sortedTeams.length > 1)
          _buildPodiumPosition(
            team: sortedTeams[1],
            originalIndex: provider.teams.indexOf(sortedTeams[1]),
            position: 2,
            height: 100,
          )
        else
          const SizedBox(width: 100),

        const SizedBox(width: 8),

        // 1st place
        _buildPodiumPosition(
          team: sortedTeams[0],
          originalIndex: provider.teams.indexOf(sortedTeams[0]),
          position: 1,
          height: 140,
        ),

        const SizedBox(width: 8),

        // 3rd place
        if (sortedTeams.length > 2)
          _buildPodiumPosition(
            team: sortedTeams[2],
            originalIndex: provider.teams.indexOf(sortedTeams[2]),
            position: 3,
            height: 70,
          )
        else
          const SizedBox(width: 100),
      ],
    );
  }

  Widget _buildPodiumPosition({
    required dynamic team,
    required int originalIndex,
    required int position,
    required double height,
  }) {
    final teamColor = AppColors.getTeamColor(originalIndex);
    final medal = position == 1
        ? '🥇'
        : position == 2
            ? '🥈'
            : '🥉';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          medal,
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(height: 8),
        Text(
          team.name,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: teamColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${team.score} pts',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 24,
            color: teamColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: height,
          decoration: BoxDecoration(
            color: teamColor.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: teamColor, width: 2),
          ),
          child: Center(
            child: Text(
              '$position',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 48,
                color: teamColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedScores(GameProvider provider, List<dynamic> sortedTeams) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray600, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'Détail par manche',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Équipe',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
              ),
              ...List.generate(
                3,
                (i) => Expanded(
                  child: Text(
                    'M${i + 1}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.gray600),

          // Team rows
          ...sortedTeams.map((team) {
            final originalIndex = provider.teams.indexOf(team);
            final teamColor = AppColors.getTeamColor(originalIndex);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      team.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: teamColor,
                      ),
                    ),
                  ),
                  ...List.generate(
                    3,
                    (i) => Expanded(
                      child: Text(
                        '${team.scoreByRound[i]}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${team.score}',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 18,
                        color: teamColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
