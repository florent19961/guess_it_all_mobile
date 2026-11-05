import 'package:flutter/material.dart';

import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../models/fiesta/symmetric_draw.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/fiesta/modifier_badge.dart';

/// Page « Voir » d'un ensemble, en lecture seule : ce qu'il fait, d'un coup
/// d'œil. « Dupliquer » rend la main à la liste, qui duplique.
class FiestaEnsembleViewScreen extends StatelessWidget {
  final FiestaEnsemble ensemble;
  final bool canDuplicate;

  const FiestaEnsembleViewScreen({
    required this.ensemble,
    required this.canDuplicate,
    super.key,
  });

  /// `true` si l'utilisateur a demandé à dupliquer.
  static Future<bool> show(
    BuildContext context, {
    required FiestaEnsemble ensemble,
    required bool canDuplicate,
  }) async =>
      await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => FiestaEnsembleViewScreen(
            ensemble: ensemble, canDuplicate: canDuplicate),
      )) ??
      false;

  /// Les modificateurs actifs dans [mode], dans l'ordre du catalogue.
  List<(ModifierDef, ModifierSetting)> _inMode(ModifierMode mode) => [
        for (final def in kModifierCatalog)
          if (ensemble.rules.activeSetting(def.id) case final setting?
              when setting.mode == mode)
            (def, setting),
      ];

  static String _roundsLabel(Set<int> rounds) {
    final sorted = rounds.toList()..sort();
    return sorted.length == 3
        ? 'Toutes les manches'
        : '${sorted.length > 1 ? 'Manches' : 'Manche'} ${sorted.join(', ')}';
  }

  /// Une cartouche vaut pour toute la partie : seule une contrainte du
  /// catalogue (mime, parole) mérite d'être dite.
  static String _chargesLabel(ModifierDef def, int charges) {
    final allowed = allowedRounds(def);
    return [
      charges == 0 ? 'Gagnées seulement' : '×$charges',
      if (allowed.length < 3) _roundsLabel(allowed),
    ].join(' · ');
  }

  /// « Toujours » vaut pour toutes les manches où il existe : seule une
  /// contrainte du catalogue (mime, parole) mérite d'être dite.
  static String? _alwaysLabel(ModifierDef def) {
    final allowed = allowedRounds(def);
    return allowed.length < 3 ? _roundsLabel(allowed) : null;
  }

  @override
  Widget build(BuildContext context) {
    final rules = ensemble.rules;
    final always = _inMode(ModifierMode.always);
    final draw = _inMode(ModifierMode.draw);
    final cartridges = _inMode(ModifierMode.cartridge);
    return Scaffold(
      backgroundColor: AppColors.backgroundMain,
      body: ShootingStars(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                      children: [
                        Text(
                          ensemble.name,
                          style: AppTextStyles.subtitle(fontSize: 34),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (always.isNotEmpty)
                          _Section(
                            title: 'Toujours',
                            rows: [
                              for (final (def, _) in always)
                                _Row(def, _alwaysLabel(def)),
                            ],
                          ),
                        if (draw.isNotEmpty)
                          _Section(
                            title: 'Au tirage (${rules.drawCount} par manche)',
                            rows: [
                              for (final (def, s) in draw)
                                _Row(def, _roundsLabel(s.rounds)),
                            ],
                          ),
                        if (cartridges.isNotEmpty)
                          _Section(
                            title: 'Cartouches pour la partie',
                            rows: [
                              for (final (def, s) in cartridges)
                                _Row(def, _chargesLabel(def, s.charges)),
                            ],
                          ),
                        if (rules.boostCount > 0)
                          _Section(
                            title: 'Coup de pouce à l\'équipe menée',
                            text: '${rules.boostCount} cartouche'
                                '${rules.boostCount > 1 ? 's' : ''} au hasard '
                                'après chaque manche',
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    color: AppColors.backgroundMain,
                    child: AppButton(
                      text: 'Dupliquer',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      disabled: !canDuplicate,
                      onPressed: canDuplicate
                          ? () => Navigator.of(context).pop(true)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            AppBackButton(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  final String? text;

  const _Section({required this.title, this.rows = const [], this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.label
                .copyWith(color: AppColors.secondaryCyan, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...rows,
          if (text != null)
            Text(
              text!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

/// Un modificateur : icône, nom, quand il joue, description courte.
class _Row extends StatelessWidget {
  final ModifierDef def;
  final String? when;

  const _Row(this.def, this.when);

  @override
  Widget build(BuildContext context) {
    final color = modifierColor(def.nature);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Text(
              modifierIcon(def.id),
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.name, style: AppTextStyles.label),
                if (when != null)
                  Text(
                    when!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondaryCyan, fontSize: 12),
                  ),
                Text(
                  def.description,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gray400, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
