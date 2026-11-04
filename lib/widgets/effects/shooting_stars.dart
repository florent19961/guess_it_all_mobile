import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fond animé « ciel étoilé calme » : des étoiles qui scintillent sur trois
/// profondeurs en dérivant lentement, et une étoile filante de temps en temps.
class ShootingStars extends StatefulWidget {
  final Widget child;

  const ShootingStars({required this.child, super.key});

  @override
  State<ShootingStars> createState() => _ShootingStarsState();
}

class _ShootingStarsState extends State<ShootingStars>
    with SingleTickerProviderStateMixin {
  // Temps écoulé en secondes : seul le painter se redessine, pas l'arbre.
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: RepaintBoundary(
            child: CustomPaint(painter: _SkyPainter(_time)),
          ),
        ),

        // Child content (wrapped in Material for TextField support)
        Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ],
    );
  }
}

class _Star {
  final double x, y, phase, frequency;
  const _Star(this.x, this.y, this.phase, this.frequency);
}

class _Layer {
  final double radius, speed;
  final List<_Star> stars;
  const _Layer(this.radius, this.speed, this.stars);
}

class _Shot {
  final double at, x, y, length;
  const _Shot(this.at, this.x, this.y, this.length);
}

/// Largeur logique de référence d'un téléphone : les tailles en découlent.
const double _refWidth = 390;

final Random _random = Random(7);

// (nombre, rayon, vitesse) : du fond, petit et lent, au premier plan.
final List<_Layer> _layers = [
  for (final (count, radius, speed) in const [
    (70, 0.6, 3.0),
    (40, 1.0, 6.0),
    (16, 1.5, 11.0)
  ])
    _Layer(radius, speed, [
      for (var i = 0; i < count; i++)
        _Star(_random.nextDouble(), _random.nextDouble(),
            _random.nextDouble() * 2 * pi, 0.6 + _random.nextDouble() * 1.6),
    ]),
];

/// Écart entre deux étoiles filantes : 4 à 7 s, y compris d'un cycle au suivant.
final List<double> _shotGaps = [
  for (var i = 0; i < 12; i++) 4 + _random.nextDouble() * 3,
];

/// Durée du cycle des étoiles filantes : la somme des écarts.
final double _shotCycle = _shotGaps.reduce((a, b) => a + b);

final List<_Shot> _shots = [
  for (var i = 0; i < _shotGaps.length; i++)
    _Shot(
        _shotGaps.take(i).fold(0.0, (a, b) => a + b),
        0.1 + _random.nextDouble() * 0.7,
        _random.nextDouble() * 0.4,
        90 + _random.nextDouble() * 70),
];

class _SkyPainter extends CustomPainter {
  final ValueNotifier<double> time;

  _SkyPainter(this.time) : super(repaint: time);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = time.value;
    final s = w / _refWidth;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h),
            const [Color(0xFF22304A), Color(0xFF2B3848)]),
    );

    final star = Paint();
    for (final layer in _layers) {
      final dim = layer.radius > 1.2 ? 1.0 : 0.8;
      for (final st in layer.stars) {
        final x = (st.x * w + t * layer.speed * s * 0.6) % w;
        final y = (st.y * h + t * layer.speed * s) % h;
        final twinkle =
            0.25 + 0.6 * (0.5 + 0.5 * sin(t * st.frequency + st.phase));
        star.color = Color.fromRGBO(255, 255, 255, twinkle * dim);
        canvas.drawCircle(Offset(x, y), layer.radius * s * 1.2, star);
      }
    }

    final cycle = t % _shotCycle;
    for (final shot in _shots) {
      final k = (cycle - shot.at) / 0.9;
      if (k < 0 || k > 1) continue;
      final head = Offset((shot.x + k * 0.35) * w, (shot.y + k * 0.25) * h);
      final length = shot.length * s;
      final tail = head - Offset(length * 0.81, length * 0.58);
      final fade = sin(k * pi);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..shader = ui.Gradient.linear(tail, head, [
            const Color.fromRGBO(255, 255, 255, 0),
            Color.fromRGBO(255, 255, 255, 0.85 * fade),
          ])
          ..strokeWidth = 1.8 * s
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
          head, 1.8 * s, Paint()..color = Color.fromRGBO(255, 255, 255, fade));
    }
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) => oldDelegate.time != time;
}
