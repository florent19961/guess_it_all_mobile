import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/reversed_word.dart';

/// Le mot à faire deviner.
class TurnWordText extends StatelessWidget {
  final String word;

  /// À l'envers : affichage du tour SEULEMENT, le mot du jeu reste en clair.
  final bool reversed;

  const TurnWordText({
    required this.word,
    this.reversed = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AutoSizeText(
        reversed ? reversedWordDisplay(word) : word,
        style: const TextStyle(
          fontFamily: 'Bangers',
          fontSize: 72,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              color: AppColors.primaryPinkDark,
              blurRadius: 0,
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        minFontSize: 36,
        wrapWords: false,
        overflow: TextOverflow.ellipsis,
      );
}

/// Les boutons Passer (rouge) et Trouvé (cyan) du tour, de même hauteur.
class TurnActionButtons extends StatefulWidget {
  /// `null` = bouton grisé (pause, `no_pass`, plus de mot à passer…).
  final VoidCallback? onPass;

  /// `null` = bouton désactivé (pause…).
  final VoidCallback? onGuessed;

  /// Sous le libellé : pénalité ou « (gratuit) », sur le bouton actif seulement.
  final String? passDetail;

  /// Bouton grisé : la bulle qu'ouvre son toucher. `null` = pas de bulle.
  final String? passBlockedReason;

  /// Cibles de l'aide du tour (coach marks).
  final Key? passKey;
  final Key? guessedKey;

  const TurnActionButtons({
    required this.onPass,
    required this.onGuessed,
    this.passDetail,
    this.passBlockedReason,
    this.passKey,
    this.guessedKey,
    super.key,
  });

  @override
  State<TurnActionButtons> createState() => _TurnActionButtonsState();
}

class _TurnActionButtonsState extends State<TurnActionButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void didUpdateWidget(TurnActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passBlockedReason == null) _bubble.reset();
  }

  @override
  void dispose() {
    _bubble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPass = widget.onPass != null;
    final canGuess = widget.onGuessed != null;
    final pass = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.skip_next,
          color: canPass ? Colors.white : AppColors.gray500,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(
          'Passer',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: canPass ? Colors.white : AppColors.gray500,
          ),
        ),
        if (canPass && widget.passDetail != null)
          Text(
            widget.passDetail!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                key: widget.passKey,
                child: GestureDetector(
                  onTap: widget.onPass ??
                      (widget.passBlockedReason == null
                          ? null
                          : () => _bubble.forward(from: 0)),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: canPass ? AppColors.error : AppColors.gray700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: pass,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                key: widget.guessedKey,
                flex: 2,
                child: GestureDetector(
                  onTap: widget.onGuessed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 33),
                    decoration: BoxDecoration(
                      color: canGuess
                          ? AppColors.secondaryCyan
                          : AppColors.gray700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.check,
                      color: canGuess ? Colors.white : AppColors.gray500,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Hors de la mise en page : la bulle ne déplace rien.
        Positioned(
          left: 0,
          right: 0,
          top: -3,
          child: IgnorePointer(
            child: FractionalTranslation(
              translation: const Offset(0, -1),
              child: AnimatedBuilder(
                animation: _bubble,
                builder: (context, _) => _bubble.isAnimating
                    ? _PassBubble(
                        text: widget.passBlockedReason ?? '',
                        progress: _bubble.value,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La bulle du bouton Passer grisé : apparaît, reste, s'efface ([progress] de 0
/// à 1). Animations réduites : elle reste simplement affichée.
class _PassBubble extends StatelessWidget {
  static const _inEnd = 0.12;
  static const _outStart = 0.85;

  final String text;
  final double progress;

  const _PassBubble({required this.text, required this.progress});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final enter = (progress / _inEnd).clamp(0.0, 1.0);
    final exit = ((progress - _outStart) / (1 - _outStart)).clamp(0.0, 1.0);
    final bubble = Align(
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.backgroundMain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: CustomPaint(
              size: const Size(12, 6),
              painter: _BubbleTailPainter(),
            ),
          ),
        ],
      ),
    );
    if (reduced) return bubble;
    return Opacity(
      opacity: enter * (1 - exit),
      child: Transform.translate(
        offset: Offset(0, 7 * (1 - enter) - 4 * exit),
        child: Transform.scale(
          scale: 0.9 + 0.1 * enter,
          alignment: Alignment.bottomLeft,
          child: bubble,
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) => false;
}
