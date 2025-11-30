import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/home_button.dart';

class TurnScreen extends StatefulWidget {
  const TurnScreen({super.key});

  @override
  State<TurnScreen> createState() => _TurnScreenState();
}

class _TurnScreenState extends State<TurnScreen> {
  Timer? _timer;
  int _timeRemaining = 30;
  bool _isPaused = false;
  int? _pausedTime;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final provider = context.read<GameProvider>();
    final endTimestamp = provider.game.turnEndTimestamp;

    if (endTimestamp == null) return;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((endTimestamp - now) / 1000).ceil();

      if (remaining <= 0) {
        timer.cancel();
        provider.endTurn();
      } else {
        setState(() {
          _timeRemaining = remaining;
        });
        provider.updateTimeRemaining(remaining);
      }
    });
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        // Resume - timer will continue from paused time
        _isPaused = false;
      } else {
        // Pause
        _pausedTime = _timeRemaining;
        _isPaused = true;
      }
    });
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
    final isLowTime = _timeRemaining <= 10;
    final passPenalty = provider.settings.passPenalty;
    final canPass = _timeRemaining >= passPenalty;

    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Timer
                  GestureDetector(
                    onTap: _togglePause,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: isLowTime
                            ? AppColors.error.withOpacity(0.2)
                            : teamColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isLowTime ? AppColors.error : teamColor,
                          width: 3,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: isLowTime ? AppColors.error : teamColor,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: isLowTime ? 1.1 : 1.0),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: isLowTime ? scale : 1.0,
                                child: Text(
                                  '$_timeRemaining',
                                  style: TextStyle(
                                    fontFamily: 'Bangers',
                                    fontSize: 80,
                                    color: isLowTime ? AppColors.error : teamColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isPaused) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
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

                  const SizedBox(height: 48),

                  // Current word
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.secondaryCyan, width: 2),
                    ),
                    child: Text(
                      currentWord ?? '',
                      style: AppTextStyles.title(fontSize: 36),
                      textAlign: TextAlign.center,
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

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      // Pass button
                      Expanded(
                        child: GestureDetector(
                          onTap: canPass && !_isPaused
                              ? () => provider.passWord()
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: canPass && !_isPaused
                                  ? AppColors.error.withOpacity(0.2)
                                  : AppColors.gray700,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: canPass && !_isPaused
                                    ? AppColors.error
                                    : AppColors.gray600,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.skip_next,
                                  color: canPass && !_isPaused
                                      ? AppColors.error
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
                                        ? AppColors.error
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
                                          ? AppColors.error.withOpacity(0.7)
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
                          onTap: _isPaused ? null : () => provider.markWordAsGuessed(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: _isPaused
                                  ? AppColors.gray700
                                  : AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isPaused
                                    ? AppColors.gray600
                                    : AppColors.success,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check,
                                  color: _isPaused
                                      ? AppColors.gray500
                                      : AppColors.success,
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
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // End turn button
                  AppButton(
                    text: 'Terminer le tour',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    icon: const Icon(Icons.fast_forward, color: Colors.white, size: 18),
                    onPressed: () => provider.endTurn(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const HomeButton(),
        ],
      ),
    );
  }
}
