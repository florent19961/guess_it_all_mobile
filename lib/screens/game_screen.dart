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
import '../widgets/fiesta/turn_cartridges.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/first_game_help.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _teamKey = GlobalKey();
  final _roundRulesKey = GlobalKey();
  final _previousTurnKey = GlobalKey();
  final _bonusTimeKey = GlobalKey();
  final _startKey = GlobalKey();
  final _fiestaKeys = FiestaPreTurnKeys();

  /// Vrai tant que l'aide automatique n'est pas tranchée : « Commencer le
  /// tour » est ignoré, sinon l'aide serait consommée sans être vue.
  bool _helpPending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstGameHelp());
  }

  /// Première partie sur ce téléphone : l'aide s'ouvre seule au premier tour
  /// de chaque joueur (jamais l'aide Fiesta, qui reste derrière le « ? »).
  Future<void> _firstGameHelp() async {
    final provider = context.read<GameProvider>();
    final player = provider.getCurrentPlayer();
    final gameId = provider.game.gameId;
    // Sans gameId (partie d'avant la mise à jour) : pas d'aide automatique.
    bool show;
    try {
      show = player != null &&
          gameId != null &&
          await FirstGameHelp.claim(
            gameId: gameId,
            playerId: player.id,
            screen: FirstGameHelp.preTurn,
          );
    } finally {
      _helpPending = false;
    }
    if (show && mounted) {
      await CoachMarks.show(context, _preTurnSteps(player.name));
    }
  }

  List<CoachStep> _preTurnSteps(String playerName,
          {List<CoachStep> fiesta = const []}) =>
      preTurnHelp(
        team: _teamKey,
        roundRules: _roundRulesKey,
        previousTurn: _previousTurnKey,
        bonusTime: _bonusTimeKey,
        start: _startKey,
        playerName: playerName,
        fiesta: fiesta,
      );

  void _showHelp(GameProvider provider) {
    CoachMarks.show(
      context,
      _preTurnSteps(
        provider.getCurrentPlayer()?.name ?? '',
        fiesta: provider.isFiesta ? fiestaPreTurnHelp(_fiestaKeys) : const [],
      ),
    );
  }

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
                  // Fiesta : hauteur fixe sous les boutons du haut, tout le
                  // reste va aux cartouches.
                  if (provider.isFiesta)
                    const SizedBox(height: _fiestaTopGap)
                  else
                    const Spacer(),

                  // Round mode (gros)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rétrécit au lieu de déborder (« Description libre »
                      // en 360 px de large).
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppConstants
                                    .roundModes[provider.game.currentRound] ??
                                '',
                            style: AppTextStyles.subtitle(fontSize: 44),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        key: _roundRulesKey,
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
                  // Grande carte d'équipe, Fiesta comme Classique. Fiesta sur
                  // petit écran, dans les cas chargés seulement : elle se
                  // resserre pour laisser tenir les cartouches sans défiler.
                  if (provider.isFiesta)
                    Expanded(
                      child: LayoutBuilder(builder: (context, box) {
                        final zoneHeight = box.maxHeight - _bigCardHeight;
                        final big = FiestaTurnZone.fitsIn(
                          provider,
                          width: box.maxWidth,
                          height: zoneHeight,
                        );
                        return Column(
                          children: [
                            if (big) ...[
                              const SizedBox(height: 16),
                              _teamCard(provider, currentTeam, currentPlayer,
                                  teamColor),
                              const SizedBox(height: 12),
                              _wordsRow(provider),
                            ] else ...[
                              const SizedBox(height: 10),
                              _compactTeamCard(provider, currentTeam,
                                  currentPlayer, teamColor),
                            ],
                            if (provider.replacedPlayer case final replaced?)
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  key: _fiestaKeys.reuseChoices,
                                  onTap: provider.reuseReplacedChoices,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '↻ Reprendre les choix de ${replaced.name}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.gray400,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.gray400,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Jamais rien sous « Commencer le tour » : un cas
                            // extrême qui ne tient pas défile dans la zone.
                            Expanded(
                              child: FiestaTurnZone(
                                provider: provider,
                                helpKeys: _fiestaKeys,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                    )
                  else ...[
                    const SizedBox(height: 32),
                    _teamCard(provider, currentTeam, currentPlayer, teamColor),
                    const SizedBox(height: 16),
                    _wordsRow(provider),
                    const Spacer(),
                  ],

                  // Temps reporté (continuation), Classique comme Fiesta
                  if (provider.game.turnBonusTime != null) ...[
                    Container(
                      key: _bonusTimeKey,
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
                            'Temps bonus : ${provider.turnTime.total}s',
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
                    key: _startKey,
                    text: 'Commencer le tour',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () {
                      if (_helpPending) return;
                      provider.startTurn();
                    },
                  ),

                  // Fiesta : cette place va aux cartouches.
                  if (!provider.isFiesta) const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const HomeButton(alignRight: true),
          HelpButton(
            right: HelpButton.besideCornerButton,
            onPressed: () => _showHelp(provider),
          ),
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

  Widget _teamCard(GameProvider provider, dynamic currentTeam,
          dynamic currentPlayer, Color teamColor) =>
      GestureDetector(
        key: _teamKey,
        onTap: () =>
            _showTeamMembersDialog(context, currentTeam, provider, teamColor),
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
                  Flexible(
                    child: Text(
                      currentTeam?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 24,
                        color: teamColor,
                      ),
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
      );

  /// Grande carte, sa ligne de mots et leurs marges (hauteur réservée).
  static const _bigCardHeight = 16.0 + 96 + 12 + 26 + 18;

  static const _fiestaTopGap = 40.0;

  /// Mots restants + mots devinés au tour précédent. Pas de score : il reste
  /// caché jusqu'aux résultats.
  Widget _wordsRow(GameProvider provider, {double fontSize = 14}) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${provider.game.remainingWords.length} ${provider.game.remainingWords.length <= 1 ? 'mot restant' : 'mots restants'}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              color: Colors.white60,
            ),
          ),
          // Bouton pour voir les mots devinés au tour précédent
          if (provider.game.history.isNotEmpty) ...[
            const SizedBox(width: 12),
            GestureDetector(
              key: _previousTurnKey,
              onTap: () => _showGuessedWordsDialog(context, provider),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: fontSize < 14 ? 1 : 4),
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
      );

  /// Carte d'équipe compacte (Fiesta) : « Équipe · Joueur » sur une ligne,
  /// mots restants dessous. Même style que la grande carte, sans ombre.
  Widget _compactTeamCard(GameProvider provider, dynamic currentTeam,
          dynamic currentPlayer, Color teamColor) =>
      GestureDetector(
        key: _teamKey,
        onTap: () =>
            _showTeamMembersDialog(context, currentTeam, provider, teamColor),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: teamColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: teamColor, width: 2),
          ),
          child: Column(
            children: [
              // Le nom d'équipe se coupe, jamais celui du joueur.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      currentTeam?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 22,
                          color: teamColor),
                    ),
                  ),
                  Text(
                    '  ·  ${currentPlayer?.name ?? ''}',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              _wordsRow(provider, fontSize: 12),
            ],
          ),
        ),
      );

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
