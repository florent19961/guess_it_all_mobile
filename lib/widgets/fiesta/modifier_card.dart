import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../models/fiesta/modifier_instance.dart';
import '../../theme/app_theme.dart';
import 'fiesta_setup_widgets.dart';
import 'modifier_badge.dart';

/// Un modificateur en détail : icône, nom, description, pastilles
/// (maquette `modCard`).
class ModifierCard extends StatelessWidget {
  final ModifierInstance instance;

  const ModifierCard(this.instance, {super.key});

  @override
  Widget build(BuildContext context) {
    final def = modifierById(instance.catalogId);
    final color = modifierColor(instance.nature);
    final pills = [
      instance.nature == ModifierNature.bonus ? 'Bonus' : 'Malus',
      if (def?.round3Only ?? false) 'Manche 3 seulement',
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMain,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              modifierIcon(instance.catalogId),
              style:
                  TextStyle(fontFamily: 'Bangers', fontSize: 18, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def?.name ?? instance.catalogId,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                if (def != null) FiestaHint(def.description),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: pills
                      .map((p) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppColors.gray600),
                            ),
                            child: Text(p,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10.5,
                                    color: AppColors.gray400)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « Tirage de la manche N » (maquette `drawCard`) : fixés et tirage de la
/// manche, pour toutes les équipes. Rien si la liste est vide.
class RoundDrawCard extends StatelessWidget {
  final int round;
  final List<ModifierInstance> modifiers;

  const RoundDrawCard({
    required this.round,
    required this.modifiers,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (modifiers.isEmpty) return const SizedBox.shrink();
    return FiestaCard(
      title: 'Tirage de la manche $round',
      children: [
        const FiestaHint('S\'applique à toutes les équipes, à chacun de leurs '
            'tours. Pas de relance : le tirage est définitif.'),
        ...modifiers.map(ModifierCard.new),
      ],
    );
  }
}

/// Le tirage en une ligne, entre les manches : « Tirage de la manche N : »
/// et une pastille par modificateur (un tap l'explique). Rien si la liste est
/// vide.
class RoundDrawLine extends StatelessWidget {
  final int round;
  final List<ModifierInstance> modifiers;

  const RoundDrawLine({
    required this.round,
    required this.modifiers,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (modifiers.isEmpty) return const SizedBox.shrink();
    return FiestaInfoLine(
      label: 'Tirage de la manche $round',
      spans: [
        for (final m in modifiers) modifierBadgeSpan(ModifierBadge.of(m)),
      ],
    );
  }
}
