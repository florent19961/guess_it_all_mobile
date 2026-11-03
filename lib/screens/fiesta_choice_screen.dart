import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fiesta/fiesta_rules.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/fiesta_setup_widgets.dart';
import 'fiesta_tutorial_screen.dart';

/// Fiesta : Mode Auto (l'app décide) ou Personnalisé (ensembles enregistrés).
class FiestaChoiceScreen extends StatefulWidget {
  const FiestaChoiceScreen({super.key});

  @override
  State<FiestaChoiceScreen> createState() => _FiestaChoiceScreenState();
}

class _FiestaChoiceScreenState extends State<FiestaChoiceScreen> {
  late FiestaMode _mode =
      context.read<GameProvider>().pendingFiesta?.mode ?? FiestaMode.auto;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return FiestaSetupScaffold(
      title: 'Fiesta',
      subtitle: 'Comment veux-tu jouer ?',
      onBack: () => provider.goToScreen(AppConstants.screenGameMode),
      onHelp: () => FiestaTutorialScreen.show(context),
      content: [
        FiestaPickCard(
          icon: 'A',
          title: 'Mode Auto',
          description: 'Personne ne choisit de bonus ni de malus : l\'app tire '
              'au sort pour tous et/ou aide l\'équipe menée.',
          selected: _mode == FiestaMode.auto,
          onTap: () => setState(() => _mode = FiestaMode.auto),
        ),
        FiestaPickCard(
          icon: '⚙',
          title: 'Mode Personnalisé',
          description: 'Tous les curseurs de la partie, enregistrés dans des '
              'ensembles réutilisables.',
          selected: _mode == FiestaMode.custom,
          onTap: () => setState(() => _mode = FiestaMode.custom),
        ),
      ],
      bottom: AppButton(
        text: 'Continuer',
        size: AppButtonSize.large,
        fullWidth: true,
        onPressed: () => provider.goToScreen(
          _mode == FiestaMode.auto
              ? AppConstants.screenFiestaAuto
              : AppConstants.screenFiestaEnsembles,
        ),
      ),
    );
  }
}
