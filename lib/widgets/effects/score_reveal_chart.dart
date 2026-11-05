import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../models/score_timeline.dart';
import '../../theme/app_theme.dart';
import '../fiesta/modifier_badge.dart';

/// Graphique de la révélation (maquette `curve(2)`) : cadre fixe, un trait par
/// équipe, sans aucun chiffre. [progress] va de 0 à 1 sur toute la partie.
class ScoreRevealPainter extends CustomPainter {
  final ScoreTimeline timeline;
  final Animation<double> progress;
  final List<String> teamNames;
  final List<Color> teamColors;

  ScoreRevealPainter({
    required this.timeline,
    required this.progress,
    required this.teamNames,
    required this.teamColors,
  }) : super(repaint: progress);

  static const _left = 14.0;
  static const _right = 16.0;
  static const _top = 14.0;
  static const _bottom = 26.0;
  static const _bubbleRadius = 14.0;

  /// Durée de chute d'une cartouche, en part de l'animation (≈ 0,16 s).
  static const _fallShare = 0.035;
  static const _fallHeight = 170.0;

  @override
  void paint(Canvas canvas, Size size) {
    final steps = timeline.steps;
    if (steps == 0) return;
    final p = progress.value;
    final t = p * steps;
    final plotW = size.width - _left - _right;
    final plotBottom = size.height - _bottom;
    final yMax = max(1, timeline.maxScore) * 1.1;
    double xAt(double step) => _left + step / steps * plotW;
    double yAt(double value) => plotBottom - value / yMax * (plotBottom - _top);

    canvas.clipRect(Offset.zero & size);
    _paintRounds(canvas, size, xAt, plotBottom);

    // Un point tous les ~2 px : assez fin pour un trait rond, quel que soit le
    // nombre de tours.
    final dx = steps / plotW * 2;
    for (var team = 0; team < timeline.series.length; team++) {
      final path = Path()..moveTo(xAt(0), yAt(timeline.valueAt(team, 0)));
      for (var x = dx; x < t; x += dx) {
        path.lineTo(xAt(x), yAt(timeline.valueAt(team, x)));
      }
      final head = Offset(xAt(t), yAt(timeline.valueAt(team, t)));
      path.lineTo(head.dx, head.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = teamColors[team]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(head, 6, Paint()..color = teamColors[team]);
    }

    _paintHeadNames(canvas, size, xAt(t), plotBottom, [
      for (var i = 0; i < teamNames.length; i++) yAt(timeline.valueAt(i, t))
    ]);

    for (final event in timeline.events) {
      final fall = p >= 1 ? 1.0 : (p - event.step / steps) / _fallShare;
      if (fall < 0) continue;
      final q = min(1.0, fall);
      final eased = 1 - (1 - q) * (1 - q);
      final rest = max(
          _top + _bubbleRadius,
          yAt(timeline.series[event.teamIndex][event.step].toDouble()) -
              22 -
              event.stack * 30);
      _paintBubble(
        canvas,
        Offset(
          xAt(event.step.toDouble())
              .clamp(_bubbleRadius + 1, size.width - _bubbleRadius - 1),
          rest - (1 - eased) * _fallHeight,
        ),
        event.catalogId,
        q,
      );
    }
  }

  void _paintRounds(Canvas canvas, Size size, double Function(double) xAt,
      double plotBottom) {
    final rounds = timeline.rounds;
    final dash = Paint()
      ..color = AppColors.gray700
      ..strokeWidth = 1;
    var labelFloor = 0.0;
    for (var i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final end = xAt(round.end.toDouble());
      if (i < rounds.length - 1) {
        for (var y = _top; y < plotBottom; y += 9) {
          canvas.drawLine(
              Offset(end, y), Offset(end, min(y + 4, plotBottom)), dash);
        }
      }
      final start = xAt(round.start.toDouble());
      var label = _text('Manche ${round.round}', 11, AppColors.gray400);
      if (label.width + 4 > end - start) {
        label = _text('M${round.round}', 11, AppColors.gray400);
      }
      final x = max(labelFloor, (start + end - label.width) / 2)
          .clamp(0.0, size.width - label.width);
      label.paint(canvas, Offset(x, plotBottom + 8));
      labelFloor = x + label.width + 4;
    }
  }

  void _paintHeadNames(Canvas canvas, Size size, double headX,
      double plotBottom, List<double> headYs) {
    const gap = 15.0;
    final toLeft = headX > size.width * .55;
    final maxWidth = toLeft ? headX - 12 - _left : size.width - headX - 12 - 2;
    final order = [for (var i = 0; i < headYs.length; i++) i]
      ..sort((a, b) => headYs[a].compareTo(headYs[b]));
    final tops = [for (final i in order) headYs[i] - 23];
    for (var i = 1; i < tops.length; i++) {
      tops[i] = max(tops[i], tops[i - 1] + gap);
    }
    // Tous à zéro au départ : on remonte plutôt que de mordre les manches.
    var floor = plotBottom - 16;
    for (var i = tops.length - 1; i >= 0; i--) {
      tops[i] = min(tops[i], floor);
      floor = tops[i] - gap;
    }
    for (var i = 0; i < order.length; i++) {
      final label = _text(teamNames[order[i]], 11, teamColors[order[i]],
          weight: FontWeight.w600, maxWidth: maxWidth);
      label.paint(canvas,
          Offset(toLeft ? headX - 12 - label.width : headX + 12, tops[i]));
    }
  }

  void _paintBubble(Canvas canvas, Offset at, String catalogId, double alpha) {
    final color =
        modifierColor(modifierById(catalogId)?.nature ?? ModifierNature.malus)
            .withValues(alpha: alpha);
    canvas.drawCircle(at, _bubbleRadius,
        Paint()..color = AppColors.backgroundMain.withValues(alpha: alpha));
    canvas.drawCircle(
        at,
        _bubbleRadius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final icon =
        _text(modifierIcon(catalogId), 11, color, weight: FontWeight.w700);
    icon.paint(canvas, at - Offset(icon.width / 2, icon.height / 2));
  }

  TextPainter _text(String text, double size, Color color,
          {FontWeight? weight, double maxWidth = double.infinity}) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: size,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);

  @override
  bool shouldRepaint(ScoreRevealPainter old) =>
      old.timeline != timeline || old.progress != progress;
}
