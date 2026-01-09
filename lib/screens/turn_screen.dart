import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../widgets/common/app_button.dart';

class TurnScreen extends StatefulWidget {
  const TurnScreen({super.key});

  @override
  State<TurnScreen> createState() => _TurnScreenState();
}

class _TurnScreenState extends State<TurnScreen> {
  Timer? _timer;
  int _timeRemaining = 30;
  bool _isPaused = false;
  int? _pausedTimeRemaining;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final provider = context.read<GameProvider>();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused) return;

      // Lire turnEndTimestamp à chaque tick pour avoir la valeur mise à jour (après pénalité)
      final endTimestamp = provider.game.turnEndTimestamp;
      if (endTimestamp == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final remainingMs = endTimestamp - now;
      final remaining = (remainingMs / 1000).ceil();

      if (remainingMs <= 0) {
        timer.cancel();
        setState(() {
          _timeRemaining = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.endTurn();
        });
      } else {
        setState(() {
          _timeRemaining = remaining > 0 ? remaining : 0;
        });
        provider.updateTimeRemaining(remaining);
      }
    });
  }

  void _togglePause(BuildContext context, GameProvider provider) {
    if (_isPaused) {
      // Resume - recalculer turnEndTimestamp basé sur le temps pausé
      final now = DateTime.now().millisecondsSinceEpoch;
      final newEndTimestamp = now + ((_pausedTimeRemaining ?? _timeRemaining) * 1000);
      provider.updateTurnEndTimestamp(newEndTimestamp);
      setState(() {
        _isPaused = false;
      });
    } else {
      // Pause - sauvegarder le temps restant et afficher popup
      setState(() {
        _pausedTimeRemaining = _timeRemaining;
        _isPaused = true;
      });
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
      // Reprendre le timer quand le dialog est fermé
      if (_isPaused) {
        _togglePause(context, provider);
      }
    });
  }

  void _handleHomePress(BuildContext context, GameProvider provider) {
    // Mettre en pause immédiatement
    if (!_isPaused) {
      setState(() {
        _pausedTimeRemaining = _timeRemaining;
        _isPaused = true;
      });
    }

    // Afficher le dialog
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.secondaryCyan, width: 2),
        ),
        title: Text(
          'Interrompre la partie',
          style: AppTextStyles.subtitle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'La partie sera mise en pause et sauvegardée automatiquement.',
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
            onPressed: () {
              Navigator.of(dialogContext).pop(false); // false = ne pas aller à l'accueil
            },
          ),
          AppButton(
            text: 'Accueil',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(dialogContext).pop(true); // true = aller à l'accueil
            },
          ),
        ],
      ),
    ).then((goHome) {
      // Si on a cliqué sur "Accueil", suspendre le jeu
      if (goHome == true) {
        provider.suspendGame();
      } else {
        // Sinon (Annuler ou clic en dehors), reprendre le timer
        if (_isPaused) {
          _togglePause(context, provider);
        }
      }
    });
  }

  void _handleEndTurnPress(BuildContext context, GameProvider provider) {
    // Mettre en pause immédiatement
    if (!_isPaused) {
      setState(() {
        _pausedTimeRemaining = _timeRemaining;
        _isPaused = true;
      });
    }

    // Afficher le dialog de confirmation
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.warning, width: 2),
        ),
        title: Text(
          'Terminer le tour ?',
          style: AppTextStyles.subtitle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Les secondes restantes seront perdues.',
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
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          AppButton(
            text: 'Terminer',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.endTurn();
            },
          ),
        ],
      ),
    ).then((_) {
      // Reprendre le timer quand le dialog est fermé (sauf si le tour est terminé)
      if (_isPaused && mounted) {
        _togglePause(context, provider);
      }
    });
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final currentWord = provider.game.currentWord;
    final currentTeam = provider.getCurrentTeam();
    final currentPlayer = provider.getCurrentPlayer();
    final isLowTime = _timeRemaining <= 10;
    final passPenalty = provider.settings.passPenalty;
    final hasWordsToPassTo = provider.effectiveRemainingWordsCount > 0;
    final canPass = _timeRemaining >= passPenalty && hasWordsToPassTo;

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
                    onTap: () => _showTeamMembersDialog(context, currentTeam, provider, AppColors.getTeamColor(provider.game.currentTeamIndex)),
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
                        const Icon(Icons.info_outline, size: 14, color: AppColors.gray400),
                      ],
                    ),
                  ),

                  // Zone centrale flexible
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: isLowTime ? 1.1 : 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: isLowTime ? scale : 1.0,
                              child: Text(
                                '${_timeRemaining}s',
                                style: TextStyle(
                                  fontFamily: 'Bangers',
                                  fontSize: 64,
                                  color: isLowTime ? AppColors.error : AppColors.secondaryCyan,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Current word
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final text = currentWord ?? '';
                              // Calculer la taille de police adaptée
                              double fontSize = 64;
                              if (text.length > 30) {
                                fontSize = 48;
                              } else if (text.length > 20) {
                                fontSize = 56;
                              }
                              return Text(
                                text,
                                style: TextStyle(
                                  fontFamily: 'Bangers',
                                  fontSize: fontSize,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      color: AppColors.primaryPinkDark,
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Words remaining (incluant passés recyclables, sans le mot actuel)
                        Builder(
                          builder: (context) {
                            final remaining = provider.effectiveRemainingWordsCount;
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

                  // Action buttons (fixes en bas)
                  Row(
                    children: [
                      // Pass button
                      Expanded(
                        child: GestureDetector(
                          onTap: canPass && !_isPaused
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  AudioService.playWhoosh();
                                  provider.passWord();
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: canPass && !_isPaused
                                  ? AppColors.error
                                  : AppColors.gray700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.skip_next,
                                  color: canPass && !_isPaused
                                      ? Colors.white
                                      : AppColors.gray500,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Passer',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: canPass && !_isPaused
                                        ? Colors.white
                                        : AppColors.gray500,
                                  ),
                                ),
                                if (passPenalty > 0)
                                  Text(
                                    '-${passPenalty}s',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: canPass && !_isPaused
                                          ? Colors.white.withOpacity( 0.7)
                                          : AppColors.gray600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Guessed button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _isPaused ? null : () {
                            HapticFeedback.lightImpact();
                            AudioService.playDing();
                            provider.markWordAsGuessed();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 33),
                            decoration: BoxDecoration(
                              color: _isPaused
                                  ? AppColors.gray700
                                  : AppColors.secondaryCyan,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.check,
                              color: _isPaused
                                  ? AppColors.gray500
                                  : Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 72),
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
              onTap: () => _togglePause(context, provider),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isPaused ? AppColors.warning : AppColors.gray700,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isPaused ? AppColors.warning : AppColors.gray500,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 24,
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
