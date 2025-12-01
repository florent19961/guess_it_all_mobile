import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final allTeamsValid = provider.allTeamsHaveMinPlayers;

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                Text(
                  'Équipes',
                  style: AppTextStyles.subtitle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Glissez les joueurs pour changer les équipes',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.gray400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Mélanger',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  icon: const Icon(Icons.shuffle, color: Colors.white, size: 18),
                  onPressed: () => provider.randomizeTeams(),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTeamsGrid(context, provider),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (!allTeamsValid)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Chaque équipe doit avoir au moins 2 joueurs',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      AppButton(
                        text: 'Commencer',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        fullWidth: true,
                        disabled: !allTeamsValid,
                        onPressed: allTeamsValid ? () => provider.startGame() : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppBackButton(
            onPressed: () => provider.goToScreen(AppConstants.screenPlayers),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsGrid(BuildContext context, GameProvider provider) {
    final teams = provider.teams;
    final numberOfTeams = teams.length;

    if (numberOfTeams <= 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: teams.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _TeamCard(
                team: teams[entry.key],
                teamIndex: entry.key,
                provider: provider,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _TeamCard(
                    team: teams[0],
                    teamIndex: 0,
                    provider: provider,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _TeamCard(
                    team: teams[1],
                    teamIndex: 1,
                    provider: provider,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (teams.length > 2)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _TeamCard(
                      team: teams[2],
                      teamIndex: 2,
                      provider: provider,
                    ),
                  ),
                ),
              if (teams.length > 3)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _TeamCard(
                      team: teams[3],
                      teamIndex: 3,
                      provider: provider,
                    ),
                  ),
                ),
              if (teams.length == 3) const Expanded(child: SizedBox()),
            ],
          ),
        ],
      );
    }
  }
}

class _TeamCard extends StatelessWidget {
  final dynamic team;
  final int teamIndex;
  final GameProvider provider;

  const _TeamCard({
    required this.team,
    required this.teamIndex,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = AppColors.getTeamColor(teamIndex);
    final players = team.playerIds
        .map((id) => provider.getPlayerById(id))
        .where((p) => p != null)
        .cast<Player>()
        .toList();

    return DragTarget<Player>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        provider.movePlayerToTeam(details.data.id, team.id);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? teamColor.withValues(alpha: 0.2)
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? AppColors.secondaryCyan : teamColor,
              width: isHovering ? 3 : 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                team.name,
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 20,
                  color: teamColor,
                ),
              ),
              const SizedBox(height: 12),
              if (players.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Glissez ici',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                )
              else
                ...players.map((player) => _buildDraggablePlayer(player, teamColor)),
              if (players.length < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Min. 2 joueurs',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggablePlayer(Player player, Color teamColor) {
    return Draggable<Player>(
      data: player,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: teamColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondaryCyan, width: 2),
          ),
          child: Text(
            player.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _PlayerTile(player: player, teamColor: teamColor),
      ),
      child: _PlayerTile(player: player, teamColor: teamColor),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player;
  final Color teamColor;

  const _PlayerTile({required this.player, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: teamColor, width: 4)),
        color: AppColors.backgroundMain.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, color: AppColors.gray500, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
