import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/reversed_word.dart';

/// Hauteur des boutons en version [TurnActionButtons.compact].
const double kCompactTurnButtonsHeight = 64;

/// Le mot à faire deviner : le même rendu pour le tour à un mot et pour
/// « Deux mots à la fois », seule la place disponible change.
class TurnWordText extends StatelessWidget {
  final String word;

  /// À l'envers : affichage du tour SEULEMENT, le mot du jeu reste en clair.
  final bool reversed;
  final int maxLines;
  final double minFontSize;

  const TurnWordText({
    required this.word,
    this.reversed = false,
    this.maxLines = 3,
    this.minFontSize = 36,
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
        maxLines: maxLines,
        minFontSize: minFontSize,
        wrapWords: false,
        overflow: TextOverflow.ellipsis,
      );
}

/// Les boutons Passer (rouge) et Trouvé (cyan) du tour. [compact] : même style,
/// moins haut, pour en superposer deux paires (« Deux mots à la fois »).
class TurnActionButtons extends StatelessWidget {
  /// `null` = bouton désactivé (pause, `no_pass`, plus de mot à passer…).
  final VoidCallback? onPass;

  /// `null` = bouton désactivé (pause…).
  final VoidCallback? onGuessed;
  final String passLabel;

  /// Sous le libellé : pénalité ou « gratuit », absent si `null`.
  final String? passDetail;
  final bool compact;

  /// Cibles de l'aide du tour (coach marks).
  final Key? passKey;
  final Key? guessedKey;

  const TurnActionButtons({
    required this.onPass,
    required this.onGuessed,
    this.passLabel = 'Passer',
    this.passDetail,
    this.compact = false,
    this.passKey,
    this.guessedKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final canPass = onPass != null;
    final canGuess = onGuessed != null;
    final pass = Column(
      children: [
        Icon(
          Icons.skip_next,
          color: canPass ? Colors.white : AppColors.gray500,
          size: compact ? 22 : 32,
        ),
        if (!compact) const SizedBox(height: 4),
        Text(
          passLabel,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: canPass ? Colors.white : AppColors.gray500,
          ),
        ),
        if (passDetail != null)
          Text(
            passDetail!,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 10 : 12,
              color:
                  canPass ? Colors.white.withOpacity(0.7) : AppColors.gray600,
            ),
          ),
      ],
    );
    final row = Row(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        Expanded(
          key: passKey,
          child: GestureDetector(
            onTap: onPass,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: compact ? 4 : 20),
              decoration: BoxDecoration(
                color: canPass ? AppColors.error : AppColors.gray700,
                borderRadius: BorderRadius.circular(20),
              ),
              // Compact : hauteur fixe, le texte agrandi par le système réduit
              // au lieu de déborder.
              child: compact
                  ? FittedBox(fit: BoxFit.scaleDown, child: pass)
                  : pass,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          key: guessedKey,
          flex: 2,
          child: GestureDetector(
            onTap: onGuessed,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: compact ? 0 : 33),
              decoration: BoxDecoration(
                color: canGuess ? AppColors.secondaryCyan : AppColors.gray700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.check,
                color: canGuess ? Colors.white : AppColors.gray500,
                size: compact ? 32 : 48,
              ),
            ),
          ),
        ),
      ],
    );
    return compact
        ? SizedBox(height: kCompactTurnButtonsHeight, child: row)
        : row;
  }
}
