import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/word_categories.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_counter.dart';
import '../widgets/common/app_toggle.dart';
import '../widgets/common/app_slider.dart';
import '../widgets/common/app_modal.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final settings = provider.settings;

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Paramètres',
                    style: AppTextStyles.subtitle(fontSize: 40),
                  ),
                  const SizedBox(height: 32),

                  // Nombre d'équipes
                  _buildSection(
                    title: 'Équipes',
                    child: AppCounter(
                      value: settings.numberOfTeams,
                      min: AppConstants.minTeams,
                      max: AppConstants.maxTeams,
                      onChange: (value) => provider.updateSettings(numberOfTeams: value),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre de joueurs
                  _buildSection(
                    title: 'Joueurs',
                    child: AppCounter(
                      value: settings.numberOfPlayers,
                      min: AppConstants.minPlayers,
                      max: AppConstants.maxPlayers,
                      onChange: (value) => provider.updateSettings(numberOfPlayers: value),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Choix des mots
                  _buildSection(
                    title: 'Choix des mots',
                    child: AppToggle(
                      options: const [AppConstants.wordChoiceCustom, AppConstants.wordChoiceRandom],
                      selected: settings.wordChoice,
                      onChange: (value) => provider.updateSettings(wordChoice: value),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton paramètres avancés
                  AppButton(
                    text: 'Paramètres avancés',
                    variant: AppButtonVariant.ghost,
                    icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                    onPressed: () => _showAdvancedSettings(context, provider),
                  ),
                  const SizedBox(height: 32),

                  // Bouton suivant
                  AppButton(
                    text: 'Suivant',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () => provider.goToScreen(AppConstants.screenPlayers),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          AppBackButton(
            onPressed: () => provider.goToScreen(AppConstants.screenHome),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  void _showAdvancedSettings(BuildContext context, GameProvider provider) {
    final settings = provider.settings;

    AppModal.show(
      context,
      title: 'Avancé',
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mots par joueur
                AppSlider(
                  label: 'Mots par joueur',
                  min: AppConstants.minWordsPerPlayer.toDouble(),
                  max: AppConstants.maxWordsPerPlayer.toDouble(),
                  value: settings.wordsPerPlayer.toDouble(),
                  onChanged: (value) {
                    provider.updateSettings(wordsPerPlayer: value.toInt());
                    setState(() {});
                  },
                ),
                const SizedBox(height: 24),

                // Durée du tour
                AppSlider(
                  label: 'Durée du tour',
                  min: AppConstants.minTurnDuration.toDouble(),
                  max: AppConstants.maxTurnDuration.toDouble(),
                  value: settings.turnDuration.toDouble(),
                  unit: 's',
                  onChanged: (value) {
                    provider.updateSettings(turnDuration: value.toInt());
                    setState(() {});
                  },
                ),
                const SizedBox(height: 24),

                // Pénalité de passe
                AppSlider(
                  label: 'Pénalité pour passer',
                  min: AppConstants.minPassPenalty.toDouble(),
                  max: AppConstants.maxPassPenalty.toDouble(),
                  value: settings.passPenalty.toDouble(),
                  unit: 's',
                  onChanged: (value) {
                    provider.updateSettings(passPenalty: value.toInt());
                    setState(() {});
                  },
                ),
                const SizedBox(height: 24),

                // Catégories (si mode aléatoire)
                if (settings.wordChoice == AppConstants.wordChoiceRandom) ...[
                  const Text(
                    'Catégories',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: getCategoryList().map((category) {
                      final isSelected = settings.selectedCategories.contains(category.id);
                      return GestureDetector(
                        onTap: () {
                          final newCategories = List<String>.from(settings.selectedCategories);
                          if (isSelected) {
                            if (newCategories.length > 1) {
                              newCategories.remove(category.id);
                            }
                          } else {
                            newCategories.add(category.id);
                          }
                          provider.updateSettings(selectedCategories: newCategories);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondaryCyan : AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.secondaryCyan : AppColors.gray600,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon),
                              const SizedBox(width: 4),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: isSelected ? Colors.white : AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),

                AppButton(
                  text: 'Fermer',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
