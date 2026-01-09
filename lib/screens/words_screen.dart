import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/word_categories/word_categories.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_input.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_modal.dart';
import '../widgets/effects/shooting_stars.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final List<TextEditingController> _wordControllers = [];
  bool _isInitialized = false;
  GameProvider? _provider;
  String? _playerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sauvegarder la référence au provider pour l'utiliser dans dispose()
    _provider ??= context.read<GameProvider>();
    _playerId ??= _provider?.currentEditingPlayerId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    final provider = context.read<GameProvider>();
    final playerId = provider.currentEditingPlayerId;
    if (playerId == null) return;

    final player = provider.getPlayerById(playerId);
    if (player == null) return;

    final wordsForPlayer = provider.getWordsCountForPlayer(playerId);

    // Initialiser les contrôleurs avec les mots existants
    for (int i = 0; i < wordsForPlayer; i++) {
      final existingWord = i < player.words.length ? player.words[i] : '';
      _wordControllers.add(TextEditingController(text: existingWord));
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    for (final controller in _wordControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveWords() {
    if (_provider == null || _playerId == null) return;

    final words = _wordControllers
        .map((c) => c.text.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    _provider!.updatePlayerWords(_playerId!, words);
  }

  // Récupère tous les mots déjà utilisés par les autres joueurs
  Set<String> _getOtherPlayersWords(GameProvider provider, String currentPlayerId) {
    final otherWords = <String>{};
    for (final p in provider.players) {
      if (p.id != currentPlayerId) {
        otherWords.addAll(p.words.map((w) => w.toLowerCase()));
      }
    }
    return otherWords;
  }

  // Génère un mot unique qui n'est pas utilisé
  Future<String?> _generateUniqueWord(
    GameProvider provider,
    Set<String> otherPlayersWords,
    List<String> currentWords,
  ) async {
    int attempts = 0;
    while (attempts < 100) {
      final words = await generateWordsFromCategoriesAsync(
        provider.settings.selectedCategories,
        1,
        difficultyLevels: provider.settings.selectedDifficultyLevels,
      );
      if (words.isNotEmpty) {
        final word = words[0];
        final wordLower = word.toLowerCase();
        if (!otherPlayersWords.contains(wordLower) &&
            !currentWords.map((w) => w.toLowerCase()).contains(wordLower)) {
          return word;
        }
      }
      attempts++;
    }
    return null;
  }

  // Vérifie si un mot est en doublon
  String? _getWordError(int index, GameProvider provider, String playerId) {
    final word = _wordControllers[index].text.trim();
    if (word.isEmpty) return null;

    final wordLower = word.toLowerCase();
    final otherPlayersWords = _getOtherPlayersWords(provider, playerId);

    // Vérifier si le mot est utilisé par un autre joueur
    if (otherPlayersWords.contains(wordLower)) {
      return 'Mot déjà pris par un autre joueur';
    }

    // Vérifier si le mot est en doublon dans les contrôleurs actuels
    for (int i = 0; i < _wordControllers.length; i++) {
      if (i != index) {
        final otherWord = _wordControllers[i].text.trim().toLowerCase();
        if (otherWord == wordLower) {
          return 'Doublon';
        }
      }
    }

    return null;
  }

  void _showClearAllConfirmation(BuildContext context) {
    AppModal.show(
      context,
      title: 'Supprimer tous les mots',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Êtes-vous sûr de vouloir supprimer tous les mots ?',
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
                  text: 'Effacer',
                  variant: AppButtonVariant.danger,
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      for (final controller in _wordControllers) {
                        controller.clear();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoWordsAvailableWarning(BuildContext context) {
    AppModal.show(
      context,
      title: 'Oups !',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Aucun mot n\'est plus disponible, tu dois en créer un toi-même !',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Compris',
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showPartialFillWarning(BuildContext context, int filled, int needed) {
    final remaining = needed - filled;
    AppModal.show(
      context,
      title: 'Attention',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Il ne reste que $filled mot${filled > 1 ? 's' : ''} disponible${filled > 1 ? 's' : ''} '
            'et tu dois en remplir $needed.\n\n'
            'Il te faudra compléter les $remaining restant${remaining > 1 ? 's' : ''} toi-même !',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Compris',
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _fillAllEmptyWords(GameProvider provider, String playerId) async {
    final otherPlayersWords = _getOtherPlayersWords(provider, playerId);
    final emptyFieldsCount = _wordControllers
        .where((c) => c.text.trim().isEmpty)
        .length;

    if (emptyFieldsCount == 0) return;

    int filledCount = 0;
    final filledWords = _wordControllers
        .map((c) => c.text.trim())
        .where((w) => w.isNotEmpty)
        .toList();

    for (int i = 0; i < _wordControllers.length; i++) {
      if (_wordControllers[i].text.trim().isEmpty) {
        final newWord = await _generateUniqueWord(
          provider,
          otherPlayersWords,
          filledWords,
        );
        if (newWord != null) {
          setState(() {
            _wordControllers[i].text = newWord;
          });
          filledWords.add(newWord);
          filledCount++;
        }
      }
    }

    if (filledCount == 0) {
      _showNoWordsAvailableWarning(context);
    } else if (filledCount < emptyFieldsCount) {
      _showPartialFillWarning(context, filledCount, emptyFieldsCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final playerId = provider.currentEditingPlayerId;

    if (playerId == null) {
      return const ShootingStars(
        child: Center(child: Text('Erreur: aucun joueur sélectionné')),
      );
    }

    final player = provider.getPlayerById(playerId);
    if (player == null) {
      return const ShootingStars(
        child: Center(child: Text('Erreur: joueur introuvable')),
      );
    }

    final wordsForPlayer = provider.getWordsCountForPlayer(playerId);

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                // Titre
                Text(
                  'Mots de ${player.name}',
                  style: AppTextStyles.subtitle(fontSize: 32),
                ),
                const SizedBox(height: 24),
                // Bouton "Grosse flemme"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppButton(
                    text: 'Grosse flemme 😴',
                    variant: AppButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () async => await _fillAllEmptyWords(provider, playerId),
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des champs de mots
                Expanded(
                  child: _isInitialized
                      ? ListView.builder(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 100,
                          ),
                          itemCount: wordsForPlayer,
                          itemBuilder: (context, index) {
                            final error = _getWordError(index, provider, playerId);
                            final otherPlayersWords = _getOtherPlayersWords(provider, playerId);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: AppInput(
                                      controller: _wordControllers[index],
                                      placeholder: 'Mot ${index + 1}',
                                      error: error,
                                      onChanged: (_) => setState(() {}),
                                      maxLength: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Bouton shuffle
                                  GestureDetector(
                                    onTap: () async {
                                      final currentWords = _wordControllers
                                          .asMap()
                                          .entries
                                          .where((e) => e.key != index)
                                          .map((e) => e.value.text.trim())
                                          .where((w) => w.isNotEmpty)
                                          .toList();

                                      final newWord = await _generateUniqueWord(
                                        provider,
                                        otherPlayersWords,
                                        currentWords,
                                      );

                                      if (newWord != null) {
                                        setState(() {
                                          _wordControllers[index].text = newWord;
                                        });
                                      } else {
                                        _showNoWordsAvailableWarning(context);
                                      }
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryCyan,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.shuffle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondaryCyan,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Bouton Sauvegarder
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppButton(
                    text: 'Sauvegarder',
                    variant: AppButtonVariant.primary,
                    fullWidth: true,
                    onPressed: () {
                      _saveWords();
                      provider.setCurrentEditingPlayer(null);
                      provider.goToScreen(AppConstants.screenPlayers);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Bouton retour (sauvegarde automatique)
          AppBackButton(
            onPressed: () {
              _saveWords();
              provider.setCurrentEditingPlayer(null);
              provider.goToScreen(AppConstants.screenPlayers);
            },
          ),
          // Bouton poubelle globale en haut à droite
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _showClearAllConfirmation(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gray600, width: 2),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
