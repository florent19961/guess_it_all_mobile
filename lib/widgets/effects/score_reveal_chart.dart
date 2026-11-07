import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/score_timeline.dart';
import '../../theme/app_theme.dart';

const _labelGap = 7.0;

/// Écart entre la tête et son étiquette : rien n'est tracé à droite de la tête,
/// donc aucun nom ne touche une courbe.
const _labelOffset = 15.0;

/// Position lissée sur une fenêtre (≈ 0,2 s) : sans état par image, l'étiquette
/// glisse quand l'ordre des courbes change au lieu de sauter.
const _smoothSamples = 7;
const _smoothWindow = 0.045;

/// Où poser l'étiquette de chaque équipe, fonction pure du progrès. La fenêtre
/// se resserre en fin de tracé : à 1, chaque étiquette a rejoint sa tête.
List<Offset> placeRevealLabels({
  required ScoreTimeline timeline,
  required double progress,
  required double headX,
  required double Function(double value) yAt,
  required List<double> heights,
  required double top,
  required double bottom,
}) {
  final window = min(_smoothWindow, 1 - progress);
  final tops = List.filled(heights.length, 0.0);
  for (var s = 0; s < _smoothSamples; s++) {
    final t =
        max(0.0, progress - window * s / (_smoothSamples - 1)) * timeline.steps;
    final sample = _stackLabels(
        [for (var i = 0; i < heights.length; i++) yAt(timeline.valueAt(i, t))],
        heights,
        top,
        bottom);
    for (var i = 0; i < tops.length; i++) {
      tops[i] += sample[i] / _smoothSamples;
    }
  }
  return [for (final y in tops) Offset(headX + _labelOffset, y)];
}

/// Le haut de chaque étiquette, centrée sur sa tête puis poussée pour ne pas
/// chevaucher ses voisines ni sortir de [top]..[bottom].
List<double> _stackLabels(
    List<double> ys, List<double> heights, double top, double bottom) {
  final count = ys.length;
  final order = [for (var i = 0; i < count; i++) i]..sort((a, b) {
      final byY = ys[a].compareTo(ys[b]);
      return byY != 0 ? byY : a - b;
    });
  final tops = [for (final i in order) ys[i] - heights[i] / 2];
  for (var pass = 0; pass < 14; pass++) {
    for (var i = 0; i < count - 1; i++) {
      final over = tops[i] + heights[order[i]] + _labelGap - tops[i + 1];
      if (over > 0) {
        tops[i] -= over / 2;
        tops[i + 1] += over / 2;
      }
    }
  }
  for (var i = 0; i < count; i++) {
    final floor =
        i == 0 ? top : tops[i - 1] + heights[order[i - 1]] + _labelGap;
    if (tops[i] < floor) tops[i] = floor;
  }
  for (var i = count - 1; i >= 0; i--) {
    final ceiling =
        (i == count - 1 ? bottom : tops[i + 1] - _labelGap) - heights[order[i]];
    if (tops[i] > ceiling) tops[i] = ceiling;
  }
  final result = List.filled(count, 0.0);
  for (var i = 0; i < count; i++) {
    result[order[i]] = tops[i];
  }
  return result;
}

/// Graphique de la révélation : cadre fixe, un trait par équipe, sans aucun
/// chiffre, les étiquettes dans une colonne réservée à droite. [progress] va de
/// 0 à 1 sur toute la partie.
class ScoreRevealPainter extends CustomPainter {
  final ScoreTimeline timeline;
  final Animation<double> progress;
  final List<String> labels;
  final List<Color> teamColors;
  final TextScaler textScaler;

  ScoreRevealPainter({
    required this.timeline,
    required this.progress,
    required this.labels,
    required this.teamColors,
    required this.textScaler,
  }) : super(repaint: progress);

  static const _left = 8.0;
  static const _top = 8.0;
  static const _bottom = 26.0;
  static const _columnWidth = 124.0;
  static const _columnMargin = 22.0;
  static const _labelFont = 12.0;
  static const _minLabelFont = 9.0;
  static const _labelLineHeight = 1.25;

  /// Au-delà, un trait fin relie l'étiquette à sa tête.
  static const _linkFrom = 9.0;

  Size? _fittedFor;
  List<TextPainter> _fitted = const [];

  @override
  void paint(Canvas canvas, Size size) {
    final steps = timeline.steps;
    if (steps == 0) return;
    final t = progress.value * steps;
    final column = min(_columnWidth * textScaler.scale(1), size.width / 2);
    final plotW = size.width - _left - column;
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
      path.lineTo(xAt(t), yAt(timeline.valueAt(team, t)));
      canvas.drawPath(
        path,
        Paint()
          ..color = teamColors[team]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (_fittedFor != size) {
      _fittedFor = size;
      _fitted = _fitLabels(column - _columnMargin, plotBottom - _top);
    }
    final headX = xAt(t);
    final placed = placeRevealLabels(
      timeline: timeline,
      progress: progress.value,
      headX: headX,
      yAt: yAt,
      heights: [for (final label in _fitted) label.height],
      top: _top,
      bottom: plotBottom,
    );
    for (var team = 0; team < _fitted.length; team++) {
      final color = teamColors[team];
      final head = Offset(headX, yAt(timeline.valueAt(team, t)));
      final at = placed[team];
      final labelY = at.dy + _fitted[team].height / 2;
      if ((labelY - head.dy).abs() > _linkFrom) {
        canvas.drawLine(
          head + const Offset(6, 0),
          Offset(at.dx - 3, labelY),
          Paint()
            ..color = color.withValues(alpha: .5)
            ..strokeWidth = 1,
        );
      }
      canvas.drawCircle(head, 5.5, Paint()..color = color);
      _fitted[team].paint(canvas, at);
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

  /// Les étiquettes à la plus grande taille qui tient dans la hauteur du
  /// graphique ; à la plus petite, elles se coupent plutôt que de se chevaucher.
  List<TextPainter> _fitLabels(double width, double room) {
    final free = room - (labels.length - 1) * _labelGap;
    for (var font = textScaler.scale(_labelFont);
        font > _minLabelFont;
        font--) {
      final fitted = [
        for (var i = 0; i < labels.length; i++) _label(i, font, width)
      ];
      if (fitted.fold(0.0, (sum, l) => sum + l.height) <= free) return fitted;
    }
    final lines =
        max(1, free / labels.length ~/ (_minLabelFont * _labelLineHeight));
    return [
      for (var i = 0; i < labels.length; i++)
        _label(i, _minLabelFont, width, maxLines: lines)
    ];
  }

  TextPainter _label(int i, double font, double width, {int? maxLines}) =>
      TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: font,
            height: _labelLineHeight,
            fontWeight: FontWeight.w600,
            color: teamColors[i],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: width);

  TextPainter _text(String text, double size, Color color) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: size,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout();

  @override
  bool shouldRepaint(ScoreRevealPainter old) =>
      old.timeline != timeline ||
      old.progress != progress ||
      old.textScaler != textScaler;
}
