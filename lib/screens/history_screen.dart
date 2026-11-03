import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_result.dart';
import '../providers/game_provider.dart';
import '../services/game_history_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';

/// Historique des dernières parties : scores, détail par manche et tendances.
///
/// Lit `GameHistoryService` (donnée archivée) et non le provider : le provider
/// ne connaît que la partie EN COURS, c'est précisément ce qui manquait.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<GameResult>> _future;

  @override
  void initState() {
    super.initState();
    _future = GameHistoryService().load();
  }

  static const List<Color> _teamPalette = [
    AppColors.team1,
    AppColors.team2,
    AppColors.team3,
    AppColors.team4,
  ];

  Color _colorFor(int index) => _teamPalette[index % _teamPalette.length];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();

    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: FutureBuilder<List<GameResult>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryCyan,
                    ),
                  );
                }

                final games = snapshot.data ?? const <GameResult>[];
                if (games.isEmpty) return _buildEmpty();

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Historique',
                        style: AppTextStyles.subtitle(fontSize: 36),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        games.length > 1
                            ? '${games.length} dernières parties'
                            : 'Dernière partie',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.gray400),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildTrends(computeTrends(games)),
                      const SizedBox(height: 24),
                      for (final g in games) ...[
                        _GameCard(game: g, colorFor: _colorFor),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          AppBackButton(
            onPressed: () => provider.goToScreen(AppConstants.screenHome),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, color: AppColors.gray500, size: 64),
            const SizedBox(height: 16),
            Text(
              'Aucune partie terminée',
              style: AppTextStyles.subtitle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Les résultats de tes parties apparaîtront ici.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrends(HistoryTrends trends) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendances', style: AppTextStyles.subtitle(fontSize: 20)),
          const SizedBox(height: 12),
          _statLine(
            'Mots devinés par partie',
            trends.averageScorePerGame.toStringAsFixed(1),
          ),
          if (trends.bestScoreTeam != null)
            _statLine(
              'Meilleur score',
              '${trends.bestScore} — ${trends.bestScoreTeam}',
            ),
          if (trends.winsByTeam.isNotEmpty)
            _statLine('Victoires', _formatWins(trends.winsByTeam)),
          if (trends.playerAppearances.isNotEmpty)
            _statLine(
              'Le plus assidu',
              '${trends.playerAppearances.first.key} '
                  '(${trends.playerAppearances.first.value})',
            ),
        ],
      ),
    );
  }

  String _formatWins(Map<String, int> wins) {
    final sorted = wins.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return sorted.take(3).map((e) => '${e.key} ${e.value}').join(' · ');
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une partie archivée : en-tête repliable + détail par manche.
class _GameCard extends StatefulWidget {
  final GameResult game;
  final Color Function(int) colorFor;

  /// « Rejouer » : pré-remplit joueurs, équipes et réglages de cette partie.
  final VoidCallback? onReplay;

  const _GameCard({
    required this.game,
    required this.colorFor,
    this.onReplay,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _expanded = false;

  String _formatDate(DateTime d) {
    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');
    final heure = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$jour/$mois à ${heure}h$minute';
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final ranking = game.ranking;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(game.playedAt),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.gray400),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.isTie
                              ? 'Égalité — ${game.winners.map((t) => t.name).join(' & ')}'
                              : '${game.winners.isEmpty ? '—' : game.winners.first.name} gagne',
                          style: AppTextStyles.subtitle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ranking.map((t) => '${t.score}').join(' – '),
                    style: AppTextStyles.subtitle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.gray400,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.gray700),
                  for (var i = 0; i < ranking.length; i++)
                    _teamRow(ranking[i], widget.colorFor(i)),
                  const SizedBox(height: 8),
                  Text(
                    '${game.totalWords} mots · tours de ${game.turnDuration}s '
                    '· ${game.roundsPlayed} manches',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          if (widget.onReplay != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AppButton(
                text: 'Rejouer',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                fullWidth: true,
                icon: const Icon(Icons.replay, size: 18, color: Colors.white),
                onPressed: widget.onReplay,
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamRow(TeamResult team, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  team.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${team.score}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (team.scoreByRound.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 2),
              child: Text(
                team.scoreByRound
                    .asMap()
                    .entries
                    .map((e) => 'M${e.key + 1}: ${e.value}')
                    .join('  ·  '),
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
              ),
            ),
          if (team.playerNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 2),
              child: Text(
                team.playerNames.join(', '),
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
              ),
            ),
        ],
      ),
    );
  }
}
