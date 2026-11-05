import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_modal.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/first_game_prompt.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _playKey = GlobalKey();
  final _resumeKey = GlobalKey();
  final _replayKey = GlobalKey();
  final _rulesKey = GlobalKey();
  final _historyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final hasSuspendedGame = provider.game.isGameSuspended;
    final hasGameSession = provider.hasGameSession;

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    'Guess It All',
                    style: AppTextStyles.title(fontSize: 72),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Cas 1: Partie suspendue
                  if (hasSuspendedGame) ...[
                    AppButton(
                      key: _resumeKey,
                      text: 'Reprendre',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      onPressed: () => provider.resumeGame(),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      key: _playKey,
                      text: 'Nouvelle partie',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      onPressed: () =>
                          _showNewGameConfirmation(context, provider),
                    ),
                  ]
                  // Cas 2: Session existante (joueurs d'une partie précédente)
                  else if (hasGameSession) ...[
                    AppButton(
                      key: _replayKey,
                      text: 'Rejouer',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      onPressed: () async {
                        await provider.restartWithSamePlayers();
                      },
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      key: _playKey,
                      text: 'Nouvelle partie',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      onPressed: () async {
                        // startNewGame() : efface session + état, GARDE les réglages.
                        // clearLocalStorage() remettait GameSettings.initial() et le
                        // réécrivait sur disque — le joueur reperdait ses réglages à
                        // chaque partie. La remise à zéro explicite reste disponible
                        // depuis le bouton « Réinitialiser » de l'écran de réglages.
                        await provider.startNewGame();
                        provider.goToScreen(AppConstants.screenSettings);
                      },
                    ),
                  ]
                  // Cas 3: Pas de partie en cours
                  else ...[
                    AppButton(
                      key: _playKey,
                      text: 'Jouer',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      onPressed: () async {
                        await FirstGamePrompt.maybeShow(context);
                        if (!context.mounted) return;
                        // startNewGame() : efface session + état, GARDE les réglages.
                        // clearLocalStorage() remettait GameSettings.initial() et le
                        // réécrivait sur disque — le joueur reperdait ses réglages à
                        // chaque partie. La remise à zéro explicite reste disponible
                        // depuis le bouton « Réinitialiser » de l'écran de réglages.
                        await provider.startNewGame();
                        provider.goToScreen(AppConstants.screenSettings);
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  AppButton(
                    key: _rulesKey,
                    text: 'Règles',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.medium,
                    onPressed: () =>
                        provider.goToScreen(AppConstants.screenRules),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    key: _historyKey,
                    text: 'Historique',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.medium,
                    onPressed: () =>
                        provider.goToScreen(AppConstants.screenHistory),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          HelpButton(
            onPressed: () => CoachMarks.show(
              context,
              homeHelp(
                play: _playKey,
                resume: _resumeKey,
                replay: _replayKey,
                rules: _rulesKey,
                history: _historyKey,
                // Sans partie ni session, le bouton s'appelle « Jouer ».
                playLabel: hasSuspendedGame || hasGameSession
                    ? 'Nouvelle partie'
                    : 'Jouer',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewGameConfirmation(BuildContext context, GameProvider provider) {
    AppModal.show(
      context,
      title: 'Nouvelle partie',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Voulez-vous abandonner la partie en cours et en commencer une nouvelle ?',
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
                  text: 'Valider',
                  variant: AppButtonVariant.primary,
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Idem : abandonner la partie en cours ne doit pas effacer
                    // les réglages du joueur.
                    await provider.startNewGame();
                    provider.goToScreen(AppConstants.screenSettings);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
