import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_confirm_dialog.dart';
import '../widgets/common/game_dialogs.dart';
import '../widgets/common/home_button.dart';
import '../widgets/common/back_button.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/fiesta/blocked_guesser.dart';
import '../widgets/fiesta/fiesta_setup_widgets.dart';
import '../widgets/fiesta/fiesta_turn_widgets.dart';
import '../widgets/fiesta/malus_reveal.dart';
import '../widgets/fiesta/modifier_badge.dart';
import '../widgets/fiesta/modifier_card.dart';
import '../widgets/fiesta/turn_time_cards.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../models/fiesta/modifier_instance.dart';

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
                        AppConstants.roundModes[provider.game.currentRound] ??
                            '',
                        style: AppTextStyles.subtitle(fontSize: 44),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showRulesDialog(
                            context, provider.game.currentRound),
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
                    onTap: () => _showTeamMembersDialog(
                        context, currentTeam, provider, teamColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 20),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gray600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.leaderboard,
                                  size: 14, color: Colors.white70),
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
                          onTap: () =>
                              _showGuessedWordsDialog(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gray600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.checklist,
                                    size: 14, color: Colors.white70),
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

                  // Fiesta : annonces avant le tour, posées juste au-dessus du
                  // bouton. Défile si l'écran est petit plutôt que de déborder.
                  // `Expanded` (et non `Flexible`) : l'espace non utilisé reste
                  // au-dessus du bloc, pas sous le bouton.
                  if (provider.isFiesta)
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          child: _FiestaAnnouncements(provider: provider),
                        ),
                      ),
                    ),

                  // Time bonus indicator (Classique : en Fiesta, la carte
                  // « Temps du tour » porte déjà la ligne « Temps reporté »)
                  if (provider.game.turnBonusTime != null &&
                      !provider.isFiesta) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer,
                              color: AppColors.warning, size: 18),
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
                    onPressed: () => _startTurn(context, provider, teamColor),
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
              onPressed: () => showBackToVerificationDialog(context, provider),
            ),
        ],
      ),
    );
  }

  /// Fiesta : révèle d'abord les malus de l'équipe à son premier tour de la
  /// manche, puis fait choisir le devineur bloqué (`block_guesser`), puis
  /// lance le compte à rebours. Sélecteur fermé sans choix : on reste ici.
  ///
  /// 🔴 Les révélations sont des routes poussées AU-DESSUS de `home` : elles
  /// survivent au changement d'écran. Sans les deux gardes, un double tap
  /// empile deux révélations et la seconde chaîne rappelle `startTurn()` en
  /// plein tour (revue 2-5 r1, MAJOR-1).
  Future<void> _startTurn(
      BuildContext context, GameProvider provider, Color teamColor) async {
    // Une révélation déjà poussée : la route du jeu n'est plus au sommet.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final maluses = provider.malusToReveal;
    if (maluses.isNotEmpty) {
      await MalusReveal.showAll(
        context,
        maluses: maluses,
        teamName: provider.getCurrentTeam()?.name ?? '',
        teamColor: teamColor,
      );
      if (!context.mounted ||
          provider.game.currentScreen != AppConstants.screenGame) {
        return;
      }
    }
    if (provider.needsBlockedGuesser) {
      if (!context.mounted) return;
      final blocked =
          await BlockedGuesser.pick(context, provider.blockableGuessers);
      if (blocked == null || !context.mounted) return;
      await BlockedGuesser.announce(
        context,
        player: blocked,
        teamName: provider.getCurrentTeam()?.name ?? '',
        teamColor: teamColor,
      );
      if (!context.mounted ||
          provider.game.currentScreen != AppConstants.screenGame) {
        return;
      }
      // Persisté APRÈS l'annonce : une app tuée pendant l'annonce redemande
      // le choix au lieu de démarrer sans l'avoir montrée.
      provider.setBlockedGuesser(blocked.id);
    }
    provider.startTurn();
  }

  void _showBackToTeamsDialog(BuildContext context, GameProvider provider) {
    AppConfirmDialog.show(
      context,
      title: 'Retour aux équipes',
      message: 'Voulez-vous revenir à la composition des équipes ?',
      confirmText: 'Retour',
    ).then((confirme) {
      if (confirme) provider.goBackToTeams();
    });
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
                final isCurrentTeam =
                    entry.key == provider.game.currentTeamIndex;

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
                            fontWeight: isCurrentTeam
                                ? FontWeight.w600
                                : FontWeight.w400,
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

  void _showTeamMembersDialog(BuildContext context, dynamic team,
      GameProvider provider, Color teamColor) {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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

/// Avant le tout premier tour : tirage de la manche 1 et annonce « Une seule
/// réponse » (maquette `r1`). Ensuite : « Actif ce tour » (maquette `cd`).
/// Dans les deux cas, la carte « Temps du tour » dessous.
class _FiestaAnnouncements extends StatelessWidget {
  final GameProvider provider;

  const _FiestaAnnouncements({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _modifiers(),
        if (provider.isDoublePointsArmed || provider.doublePointsLeft > 0)
          _doublePoints(),
        TurnTimeCard(provider.turnTime),
      ],
    );
  }

  /// Interrupteur « Mot compte double » (maquette `cd`). La charge ne se
  /// dépense qu'au départ du tour ; ensuite l'interrupteur est figé.
  Widget _doublePoints() {
    final left = provider.doublePointsLeft;
    final String label;
    final String detail;
    var editable = false;
    if (provider.isDoublePointsOn) {
      label = 'Mot compte double activé';
      detail = 'Les points de ce tour comptent ×2.';
    } else if (!provider.isDoublePointsArmed && provider.doublePointsCapped) {
      label = 'Activer Mot compte double';
      detail = 'Impossible : votre équipe a déjà 2 modificateurs ce tour.';
    } else {
      label = 'Activer Mot compte double';
      detail = '$left charge${left > 1 ? 's' : ''} pour cette manche. '
          'Les points du tour seront ×2.';
      editable = true;
    }
    return FiestaCard(
      title: 'Bonus',
      children: [
        FiestaLine(
          label: label,
          detail: detail,
          value: provider.isDoublePointsArmed,
          onChanged: editable ? provider.setDoublePoints : null,
        ),
      ],
    );
  }

  Widget _modifiers() {
    final rules = provider.game.fiesta!.rules;
    final modifiers = provider.currentTeamModifiers;

    if (provider.isFirstTurnOfGame) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rules.oneAnswer)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Une seule réponse par mot. Une mauvaise réponse → il faut '
                'passer (pénalité de passe).',
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 12.5, color: AppColors.warning),
              ),
            ),
          RoundDrawCard(round: 1, modifiers: modifiers),
          ..._constraints(rules.oneAnswer, modifiers),
        ],
      );
    }

    return FiestaCard(
      title: 'Actif ce tour',
      children: [
        ..._constraints(rules.oneAnswer, modifiers),
        if (modifiers.isEmpty && !rules.oneAnswer)
          const FiestaHint('Aucun modificateur')
        else
          ModifierBadges(
            modifiers: modifiers,
            alignment: WrapAlignment.start,
            extra: [
              if (rules.oneAnswer)
                const ModifierBadge(
                  icon: '☝',
                  label: 'Une seule réponse',
                  nature: ModifierNature.bonus,
                ),
            ],
          ),
      ],
    );
  }

  /// Contraintes annoncées (2-8) : bandeaux de mime / dessin, et Q6 « Une
  /// seule réponse » + « Interdit de passer ».
  List<Widget> _constraints(bool oneAnswer, List<ModifierInstance> modifiers) {
    final ids = modifiers.map((m) => m.catalogId).toSet();
    return [
      for (final id in MimeConstraintBanner.icons.keys)
        if (ids.contains(id)) ...[
          MimeConstraintBanner(modifierId: id),
          const SizedBox(height: 12),
        ],
      if (oneAnswer && ids.contains('no_pass')) ...[
        const FiestaHint(
            'Mauvaise réponse : le mot est grillé jusqu\'à la fin du tour.'),
        const SizedBox(height: 12),
      ],
    ];
  }
}
