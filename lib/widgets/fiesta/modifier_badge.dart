import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../models/fiesta/modifier_instance.dart';
import '../../theme/app_theme.dart';

/// Pictogramme texte d'un modificateur : le repli de [ModifierIcon] pour
/// `two_words` (retiré du jeu, reste dans l'historique) et les ids inconnus.
/// Les autres entrées ne servent plus qu'au dessin de `score_reveal_chart.dart`,
/// qui n'utilise plus d'icône une fois le lot `retours-reveal` mergé : la table se
/// réduit alors à `two_words`.
const Map<String, String> kModifierIcons = {
  'mime_no_arms': '✋',
  'mime_no_fists': '🖐',
  'mime_eyes_closed': '◉',
  'draw': '✎',
  'no_pass': '⊘',
  'free_pass': '↷',
  'minus_10s': '−10',
  'double_points': '×2',
  'two_words': '⧉', // Retiré du jeu : reste pour l'historique.
  'reversed': '⇄',
  'block_guesser': '🔇',
  'mime_under_sheet': '⛺',
  'mime_back_turned': '↩',
  'other_language': '🌐',
  'one_answer': '☝',
  'sounds_only': '🔊',
  'plus_10s': '+10',
  'block_giver': '🚫',
};

String modifierIcon(String id) => kModifierIcons[id] ?? '✦';

/// Icônes en image : `assets/icons/modifiers/<id>.png`.
const Set<String> _imageIcons = {
  'free_pass',
  'double_points',
  'plus_10s',
  'minus_10s',
  'no_pass',
  'reversed',
  'one_answer',
  'block_giver',
  'mime_no_fists',
  'draw',
  'mime_under_sheet',
  'mime_back_turned',
  'sounds_only',
};

const Map<String, String> _emojiIcons = {
  'other_language': '🌍',
  'block_guesser': '🤐',
  'mime_no_arms': '💪',
  'mime_eyes_closed': '👀',
};

/// Émojis barrés par `slash.png`.
const Set<String> _slashedIcons = {'mime_no_arms', 'mime_eyes_closed'};

/// L'icône d'un modificateur : boîte carrée de [size], contenu centré. Seul
/// point d'affichage des icônes. Un émoji ne dépend ni de la police de l'app, ni
/// des métriques de sa ligne, ni de la taille de texte système : même centrage à
/// toutes les tailles, et `slash.png` le barre toujours.
/// [color] ne teinte que le repli texte ([kModifierIcons]).
class ModifierIcon extends StatelessWidget {
  final String id;
  final double size;
  final Color color;

  const ModifierIcon(this.id,
      {required this.size, this.color = Colors.white, super.key});

  Widget _image(String name) => Image.asset(
        'assets/icons/modifiers/$name.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      );

  Widget _glyph(String text) {
    final fontSize = size * 0.72;
    return Text(
      text,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: 1,
        forceStrutHeight: true,
      ),
      style: TextStyle(
        inherit: false,
        fontSize: fontSize,
        height: 1,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: _imageIcons.contains(id)
            ? _image(id)
            : Stack(
                alignment: Alignment.center,
                children: [
                  _glyph(_emojiIcons[id] ?? modifierIcon(id)),
                  if (_slashedIcons.contains(id)) _image('slash'),
                ],
              ),
      );
}

/// Titre de fiche, centré : icône (si [id]) puis [text], à la ligne au besoin.
class ModifierHeading extends StatelessWidget {
  final String? id;
  final String text;
  final TextStyle style;
  final double iconSize;

  const ModifierHeading({
    required this.id,
    required this.text,
    required this.style,
    required this.iconSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          if (id != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ModifierIcon(id!,
                    size: iconSize, color: style.color ?? Colors.white),
              ),
            ),
          TextSpan(text: text),
        ]),
        textAlign: TextAlign.center,
        style: style,
      );
}

/// Couleur d'un modificateur (Fiesta v2) : vert pour un bonus, rouge pour un
/// malus.
Color modifierColor(ModifierNature nature) =>
    nature == ModifierNature.bonus ? AppColors.success : AppColors.malus;

/// Enveloppe l'ouverture de l'explication d'un badge. L'écran du tour s'en
/// sert pour geler le chrono tant que la fiche est ouverte.
typedef BadgeExplainWrapper = Future<void> Function(
    Future<void> Function() show);

/// Pastille « icône + texte » (maquette `.badge`).
///
/// Avec une [description], un tap ouvre une petite fiche qui l'explique.
class ModifierBadge extends StatelessWidget {
  /// Id de l'icône ; `null` = texte seul.
  final String? iconId;
  final String label;

  /// Titre de la fiche ; `null` = [label].
  final String? title;
  final ModifierNature nature;
  final String? description;
  final BadgeExplainWrapper? wrapExplain;

