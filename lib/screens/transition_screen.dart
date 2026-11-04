import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/game_dialogs.dart';
import '../widgets/common/home_button.dart';
import '../widgets/common/back_button.dart';
import '../widgets/fiesta/modifier_card.dart';
import '../widgets/fiesta/offer_widgets.dart';
import '../widgets/fiesta/turn_time_cards.dart';
import '../models/fiesta/turn_time.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

class TransitionScreen extends StatefulWidget {
  const TransitionScreen({super.key});

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> {
  final _nextRoundKey = GlobalKey();
  final _previousTurnKey = GlobalKey();
  final _nextKey = GlobalKey();
  final _backKey = GlobalKey();
  final _homeKey = GlobalKey();
  final _catchUpKey = GlobalKey();
  final _pickThreeKey = GlobalKey();
  final _appBoostKey = GlobalKey();

  void _showHelp(GameProvider provider) {
    CoachMarks.show(
      context,
      transitionHelp(
        nextRound: _nextRoundKey,
        previousTurn: _previousTurnKey,
        next: _nextKey,
        back: _backKey,
        home: _homeKey,
        fiesta: provider.isFiesta
            ? fiestaTransitionHelp(
                catchUp: _catchUpKey,
                pickThree: _pickThreeKey,
                appBoost: _appBoostKey,
              )
            : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final currentRound = provider.game.currentRound;
    final nextRound = currentRound + 1;
    final fiestaRules = provider.game.fiesta?.rules;
    final catchUpRules =
        fiestaRules == null ? null : effectiveCatchUp(fiestaRules);
    // 1 parmi 3 : « Manche suivante » attend la fin de la file (le provider
    // refuse aussi, cf. `nextRound`).
    final chooserId = provider.nextChooserId;
    final chooser = chooserId == null ? null : provider.getTeamById(chooserId);
    // `nextRound` ne touche pas à l'équipe ni au joueur courants : ce sont
    // ceux que l'avant-tour de la manche suivante affichera.
    final starterTeam = provider.getCurrentTeam();
    final starterPlayer = provider.getCurrentPlayer();
    final starterColor = AppColors.getTeamColor(provider.game.currentTeamIndex);
    final bonus = provider.game.turnBonusTime ?? 0;

    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'MANCHE $currentRound TERMINÉE',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Pas de score ici : il reste caché jusqu'aux
                          // résultats.
                          _Hero(
                            key: _nextRoundKey,
                            children: [
                              _HeroTitle('Manche $nextRound : '
                                  '${AppConstants.roundModes[nextRound] ?? ''}'),
                              _HeroText(
                                  AppConstants.roundDescriptions[nextRound] ??
                                      ''),
                            ],
                          ),
                          if (starterTeam != null) ...[
                            const SizedBox(height: 14),
                            _Starter(
                              team: starterTeam.name,
                              player: starterPlayer?.name,
                              color: starterColor,
                            ),
                          ],
                          if (bonus > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Temps bonus conservé : ${bonus}s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                          // Bouton pour consulter les mots devinés du tour
                          // précédent.
                          if (provider.game.history.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Center(
                              child: GestureDetector(
                                key: _previousTurnKey,
                                onTap: () =>
                                    _showGuessedWordsDialog(context, provider),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.checklist,
                                          size: 16, color: Colors.white70),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Voir les ${provider.game.history.last.wordsGuessed.length} mots devinés',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Fiesta : sous le héros. Vides en Classique.
                          RoundDrawLine(
                            round: nextRound,
                            modifiers: provider.nextRoundModifiers,
                          ),
                          if (catchUpRules != null)
                            CatchUpLine(
                              // Ligne vide (aucun rattrapage) : pas d'aide.
                              key: provider.catchUpPreview.isEmpty
                                  ? null
                                  : _catchUpKey,
                              entries: provider.catchUpPreview,
                              teams: provider.teams,
                            ),
                          // Fiesta Auto : coup de pouce de l'app.
                          AppBoostLine(
                            key: provider.appBoostPreview.isEmpty
                                ? null
                                : _appBoostKey,
                            teams: provider.teams,
                            gifts: provider.appBoostPreview,
                          ),
                          // Fiesta Personnalisé : choix 1 parmi 3.
                          if (provider.hasPickThree)
                            PickThreeCard(
                              key: _pickThreeKey,
                              teams: provider.teams,
                              nextTeamId: chooserId,
                              onPassPhone: () =>
                                  _PickThreeFlow.open(context, chooserId!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    key: _nextKey,
                    text: chooser != null
                        ? 'En attente du choix : ${chooser.name}'
                        : 'Manche $nextRound',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    disabled: chooser != null,
                    onPressed:
                        chooser != null ? null : () => provider.nextRound(),
                  ),
                ],
              ),
            ),
          ),
          HomeButton(key: _homeKey, alignRight: true),
          HelpButton(
            right: HelpButton.besideCornerButton,
            onPressed: () => _showHelp(provider),
          ),
          // Back button pour revenir à l'écran de vérification
          if (provider.canGoBackToVerification)
            GameBackButton(
              key: _backKey,
              onPressed: () => showBackToVerificationDialog(context, provider),
            ),
        ],
      ),
    );
  }

