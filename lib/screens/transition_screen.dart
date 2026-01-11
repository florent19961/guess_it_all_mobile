import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/home_button.dart';
import '../widgets/common/back_button.dart';

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
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.success, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manche $currentRound',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: AppColors.success, size: 22),
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

                          return GestureDetector(
                            onTap: () => _showTeamMembersDialog(context, team, provider, teamColor),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
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
                                  const SizedBox(width: 8),
                                  Icon(Icons.people_outline, color: teamColor.withOpacity(0.6), size: 18),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Time bonus indicator (only show if not last round)
                  if (provider.game.turnBonusTime != null &&
                      provider.game.turnBonusTime! > 0 &&
                      currentRound < 3) ...[
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
                            'Temps bonus conservé : ${provider.game.turnBonusTime}s',
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

                  // Bouton pour consulter les mots devinés du tour précédent
                  if (provider.game.history.isNotEmpty) ...[
                    Center(
                      child: GestureDetector(
                        onTap: () => _showGuessedWordsDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gray600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.checklist, size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                'Voir les ${provider.game.history.last.wordsGuessed.length} mots devinés',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
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
          const HomeButton(alignRight: true),
          // Back button pour revenir à l'écran de vérification
          if (provider.canGoBackToVerification)
            GameBackButton(
              onPressed: () => _showBackToVerificationDialog(context, provider),
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
