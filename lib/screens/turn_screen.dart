import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
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
    final currentPlayer = provider.getCurrentPlayer();
    final currentTeam = provider.getCurrentTeam();
    final teamColor = AppColors.getTeamColor(provider.game.currentTeamIndex);

    // Récupérer les noms des joueurs de l'équipe (sauf le joueur actuel)
    final otherPlayers = currentTeam?.playerIds
        .where((id) => id != currentPlayer?.id)
        .map((id) => provider.getPlayerById(id)?.name ?? '')
        .where((name) => name.isNotEmpty)
        .toList() ?? [];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: AppColors.backgroundMain,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: teamColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: teamColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec icône pause
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: teamColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: teamColor, width: 2),
                      ),
                      child: Icon(
                        Icons.pause_rounded,
                        color: teamColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PAUSE',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 36,
                        color: teamColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Joueur actuel - carte mise en avant
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            teamColor.withOpacity(0.2),
                            teamColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: teamColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, color: teamColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Fait deviner',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: teamColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentPlayer?.name ?? '',
                            style: const TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Équipe
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.groups, color: teamColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                currentTeam?.name ?? '',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: teamColor,
                                ),
                              ),
                            ],
                          ),
                          if (otherPlayers.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              otherPlayers.join(' • '),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.gray400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mode de manche
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondaryCyan.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryCyan.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Manche ${provider.game.currentRound}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondaryCyan,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppConstants.roundModes[provider.game.currentRound] ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.roundDescriptions[provider.game.currentRound] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.gray400,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton Reprendre
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Reprendre',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        fullWidth: true,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _togglePause(context, provider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
              Navigator.of(dialogContext).pop();
              // Reprendre le timer
              _togglePause(context, provider);
            },
          ),
          AppButton(
            text: 'Accueil',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.suspendGame();
            },
          ),
        ],
      ),
    );
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
        content: Text(
          'Les ${_pausedTimeRemaining}s restantes seront perdues.',
          style: const TextStyle(
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
              // Reprendre le timer
              _togglePause(context, provider);
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
    final teamColor = AppColors.getTeamColor(provider.game.currentTeamIndex);
    final currentWord = provider.game.currentWord;
    final currentTeam = provider.getCurrentTeam();
    final currentPlayer = provider.getCurrentPlayer();
    final isLowTime = _timeRemaining <= 10;
    final passPenalty = provider.settings.passPenalty;
    final hasWordsToPassTo = provider.game.remainingWords.length > 1;
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
                  // Player and team info (fixe en haut)
                  Text(
                    '${currentPlayer?.name ?? ''} (${currentTeam?.name ?? ''})',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.gray400,
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
                                  fontSize: 80,
                                  color: isLowTime ? AppColors.error : teamColor,
                                ),
                              ),
                            );
                          },
                        ),

                        if (_isPaused) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PAUSE',
                              style: TextStyle(
                                fontFamily: 'Bangers',
                                fontSize: 24,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],

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
                                maxLines: 2,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Words remaining
                        Text(
                          '${provider.game.remainingWords.length} mots restants',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.gray400,
                          ),
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
                                          ? Colors.white.withValues(alpha: 0.7)
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
                            AudioService.playDing();
                            provider.markWordAsGuessed();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: _isPaused
                                  ? AppColors.gray700
                                  : AppColors.secondaryCyan,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check,
                                  color: _isPaused
                                      ? AppColors.gray500
                                      : Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deviné !',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _isPaused
                                        ? AppColors.gray500
                                        : Colors.white,
                                  ),
                                ),
                              ],
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
