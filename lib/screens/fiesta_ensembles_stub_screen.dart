import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fiesta/fiesta_rules.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/fiesta_setup_widgets.dart';

/// 🔴 BOUCHON de la story 2-4, à SUPPRIMER au merge de la story 2-3 : la vraie
/// liste « Mes ensembles » prend la route `screenFiestaEnsembles` dans
/// `lib/app.dart`. Son « Utiliser » fait la même chose que le bouton
/// ci-dessous : `setPendingFiesta(rules)` puis le Récap.
class FiestaEnsemblesStubScreen extends StatelessWidget {
  const FiestaEnsemblesStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return FiestaSetupScaffold(
      title: 'Mes ensembles',
      subtitle: 'Bientôt disponible.',
      onBack: () => provider.goToScreen(AppConstants.screenFiestaChoice),
      content: const [],
      bottom: AppButton(
        text: 'Utiliser un ensemble d\'essai',
        size: AppButtonSize.large,
        fullWidth: true,
        onPressed: () {
          provider.setPendingFiesta(
            FiestaRules(mode: FiestaMode.custom, ensembleName: 'Essai'),
          );
          provider.goToScreen(AppConstants.screenFiestaRecap);
        },
      ),
    );
  }
}
