import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../models/fiesta/modifier_instance.dart';
import '../../theme/app_theme.dart';
import '../common/app_button.dart';
import 'modifier_badge.dart';

/// Révélation plein écran d'un malus (maquette `malus`), au début du tour de
/// l'équipe visée, avant le compte à rebours. Réutilisable par 2-8 et 2-10.
class MalusReveal extends StatelessWidget {
  final ModifierInstance malus;
  final String teamName;
  final Color teamColor;

  const MalusReveal({
    required this.malus,
    required this.teamName,
    required this.teamColor,
    super.key,
  });

  /// Montre chaque malus de [maluses] l'un après l'autre ; rend la main quand
  /// le dernier est fermé (« Compris » ou retour système).
  static Future<void> showAll(
    BuildContext context, {
    required List<ModifierInstance> maluses,
    required String teamName,
    required Color teamColor,
  }) async {
    for (final malus in maluses) {
      if (!context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MalusReveal(
          malus: malus,
          teamName: teamName,
          teamColor: teamColor,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = modifierById(malus.catalogId);
    return Material(
      color: AppColors.backgroundMain,
      child: SafeArea(
        // Défile sur petit écran / grande police plutôt que de pousser
        // « Compris » hors de l'écran.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Au tour de '),
                    TextSpan(
                        text: teamName, style: TextStyle(color: teamColor)),
                  ]),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gray400),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      modifierIcon(malus.catalogId),
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 44,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  def?.name ?? malus.catalogId,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(fontSize: 34),
                ),
                if (def != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    def.description,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gray400),
                  ),
                ],
                if (malus.target == ModifierTarget.both) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'Tiré pour la manche : toutes les équipes le subissent.',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontSize: 12.5, color: AppColors.warning),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: 'Compris',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
