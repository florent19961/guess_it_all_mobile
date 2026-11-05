import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/game_dialogs.dart';
import '../widgets/common/back_button.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

/// Fin d'une manche, Classique et Fiesta. Aucun score : il reste caché jusqu'aux
/// résultats. Après M1 et M2, une animation puis directement l'écran avant le
/// tour ([_RoundStage]) ; après M3, un écran fixe, dernière chance de contester
/// le dernier tour ([_LastRoundEnd]).
class TransitionScreen extends StatelessWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final round = provider.game.currentRound;
    return round >= 3
        ? const _LastRoundEnd()
        : _RoundStage(key: ValueKey(round), round: round);
  }
}

/// Durée de l'animation, et ses instants en fraction (maquette `.stagep`).
const _stageDuration = Duration(milliseconds: 2800);
const _impactAt = 0.11;
const _arrivalAt = 0.42;

/// Sans animation : le temps de lire.
const _stillDuration = Duration(milliseconds: 1600);

/// « Manche N terminée » s'écrase (zoom, flash, secousse, éclats, vibration),
/// puis « Manche N+1 : nom » arrive en glissant. Un toucher fait passer.
///
/// Rien n'est persisté ici : `nextRound` est idempotent et une app tuée rejoue
/// simplement l'animation.
class _RoundStage extends StatefulWidget {
  final int round;
  const _RoundStage({required this.round, super.key});

  @override
  State<_RoundStage> createState() => _RoundStageState();
}

class _RoundStageState extends State<_RoundStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _still;
  bool _started = false;
  bool _impacted = false;
  bool _arrived = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _stageDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      AudioService.playImpact();
      _still = Timer(_stillDuration, _finish);
      return;
    }
    _controller
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _onTick() {
    final t = _controller.value;
    if (!_impacted && t >= _impactAt) {
      _impacted = true;
      AudioService.playImpact();
      HapticFeedback.lightImpact();
    }
    if (!_arrived && t >= _arrivalAt) {
      _arrived = true;
      AudioService.playWhooshShort();
    }
  }

  void _finish() {
    if (mounted) context.read<GameProvider>().nextRound();
  }

  @override
  void dispose() {
    _still?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.round + 1;
    final finished = _SlamTitle('Manche ${widget.round} terminée');
    final upcoming =
        _NextTitle('Manche $next : ${AppConstants.roundModes[next] ?? ''}');
    return Material(
      color: AppColors.backgroundMain,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: _reduced
            ? _StageLayout(finished: finished, upcoming: upcoming)
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  final slam = _slamAt(t);
                  final slide = _slideAt(t);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.translate(
                        offset: _shakeAt(t),
                        child: _StageLayout(
                          finished: Opacity(
                            opacity: slam.opacity,
                            child: Transform.rotate(
                              angle: slam.turn,
                              child: Transform.scale(
                                scale: slam.scale,
                                child: finished,
                              ),
                            ),
                          ),
                          upcoming: Opacity(
                            opacity: slide.opacity,
                            child: FractionalTranslation(
                              translation: Offset(slide.x, 0),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.skewX(slide.skew),
                                child: upcoming,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Opacity(
                          opacity: _flashAt(t),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xE6FFFFFF),
                                  Color(0x73F19B9B),
                                  Color(0x00F19B9B),
                                ],
                                stops: [0, 0.45, 0.72],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(painter: _SparksPainter(t)),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Interpole entre les [points] `(instant, valeur)`, triés.
double _keyframes(double t, List<(double, double)> points) {
  if (t <= points.first.$1) return points.first.$2;
  for (var i = 1; i < points.length; i++) {
    final (t1, v1) = points[i];
    if (t <= t1) {
      final (t0, v0) = points[i - 1];
      return v0 + (v1 - v0) * (t - t0) / (t1 - t0);
    }
  }
  return points.last.$2;
}

double _degrees(double d) => d * pi / 180;

({double scale, double turn, double opacity}) _slamAt(double t) => (
      scale: _keyframes(t, [(0, 3.4), (.11, .9), (.16, 1.08), (.22, 1)]),
      turn: _degrees(_keyframes(t, [(0, -5), (.11, 1), (.16, 0)])),
      opacity: _keyframes(t, [(0, 0), (.11, 1)]),
    );

({double x, double skew, double opacity}) _slideAt(double t) => (
      x: _keyframes(t, [(.42, 1.2), (.52, -.05), (.58, 0)]),
      skew: _degrees(_keyframes(t, [(.42, -14), (.52, 5), (.58, 0)])),
      opacity: _keyframes(t, [(.42, 0), (.52, 1)]),
    );

double _flashAt(double t) => _keyframes(t, [(.09, 0), (.12, 1), (.30, 0)]);

Offset _shakeAt(double t) => Offset(
      _keyframes(
          t, [(.11, 0), (.13, -7), (.16, 7), (.19, -5), (.22, 4), (.26, 0)]),
      _keyframes(
          t, [(.11, 0), (.13, 5), (.16, -5), (.19, -3), (.22, 3), (.26, 0)]),
    );

/// Éclats de l'impact : mêmes directions à chaque fois, aucun hasard à l'écran.
class _SparksPainter extends CustomPainter {
  final double t;
  const _SparksPainter(this.t);

  static const _count = 16;
  static const _colors = [
    AppColors.primaryPink,
    AppColors.secondaryCyan,
    AppColors.warning,
    AppColors.team3,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final progress = (t - _impactAt) / (_arrivalAt - _impactAt);
    if (progress <= 0 || progress >= 1) return;
    final eased = 1 - pow(1 - progress, 3).toDouble();
    final center = Offset(size.width / 2, size.height * 0.42);
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final angle = i * 2 * pi / _count;
      final reach = (i.isEven ? 170.0 : 120.0) * eased;
      paint.color = _colors[i % _colors.length].withValues(alpha: 1 - progress);
      canvas.save();
      canvas.translate(
          center.dx + cos(angle) * reach, center.dy + sin(angle) * reach);
      canvas.rotate(_degrees(220) * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -5, 10, 10),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SparksPainter oldDelegate) => oldDelegate.t != t;
}

class _StageLayout extends StatelessWidget {
  final Widget finished;
  final Widget upcoming;
  const _StageLayout({required this.finished, required this.upcoming});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [finished, const SizedBox(height: 18), upcoming],
            ),
          ),
        ),
      );
}

class _SlamTitle extends StatelessWidget {
  final String text;
  const _SlamTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Bangers',
          fontSize: 58,
          height: 1,
          letterSpacing: 1,
          color: Colors.white,
          shadows: [
            Shadow(offset: Offset(4, 4), color: AppColors.primaryPinkDark),
          ],
        ),
      );
}

