import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/stats_aggregation.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_back_button.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showAdvancedStats = false;

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

                  // Section 1: Top des joueurs (nombre de mots)
                  _topJoueurs(provider),

                  const SizedBox(height: 32),

                  // Section 2: Évolution des scores
                  _buildScoreEvolution(provider),

                  const SizedBox(height: 32),

                  // Bouton "Statistiques pas ludiques"
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAdvancedStats = !_showAdvancedStats;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray600),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAdvancedStats
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.gray400,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Cherry on the cake',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('🍒', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                  // Section 3: Stats avancées (déroulable)
                  if (_showAdvancedStats) ...[
                    const SizedBox(height: 16),
                    _tempsMoyen(
                        provider), // Temps moyen par mot (partie entière)
                    const SizedBox(height: 16),
                    _tempsMoyen(provider,
                        round: 1), // Temps moyen par mot (manche 1)
                    const SizedBox(height: 16),
                    _topJoueurs(provider, round: 1), // Top joueurs (manche 1)
                    const SizedBox(height: 16),
                    _tempsMoyen(provider,
                        round: 2), // Temps moyen par mot (manche 2)
                    const SizedBox(height: 16),
                    _topJoueurs(provider, round: 2), // Top joueurs (manche 2)
                    const SizedBox(height: 16),
                    _tempsMoyen(provider,
                        round: 3), // Temps moyen par mot (manche 3)
                    const SizedBox(height: 16),
                    _topJoueurs(provider, round: 3), // Top joueurs (manche 3)
                  ],

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

  /// Couleur d'équipe d'un joueur — la boucle était recopiée cinq fois.
  Color _teamColorOf(GameProvider provider, String playerId) {
    for (int i = 0; i < provider.teams.length; i++) {
      if (provider.teams[i].playerIds.contains(playerId)) {
        return AppColors.getTeamColor(i);
      }
    }
    return AppColors.gray400;
  }

  /// Carte « classement en barres ».
  ///
  /// 🔴 Ce widget remplace QUATRE builders qui ne différaient que par le titre,
  /// une largeur et deux tailles de police : les blocs « partie entière » et
  /// « manche N » étaient identiques à l'octet près. Corriger un défaut de
  /// rendu demandait quatre modifications cohérentes, et l'écran divergeait de
  /// lui-même dès qu'on en oubliait une.
  ///
  /// [inverse] rend la barre la plus longue à la plus PETITE valeur : c'est le
  /// cas du temps moyen par mot, où être rapide est être meilleur.
  Widget _buildRankedBars(
    GameProvider provider, {
    required String title,
    required List<StatRow> rows,
    IconData? icon,
    bool inverse = false,
    double valueWidth = 50,
    double valueFontSize = 18,
  }) {
    if (rows.isEmpty) return const SizedBox();

    // L'échelle : la plus grande valeur en direct, la plus grande aussi en
    // inversé (c'est elle qui donne la barre la plus COURTE).
    final echelle = inverse ? rows.last.value : rows.first.value;

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
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.warning, size: 24),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.asMap().entries.map((e) {
            final index = e.key;
            final row = e.value;
            final couleur = _teamColorOf(provider, row.playerId);
            final nom =
                provider.getPlayerById(row.playerId)?.name ?? 'Joueur inconnu';

            final medaille = index == 0
                ? '🥇'
                : index == 1
                    ? '🥈'
                    : index == 2
                        ? '🥉'
                        : '';

            final remplissage = echelle <= 0
                ? 0.0
                : inverse
                    ? (row.value > 0
                        ? (1 - (row.value / echelle)) * 0.8 + 0.2
                        : 0.0)
                    : row.value / echelle;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (medaille.isNotEmpty) ...[
                    Text(medaille, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                  ] else
                    const SizedBox(width: 26),
                  Expanded(
                    flex: 2,
                    child: Text(
                      nom,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: couleur,
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
                          widthFactor: remplissage,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: couleur,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: valueWidth,
                    child: Text(
                      row.label,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: valueFontSize,
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

  Widget _topJoueurs(GameProvider provider, {int? round}) => _buildRankedBars(
        provider,
        title: round == null ? 'Top joueurs' : 'Top joueurs (manche $round)',
        icon: Icons.emoji_events,
        rows: guessedWordsRanking(provider.game.history, round: round),
      );

  Widget _tempsMoyen(GameProvider provider, {int? round}) => _buildRankedBars(
        provider,
        title: round == null
            ? 'Temps moyen par mot (partie entière)'
            : 'Temps moyen par mot (manche $round)',
        rows: averageTimePerWordRanking(provider.game.history, round: round),
        inverse: true,
        valueWidth: 45,
        valueFontSize: 16,
      );

  Widget _buildScoreEvolution(GameProvider provider) {
    if (provider.game.history.isEmpty) {
      return const SizedBox();
    }

    // Pour chaque équipe : liste de points (tour par équipe, score cumulatif)
    final Map<String, List<FlSpot>> teamSpots = {};
    final Map<String, int> teamCumulativeScore = {};
    final Map<String, int> teamTurnCount = {};

    // Initialiser chaque équipe à (0, 0)
    for (var team in provider.teams) {
      teamSpots[team.id] = [const FlSpot(0, 0)];
      teamCumulativeScore[team.id] = 0;
      teamTurnCount[team.id] = 0;
    }

    // Détecter le premier tour de chaque manche (pour les barres verticales)
    Map<int, int> roundStartX = {}; // round -> premier X (teamTurnCount)
    Map<String, int> lastRoundSeen = {}; // teamId -> dernière manche vue

    // Parcourir l'historique
    for (final entry in provider.game.history) {
      final teamId = entry.teamId;
      // Points du tour, pas nombre de mots : un tour à ×2 compte double.
      teamCumulativeScore[teamId] =
          (teamCumulativeScore[teamId] ?? 0) + entry.points;

      if (entry.isBonusContinuation) {
        // C'est une continuation du tour précédent (bonus time)
        // Mettre à jour le dernier point au lieu d'en ajouter un nouveau
        final spots = teamSpots[teamId]!;
        if (spots.isNotEmpty) {
          spots[spots.length - 1] = FlSpot(
            teamTurnCount[teamId]!.toDouble(),
            teamCumulativeScore[teamId]!.toDouble(),
          );
        }
      } else {
        // Nouveau tour : incrémenter le compteur et ajouter un point
        teamTurnCount[teamId] = (teamTurnCount[teamId] ?? 0) + 1;

        // Détecter si c'est le premier tour d'une nouvelle manche
        final lastRound = lastRoundSeen[teamId] ?? 0;
        if (entry.round > lastRound && !roundStartX.containsKey(entry.round)) {
          roundStartX[entry.round] = teamTurnCount[teamId]!;
        }
        lastRoundSeen[teamId] = entry.round;

        teamSpots[teamId]!.add(FlSpot(
          teamTurnCount[teamId]!.toDouble(),
          teamCumulativeScore[teamId]!.toDouble(),
        ));
      }
    }

    // Créer la liste des positions X pour les barres M1, M2 et M3
    // M1 est toujours à x=0 (début du graphique)
    final List<double> mancheStartsX = [
      0,
      if (roundStartX.containsKey(2)) roundStartX[2]!.toDouble(),
      if (roundStartX.containsKey(3)) roundStartX[3]!.toDouble(),
    ];

    // Trouver les max pour les axes
    int maxTurn = 1;
    int maxScore = 1;
    for (final spots in teamSpots.values) {
      for (final spot in spots) {
        if (spot.x > maxTurn) maxTurn = spot.x.toInt();
        if (spot.y > maxScore) maxScore = spot.y.toInt();
      }
    }

    // Créer les lignes (courbes lisses)
    final List<LineChartBarData> lines = [];
    for (int i = 0; i < provider.teams.length; i++) {
      final team = provider.teams[i];
      final teamColor = AppColors.getTeamColor(i);
      final spots = teamSpots[team.id]!;

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: teamColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: teamColor.withOpacity(0.1),
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
                  horizontalInterval:
                      (maxScore / 4).ceilToDouble().clamp(1, 100),
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
                      interval:
                          maxTurn <= 10 ? 1 : (maxTurn / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        if (value != value.roundToDouble())
                          return const Text('');
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: maxTurn.toDouble(),
                minY: 0,
                maxY: maxScore.toDouble() * 1.1,
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    for (int i = 0; i < mancheStartsX.length; i++)
                      VerticalLine(
                        x: mancheStartsX[i],
                        color: Colors.white.withOpacity(0.4),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: VerticalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) => 'M${i + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
