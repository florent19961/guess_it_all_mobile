import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/home_button.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late Set<String> _validatedWords;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    // Par défaut : mots devinés = validés, mots passés = invalidés
    _validatedWords = Set.from(provider.game.wordsGuessedThisTurn);
  }

  void _toggleWord(String word) {
    setState(() {
      if (_validatedWords.contains(word)) {
        _validatedWords.remove(word);
      } else {
        _validatedWords.add(word);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final guessedWords = provider.game.wordsGuessedThisTurn;
    final passedWords = provider.game.passedWordsThisTurn;
    final teamColor = AppColors.getTeamColor(provider.game.currentTeamIndex);

    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                Text(
                  'Vérification',
                  style: AppTextStyles.subtitle(fontSize: 36),
                ),
                const SizedBox(height: 8),
                Text(
                  'Touchez pour valider/invalider',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 24),

                // Score preview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: teamColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: teamColor, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: teamColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '+${_validatedWords.length} points',
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 24,
                          color: teamColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Guessed words section
                        if (guessedWords.isNotEmpty) ...[
                          const Text(
                            'Mots devinés',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...guessedWords.map((word) => _buildWordCard(
                                word,
                                isGuessed: true,
                              )),
                          const SizedBox(height: 24),
                        ],

                        // Passed words section
                        if (passedWords.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text(
                                'Mots passés',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Pénalité',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...passedWords.map((word) => _buildWordCard(
                                word,
                                isGuessed: false,
                              )),
                        ],
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppButton(
                    text: 'Valider',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () {
                      provider.validateWords(_validatedWords.toList());
                    },
                  ),
                ),
              ],
            ),
          ),
          const HomeButton(),
        ],
      ),
    );
  }

  Widget _buildWordCard(String word, {required bool isGuessed}) {
    final isValidated = _validatedWords.contains(word);

    return GestureDetector(
      onTap: () => _toggleWord(word),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isValidated
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isValidated ? AppColors.success : AppColors.error,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isValidated ? Icons.check_circle : Icons.cancel,
              color: isValidated ? AppColors.success : AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                word,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              isValidated ? 'Cliquer pour invalider' : 'Cliquer pour valider',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: isValidated ? AppColors.error.withValues(alpha: 0.7) : AppColors.success.withValues(alpha: 0.7),
              ),
            ),
            if (!isGuessed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Passé',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
