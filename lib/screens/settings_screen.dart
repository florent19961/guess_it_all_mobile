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
                      onChange: (value) {
                        provider.updateSettings(numberOfTeams: value);
                        // Ajuster le nombre de joueurs si nécessaire (min 2 par équipe)
                        final minPlayers = value * 2;
                        if (settings.numberOfPlayers < minPlayers) {
                          provider.updateSettings(numberOfPlayers: minPlayers);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre de joueurs (minimum = 2 x nombre d'équipes)
                  _buildSection(
                    title: 'Joueurs',
                    child: AppCounter(
                      value: settings.numberOfPlayers,
                      min: settings.numberOfTeams * 2, // Minimum dynamique
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

                  const SizedBox(height: 8),

                  // Bouton réinitialiser
                  GestureDetector(
                    onTap: () => _showResetConfirmation(context, provider),
                    child: const Text(
                      'Réinitialiser les paramètres',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.gray500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton suivant
                  AppButton(
                    text: 'Suivant',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () {
                      // Si mode aléatoire, vérifier le nombre de mots disponibles
                      if (settings.wordChoice == AppConstants.wordChoiceRandom) {
                        final totalWordsNeeded = settings.numberOfPlayers * settings.wordsPerPlayer;
                        final availableWords = getTotalWordsCount(
                          settings.selectedCategories,
                          difficultyLevels: settings.selectedDifficultyLevels,
                        );

                        if (availableWords < totalWordsNeeded) {
                          _showNotEnoughWordsWarning(context, provider, availableWords, totalWordsNeeded);
                          return;
                        }
                      }
                      provider.goToScreen(AppConstants.screenPlayers);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          AppBackButton(
            onPressed: () => provider.goToScreen(AppConstants.screenHome),
          ),
          // Icône paramètres avancés en haut à droite (aligné avec le bouton retour)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _showAdvancedSettings(context, provider),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gray600, width: 2),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
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

  void _showResetConfirmation(BuildContext context, GameProvider provider) {
    AppModal.show(
      context,
      title: 'Réinitialiser',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Êtes-vous sûr de vouloir réinitialiser les paramètres ?',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Annuler',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Réinitialiser',
                  variant: AppButtonVariant.danger,
                  onPressed: () {
                    Navigator.of(context).pop();
                    provider.clearLocalStorage();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotEnoughWordsWarning(
    BuildContext context,
    GameProvider provider,
    int available,
    int needed,
  ) {
    AppModal.show(
      context,
      title: 'Attention',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pas assez de mots disponibles pour les catégories et niveaux de difficulté choisis.\n\n'
            'Disponibles : $available\n'
            'Nécessaires : $needed\n\n'
            'Si vous continuez, il faudra écrire ${needed - available} mot(s) à la main.',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Paramètres',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    Navigator.pop(context);
                    _showAdvancedSettings(context, provider, scrollToCategories: true);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Continuer',
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    Navigator.pop(context);
                    provider.goToScreen(AppConstants.screenPlayers);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdvancedSettings(BuildContext context, GameProvider provider, {bool scrollToCategories = false}) {
    final scrollController = ScrollController();
    final categoriesKey = GlobalKey();

    // Scroll vers les catégories après le build si demandé
    if (scrollToCategories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoriesContext = categoriesKey.currentContext;
        if (categoriesContext != null) {
          Scrollable.ensureVisible(
            categoriesContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    AppModal.show(
      context,
      title: 'Avancé',
      child: StatefulBuilder(
        builder: (context, setState) {
          // Récupérer settings à chaque rebuild pour avoir les valeurs à jour
          final settings = provider.settings;

          return SingleChildScrollView(
            controller: scrollController,
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

                // Niveaux de difficulté
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Difficulté',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sélectionnez au moins 1 niveau',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 2, 3].map((level) {
                    final isSelected = settings.selectedDifficultyLevels.contains(level);
                    return GestureDetector(
                      onTap: () {
                        final newLevels = List<int>.from(settings.selectedDifficultyLevels);
                        if (isSelected) {
                          if (newLevels.length > 1) {
                            newLevels.remove(level);
                          }
                        } else {
                          newLevels.add(level);
                        }
                        newLevels.sort();
                        provider.updateSettings(selectedDifficultyLevels: newLevels);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.secondaryCyan : AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.secondaryCyan : AppColors.gray600,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          AppConstants.difficultyLabels[level]!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: isSelected ? Colors.white : AppColors.gray400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Catégories (toujours visibles pour le bouton aléatoire)
                Row(
                  key: categoriesKey,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catégories',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sélectionnez au moins 1 catégorie',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final allCategories = getCategoryList().map((c) => c.id).toList();
                            provider.updateSettings(selectedCategories: allCategories);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.secondaryCyan, width: 1),
                            ),
                            child: const Text(
                              'Tout',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.secondaryCyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final firstCategory = getCategoryList().first.id;
                            provider.updateSettings(selectedCategories: [firstCategory]);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.gray600.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.gray600, width: 1),
                            ),
                            child: const Text(
                              'Une seule',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.gray400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
