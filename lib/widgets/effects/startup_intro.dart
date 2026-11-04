import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Animation de démarrage « Le chrono se lance » (choix Florent 2026-11-04).
///
/// Posée au-dessus de toute l'app (`MaterialApp.builder`) : son état vit aussi
/// longtemps que le process, elle ne joue donc qu'au démarrage à froid — ni au
/// retour d'arrière-plan, ni en revenant sur l'accueil. Un tap la saute. Si le
/// système demande moins d'animations, logo et titre apparaissent en fondu.
/// Le splash natif est un simple fond #2B3848 : le logo part de rien.
class StartupIntro extends StatefulWidget {
  final Widget child;

  const StartupIntro({required this.child, super.key});

  @override
  State<StartupIntro> createState() => _StartupIntroState();
}

class _StartupIntroState extends State<StartupIntro>
    with TickerProviderStateMixin {
  static const _background = Color(0xFF2B3848);
  static const _playMs = 1450;
  static const _reducedMs = 900;

  late final AnimationController _play;
  // `preserve` : en « animations réduites », Flutter raccourcirait sinon les
  // durées à 5 % — le fondu réduit est géré ici, il doit garder sa durée.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _started = false;
  bool _reduced = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    );
    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _done = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.of(context).disableAnimations;
    _play.duration = Duration(milliseconds: _reduced ? _reducedMs : _playMs);
    _play.forward().whenComplete(_leave);
  }

  void _leave() {
    if (!mounted || _exit.isAnimating || _done) return;
    _play.stop();
    _exit.forward();
  }

  @override
  void dispose() {
    _play.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Structure stable : l'app reste le premier enfant, seule l'intro disparaît.
    return Stack(
      children: [
        widget.child,
        if (!_done)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _leave,
              child: AnimatedBuilder(
                animation: Listenable.merge([_play, _exit]),
                builder: (context, _) => Opacity(
                  opacity: 1 - _exit.value,
                  // Material : sans lui, le style de texte par défaut de
                  // WidgetsApp (au-dessus du Navigator) souligne le titre.
                  child: Material(
                    color: _background,
                    child: _buildScene(context),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScene(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = width * 0.52;
    final fontSize = logoSize * 0.26;
    final titleHeight = fontSize * 1.3;
    final ms = _play.value * _play.duration!.inMilliseconds;

    final double shift;
    final _LogoFrame frame;
    final double fade;
    if (_reduced) {
      shift = 0;
      frame = const _LogoFrame.end();
      fade = Curves.easeOut.transform((ms / 300).clamp(0.0, 1.0));
    } else {
      shift = titleHeight / 2 * (1 - _t(ms, 820, 300));
      frame = _LogoFrame(
        track: _t(ms, 0, 300),
        arc: _t(ms, 0, 560),
        dot: _t(ms, 0, 120),
        pop: _t(ms, 300, 420, _back),
        swing: _t(ms, 560, 380),
      );
      fade = 1;
    }

    var letterIndex = 0;
    final letters = <Widget>[];
    for (final char in 'Guess It All'.split('')) {
      final style = AppTextStyles.title(fontSize: fontSize);
      if (char == ' ') {
        letters.add(Text(char, style: style));
        continue;
      }
      final t = _reduced ? 1.0 : _t(ms, 860 + 35.0 * letterIndex, 260);
      letterIndex++;
      letters.add(Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: Text(char, style: style),
        ),
      ));
    }

    return Center(
      child: Opacity(
        opacity: fade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, shift),
              child: CustomPaint(
                size: Size.square(logoSize),
                painter: _StartupLogoPainter(frame),
              ),
            ),
            SizedBox(
              height: titleHeight,
              width: width - 48,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: letters),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _out = Cubic(0.2, 0.8, 0.2, 1);
  static const _back = Cubic(0.34, 1.56, 0.64, 1);

  /// Progression 0→1 d'un segment [start, start + duration] (ms), courbée.
  static double _t(double ms, double start, double duration,
      [Curve curve = _out]) {
    final raw = ((ms - start) / duration).clamp(0.0, 1.0);
    return curve.transform(raw);
  }
}

/// État de chaque élément du logo, 0 = absent, 1 = en place.
class _LogoFrame {
  final double track, arc, dot, pop, swing;

  const _LogoFrame({
    required this.track,
    required this.arc,
    required this.dot,
    required this.pop,
    required this.swing,
  });

  const _LogoFrame.end()
      : track = 1,
        arc = 1,
        dot = 1,
        pop = 1,
        swing = 1;
}

/// Logo « Bulle chrono », mêmes constantes que `scripts/render_logo.py`
/// (`artwork()`, canevas 1024) : toute modification se reporte à la main des
/// deux côtés.
class _StartupLogoPainter extends CustomPainter {
  final _LogoFrame frame;

  _StartupLogoPainter(this.frame);

  static const _teal = AppColors.secondaryCyan; // #7DD3C0
  static const _pink = AppColors.primaryPink; // #F19B9B
  static const _center = Offset(512, 512);
  static const _ringRadius = 345.0;
  static const _ringWidth = 58.0;
  static const _dot = Offset(512, 167);
  static const _dotRadius = 44.0;
  static const _bubble = Offset(512, 490);
  static const _bubbleRadius = 215.0;
  static const _tail = [Offset(475, 632), Offset(368, 748), Offset(377, 615)];
  static const _tailStroke = 18.0;
  // Centre de la boîte englobante bulle + queue : pivot du « pop ».
  static const _popPivot = Offset(543, 516);
  static const _questionBaseline = Offset(512, 600);
  static const _questionSize = 300.0;
  static const _questionTilt = -6 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024);

    final ring = Rect.fromCircle(center: _center, radius: _ringRadius);
    if (frame.track > 0) {
      canvas.drawCircle(
        _center,
        _ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth
          ..color = _teal.withValues(alpha: 0.22 * frame.track),
      );
    }
    if (frame.arc > 0) {
      // Du haut, sens horaire, 270° : le quart haut-gauche reste vide.
      canvas.drawArc(
        ring,
        -math.pi / 2,
        1.5 * math.pi * frame.arc,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth
          ..strokeCap = StrokeCap.round
          ..color = _teal,
      );
    }
    if (frame.dot > 0) {
      canvas.drawCircle(_dot, _dotRadius,
          Paint()..color = _teal.withValues(alpha: frame.dot));
    }

    if (frame.pop > 0) {
      canvas.save();
      canvas.translate(_popPivot.dx, _popPivot.dy);
      canvas.scale(frame.pop);
      canvas.translate(-_popPivot.dx, -_popPivot.dy);
      _paintBubble(canvas);
      _paintQuestion(canvas);
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintBubble(Canvas canvas) {
    final pink = Paint()..color = _pink;
    canvas.drawCircle(_bubble, _bubbleRadius, pink);
    final tail = Path()..addPolygon(_tail, true);
    canvas.drawPath(tail, pink);
    canvas.drawPath(
      tail,
      Paint()
        ..color = _pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = _tailStroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintQuestion(Canvas canvas) {
    final text = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: _questionSize,
          color: Colors.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline =
        text.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final topLeft = Offset(
      _questionBaseline.dx - text.width / 2,
      _questionBaseline.dy - baseline,
    );

    // Balancier -24° → +12° → 0° autour du centre du glyphe.
    final s = frame.swing;
    final swingDeg = s < 0.5 ? -24 + 72 * s : 12 - 24 * (s - 0.5);
    final glyphCenter = topLeft + Offset(text.width / 2, text.height / 2);

    canvas.save();
    // Inclinaison fixe du logo : -6° autour du point de base.
    canvas.translate(_questionBaseline.dx, _questionBaseline.dy);
    canvas.rotate(_questionTilt);
    canvas.translate(-_questionBaseline.dx, -_questionBaseline.dy);
    canvas.translate(glyphCenter.dx, glyphCenter.dy);
    canvas.rotate(swingDeg * math.pi / 180);
    canvas.translate(-glyphCenter.dx, -glyphCenter.dy);
    text.paint(canvas, topLeft);
    canvas.restore();
    text.dispose();
  }

  @override
  bool shouldRepaint(_StartupLogoPainter old) =>
      old.frame.track != frame.track ||
      old.frame.arc != frame.arc ||
      old.frame.dot != frame.dot ||
      old.frame.pop != frame.pop ||
      old.frame.swing != frame.swing;
}
