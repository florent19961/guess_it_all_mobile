import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/fiesta_setup_widgets.dart';
import 'fiesta_tutorial_screen.dart';

/// Premier choix d'une nouvelle partie : Classique (la partie d'aujourd'hui,
/// inchangée) ou Fiesta.
class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  late bool _fiesta = context.read<GameProvider>().pendingFiesta != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return FiestaSetupScaffold(
      title: 'Mode de jeu',
      onBack: () => provider.goToScreen(AppConstants.screenHome),
      content: [
        FiestaPickCard(
          icon: '3',
          title: 'Classique',
          description: 'Les 3 manches habituelles, sans modificateur. '
              'Rien ne change.',
          selected: !_fiesta,
          onTap: () => setState(() => _fiesta = false),
        ),
        FiestaPickCard(
          icon: '✦',
          title: 'Fiesta',
          description: 'Les mêmes 3 manches, avec des bonus et malus qui '
              'pimentent la partie.',
          selected: _fiesta,
          onTap: () => setState(() => _fiesta = true),
        ),
      ],
      bottom: AppButton(
        text: 'Continuer',
        size: AppButtonSize.large,
        fullWidth: true,
        onPressed: () async {
          if (_fiesta) {
            // Première partie Fiesta : le tuto (3 cartes) s'ouvre une fois.
            if (!await StorageService().hasSeenFiestaTutorial()) {
              if (!context.mounted) return;
              await FiestaTutorialScreen.show(context);
            }
            provider.goToScreen(AppConstants.screenFiestaChoice);
          } else {
            provider.setPendingFiesta(null);
            provider.goToScreen(AppConstants.screenSettings);
          }
        },
      ),
    );
  }
}
