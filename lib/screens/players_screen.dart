import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/word_categories.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_input.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  void _initializePlayers() {
    final provider = context.read<GameProvider>();
    final settings = provider.settings;

    // Créer les joueurs si nécessaire
    while (provider.players.length < settings.numberOfPlayers) {
      provider.addPlayer('', allowEmpty: true);
    }

    // Supprimer les joueurs en trop
    while (provider.players.length > settings.numberOfPlayers) {
      provider.removePlayer(provider.players.last.id);
    }

    // Créer les contrôleurs
    for (final player in provider.players) {
      _controllers[player.id] = TextEditingController(text: player.name);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validatePlayers(GameProvider provider) {
    _errors.clear();
    bool isValid = true;
    final names = <String>{};

    for (final player in provider.players) {
      final name = _controllers[player.id]?.text.trim() ?? '';

      if (name.isEmpty) {
        _errors[player.id] = 'Nom requis';
        isValid = false;
      } else if (names.contains(name)) {
        _errors[player.id] = 'Nom déjà utilisé';
        isValid = false;
      } else {
        names.add(name);
      }
    }

    setState(() {});
    return isValid;
  }

  void _saveAndContinue(GameProvider provider) {
    // Sauvegarder les noms
    for (final player in provider.players) {
      final name = _controllers[player.id]?.text.trim() ?? '';
      provider.updatePlayer(player.id, name: name);
    }

    if (_validatePlayers(provider)) {
      provider.cleanupEmptyPlayers();
      provider.createTeams();
      provider.randomizeTeams();
      provider.goToScreen(AppConstants.screenWords);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                Text(
                  'Joueurs',
                  style: AppTextStyles.subtitle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.settings.numberOfPlayers} joueurs',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: provider.players.length,
                    itemBuilder: (context, index) {
                      final player = provider.players[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AppInput(
                          controller: _controllers[player.id],
                          placeholder: 'Joueur ${index + 1}',
                          error: _errors[player.id],
                          onChanged: (value) {
                            if (_errors.containsKey(player.id)) {
                              setState(() => _errors.remove(player.id));
                            }
                          },
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.secondaryCyan,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppButton(
                    text: 'Suivant',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () => _saveAndContinue(provider),
                  ),
                ),
              ],
            ),
          ),
          AppBackButton(
            onPressed: () => provider.goToScreen(AppConstants.screenSettings),
          ),
        ],
      ),
    );
  }
}
