import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../theme/app_theme.dart';
import '../../utils/reversed_word.dart';

/// Durée de l'animation d'apparition d'un mot, qui est aussi la durée du
/// verrou des boutons : un tap ne peut pas valider un mot qui vient de
/// remplacer le précédent sous le doigt (2-11, critère 9).
const Duration kWordCardLock = Duration(milliseconds: 300);

/// Carte d'un mot pendant le tour Fiesta : le mot (à l'envers si [reversed]),
/// et les actions Passer / Trouvé. Purement visuelle : la logique de jeu
/// reste dans les callbacks.
///
/// À chaque nouveau mot (montage, ou [word] qui change), la carte s'anime et
/// ignore les taps pendant [kWordCardLock]. Ce verrou est un état de widget :
/// il ne persiste rien et ne touche pas au chrono.
class FiestaWordCard extends StatefulWidget {
  final String word;
  final bool reversed;

  /// `null` = bouton désactivé (pause, fin de tour…).
  final VoidCallback? onGuessed;

  /// `null` = bouton désactivé (pause, `no_pass`, plus de mot à passer…).
  final VoidCallback? onPass;

  /// Libellé du bouton Passer : « Passer · −3 s », « Passer (bloqué) »…
  final String passLabel;

  /// Petit libellé au-dessus du mot (« Mot A »), absent si `null`.
  final String? label;

  final double fontSize;

  const FiestaWordCard({
    required this.word,
    this.reversed = false,
    this.onGuessed,
    this.onPass,
    this.passLabel = 'Passer',
    this.label,
    this.fontSize = 56,
    super.key,
  });

  @override
  State<FiestaWordCard> createState() => _FiestaWordCardState();
}

class _FiestaWordCardState extends State<FiestaWordCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry =
      AnimationController(vsync: this, duration: kWordCardLock)..forward();
  late final Animation<double> _curve =
      CurvedAnimation(parent: _entry, curve: Curves.easeOut);

  @override
  void didUpdateWidget(FiestaWordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) _entry.forward(from: 0);
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  VoidCallback? _locked(VoidCallback? action) {
    if (action == null) return null;
    return () {
      if (!_entry.isAnimating) action();
    };
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(_curve),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label != null)
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.gray500,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AutoSizeText(
                  widget.reversed
                      ? reversedWordDisplay(widget.word)
                      : widget.word,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 24,
                  wrapWords: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: widget.fontSize,
                    letterSpacing: 1,
                    color: AppColors.backgroundMain,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _CardButton(
                      label: widget.passLabel,
                      color: AppColors.gray600,
                      textColor: Colors.white,
                      onTap: _locked(widget.onPass),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardButton(
                      label: 'Trouvé ✓',
                      color: AppColors.secondaryCyan,
                      textColor: AppColors.backgroundMain,
                      onTap: _locked(widget.onGuessed),
                    ),
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

class _CardButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _CardButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color : AppColors.gray700,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled ? textColor : AppColors.gray500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bonus « Deux mots à la fois » (2-11) : deux [FiestaWordCard] empilées, une
/// paire de callbacks par carte. Une seule carte, sans place vide, quand
/// [secondWord] est `null` (dernier mot de la manche).
class TwoWordsLayout extends StatelessWidget {
  final String firstWord;
  final String? secondWord;
  final bool reversed;
  final VoidCallback? onGuessedFirst;
  final VoidCallback? onPassFirst;
  final VoidCallback? onGuessedSecond;
  final VoidCallback? onPassSecond;
  final String passLabel;

  const TwoWordsLayout({
    required this.firstWord,
    this.secondWord,
    this.reversed = false,
    this.onGuessedFirst,
    this.onPassFirst,
    this.onGuessedSecond,
    this.onPassSecond,
    this.passLabel = 'Passer',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final second = secondWord;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FiestaWordCard(
          word: firstWord,
          reversed: reversed,
          label: second == null ? null : 'Mot A',
          fontSize: second == null ? 56 : 40,
          passLabel: passLabel,
          onGuessed: onGuessedFirst,
          onPass: onPassFirst,
        ),
        if (second != null) ...[
          const SizedBox(height: 12),
          FiestaWordCard(
            word: second,
            reversed: reversed,
            label: 'Mot B',
            fontSize: 40,
            passLabel: passLabel,
            onGuessed: onGuessedSecond,
            onPass: onPassSecond,
          ),
        ],
      ],
    );
  }
}

/// Bandeau statique d'une contrainte annoncée de la manche 3 (mime, dessin) :
/// nom et description du catalogue (2-8).
class MimeConstraintBanner extends StatelessWidget {
  /// Les ids du catalogue que ce bandeau sait afficher.
  static const Map<String, IconData> icons = {
    'mime_no_arms': Icons.do_not_touch,
    'mime_no_fists': Icons.back_hand,
    'mime_eyes_closed': Icons.visibility_off,
    'draw': Icons.edit,
  };

  final String modifierId;

  MimeConstraintBanner({required this.modifierId, super.key})
      : assert(icons.containsKey(modifierId));

  @override
  Widget build(BuildContext context) {
    final def = modifierById(modifierId)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icons[modifierId], color: AppColors.warning, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  def.name,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  def.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
