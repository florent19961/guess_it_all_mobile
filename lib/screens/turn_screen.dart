import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../widgets/common/app_confirm_dialog.dart';
import '../widgets/common/turn_play_widgets.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../widgets/fiesta/fiesta_turn_widgets.dart';
import '../widgets/fiesta/modifier_badge.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

class TurnScreen extends StatefulWidget {
  const TurnScreen({super.key});

  @override
  State<TurnScreen> createState() => _TurnScreenState();
}

class _TurnScreenState extends State<TurnScreen> with WidgetsBindingObserver {
  Timer? _timer;

  /// Posé par le cycle de vie : l'app a quitté le premier plan.
  bool _wentBackground = false;

  final _timerKey = GlobalKey();
  final _wordKey = GlobalKey();
  final _guessedKey = GlobalKey();
  final _passKey = GlobalKey();
  final _pauseKey = GlobalKey();

  /// L'écran n'est plus l'autorité sur le temps : il lit `provider.turnClock` et
  /// demande au provider de geler / reprendre. Avant, la pause n'était qu'un
  /// booléen local — l'affichage se figeait pendant que la deadline continuait
  /// de courir, et tout le temps passé dans un dialogue était volé au joueur.
  bool _isPausedOf(GameProvider provider) => provider.turnClock.isPaused;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  /// Gèle le tour dès que l'app quitte le premier plan.
  ///
  /// Appel entrant, notification plein écran, verrouillage d'écran, bascule
  /// d'application : la deadline est en horloge murale, donc sans ce gel elle
  /// continue de courir et le tour se termine tout seul au retour.
  /// On ne reprend PAS automatiquement — c'est au joueur de relancer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      _wentBackground = true;
      context.read<GameProvider>().pauseTurn();
    }
  }

  void _startTimer() {
    final provider = context.read<GameProvider>();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final clock = provider.turnClock;
      // Gelée ou arrêtée : il n'y a rien à décompter. C'est le type qui porte la
      // garantie, plus un booléen que chaque chemin devait penser à poser.
      if (!clock.isRunning) return;

      if (clock.isExpiredAt(DateTime.now().millisecondsSinceEpoch)) {
        timer.cancel();
        // Directement, surtout pas dans un `addPostFrameCallback` : il ne demande
        // pas de frame, et pendant la dernière seconde rien n'en produit (le
        // tour restait sur « 1s » jusqu'à un toucher). `mounted` est testé plus
        // haut, et un callback de Timer n'est pas une phase de build.
        provider.endTurn();
        return;
      }

      // Ne notifie que si la seconde AFFICHÉE change (et non 10 fois/s).
      provider.refreshDisplayedTime();
    });
  }

  /// Gèle le chrono pendant [show] (aide, fiche d'un badge), puis le relance
  /// seulement s'il tournait : une pause du joueur reste une pause.
  ///
  /// App passée en arrière-plan pendant la fiche : pas de reprise
  /// automatique, c'est au joueur de relancer (même règle que le gel du
  /// cycle de vie).
  Future<void> _whilePaused(
      GameProvider provider, Future<void> Function() show) async {
    final wasRunning = provider.turnClock.isRunning;
    _wentBackground = false;
    provider.pauseTurn();
    await show();
    if (wasRunning && !_wentBackground && mounted) provider.resumeTurn();
  }

  void _togglePause(BuildContext context, GameProvider provider) {
    if (_isPausedOf(provider)) {
      provider.resumeTurn();
    } else {
      provider.pauseTurn();
      _showPauseDialog(context, provider);
    }
  }

  void _showPauseDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundMain,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.warning, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec croix
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.gray400,
                    size: 24,
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: AppColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PAUSE',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 48,
                  color: AppColors.warning,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Reprendre le timer quand le dialog est fermé.
      // `resumeTurn` est idempotent : inutile de tester l'état avant.
      if (mounted) provider.resumeTurn();
    });
  }

  void _handleHomePress(BuildContext context, GameProvider provider) {
    // Geler le tour immédiatement. C'est le provider qui détient le temps, donc
    // le temps passé dans ce dialogue ne peut plus être décompté au joueur —
    // c'était le bug : le widget capturait le bon reste, et `suspendGame` le
    // recalculait ensuite depuis une deadline restée vivante.
    provider.pauseTurn();

    AppConfirmDialog.show(
      context,
      title: 'Interrompre la partie',
      message: 'La partie sera mise en pause et sauvegardée automatiquement.',
      confirmText: 'Accueil',
      accentColor: AppColors.secondaryCyan,
    ).then((goHome) {
      // Si on a cliqué sur "Accueil", suspendre le jeu
      if (goHome == true) {
        provider.suspendGame();
      } else {
        // Sinon (Annuler ou clic en dehors), reprendre le timer
        if (mounted) provider.resumeTurn();
      }
    });
  }

  void _handleEndTurnPress(BuildContext context, GameProvider provider) {
    // Geler le tour pendant la confirmation.
    provider.pauseTurn();

    AppConfirmDialog.show(
      context,
      title: 'Terminer le tour ?',
      message: 'Les secondes restantes seront perdues.',
      confirmText: 'Terminer',
      accentColor: AppColors.warning,
    ).then((confirme) {
      if (confirme) provider.endTurn();

      // Reprendre le timer quand le dialog est fermé. Si « Terminer » a été
      // choisi, `endTurn` a ARRÊTÉ l'horloge : `resumeTurn` est alors un no-op
      // et ne peut donc pas ré-armer une deadline sur l'écran de vérification.
      if (mounted) provider.resumeTurn();
    });
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final currentWord = provider.game.currentWord;
    final currentTeam = provider.getCurrentTeam();
    final currentPlayer = provider.getCurrentPlayer();
    final timeRemaining = provider.game.timeRemaining;
    final isPaused = _isPausedOf(provider);
    final isLowTime = timeRemaining <= 10;
    // Pénalité EFFECTIVE et garde partagée avec `passWord` (Fiesta 2-8) ; en
    // Classique, la pénalité réglée et la garde d'avant.
    final passPenalty = provider.currentPassPenalty;
    final hasFreePass = provider.hasFreePass;
    final hasWordsToPassTo = provider.effectiveRemainingWordsCount > 0;
    final canPass = provider.canPassWith(timeRemaining) && hasWordsToPassTo;
    // Fiesta 2-11 : deux cartes, chacune avec ses boutons (une seule au
    // dernier mot). Le mot visé est passé au provider : un tap sur une carte
    // déjà remplacée est ignoré.
    final twoWords = provider.isTwoWordsOn && currentWord != null;
    final passLabel = provider.passBlocked ? 'Passer (bloqué)' : 'Passer';
    final passDetail = hasFreePass
        ? 'gratuit'
        : passPenalty > 0
            ? '-${passPenalty}s'
            : null;
    VoidCallback? guess(String word) => isPaused
        ? null
        : () {
            HapticFeedback.lightImpact();
            AudioService.playDing();
            provider.markWordAsGuessed(word);
          };
    VoidCallback? pass(String word) => canPass && !isPaused
        ? () {
            HapticFeedback.mediumImpact();
            AudioService.playWhoosh();
            provider.passWord(word);
          }
        : null;

    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Player and team info (fixe en haut, cliquable pour voir l'équipe)
                  GestureDetector(
                    onTap: () => _showTeamMembersDialog(
                        context,
                        currentTeam,
                        provider,
                        AppColors.getTeamColor(provider.game.currentTeamIndex)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentPlayer?.name ?? ''} - ${currentTeam?.name ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.gray400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.info_outline,
                            size: 14, color: AppColors.gray400),
                      ],
                    ),
                  ),

                  // Deux mots : même écran, espacements resserrés pour tenir.
                  SizedBox(height: twoWords ? 12 : 32),

                  // Zone centrale flexible
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer
                        TweenAnimationBuilder<double>(
                          key: _timerKey,
                          tween: Tween(begin: 1.0, end: isLowTime ? 1.1 : 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: isLowTime ? scale : 1.0,
                              child: Text(
                                '${timeRemaining}s',
                                style: TextStyle(
                                  fontFamily: 'Bangers',
                                  fontSize: 64,
                                  color: isLowTime
                                      ? AppColors.error
                                      : AppColors.secondaryCyan,
                                ),
                              ),
                            );
                          },
                        ),

                        // Fiesta : modificateurs du tour, sous le chrono.
                        if (provider.turnModifiers.isNotEmpty ||
                            provider.spentBonuses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ModifierBadges(
                            modifiers: provider.turnModifiers,
                            wrapExplain: (show) => _whilePaused(provider, show),
                            extra: [
                              for (final id in provider.spentBonuses)
                                ModifierBadge.catalog(
                                  id,
                                  nature: ModifierNature.bonus,
                                  wrapExplain: (show) =>
                                      _whilePaused(provider, show),
                                ),
                            ],
                          ),
                          if (provider.freePasses > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Passes gratuites : ${provider.freePassesUsed} / ${provider.freePasses}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.secondaryCyan,
                              ),
                            ),
                          ],
                          SizedBox(height: twoWords ? 8 : 16),
                        ] else
                          SizedBox(height: twoWords ? 16 : 32),

                        if (twoWords)
                          Expanded(
                            key: _wordKey,
                            child: TwoWordsLayout(
                              firstWord: currentWord,
                              secondWord: provider.secondWord,
                              reversed: provider.isWordReversed,
                              passLabel: passLabel,
                              passDetail: passDetail,
                              onGuessedFirst: guess(currentWord),
                              onPassFirst: pass(currentWord),
                              onGuessedSecond: provider.secondWord == null
                                  ? null
                                  : guess(provider.secondWord!),
                              onPassSecond: provider.secondWord == null
                                  ? null
                                  : pass(provider.secondWord!),
                            ),
                          )
                        else
                          // Current word
                          Flexible(
                            key: _wordKey,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: TurnWordText(
                                word: currentWord ?? '',
                                reversed: provider.isWordReversed,
                              ),
                            ),
                          ),

                        SizedBox(height: twoWords ? 8 : 16),

                        // Words remaining (incluant passés recyclables, sans le mot actuel)
                        Builder(
                          builder: (context) {
                            final remaining =
                                provider.effectiveRemainingWordsCount;
                            final count = remaining < 0 ? 0 : remaining;
                            return Text(
                              '$count ${count <= 1 ? 'mot restant' : 'mots restants'}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.gray400,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Action buttons (fixes en bas). Deux mots : sous chaque mot.
                  if (!twoWords) ...[
                    const SizedBox(height: 32),
                    TurnActionButtons(
                      passKey: provider.passBlocked ? null : _passKey,
                      guessedKey: _guessedKey,
                      passLabel: passLabel,
                      passDetail: passDetail,
                      onPass: canPass && !isPaused
                          ? () {
                              HapticFeedback.mediumImpact();
                              AudioService.playWhoosh();
                              provider.passWord();
                            }
                          : null,
                      onGuessed: isPaused
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              AudioService.playDing();
                              provider.markWordAsGuessed();
                            },
                    ),
                  ],

                  // Sous cette marge, le bouton « terminer le tour » (bas à droite).
                  SizedBox(height: twoWords ? 52 : 72),
                ],
              ),
            ),
          ),
          // Bouton Home personnalisé qui pause le timer
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => _handleHomePress(context, provider),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryCyan,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 24),
              ),
            ),
          ),
          // Bouton pause en haut à droite
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              key: _pauseKey,
              onTap: () => _togglePause(context, provider),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPaused ? AppColors.warning : AppColors.gray700,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPaused ? AppColors.warning : AppColors.gray500,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          HelpButton(
            right: HelpButton.besideCornerButton,
            onPressed: () => _whilePaused(
              provider,
              () => CoachMarks.show(
                context,
                turnHelp(
                  timer: _timerKey,
                  word: _wordKey,
                  guessed: _guessedKey,
                  pass: _passKey,
                  pause: _pauseKey,
                  passPenalty: passPenalty,
                ),
              ),
            ),
          ),
          // Bouton terminer le tour en bas à droite
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 24,
            child: GestureDetector(
              onTap: () => _handleEndTurnPress(context, provider),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gray700,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gray500,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.fast_forward,
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
}
