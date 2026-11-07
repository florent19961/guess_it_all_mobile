import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/modifier_badge.dart';

/// Le piège d'« Interdit de faire deviner » : après son décompte, le joueur
/// découvre qu'il ne joue pas ce tour. Rien n'est consommé avant « Suivant »
/// (`GameProvider.confirmGiverBlock`) : une app tuée ici remontre la même phrase.
class GiverBlockedScreen extends StatelessWidget {
  const GiverBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final screen = provider.giverBlockScreen;
    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.backgroundMain,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const ModifierIcon('block_giver', size: 64),
                          const SizedBox(height: 14),
                          Text(
                            screen?.phrase ?? '',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.subtitle(fontSize: 34),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Passe le téléphone à ${screen?.nextPlayer ?? ''}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Suivant',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: provider.confirmGiverBlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
