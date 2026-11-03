import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/home_button.dart';
import '../services/audio_service.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/first_game_help.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late Set<String> _validatedWords;

  final _wordListKey = GlobalKey();
  final _validateKey = GlobalKey();

  List<CoachStep> get _helpSteps =>
      verificationHelp(wordList: _wordListKey, validate: _validateKey);

  /// Première partie sur ce téléphone : l'aide s'ouvre seule à la première
  /// vérification de chaque joueur.
  /// Vrai tant que l'aide automatique n'est pas tranchée : « Valider » est
  /// ignoré, sinon l'aide serait consommée sans être vue.
  bool _helpPending = true;

  Future<void> _firstGameHelp() async {
    final provider = context.read<GameProvider>();
    final player = provider.getCurrentPlayer();
    final gameId = provider.game.gameId;
    // Sans gameId (partie d'avant la mise à jour) : pas d'aide automatique.
    final show = player != null &&
        gameId != null &&
        await FirstGameHelp.claim(
          gameId: gameId,
          playerId: player.id,
          screen: FirstGameHelp.verification,
        );
    _helpPending = false;
    if (show && mounted) {
      await CoachMarks.show(context, _helpSteps);
    }
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();

    // Si on revient en arrière, utiliser les mots validés restaurés
    if (provider.game.restoredValidatedWords != null) {
      _validatedWords = Set.from(provider.game.restoredValidatedWords!);
      // Effacer après utilisation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearRestoredValidatedWords();
      });
    } else {
      // Par défaut : mots devinés = validés, mots passés = invalidés
      _validatedWords = Set.from(provider.game.wordsGuessedThisTurn);
      // Jouer le son de fin de tour seulement si ce n'est pas un retour en arrière
      AudioService.playKlaxon();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstGameHelp());
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
    // Mots à l'écran quand le chrono est tombé : un, ou deux avec « Deux mots
    // à la fois » (2-11). Chacun a sa carte, hors de la liste des passés.
    final expiredWords = [
      if (provider.game.expiredWord != null) provider.game.expiredWord!,
      if (provider.secondExpiredWord != null) provider.secondExpiredWord!,
    ];
    final passedWords = provider.game.passedWordsThisTurn
        .where((w) => !expiredWords.contains(w))
        .toList();
    // Fiesta 2-9 : même multiplicateur que `validateWords` (maquette `verif`).
    final doubled = provider.isDoublePointsOn;
    final points = _validatedWords.length * (doubled ? 2 : 1);

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
                  'Cliquez pour valider/invalider',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 24),

                // Score preview
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.secondaryCyan, width: 2),
                  ),
                  child: Text(
                    'Score : $points ${points <= 1 ? 'point' : 'points'}',
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 24,
                      color: AppColors.secondaryCyan,
                    ),
                  ),
                ),
                if (doubled) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mots devinés ${_validatedWords.length} · '
                    'Mot compte double ×2 · Points du tour $points',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.secondaryCyan,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    key: _wordListKey,
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

                        // Expired word section
                        if (expiredWords.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                expiredWords.length > 1
                                    ? 'Mots en cours'
                                    : 'Mot en cours',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Temps écoulé',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...expiredWords.map((word) => _buildWordCard(
                                word,
                                isGuessed: false,
                                isExpired: true,
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
                                  color: AppColors.warning.withOpacity(0.2),
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
                    key: _validateKey,
                    text: 'Valider',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () {
                      if (_helpPending) return;
                      provider.savePreValidationState(_validatedWords.toList());
                      provider.validateWords(_validatedWords.toList());
                    },
                  ),
                ),
              ],
            ),
          ),
          const HomeButton(),
          HelpButton(onPressed: () => CoachMarks.show(context, _helpSteps)),
        ],
      ),
    );
  }

  Widget _buildWordCard(String word,
      {required bool isGuessed, bool isExpired = false}) {
    final isValidated = _validatedWords.contains(word);

    return GestureDetector(
      onTap: () => _toggleWord(word),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isValidated
              ? AppColors.success.withOpacity(0.2)
              : AppColors.error.withOpacity(0.2),
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
          ],
        ),
      ),
    );
  }
}
