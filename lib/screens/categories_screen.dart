import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../services/word_loader_service.dart';
import '../models/category_metadata.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Catégories à exclure du "Toutes les catégories"
  static const List<String> _excludedFromSelectAll = ['metro_parisien'];

  List<CategoryMetadata>? _categories;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final loader = WordLoaderService();
      final categories = loader.getCategoriesMetadata();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement catégories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final settings = provider.settings;

    // Afficher un loader pendant le chargement
    if (_isLoading) {
      return const ShootingStars(
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryPink,
          ),
        ),
      );
    }

    // Afficher une erreur si échec du chargement
    if (_categories == null || _categories!.isEmpty) {
      return const ShootingStars(
        child: Center(
          child: Text(
            'Erreur de chargement des catégories',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: AppColors.error,
            ),
          ),
        ),
      );
    }

    final categories = _categories!;

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
                  'Personnalise ta partie',
                  style: AppTextStyles.subtitle(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Liste scrollable avec Difficulté + Catégories
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      // === SECTION DIFFICULTÉ ===
                      _buildDifficultySection(provider),
                      const SizedBox(height: 24),

                      // === SECTION CATÉGORIES ===
                      const Text(
                        'CATÉGORIES',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSelection
                            ? '${settings.selectedCategories.length} catégorie${settings.selectedCategories.length > 1 ? 's' : ''} sélectionnée${settings.selectedCategories.length > 1 ? 's' : ''}'
                            : 'Sélectionne au moins 1 catégorie',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: hasSelection ? AppColors.gray400 : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bouton "Toutes les catégories"
                      GestureDetector(
                        onTap: () {
                          if (allSelected) {
                            provider.updateSettings(selectedCategories: []);
                          } else {
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
                      const SizedBox(height: 12),

                      // Liste des catégories
                      ...categories.map((category) {
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
                                      category.getLocalizedName('fr'),
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
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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

  Widget _buildDifficultySection(GameProvider provider) {
    final selectedLevels = provider.settings.selectedDifficultyLevels;
    final hasValidSelection = selectedLevels.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DIFFICULTÉ',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasValidSelection
              ? '${selectedLevels.length} niveau${selectedLevels.length > 1 ? 'x' : ''} sélectionné${selectedLevels.length > 1 ? 's' : ''}'
              : 'Sélectionne au moins 1 niveau',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: hasValidSelection ? AppColors.gray400 : AppColors.error,
          ),
        ),
        const SizedBox(height: 12),

        // Grille 2x2
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [1, 2, 3, 4].map((level) {
            final isSelected = selectedLevels.contains(level);
            return _buildDifficultyCard(level, isSelected, provider);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(int level, bool isSelected, GameProvider provider) {
    return GestureDetector(
      onTap: () => provider.toggleDifficultyLevel(level),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryCyan : AppColors.gray700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.difficultyEmojis[level] ?? '',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.difficultyLabels[level] ?? '',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.gray400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, color: Colors.white, size: 16),
            ],
          ],
        ),
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
