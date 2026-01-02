import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/word_categories/word_categories.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  // Catégories à exclure du "Toutes les catégories"
  static const List<String> _excludedFromSelectAll = ['metro_parisien'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final settings = provider.settings;
    final categories = getCategoryList();

    final hasSelection = settings.selectedCategories.isNotEmpty;

    // Vérifier si toutes les catégories (sauf exclues) sont sélectionnées
    final selectableCategories = categories
        .where((c) => !_excludedFromSelectAll.contains(c.id))
        .map((c) => c.id)
        .toList();
    final allSelected = selectableCategories.every(
      (id) => settings.selectedCategories.contains(id),
    );

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                Text(
                  'Catégories',
                  style: AppTextStyles.subtitle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                // Message d'avertissement si aucune catégorie sélectionnée
                if (!hasSelection)
                  const Text(
                    'Sélectionnez au moins une catégorie',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const SizedBox(height: 14), // Placeholder pour garder l'alignement
                const SizedBox(height: 24),

                // Bouton "Toutes les catégories"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      if (allSelected) {
                        // Désélectionner toutes les catégories
                        provider.updateSettings(selectedCategories: []);
                      } else {
                        // Sélectionner toutes les catégories (sauf exclues)
                        provider.updateSettings(selectedCategories: selectableCategories);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: allSelected
                            ? AppColors.secondaryCyan.withOpacity(0.2)
                            : AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: allSelected ? AppColors.secondaryCyan : AppColors.gray600,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.select_all,
                            size: 24,
                            color: allSelected ? AppColors.secondaryCyan : AppColors.gray400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Toutes les catégories',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: allSelected ? AppColors.secondaryCyan : AppColors.gray400,
                              ),
                            ),
                          ),
                          _buildSwitch(allSelected, true),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Liste des catégories
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = settings.selectedCategories.contains(category.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            final newCategories = List<String>.from(settings.selectedCategories);
                            if (isSelected) {
                              newCategories.remove(category.id);
                            } else {
                              newCategories.add(category.id);
                            }
                            provider.updateSettings(selectedCategories: newCategories);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.secondaryCyan : AppColors.gray600,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  category.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.gray400,
                                    ),
                                  ),
                                ),
                                _buildSwitch(isSelected, true),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          AppBackButton(
            onPressed: hasSelection
                ? () => provider.goToScreen(AppConstants.screenSettings)
                : null,
            disabled: !hasSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(bool isOn, bool isEnabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isOn ? AppColors.success : AppColors.gray600,
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: isOn ? 24 : 4,
            top: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
