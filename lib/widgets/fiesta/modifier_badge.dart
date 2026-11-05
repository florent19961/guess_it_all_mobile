import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../models/fiesta/modifier_instance.dart';
import '../../theme/app_theme.dart';

/// Pictogramme court d'un modificateur (maquette `CAT[].ic`). Affichage
/// seulement : un id absent retombe sur « ✦ ».
const Map<String, String> kModifierIcons = {
  'mime_no_arms': '✋',
  'mime_no_fists': '🖐',
  'mime_eyes_closed': '◉',
  'draw': '✎',
  'no_pass': '⊘',
  'free_pass': '↷',
  'minus_10s': '−10',
  'double_points': '×2',
  'two_words': '⧉',
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

/// Couleur d'un modificateur (Fiesta v2) : vert pour un bonus, rouge pour un
/// malus.
Color modifierColor(ModifierNature nature) =>
    nature == ModifierNature.bonus ? AppColors.success : AppColors.malus;

/// Enveloppe l'ouverture de l'explication d'un badge. L'écran du tour s'en
/// sert pour geler le chrono tant que la fiche est ouverte.
typedef BadgeExplainWrapper = Future<void> Function(
    Future<void> Function() show);

/// Pastille « icône + nom » (maquette `.badge`).
///
/// Avec une [description], un tap ouvre une petite fiche qui l'explique.
class ModifierBadge extends StatelessWidget {
  final String icon;
  final String label;
  final ModifierNature nature;
  final String? description;
  final BadgeExplainWrapper? wrapExplain;

  const ModifierBadge({
    required this.icon,
    required this.label,
    required this.nature,
    this.description,
    this.wrapExplain,
    super.key,
  });

  factory ModifierBadge.of(ModifierInstance instance,
          {Iterable<String> playingWith = const [],
          BadgeExplainWrapper? wrapExplain,
          Key? key}) =>
      ModifierBadge.catalog(instance.catalogId,
          nature: instance.nature,
          playingWith: playingWith,
          wrapExplain: wrapExplain,
          key: key);

  /// Badge d'un modificateur du catalogue, sans instance (×2, Deux mots…).
  factory ModifierBadge.catalog(String id,
      {required ModifierNature nature,
      Iterable<String> playingWith = const [],
      BadgeExplainWrapper? wrapExplain,
      Key? key}) {
    final def = modifierById(id);
    return ModifierBadge(
      key: key,
      icon: modifierIcon(id),
      label: def?.name ?? id,
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
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: color, width: 2),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$icon $label',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle(fontSize: 26),
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
      child: Text(
        '$icon $label',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Les badges des [modifiers], centrés et repliés sur plusieurs lignes.
///
/// Le texte d'un modificateur dépend de ceux qui jouent avec lui
/// ([modifierDescription]).
class ModifierBadges extends StatelessWidget {
  final List<ModifierInstance> modifiers;
  final List<Widget> extra;
  final WrapAlignment alignment;
  final BadgeExplainWrapper? wrapExplain;

  const ModifierBadges({
    required this.modifiers,
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
            ModifierBadge.of(m,
                playingWith: modifiers.map((other) => other.catalogId),
                wrapExplain: wrapExplain),
          ...extra,
        ],
      );
}
