import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/score_timeline.dart';
import '../providers/game_provider.dart';
import '../services/reveal_sound.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/effects/score_reveal_chart.dart';
import 'results_screen.dart';

/// Ce que montre `screenResults` : la révélation une seule fois, puis les
/// Résultats. Passer par cet aiguillage plutôt que par un écran de plus laisse
/// intacts tous les chemins qui mènent aux résultats.
class EndOfGameScreen extends StatelessWidget {
  final RevealSound? sound;

  const EndOfGameScreen({super.key, this.sound});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>().game;
    if (game.scoreRevealSeen || game.history.isEmpty) {
      return const ResultsScreen();
    }
    return ScoreRevealScreen(sound: sound);
  }
}

/// Révélation des scores (maquette `curve(2)`) : les courbes se tracent tour
/// par tour, sans chiffres, puis le vainqueur. Un toucher passe aux résultats.
class ScoreRevealScreen extends StatefulWidget {
  final RevealSound? sound;

  const ScoreRevealScreen({super.key, this.sound});

  @override
  State<ScoreRevealScreen> createState() => _ScoreRevealScreenState();
}

class _ScoreRevealScreenState extends State<ScoreRevealScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _duration = Duration(milliseconds: 4500);
  static const _musicWait = Duration(milliseconds: 800);

  /// Réservé sous le graphique pour que la carte de fin ne le déplace pas.
  static const _endCardHeight = 170.0;

  /// En dessous, le graphique passe avant le titre et la légende (très grande
  /// police).
  static const _minChartHeight = 100.0;

  late final RevealSound _sound = widget.sound ?? RevealSound();
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _duration);
  late final ScoreTimeline _timeline;
  late final List<String> _names;
  late final List<String> _labels;
  late final List<Color> _colors;
  late final String _headline;
  late final String _scores;

  bool _started = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = context.read<GameProvider>();
    final teams = provider.teams;
    _timeline = buildScoreTimeline(
      teamIds: [for (final t in teams) t.id],
      history: provider.game.history,
    );
    _names = [for (final t in teams) t.name];
    _colors = [
      for (var i = 0; i < teams.length; i++) AppColors.getTeamColor(i)
    ];
    _labels = revealLabels(
      teamNames: _names,
      players: [
        for (final t in teams)
          t.playerIds
              .map((id) => provider.getPlayerById(id)?.name)
              .whereType<String>()
              .toList()
      ],
    );
    final ranked = provider.getTeamsSortedByScore();
    _headline = revealHeadline(ranked.first.name);
    _scores = ranked.map((t) => '${t.name} ${t.score}').join(' · ');
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed || _finished) return;
      // Le gong de la musique tombe ici ; sa queue s'éteint seule.
      setState(() => _finished = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _finished = true;
      _controller.value = 1;
    } else {
      _startWithMusic();
    }
  }

  /// L'animation part avec la musique, pour que le gong tombe à la fin du
  /// tracé. Une musique en échec ou trop lente ne la retient pas.
  Future<void> _startWithMusic() async {
    try {
      await _sound.startMusic().timeout(_musicWait);
    } catch (_) {
      // Sans musique, ou en retard sur elle : la révélation part quand même.
    }
    if (mounted) _controller.forward();
  }

  void _goToResults() {
    context.read<GameProvider>().markScoreRevealSeen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _sound.stopMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    // Passé pendant le tracé : fondu. Après le gong, sa queue sonne jusqu'au bout.
    if (!_finished) _sound.fadeOutMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToResults();
      },
      child: Material(
        color: AppColors.backgroundMain,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finished ? null : _goToResults,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: LayoutBuilder(builder: _buildContent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints box) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight = min(_endCardHeight * scale, box.maxHeight / 2);
    final titleHeight = 44 * scale;
    final legendHeight = _names.length * 24 * scale + 6;
    final chartRoom = box.maxHeight - cardHeight - _minChartHeight;
    final showTitle = chartRoom >= titleHeight;
    final showLegend = chartRoom >= titleHeight + legendHeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _finished ? 'Finale' : 'Qui a mené la danse ?',
              style: AppTextStyles.subtitle(fontSize: 26),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (showLegend) ...[
          for (var i = 0; i < _names.length; i++) _legendLine(i),
          const SizedBox(height: 6),
        ],
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: ScoreRevealPainter(
              timeline: _timeline,
              progress: _controller,
              labels: _labels,
              teamColors: _colors,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: _finished ? _endCard() : null,
        ),
      ],
    );
  }

  Widget _legendLine(int i) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: _colors[i], shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                _names[i],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _colors[i],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _endCard() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 26 * (1 - v)), child: child),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Le texte défile au besoin : le bouton reste toujours visible.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_headline,
                        style: AppTextStyles.subtitle(fontSize: 32)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _scores,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppButton(
            text: 'Suivant',
            variant: AppButtonVariant.primary,
            fullWidth: true,
            onPressed: _goToResults,
          ),
        ],
      ),
    );
  }
}
