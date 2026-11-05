import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/app_button.dart';

/// Une étape d'aide : le contrôle mis en lumière ([target]) et sa bulle.
class CoachStep {
  final GlobalKey target;
  final String title;
  final String text;

  const CoachStep({
    required this.target,
    required this.title,
    required this.text,
  });
}

/// Aide en surimpression : voile sombre percé autour du contrôle, bulle
/// d'explication, « Suivant » / « Passer ».
///
/// Les étapes dont la cible n'est pas affichée (clé non montée) sont sautées :
/// un écran peut passer toutes ses clés sans se soucier de ce qui est visible.
/// Le retour système (Android) ferme l'aide comme « Passer ».
class CoachMarks {
  CoachMarks._();

  /// Rend la main quand l'aide est terminée ou passée.
  static Future<void> show(BuildContext context, List<CoachStep> steps) async {
    final visible =
        steps.where((s) => s.target.currentContext != null).toList();
    if (visible.isEmpty) return;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => _CoachOverlay(steps: visible),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }
}

class _CoachOverlay extends StatefulWidget {
  final List<CoachStep> steps;

  const _CoachOverlay({required this.steps});

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay> {
  int _index = 0;
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrent());
  }

  /// Fait défiler la cible dans l'écran si besoin, puis mesure sa position.
  Future<void> _focusCurrent() async {
    final targetContext = widget.steps[_index].target.currentContext;
    if (targetContext == null) {
      _next();
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.3,
      duration: const Duration(milliseconds: 250),
    );
    // La dernière image du défilement n'est pas encore mise en page : mesurer
    // ici placerait le trou à côté de la cible. `ensureVisualUpdate` : rien ne
    // défilait, aucune image n'est demandée, et l'attente ne finirait jamais.
    WidgetsBinding.instance.ensureVisualUpdate();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    // Cible démontée pendant le défilement : on passe à la suite plutôt que de
    // laisser un voile sans bulle (sur iOS, aucune autre issue).
    if (!targetContext.mounted) return _next();
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return _next();
    setState(() => _hole = box.localToGlobal(Offset.zero) & box.size);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _hole = null;
    });
    _focusCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;
    final hole = _hole;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Absorbe les taps : on ne touche pas l'écran dessous pendant l'aide.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(painter: CoachVeilPainter(hole)),
            ),
          ),
          if (hole != null) _bubble(context, hole, step, isLast),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, Rect hole, CoachStep step, bool isLast) {
    final media = MediaQuery.of(context);
    final height = media.size.height;
    final below = height - hole.bottom - media.padding.bottom;
    final above = hole.top - media.padding.top;
    const minSpace = 180.0;

    // Les deux bords sont toujours bornés et le texte défile : grand texte
    // système ou petit écran, les boutons restent visibles.
    var top = media.padding.top + 16;
    var bottom = media.padding.bottom + 16;
    var alignment = Alignment.bottomCenter;
    if (below >= minSpace && below >= above) {
      top = hole.bottom + 14;
      alignment = Alignment.topCenter;
    } else if (above >= minSpace) {
      bottom = height - hole.top + 14;
    }
    // Sinon : cible trop grande (ex. une longue liste), bulle posée en bas.

    return Positioned(
      left: 16,
      right: 16,
      top: top,
      bottom: bottom,
      child: Align(
        alignment: alignment,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundMain,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray600),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: AppTextStyles.title(fontSize: 24),
                    ),
                  ),
                  Text(
                    '${_index + 1} / ${widget.steps.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    step.text,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gray400,
                      ),
                      child: const Text(
                        'Passer',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      ),
                    ),
                  const Spacer(),
                  AppButton(
                    text: isLast ? 'Compris' : 'Suivant',
                    onPressed: _next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Public pour que les tests vérifient que la cible est bien dans l'écran.
class CoachVeilPainter extends CustomPainter {
  final Rect? hole;

  CoachVeilPainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final veilPaint = Paint()..color = const Color(0xC7020617);
    final screen = Offset.zero & size;
    if (hole == null) {
      canvas.drawRect(screen, veilPaint);
      return;
    }
    final spot = RRect.fromRectAndRadius(
      hole!.inflate(6),
      const Radius.circular(16),
    );
    // Un seul chemin pair-impair (écran + cible) : la cible est un trou net
    // sur tous les moteurs de rendu. `Path.combine` laissait la cible voilée
    // sur Flutter web.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(screen)
        ..addRRect(spot),
      veilPaint,
    );
    canvas.drawRRect(
      spot,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(CoachVeilPainter old) => old.hole != hole;
}