  void _showGuessedWordsDialog(BuildContext context, GameProvider provider) {
    final lastEntry = provider.game.history.last;
    final team = provider.getTeamById(lastEntry.teamId);
    final player = provider.getPlayerById(lastEntry.playerId);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.backgroundMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.gray500, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec croix
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tour précédent',
                      style: AppTextStyles.subtitle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'par ${team?.name ?? "Équipe"} (${player?.name ?? "Joueur"})',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.gray400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Contenu
              if (lastEntry.wordsGuessed.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucun mot deviné durant ce tour',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.gray400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lastEntry.wordsGuessed.map((word) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.secondaryCyan.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            word,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                '${lastEntry.wordsGuessed.length} mot${lastEntry.wordsGuessed.length > 1 ? "s" : ""} au total',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1 parmi 3 d'UNE équipe : « Passe le téléphone » (rien des offres n'est
/// visible), puis le choix. Route au-dessus de la transition, non persistée :
/// une app tuée revient sur la transition, qui montre l'équipe suivante.
class _PickThreeFlow extends StatefulWidget {
  final String teamId;

  const _PickThreeFlow({required this.teamId});

  static Future<void> open(BuildContext context, String teamId) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PickThreeFlow(teamId: teamId),
      ));

  @override
  State<_PickThreeFlow> createState() => _PickThreeFlowState();
}

class _PickThreeFlowState extends State<_PickThreeFlow> {
  bool _revealed = false;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final teamIndex = provider.teams.indexWhere((t) => t.id == widget.teamId);
    if (!_revealed) {
      return PassPhonePanel(
        teamName: provider.getTeamById(widget.teamId)?.name ?? '',
        teamColor: AppColors.getTeamColor(teamIndex < 0 ? 0 : teamIndex),
        onReady: () => setState(() => _revealed = true),
      );
    }
    return Material(
      color: AppColors.backgroundMain,
      child: OfferChoiceBody(
        round: provider.game.currentRound,
        teams: provider.teams,
        standings: provider.standings,
        chooserId: widget.teamId,
        offers: provider.offersFor(widget.teamId),
        selected: _selected,
        onSelect: (i) => setState(() => _selected = i),
        // Fermer AVANT de choisir : sinon la route qui se ferme se
        // reconstruit avec les offres recalculées après ce choix.
        onConfirm: () {
          Navigator.of(context).pop();
          provider.chooseOffer(widget.teamId, _selected!);
        },
      ),
    );
  }
}

// ========== La manche suivante (sans aucun score) ==========

/// Carte sobre de la manche suivante : son titre et sa règle.
class _Hero extends StatelessWidget {
  final List<Widget> children;

  const _Hero({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.primaryPink.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPink.withValues(alpha: 0.22),
            AppColors.team3.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  final String text;

  const _HeroTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 30,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
      );
}

class _HeroText extends StatelessWidget {
  final String text;

  const _HeroText(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            color: Colors.white,
          ),
        ),
      );
}

/// « Commence : <équipe> · <joueur> fait deviner ».
class _Starter extends StatelessWidget {
  final String team;
  final String? player;
  final Color color;

  const _Starter({required this.team, this.player, required this.color});

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: Colors.white,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text.rich(
            TextSpan(
              style: base,
              children: [
                const TextSpan(text: 'Commence : '),
                TextSpan(
                  text: team,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                if (player != null) TextSpan(text: ' · $player fait deviner'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
