import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/app_button.dart';

/// Une ligne numérotée d'une carte (ex. les 3 manches).
class TutorialRow {
  final String number;
  final String title;
  final String subtitle;

  const TutorialRow(this.number, this.title, this.subtitle);
}

/// Une carte de tuto : un symbole, un titre, puis un texte ou des lignes.
class TutorialCard {
  final String symbol;
  final String title;
  final String? text;
  final List<TutorialRow> rows;

  const TutorialCard({
    required this.symbol,
    required this.title,
    this.text,
    this.rows = const [],
  });
}

/// Cartes qu'on fait défiler, « Passer » en haut à droite à tout moment.
/// Ferme la route à la fin ou sur « Passer ».
class TutorialPager extends StatefulWidget {
  final List<TutorialCard> cards;
  final Color accent;
  final String? tag;

  const TutorialPager({
    required this.cards,
    this.accent = AppColors.primaryPink,
    this.tag,
    super.key,
  });

  @override
  State<TutorialPager> createState() => _TutorialPagerState();
}

class _TutorialPagerState extends State<TutorialPager> {
  int _index = 0;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    final isLast = _index == widget.cards.length - 1;

    return Material(
      color: AppColors.backgroundMain,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (widget.tag != null)
                    Text(
                      widget.tag!.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _close,
                    child: const Text(
                      'Passer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _CardBody(card: card, accent: widget.accent),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.cards.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? AppColors.primaryPink
                            : AppColors.gray600,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_index > 0) ...[
                    Expanded(
                      child: AppButton(
                        text: 'Précédent',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => setState(() => _index--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: AppButton(
                      text: isLast ? 'C\'est parti !' : 'Suivant',
                      variant: AppButtonVariant.primary,
                      onPressed:
                          isLast ? _close : () => setState(() => _index++),
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

class _CardBody extends StatelessWidget {
  final TutorialCard card;
  final Color accent;

  const _CardBody({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Text(
              card.symbol,
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 52,
                color: accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          card.title,
          style: AppTextStyles.subtitle(fontSize: 34),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (card.text != null)
          Text(
            card.text!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              height: 1.45,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        for (final row in card.rows)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    row.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 26,
                      color: AppColors.secondaryCyan,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        row.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
