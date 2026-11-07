import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/fiesta/fiesta_state.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../models/score_timeline.dart';
import '../models/stats_aggregation.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/fiesta/modifier_badge.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showAdvancedStats = false;

  /// Badges des cartouches sur « Évolution des scores ». Non mémorisé.
  bool _showChargeBadges = false;

  // Marges de la zone de tracé du graphique, dans le repère du `LineChart`.
  static const double _chartLeftTitles = 30;
  static const double _chartBottomTitles = 24;

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

            // En inversé, 0 s est le meilleur temps possible : barre pleine.
            final remplissage = inverse
                ? (echelle > 0 ? (1 - row.value / echelle) * 0.8 + 0.2 : 1.0)
                : (echelle > 0 ? row.value / echelle : 0.0);

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

    // Le début de chaque manche (pour les barres verticales) : le point de sa
    // continuation, ou celui d'avant son premier tour si rien n'était reporté.
    final Map<int, int> roundStartX = {}; // round -> X de la première entrée

    // Abscisse de chaque entrée, sur la courbe de son équipe.
    final Map<int, int> entryX = {};

    // Parcourir l'historique
    for (final (index, entry) in provider.game.history.indexed) {
      final teamId = entry.teamId;
      // Entrée incomplète (`teamId` absent) : aucune courbe à qui l'attribuer.
      if (!teamSpots.containsKey(teamId)) continue;
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

        teamSpots[teamId]!.add(FlSpot(
          teamTurnCount[teamId]!.toDouble(),
          teamCumulativeScore[teamId]!.toDouble(),
        ));
      }
      roundStartX.putIfAbsent(
          entry.round,
          () => entry.isBonusContinuation
              ? teamTurnCount[teamId]!
              : teamTurnCount[teamId]! - 1);
      entryX[index] = teamTurnCount[teamId]!;
    }

    // Barres M1, M2 et M3, chacune avec le numéro de SA manche.
    // M1 est toujours à x=0 (début du graphique)
    final Map<int, double> mancheStartsX = {
      1: 0,
      for (final round in [2, 3])
        if (roundStartX.containsKey(round))
          round: roundStartX[round]!.toDouble(),
    };

    // Trouver les max pour les axes
    int maxTurn = 1;
    int maxScore = 1;
    for (final spots in teamSpots.values) {
      for (final spot in spots) {
        if (spot.x > maxTurn) maxTurn = spot.x.toInt();
        if (spot.y > maxScore) maxScore = spot.y.toInt();
      }
    }

    // Repères de l'axe des scores : fl_chart ajoute toujours le haut de l'axe
    // (maxScore × 1,1), qui n'est pas un repère et mord sur le dernier.
    final scoreInterval = (maxScore / 4).ceilToDouble().clamp(1.0, 100.0);

    // Cartouches jouées, chacune à la fin de son tour sur la courbe de l'équipe
    // qui l'a jouée (malus compris, comme la révélation). Sans numéro de tour
    // (partie antérieure), on ne sait pas où la poser.
    final List<_ChargeBadge> badges = [];
    for (final use
        in provider.game.fiesta?.chargesUsed ?? const <ChargeUse>[]) {
      final x = entryX[entryOfCharge(use, provider.game.history)];
      if (x == null) continue;
      badges.add(_ChargeBadge(
        catalogId: use.catalogId,
        x: x,
        score: teamSpots[use.teamId]![x].y,
        stack: badges.where((b) => b.teamId == use.teamId && b.x == x).length,
        teamId: use.teamId,
      ));
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
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bonus et malus joués',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
                Switch(
                  value: _showChargeBadges,
                  activeTrackColor: AppColors.secondaryCyan,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (on) => setState(() => _showChargeBadges = on),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Graphique
          SizedBox(
            height: 200,
            child: Stack(fit: StackFit.expand, children: [
              LineChart(
                LineChartData(
                  lineBarsData: lines,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: scoreInterval,
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
                        reservedSize: _chartLeftTitles,
                        interval: scoreInterval,
                        getTitlesWidget: (value, meta) {
                          if (value % scoreInterval != 0) {
                            return const SizedBox.shrink();
                          }
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
                        reservedSize: _chartBottomTitles,
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
                      for (final MapEntry(key: round, value: x)
                          in mancheStartsX.entries)
                        VerticalLine(
                          x: x,
                          color: Colors.white.withOpacity(0.4),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                          label: VerticalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            labelResolver: (_) => 'M$round',
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
              if (_showChargeBadges)
                _buildChargeBadges(badges,
                    maxTurn: maxTurn.toDouble(), maxY: maxScore * 1.1),
            ]),
          ),
        ],
      ),
    );
  }

  /// Calque des badges, dans le repère du `LineChart` : posé au-dessus du point
  /// de son tour, les badges d'un même point empilés.
  Widget _buildChargeBadges(List<_ChargeBadge> badges,
      {required double maxTurn, required double maxY}) {
    const size = 24.0;
    return LayoutBuilder(builder: (context, box) {
      final plotWidth = box.maxWidth - _chartLeftTitles;
      final plotHeight = box.maxHeight - _chartBottomTitles;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (final badge in badges)
            Positioned(
              left: (_chartLeftTitles + badge.x / maxTurn * plotWidth)
                      .clamp(size / 2, box.maxWidth - size / 2) -
                  size / 2,
              top: ((1 - badge.score / maxY) * plotHeight -
                          16 -
                          badge.stack * size)
                      .clamp(size / 2, plotHeight) -
                  size / 2,
              child: _chargeBadge(badge.catalogId, size),
            ),
        ],
      );
    });
  }

  Widget _chargeBadge(String catalogId, double size) {
    final color =
        modifierColor(modifierById(catalogId)?.nature ?? ModifierNature.malus);
    return Tooltip(
      message: modifierById(catalogId)?.name ?? catalogId,
      child: Container(
        key: const ValueKey('chart-badge'),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.backgroundMain,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: ModifierIcon(catalogId, size: size * 0.78, color: color),
      ),
    );
  }
}

/// Une cartouche jouée, placée sur le graphique des scores.
class _ChargeBadge {
  final String catalogId;
  final String teamId;
  final int x;
  final double score;

  /// Rang parmi les badges de la même équipe au même point.
  final int stack;

  const _ChargeBadge({
    required this.catalogId,
    required this.teamId,
    required this.x,
    required this.score,
    required this.stack,
  });
}