class _NextTitle extends StatelessWidget {
  final String text;
  const _NextTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Bangers',
          fontSize: 34,
          height: 1.1,
          color: AppColors.secondaryCyan,
          shadows: [Shadow(offset: Offset(2, 2), color: Color(0xFF0B1220))],
        ),
      );
}

/// Après la manche 3 : écran fixe, avec retour vers la vérification.
class _LastRoundEnd extends StatefulWidget {
  const _LastRoundEnd();

  @override
  State<_LastRoundEnd> createState() => _LastRoundEndState();
}

class _LastRoundEndState extends State<_LastRoundEnd> {
  final _previousTurnKey = GlobalKey();
  final _nextKey = GlobalKey();
  final _backKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final history = provider.game.history;
    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              'Manche 3 terminée',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle(fontSize: 44),
                            ),
                            if (history.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              GestureDetector(
                                key: _previousTurnKey,
                                onTap: () =>
                                    _showGuessedWordsDialog(context, provider),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.checklist,
                                          size: 16, color: Colors.white70),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Voir les ${history.last.wordsGuessed.length} mots devinés',
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
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    key: _nextKey,
                    text: 'Voir les résultats',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: provider.nextRound,
                  ),
                ],
              ),
            ),
          ),
          HelpButton(
            onPressed: () => CoachMarks.show(
              context,
              transitionHelp(
                previousTurn: _previousTurnKey,
                next: _nextKey,
                back: _backKey,
              ),
            ),
          ),
          if (provider.canGoBackToVerification)
            GameBackButton(
              key: _backKey,
              onPressed: () => showBackToVerificationDialog(context, provider),
            ),
        ],
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
