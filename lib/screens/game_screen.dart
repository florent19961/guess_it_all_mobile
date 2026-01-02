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

                  // Round mode (gros)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppConstants.roundModes[provider.game.currentRound] ?? '',
                        style: AppTextStyles.subtitle(fontSize: 44),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showRulesDialog(context, provider.game.currentRound),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gray600,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Team card (cliquable pour voir la composition)
                  GestureDetector(
                    onTap: () => _showTeamMembersDialog(context, currentTeam, provider, teamColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: teamColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: teamColor, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentTeam?.name ?? '',
                                style: TextStyle(
                                  fontFamily: 'Bangers',
                                  fontSize: 24,
                                  color: teamColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.people_outline,
                                color: teamColor,
                                size: 18,
                              ),
                            ],
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
                  ),

                  const SizedBox(height: 16),

                  // Bouton pour voir les autres scores + mots restants
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${provider.game.remainingWords.length} ${provider.game.remainingWords.length <= 1 ? 'mot restant' : 'mots restants'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showAllScoresDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gray600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.leaderboard, size: 14, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'Scores',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bouton pour voir les mots devinés au tour précédent
                      if (provider.game.history.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showGuessedWordsDialog(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gray600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.checklist, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${provider.game.history.last.wordsGuessed.length} mots',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // Time bonus indicator
                  if (provider.game.turnBonusTime != null) ...[
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
                            'Temps bonus : ${provider.game.turnBonusTime}s',
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
      barrierColor: Colors.black.withOpacity(0.7),
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
      barrierColor: Colors.black.withOpacity(0.7),
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

  void _showAllScoresDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.gray600, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec titre et croix
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scores',
                      style: AppTextStyles.subtitle(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Liste des scores
              ...provider.teams.asMap().entries.map((entry) {
                final team = entry.value;
                final teamColor = AppColors.getTeamColor(entry.key);
                final isCurrentTeam = entry.key == provider.game.currentTeamIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          team.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: isCurrentTeam ? FontWeight.w600 : FontWeight.w400,
                            color: teamColor,
                          ),
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
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context, int round) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.secondaryCyan, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec titre et croix
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Règles',
                      style: AppTextStyles.subtitle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                AppConstants.roundDescriptions[round] ?? '',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTeamMembersDialog(BuildContext context, dynamic team, GameProvider provider, Color teamColor) {
    if (team == null) return;

    final players = team.playerIds
        .map((id) => provider.getPlayerById(id))
        .where((p) => p != null)
        .toList();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: teamColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                team.name,
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 24,
                  color: teamColor,
                ),
              ),
              const SizedBox(height: 16),
              ...players.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  p!.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuessedWordsDialog(BuildContext context, GameProvider provider) {
    final lastEntry = provider.game.history.last;
    final team = provider.getTeamById(lastEntry.teamId);
    final player = provider.getPlayerById(lastEntry.playerId);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.gray500, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec croix
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tour précédent',
                      style: AppTextStyles.subtitle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'par ${team?.name ?? "Équipe"} (${player?.name ?? "Joueur"})',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.gray400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Contenu
              if (lastEntry.wordsGuessed.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucun mot deviné durant ce tour',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.gray400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lastEntry.wordsGuessed.map((word) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.secondaryCyan.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            word,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                '${lastEntry.wordsGuessed.length} mot${lastEntry.wordsGuessed.length > 1 ? "s" : ""} au total',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
