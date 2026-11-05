import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../providers/game_provider.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/word_categories/word_categories.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_counter.dart';
import '../widgets/common/app_toggle.dart';
import '../widgets/common/app_slider.dart';
import '../widgets/common/app_modal.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';
import 'fiesta_tutorial_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showAdvancedAnimation = false;

  final _modeKey = GlobalKey();
  final _countsKey = GlobalKey();
  final _wordChoiceKey = GlobalKey();
  final _categoriesKey = GlobalKey();
  final _advancedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkAdvancedSettingsSeen();
  }

  Future<void> _checkAdvancedSettingsSeen() async {
    final storage = StorageService();
    final hasSeen = await storage.hasSeenAdvancedSettings();
    if (!hasSeen && mounted) {
      setState(() {
        _showAdvancedAnimation = true;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static const _classic = 'Classique';
  static const _fiesta = 'Fiesta';

  /// Garde contre le double tap : un seul tuto Fiesta.
  bool _tutorialBusy = false;

  /// Classique / Fiesta. L'ensemble se choisit juste après cet écran ; la
  /// première fois, le tuto Fiesta s'ouvre (clé
  /// `guessItAll_fiestaTutorialSeen`).
  Future<void> _setMode(GameProvider provider, String mode) async {
    if (mode == _classic) {
      provider.setPendingFiesta(null);
      return;
    }
    if (provider.pendingFiesta != null) return;
    provider.setPendingFiesta(FiestaRules());
    if (_tutorialBusy) return;
    _tutorialBusy = true;
    try {
      if (!await StorageService().hasSeenFiestaTutorial() && mounted) {
        await FiestaTutorialScreen.show(context);
      }
    } finally {
      _tutorialBusy = false;
    }
  }

  /// Fiesta : la liste des ensembles vient avant les joueurs.
  void _goNext(GameProvider provider) => provider.goToScreen(
        provider.pendingFiesta != null
            ? AppConstants.screenFiestaEnsembles
            : AppConstants.screenPlayers,
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final settings = provider.settings;

    // Retour système (Android) = bouton retour : l'accueil, pas la sortie de
    // l'app (écran racine du `MaterialApp`).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) provider.goToScreen(AppConstants.screenHome);
      },
      child: ShootingStars(
        child: Stack(
          children: [
            SafeArea(
              // Tout tient sans défiler sur un iPhone 390 × 844 (763 px utiles)
              // et un Android 360 × 780 (740 utiles), avertissement « partie
              // longue » compris : espacements serrés (retours 2026-11-04).
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    // Sous les boutons du haut (retour, aide, roue crantée).
                    const SizedBox(height: 48),
                    Text(
                      'Paramètres',
                      style: AppTextStyles.subtitle(fontSize: 40),
                    ),
                    const SizedBox(height: _sectionGap),

                    // Nombre de joueurs et d'équipes (une seule cible d'aide)
                    Column(
                      key: _countsKey,
                      children: [
                        _buildSection(
                          title: 'Joueurs',
                          child: AppCounter(
                            value: settings.numberOfPlayers,
                            min:
                                settings.numberOfTeams * 2, // Minimum dynamique
                            max: AppConstants.maxPlayers,
                            onChange: (value) =>
                                provider.updateSettings(numberOfPlayers: value),
                          ),
                        ),
                        const SizedBox(height: _sectionGap),

                        // Nombre d'équipes (ajuste le minimum de joueurs)
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
                                provider.updateSettings(
                                    numberOfPlayers: minPlayers);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _sectionGap),

                    // Classique / Fiesta
                    _buildSection(
                      title: 'Mode de jeu',
                      child: AppToggle(
                        key: _modeKey,
                        options: const [_classic, _fiesta],
                        selected:
                            provider.pendingFiesta == null ? _classic : _fiesta,
                        onChange: (value) => _setMode(provider, value),
                      ),
                    ),
                    const SizedBox(height: _sectionGap),

                    // Choix des mots
                    KeyedSubtree(
                      key: _wordChoiceKey,
                      child: _buildSection(
                        title: 'Choix des mots',
                        child: AppToggle(
                          options: const [
                            AppConstants.wordChoiceCustom,
                            AppConstants.wordChoiceRandom
                          ],
                          selected: settings.wordChoice,
                          onChange: (value) =>
                              provider.updateSettings(wordChoice: value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Choix des catégories (sous le toggle)
                    GestureDetector(
                      key: _categoriesKey,
                      onTap: () =>
                          provider.goToScreen(AppConstants.screenCategories),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.gray600, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: const Icon(
                                    Icons.category,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Catégories & Difficultés',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.gray400,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: _sectionGap),

                    // Avertissement si trop de mots
                    if (settings.totalWords > 50)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${settings.totalWords} mots : partie longue ! Réglable via ',
                                  ),
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(
                                      Icons.settings,
                                      color: AppColors.warning,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bouton suivant
                    AppButton(
                      text: 'Suivant',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      onPressed: () async {
                        // Si mode aléatoire, vérifier le nombre de mots disponibles
                        if (settings.wordChoice ==
                            AppConstants.wordChoiceRandom) {
                          final totalWordsNeeded = settings.totalWords;
                          final availableWords = await getTotalWordsCountAsync(
                            settings.selectedCategories,
                            difficultyLevels: settings.selectedDifficultyLevels,
                          );

                          if (availableWords < totalWordsNeeded) {
                            _showNotEnoughWordsWarning(context, provider,
                                availableWords, totalWordsNeeded);
                            return;
                          }
                        }
                        _goNext(provider);
                      },
                    ),
                  ],
                ),
              ),
            ),
            AppBackButton(
              onPressed: () => provider.goToScreen(AppConstants.screenHome),
            ),
            // Boutons en haut à droite : aide + Paramètres avancés
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Row(
                children: [
                  HelpButton.inline(
                    onPressed: () => CoachMarks.show(
                      context,
                      settingsHelp(
                        mode: _modeKey,
                        counts: _countsKey,
                        wordChoice: _wordChoiceKey,
                        categories: _categoriesKey,
                        advanced: _advancedKey,
                        passPenalty: provider.settings.passPenalty,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bouton paramètres avancés
                  GestureDetector(
                    key: _advancedKey,
                    onTap: () {
                      // Marquer comme vu et arrêter l'animation
                      if (_showAdvancedAnimation) {
                        StorageService().markAdvancedSettingsSeen();
                        setState(() {
                          _showAdvancedAnimation = false;
                        });
                      }
                      _showAdvancedSettings(context, provider);
                    },
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _showAdvancedAnimation
                              ? _pulseAnimation.value
                              : 1.0,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.gray600, width: 2),
                            ),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// Espace entre deux sections (serré : l'écran tient sans défiler).
  static const double _sectionGap = 16;

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
                  text: 'Réinit.',
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
                  text: 'Catégories & Difficultés',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    Navigator.pop(context);
                    provider.goToScreen(AppConstants.screenCategories);
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
                    _goNext(provider);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdvancedSettings(BuildContext context, GameProvider provider) {
    final screenContext = context;
    AppModal.show(
      context,
      title: 'Avancés',
      child: StatefulBuilder(
        builder: (context, setState) {
          // Récupérer settings à chaque rebuild pour avoir les valeurs à jour
          final settings = provider.settings;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Serré : tout tient sans défiler (iPhone 390 × 844).
              children: [
                // Nombre total de mots
                AppSlider(
                  label: 'Nombre total de mots',
                  min: AppConstants.minTotalWords.toDouble(),
                  max: AppConstants.maxTotalWords.toDouble(),
                  value: settings.totalWords.toDouble(),
                  compact: true,
                  onChanged: (value) {
                    provider.updateSettings(totalWords: value.toInt());
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),

                // Durée du tour
                AppSlider(
                  label: 'Durée du tour',
                  min: AppConstants.minTurnDuration.toDouble(),
                  max: AppConstants.maxTurnDuration.toDouble(),
                  value: settings.turnDuration.toDouble(),
                  unit: 's',
                  compact: true,
                  onChanged: (value) {
                    provider.updateSettings(turnDuration: value.toInt());
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),

                // Pénalité de passe
                AppSlider(
                  label: 'Pénalité pour passer',
                  min: AppConstants.minPassPenalty.toDouble(),
                  max: AppConstants.maxPassPenalty.toDouble(),
                  value: settings.passPenalty.toDouble(),
                  unit: 's',
                  compact: true,
                  onChanged: (value) {
                    provider.updateSettings(passPenalty: value.toInt());
                    setState(() {});
                  },
                ),

                // Réinitialiser (ancien bouton rond du coin haut droit) : ferme
                // « Avancés », puis la même confirmation qu'avant. Un peu d'air
                // pour le séparer des réglages.
                const SizedBox(height: 24),
                AppButton(
                  text: 'Réinitialiser les paramètres',
                  variant: AppButtonVariant.ghost,
                  // Medium : cible tactile ≥ 44 px (revue r1).
                  size: AppButtonSize.medium,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showResetConfirmation(screenContext, provider);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