  const ModifierBadge({
    required this.iconId,
    required this.label,
    required this.nature,
    this.title,
    this.description,
    this.wrapExplain,
    super.key,
  });

  /// Badge du tour : la mini-phrase du catalogue (« Une seule réponse par
  /// mot »), texte seul pour le temps (« +10 secondes » se suffit). La fiche
  /// garde le nom du modificateur. [playerName] : le joueur bloqué.
  factory ModifierBadge.turn(String id,
      {required ModifierNature nature,
      String? playerName,
      Iterable<String> playingWith = const [],
      BadgeExplainWrapper? wrapExplain,
      Key? key}) {
    final def = modifierById(id);
    final turnLabel = def?.turnLabel ?? def?.name ?? id;
    return ModifierBadge(
      key: key,
      iconId: id == 'plus_10s' || id == 'minus_10s' ? null : id,
      label: id != 'block_guesser'
          ? turnLabel
          : playerName == null
              ? def?.name ?? id
              : '$playerName $turnLabel',
      title: def?.name,
      nature: nature,
      description: def == null ? null : modifierDescription(id, playingWith),
      wrapExplain: wrapExplain,
    );
  }

  /// Badge d'un modificateur du catalogue, sans instance (×2, +10 s…).
  /// [count] : ses cartouches, dites dans le libellé, sans pictogramme (le « ×2 »
  /// de Mot compte double se lirait comme un nombre de cartouches).
  factory ModifierBadge.catalog(String id,
      {required ModifierNature nature,
      int? count,
      Iterable<String> playingWith = const [],
      BadgeExplainWrapper? wrapExplain,
      Key? key}) {
    final def = modifierById(id);
    return ModifierBadge(
      key: key,
      iconId: count == null ? id : null,
      label: '${def?.name ?? id}${count == null ? '' : ' ×$count'}',
      nature: nature,
      description: def == null ? null : modifierDescription(id, playingWith),
      wrapExplain: wrapExplain,
    );
  }

  Future<void> _explain(BuildContext context) {
    final color = modifierColor(nature);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundMain,
      shape: SheetTopBorder(color),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModifierHeading(
                id: iconId,
                text: title ?? label,
                style: AppTextStyles.subtitle(fontSize: 26),
                iconSize: 28,
              ),
              const SizedBox(height: 10),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text('Compris',
                    style: AppTextStyles.bodySmall.copyWith(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill();
    if (description == null) return pill;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Future<void> show() => _explain(context);
          wrapExplain != null ? wrapExplain!(show) : show();
        },
        child: pill,
      ),
    );
  }

  Widget _pill() {
    final color = modifierColor(nature);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconId != null) ...[
            ModifierIcon(iconId!, size: 16, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les badges du tour, centrés et repliés sur plusieurs lignes.
///
/// Le texte d'un modificateur dépend de ceux qui jouent avec lui
/// ([modifierDescription]). [playerName] nomme le joueur d'un blocage.
class ModifierBadges extends StatelessWidget {
  final List<ModifierInstance> modifiers;
  final String? Function(String playerId) playerName;
  final List<Widget> extra;
  final WrapAlignment alignment;
  final BadgeExplainWrapper? wrapExplain;

  const ModifierBadges({
    required this.modifiers,
    required this.playerName,
    this.extra = const [],
    this.alignment = WrapAlignment.center,
    this.wrapExplain,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: alignment,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in modifiers)
            ModifierBadge.turn(m.catalogId,
                nature: m.nature,
                playerName: m.playerId == null ? null : playerName(m.playerId!),
                playingWith: modifiers.map((other) => other.catalogId),
                wrapExplain: wrapExplain),
          ...extra,
        ],
      );
}

/// Forme des feuilles du bas (explication d'un badge, choix d'une équipe) :
/// coins du haut arrondis, liseré [color] sur le seul bord supérieur.
class SheetTopBorder extends RoundedRectangleBorder {
  final Color color;

  static const _radius = 20.0;
  static const _width = 2.0;

  const SheetTopBorder(this.color)
      : super(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(_radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    const h = _width / 2;
    const arc = Radius.circular(_radius - h);
    final path = Path()
      ..moveTo(rect.left + h, rect.top + _radius)
      ..arcToPoint(Offset(rect.left + _radius, rect.top + h), radius: arc)
      ..lineTo(rect.right - _radius, rect.top + h)
      ..arcToPoint(Offset(rect.right - h, rect.top + _radius), radius: arc);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _width
          ..color = color);
  }

  @override
  bool operator ==(Object other) =>
      other is SheetTopBorder && other.color == color;

  @override
  int get hashCode => color.hashCode;
}
