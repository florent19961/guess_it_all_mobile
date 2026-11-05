import 'package:flutter/material.dart';

import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/modifier_catalog.dart';
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

  /// Seule une contrainte du catalogue (mime, parole) mérite d'être dite.
  static String? _roundsLabel(ModifierDef def) => def.round3Only
      ? 'Manche 3 seulement'
      : def.notInRound3
          ? 'Manches 1 et 2 seulement'
          : null;

  static String _plural(int n, String word) => '$n $word${n > 1 ? 's' : ''}';

  @override
  Widget build(BuildContext context) {
    final rules = ensemble.rules;
    final always = kModifierCatalog.where((d) => rules.isAlways(d.id)).toList();
    final draw = rules.drawCount == 0
        ? const <ModifierDef>[]
        : kModifierCatalog.where((d) => rules.drawsFrom(d.id)).toList();
    final cartridges =
        kModifierCatalog.where((d) => rules.chargesOf(d.id) > 0).toList();
    final alwaysIds = always.map((d) => d.id);
    final random = [
      if (rules.balance)
        'Équilibrer la partie : plus une équipe est distancée, plus elle '
            'reçoit de cartouches'
      else if (rules.trailingCount > 0)
        'Aux équipes menées : ${_plural(rules.trailingCount, 'cartouche')} '
            'après les manches 1 et 2',
      if (rules.allCount > 0)
        'À tous, à chaque manche : ${_plural(rules.allCount, 'cartouche')}',
      if (rules.challenges)
        'Défis surprises : 1 ou 2 fois dans la partie, une cartouche à gagner',
    ];
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
                              for (final def in always)
                                _Row(
                                  def,
                                  _roundsLabel(def),
                                  description:
                                      modifierDescription(def.id, alwaysIds),
                                ),
                            ],
                          ),
                        if (draw.isNotEmpty)
                          _Section(
                            title:
                                'Aléatoire par manche (${rules.drawCount} par manche)',
                            rows: [
                              for (final def in draw)
                                _Row(def, _roundsLabel(def)),
                            ],
                          ),
                        if (cartridges.isNotEmpty || random.isNotEmpty)
                          _Section(
                            title: 'Cartouches',
                            lines: random,
                            rows: [
                              for (final def in cartridges)
                                _Row(
                                  def,
                                  [
                                    '×${rules.chargesOf(def.id)} pour chaque équipe',
                                    if (_roundsLabel(def) case final rounds?)
                                      rounds,
                                  ].join(' · '),
                                ),
                            ],
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
  final List<String> lines;

  const _Section({
    required this.title,
    this.rows = const [],
    this.lines = const [],
  });

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
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                line,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white, fontSize: 13),
              ),
            ),
          ...rows,
        ],
      ),
    );
  }
}

/// Un modificateur : icône, nom, quand il joue, description courte.
class _Row extends StatelessWidget {
  final ModifierDef def;
  final String? when;
  final String? description;

  const _Row(this.def, this.when, {this.description});

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
                  description ?? def.description,
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
