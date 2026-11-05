import 'package:flutter/material.dart';

import '../common/turn_play_widgets.dart';

/// Durée de l'animation d'apparition d'un mot, qui est aussi la durée du
/// verrou des boutons : un tap ne peut pas valider un mot qui vient de
/// remplacer le précédent sous le doigt (2-11, critère 9).
const Duration kWordCardLock = Duration(milliseconds: 300);

/// Un mot pendant le tour Fiesta, au même rendu que le tour à un mot : le mot
/// (à l'envers si [reversed]) sur le fond de l'écran, et les boutons Passer /
/// Trouvé. Purement visuelle : la logique de jeu reste dans les callbacks.
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

  /// Libellé du bouton Passer : « Passer », « Passer (bloqué) ».
  final String passLabel;

  /// Sous le libellé : pénalité ou « gratuit ».
  final String? passDetail;

  const FiestaWordCard({
    required this.word,
    this.reversed = false,
    this.onGuessed,
    this.onPass,
    this.passLabel = 'Passer',
    this.passDetail,
    super.key,
  });

  @override
  State<FiestaWordCard> createState() => _FiestaWordCardState();
}

class _FiestaWordCardState extends State<FiestaWordCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry =
      AnimationController(vsync: this, duration: kWordCardLock)..forward();
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _entry, curve: Curves.easeOut);
  late final Animation<double> _opacity =
      Tween<double>(begin: 0.4, end: 1).animate(_curve);
  late final Animation<double> _scale =
      Tween<double>(begin: 0.94, end: 1).animate(_curve);

  @override
  void didUpdateWidget(FiestaWordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) _entry.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _entry.dispose();
    super.dispose();
  }

  // Garde au moment du tap : couvre un appui commencé avant le changement de
  // mot et relâché après (l'IgnorePointer, lui, retire l'effet d'appui).
  VoidCallback? _locked(VoidCallback? action) {
    if (action == null) return null;
    return () {
      if (!_entry.isAnimating) action();
    };
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TurnWordText(
                      word: widget.word,
                      reversed: widget.reversed,
                      maxLines: 2,
                      minFontSize: 16,
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _entry,
                builder: (context, child) => IgnorePointer(
                  ignoring: _entry.isAnimating,
                  child: child,
                ),
                child: TurnActionButtons(
                  compact: true,
                  passLabel: widget.passLabel,
                  passDetail: widget.passDetail,
                  onPass: _locked(widget.onPass),
                  onGuessed: _locked(widget.onGuessed),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Bonus « Deux mots à la fois » (2-11) : deux [FiestaWordCard] superposées qui
/// se partagent la hauteur reçue (à borner), une paire de callbacks par carte.
/// Une seule carte, sans place vide, quand [secondWord] est `null` (dernier mot
/// de la manche).
class TwoWordsLayout extends StatelessWidget {
  final String firstWord;
  final String? secondWord;
  final bool reversed;
  final VoidCallback? onGuessedFirst;
  final VoidCallback? onPassFirst;
  final VoidCallback? onGuessedSecond;
  final VoidCallback? onPassSecond;
  final String passLabel;
  final String? passDetail;

  const TwoWordsLayout({
    required this.firstWord,
    this.secondWord,
    this.reversed = false,
    this.onGuessedFirst,
    this.onPassFirst,
    this.onGuessedSecond,
    this.onPassSecond,
    this.passLabel = 'Passer',
    this.passDetail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final second = secondWord;
    return Column(
      children: [
        // Clé = le mot (A ≠ B, doublons refusés à la saisie) : la carte B qui
        // passe seule en tête garde son état, sans se ré-animer ni se reverrouiller.
        Expanded(
          key: ValueKey(firstWord),
          child: FiestaWordCard(
            word: firstWord,
            reversed: reversed,
            passLabel: passLabel,
            passDetail: passDetail,
            onGuessed: onGuessedFirst,
            onPass: onPassFirst,
          ),
        ),
        if (second != null)
          Expanded(
            key: ValueKey(second),
            child: FiestaWordCard(
              word: second,
              reversed: reversed,
              passLabel: passLabel,
              passDetail: passDetail,
              onGuessed: onGuessedSecond,
              onPass: onPassSecond,
            ),
          ),
      ],
    );
  }
}
