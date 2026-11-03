import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Le bouton « ? » en haut à droite d'un écran : rejoue l'aide de l'écran.
///
/// Comme `AppBackButton` / `HomeButton`, c'est un [Positioned] : à placer
/// directement dans le `Stack` de l'écran. [HelpButton.inline] rend le seul
/// rond, à glisser dans une rangée de boutons existante (Paramètres).
class HelpButton extends StatelessWidget {
  /// Décalage à droite quand un `HomeButton(alignRight: true)` ou un bouton
  /// pause occupe déjà le coin.
  static const double besideCornerButton = 72;

  final VoidCallback onPressed;
  final double? right;

  const HelpButton({required this.onPressed, this.right = 16, super.key});

  const HelpButton.inline({required this.onPressed, super.key}) : right = null;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: 'Aide',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gray700,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.secondaryCyan, width: 2),
          ),
          child: const Text(
            '?',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
    if (right == null) return button;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: right,
      child: button,
    );
  }
}
