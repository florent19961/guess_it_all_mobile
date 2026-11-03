import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../theme/app_theme.dart';
import '../common/app_button.dart';
import '../common/app_modal.dart';

/// « Bloquer un devineur » (2-8) : les adversaires choisissent un devineur de
/// l'équipe qui joue, puis l'annonce plein écran (maquette `block`). Simple
/// annonce : l'app ne contrôle rien, la rotation ne change pas.
class BlockedGuesser {
  BlockedGuesser._();

  /// Sélecteur « Les adversaires choisissent ». Rend le joueur choisi, ou `null` si
  /// fermé sans choix : l'appelant reste alors sur l'écran d'avant-tour.
  /// [chooserName] : l'équipe qui a choisi la carte (1 parmi 3, 2-10).
  static Future<Player?> pick(BuildContext context, List<Player> guessers,
      {String? chooserName}) {
    return AppModal.show<Player>(
      context,
      title: chooserName == null
          ? 'Les adversaires choisissent'
          : '$chooserName choisit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quel devineur ne répond pas pendant ce tour ?',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
          ),
          for (final player in guessers) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) => AppButton(
                text: player.name,
                variant: AppButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(player),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Annonce plein écran « X ne répond pas ».
  static Future<void> announce(
    BuildContext context, {
    required Player player,
    required String teamName,
    required Color teamColor,
    String? chooserName,
  }) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Material(
        color: AppColors.backgroundMain,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choisi par ${chooserName ?? 'les adversaires'} · '
                  'annonce seulement',
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
                    child: const Icon(Icons.volume_off,
                        size: 48, color: AppColors.primaryPink),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${player.name} ne répond pas',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(fontSize: 34),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Pendant ce tour de '),
                    TextSpan(
                        text: teamName, style: TextStyle(color: teamColor)),
                    TextSpan(
                        text: ', ${player.name} n\'a pas le droit de proposer '
                            'de réponse. Les autres joueurs veillent.'),
                  ]),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gray400),
                ),
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
    ));
  }
}
