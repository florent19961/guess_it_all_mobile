import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_back_button.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Statistiques',
                    style: AppTextStyles.subtitle(fontSize: 36),
                  ),
                  const SizedBox(height: 32),

                  // Section 1: Classement des joueurs
                  _buildPlayerRanking(provider),

                  const SizedBox(height: 32),

                  // Section 2: Évolution des scores
                  _buildScoreEvolution(provider),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          AppBackButton(
            onPressed: () => provider.goToScreen(AppConstants.screenResults),
          ),
          // Icône accueil en haut à droite
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                await provider.endGameAndGoHome();
                provider.goToScreen(AppConstants.screenHome);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gray600, width: 2),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRanking(GameProvider provider) {
    // Calculer le temps total et mots total par joueur
    final Map<String, int> playerTotalTime = {};
    final Map<String, int> playerTotalWords = {};

    for (final entry in provider.game.history) {
      final words = entry.wordsGuessed.length;
      if (words > 0) {
        playerTotalTime[entry.playerId] =
            (playerTotalTime[entry.playerId] ?? 0) + entry.timeSpent;
        playerTotalWords[entry.playerId] =
            (playerTotalWords[entry.playerId] ?? 0) + words;
      }
    }

    // Calculer le temps moyen par mot (plus bas = meilleur)
    final Map<String, double> playerAvgTime = {};
    for (final playerId in playerTotalWords.keys) {
      final totalTime = playerTotalTime[playerId] ?? 0;
      final totalWords = playerTotalWords[playerId] ?? 1;
      playerAvgTime[playerId] = totalTime / totalWords;
    }

    // Trier par temps moyen croissant (le plus rapide en premier)
    final sortedPlayers = playerAvgTime.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    if (sortedPlayers.isEmpty) {
      return const SizedBox();
    }

    // Le temps le plus long pour l'échelle de la barre (inversée)
    final maxTime = sortedPlayers.last.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Les plus rapides',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final playerId = entry.value.key;
            final avgTime = entry.value.value;
            final player = provider.getPlayerById(playerId);
            final playerName = player?.name ?? 'Joueur inconnu';

            // Trouver l'équipe du joueur pour la couleur
            Color playerColor = AppColors.gray400;
            for (int i = 0; i < provider.teams.length; i++) {
              if (provider.teams[i].playerIds.contains(playerId)) {
                playerColor = AppColors.getTeamColor(i);
                break;
              }
            }

            final medal = index == 0
                ? '🥇'
                : index == 1
                    ? '🥈'
                    : index == 2
                        ? '🥉'
                        : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (medal.isNotEmpty)
                    Text(medal, style: const TextStyle(fontSize: 18)),
                  if (medal.isNotEmpty) const SizedBox(width: 8),
                  if (medal.isEmpty) const SizedBox(width: 26),
                  Expanded(
                    flex: 2,
                    child: Text(
                      playerName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: playerColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.gray700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          // Barre inversée : plus le temps est court, plus la barre est longue
                          widthFactor: maxTime > 0 && avgTime > 0 ? (1 - (avgTime / maxTime)) * 0.8 + 0.2 : 0,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: playerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${avgTime.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
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

  Widget _buildScoreEvolution(GameProvider provider) {
    if (provider.game.history.isEmpty) {
      return const SizedBox();
    }

    // Calculer l'évolution des scores par tour d'équipe
    final Map<String, List<int>> scoresByTeamTurn = {};
    final Map<String, int> cumulativeScores = {};

    for (var team in provider.teams) {
      scoresByTeamTurn[team.id] = [0]; // Démarre à 0
      cumulativeScores[team.id] = 0;
    }

    for (final entry in provider.game.history) {
      final teamId = entry.teamId;
      final points = entry.wordsGuessed.length;
      cumulativeScores[teamId] = (cumulativeScores[teamId] ?? 0) + points;
      scoresByTeamTurn[teamId]!.add(cumulativeScores[teamId]!);
    }

    // Trouver le score max pour l'échelle
    int maxScore = 1;
    for (final scores in scoresByTeamTurn.values) {
      for (final score in scores) {
        if (score > maxScore) maxScore = score;
      }
    }

    // Trouver le nombre max de tours pour une équipe
    int maxTurns = 0;
    for (final turns in scoresByTeamTurn.values) {
      if (turns.length > maxTurns) maxTurns = turns.length;
    }

    // Créer les lignes pour chaque équipe
    final List<LineChartBarData> lines = [];
    for (int teamIndex = 0; teamIndex < provider.teams.length; teamIndex++) {
      final team = provider.teams[teamIndex];
      final teamColor = AppColors.getTeamColor(teamIndex);
      final teamScores = scoresByTeamTurn[team.id]!;

      final spots = <FlSpot>[];
      for (int i = 0; i < teamScores.length; i++) {
        spots.add(FlSpot(i.toDouble(), teamScores[i].toDouble()));
      }

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: teamColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: teamColor,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: teamColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution des scores',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Légende
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: provider.teams.asMap().entries.map((entry) {
              final teamColor = AppColors.getTeamColor(entry.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: teamColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.value.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: teamColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Graphique
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: lines,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxScore / 4).ceilToDouble().clamp(1, 100),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.gray600,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (maxScore / 4).ceilToDouble().clamp(1, 100),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.gray400,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: (maxTurns / 5).ceilToDouble().clamp(1, 100),
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          'T${value.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.gray400,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (maxTurns - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: maxScore.toDouble() * 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
