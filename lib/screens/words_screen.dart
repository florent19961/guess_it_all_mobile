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

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  int _currentPlayerIndex = 0;
  final List<TextEditingController> _wordControllers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    if (provider.settings.wordChoice == AppConstants.wordChoiceRandom) {
      // Retarder l'exécution après le build initial pour éviter setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateRandomWordsForAll(provider);
      });
    } else {
      _initializeWords();
    }
  }

  void _initializeWords() {
    final provider = context.read<GameProvider>();
    final wordsPerPlayer = provider.settings.wordsPerPlayer;

    // Si mode aléatoire, générer les mots pour tous les joueurs
    if (provider.settings.wordChoice == AppConstants.wordChoiceRandom) {
      _generateRandomWordsForAll(provider);
      return;
    }

    // Mode personnalisé : initialiser les contrôleurs
    _wordControllers.clear();
    final currentPlayer = provider.players[_currentPlayerIndex];
    for (int i = 0; i < wordsPerPlayer; i++) {
      final existingWord = i < currentPlayer.words.length ? currentPlayer.words[i] : '';
      _wordControllers.add(TextEditingController(text: existingWord));
    }
  }

  void _generateRandomWordsForAll(GameProvider provider) {
    final wordsPerPlayer = provider.settings.wordsPerPlayer;
    final totalWords = provider.players.length * wordsPerPlayer;
    final allWords = generateWordsFromCategories(
      provider.settings.selectedCategories,
      totalWords,
    );

    int wordIndex = 0;
    for (final player in provider.players) {
      final playerWords = <String>[];
      for (int i = 0; i < wordsPerPlayer && wordIndex < allWords.length; i++) {
        playerWords.add(allWords[wordIndex++]);
      }
      provider.updatePlayerWords(player.id, playerWords);
    }

    // Passer directement à l'écran des équipes
    provider.goToScreen(AppConstants.screenTeams);
  }

  void _loadPlayerWords(int playerIndex) {
    final provider = context.read<GameProvider>();
    final wordsPerPlayer = provider.settings.wordsPerPlayer;
    final player = provider.players[playerIndex];

    // Créer de nouveaux contrôleurs pour le joueur spécifié
    final newControllers = <TextEditingController>[];
    for (int i = 0; i < wordsPerPlayer; i++) {
      final existingWord = i < player.words.length ? player.words[i] : '';
      newControllers.add(TextEditingController(text: existingWord));
    }

    setState(() {
      _wordControllers.clear();
      _wordControllers.addAll(newControllers);
      _currentPlayerIndex = playerIndex;
      _error = null;
    });
  }

  @override
  void dispose() {
    for (final controller in _wordControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateWords() {
    final words = _wordControllers.map((c) => c.text.trim()).toList();

    // Vérifier que tous les mots sont remplis
    if (words.any((w) => w.isEmpty)) {
      setState(() => _error = 'Tous les mots doivent être remplis');
      return false;
    }

    // Vérifier les doublons
    final uniqueWords = words.toSet();
    if (uniqueWords.length != words.length) {
      setState(() => _error = 'Les mots doivent être différents');
      return false;
    }

    setState(() => _error = null);
    return true;
  }

  void _saveCurrentPlayerWords(GameProvider provider) {
    final words = _wordControllers.map((c) => c.text.trim()).toList();
    final currentPlayer = provider.players[_currentPlayerIndex];
    provider.updatePlayerWords(currentPlayer.id, words);
  }

  void _nextPlayer(GameProvider provider) {
    _saveCurrentPlayerWords(provider);

    if (!_validateWords()) return;

    if (_currentPlayerIndex < provider.players.length - 1) {
      _loadPlayerWords(_currentPlayerIndex + 1);
    } else {
      // Tous les joueurs ont entré leurs mots
      provider.goToScreen(AppConstants.screenTeams);
    }
  }

  void _previousPlayer(GameProvider provider) {
    _saveCurrentPlayerWords(provider);

    if (_currentPlayerIndex > 0) {
      _loadPlayerWords(_currentPlayerIndex - 1);
    } else {
      provider.goToScreen(AppConstants.screenPlayers);
    }
  }

  void _generateRandomWord(int index, GameProvider provider) {
    final existingWords = _wordControllers
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => e.value.text.trim())
        .toList();

    // Générer un mot qui n'est pas déjà utilisé
    String? newWord;
    int attempts = 0;
    while (attempts < 100) {
      final words = generateWordsFromCategories(
        provider.settings.selectedCategories,
        1,
      );
      if (words.isNotEmpty && !existingWords.contains(words[0])) {
        newWord = words[0];
        break;
      }
      attempts++;
    }

    if (newWord != null) {
      setState(() {
        _wordControllers[index].text = newWord!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    // Si mode aléatoire, afficher un écran de chargement
    if (provider.settings.wordChoice == AppConstants.wordChoiceRandom) {
      return const ShootingStars(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondaryCyan),
        ),
      );
    }

    final currentPlayer = provider.players[_currentPlayerIndex];

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                Text(
                  'Mots de ${currentPlayer.name}',
                  style: AppTextStyles.subtitle(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Joueur ${_currentPlayerIndex + 1}/${provider.players.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    key: ValueKey('player_$_currentPlayerIndex'),
                    padding: const EdgeInsets.all(24),
                    itemCount: _wordControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        key: ValueKey('word_${_currentPlayerIndex}_$index'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppInput(
                                key: ValueKey('input_${_currentPlayerIndex}_$index'),
                                controller: _wordControllers[index],
                                placeholder: 'Mot ${index + 1}',
                                onChanged: (_) {
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _generateRandomWord(index, provider),
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Précédent',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => _previousPlayer(provider),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: _currentPlayerIndex < provider.players.length - 1
                              ? 'Suivant'
                              : 'Terminer',
                          variant: AppButtonVariant.primary,
                          onPressed: () => _nextPlayer(provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppBackButton(
            onPressed: () => _previousPlayer(provider),
          ),
        ],
      ),
    );
  }
}
