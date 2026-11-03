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
};

String modifierIcon(String id) => kModifierIcons[id] ?? '✦';

/// Couleur d'un modificateur : cyan pour un bonus, rose pour un malus.
Color modifierColor(ModifierNature nature) => nature == ModifierNature.bonus
    ? AppColors.secondaryCyan
    : AppColors.primaryPink;

/// Pastille « icône + nom » (maquette `.badge`). [label] remplace le nom du
/// catalogue (ex. « Une seule réponse », qui n'est pas un modificateur).
class ModifierBadge extends StatelessWidget {
  final String icon;
  final String label;
  final ModifierNature nature;

  const ModifierBadge({
    required this.icon,
    required this.label,
    required this.nature,
    super.key,
  });

  factory ModifierBadge.of(ModifierInstance instance, {Key? key}) =>
      ModifierBadge(
        key: key,
        icon: modifierIcon(instance.catalogId),
        label: modifierById(instance.catalogId)?.name ?? instance.catalogId,
        nature: instance.nature,
      );

  @override
  Widget build(BuildContext context) {
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
class ModifierBadges extends StatelessWidget {
  final List<ModifierInstance> modifiers;
  final List<Widget> extra;
  final WrapAlignment alignment;

  const ModifierBadges({
    required this.modifiers,
    this.extra = const [],
    this.alignment = WrapAlignment.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: alignment,
        spacing: 6,
        runSpacing: 6,
        children: [...modifiers.map(ModifierBadge.of), ...extra],
      );
}
