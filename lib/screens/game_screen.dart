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
import '../widgets/fiesta/malus_reveal.dart';
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
  final _startKey = GlobalKey();
  final _thisTurnKey = GlobalKey();
  final _reserveKey = GlobalKey();

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

  List<CoachStep> _preTurnSteps(String playerName) => preTurnHelp(
        team: _teamKey,
        roundRules: _roundRulesKey,
        previousTurn: _previousTurnKey,
        start: _startKey,
        playerName: playerName,
      );

  void _showHelp(GameProvider provider) {
    CoachMarks.show(context, [
      ..._preTurnSteps(provider.getCurrentPlayer()?.name ?? ''),
      if (provider.isFiesta)
        ...fiestaPreTurnHelp(
          thisTurn: _thisTurnKey,
          reserve: _reserveKey,
        ),
    ]);
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
                  const SizedBox(height: 32),

                  // Team card (cliquable pour voir la composition)
                  GestureDetector(
                    key: _teamKey,
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

                  // Mots restants + mots devinés au tour précédent. Pas de
                  // score : il reste caché jusqu'aux résultats.
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
                      // Bouton pour voir les mots devinés au tour précédent
                      if (provider.game.history.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          key: _previousTurnKey,
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

                  // Fiesta : « Ce tour » et « Réserve » juste sous l'équipe,
                  // sans défilement (les cercles s'adaptent à la place) ;
                  // l'espace libre reste au-dessus du bouton.
                  if (provider.isFiesta) ...[
                    const SizedBox(height: 18),
                    Expanded(
                      flex: 6,
                      child: FiestaTurnZone(
                        provider: provider,
                        thisTurnKey: _thisTurnKey,
                        reserveKey: _reserveKey,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else
                    const Spacer(),

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
                    key: _startKey,
                    text: 'Commencer le tour',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () {
                      if (_helpPending) return;
                      _startTurn(context, provider, teamColor);
                    },
                  ),

                  const SizedBox(height: 24),
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
      // 2-10 : la carte vient du 1 parmi 3, l'équipe qui l'a choisie désigne.
      final chooserName = provider.blockingTeam?.name;
      final blocked = await BlockedGuesser.pick(
          context, provider.blockableGuessers,
          chooserName: chooserName);
      if (blocked == null || !context.mounted) return;
      await BlockedGuesser.announce(
        context,
        player: blocked,
        teamName: provider.getCurrentTeam()?.name ?? '',
        teamColor: teamColor,
        chooserName: chooserName,
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
