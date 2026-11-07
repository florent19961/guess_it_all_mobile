import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/fiesta/surprise_challenge.dart';
import '../services/challenge_sounds.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/modifier_badge.dart';

const kVersusDuration = Duration(milliseconds: 1900);
const kRouletteDuration =
    Duration(milliseconds: _rouletteTick * _rouletteTicks);

const _rouletteTick = 110;
const _rouletteTicks = 14;

/// Ce qui défile dans la roulette : (id du modificateur, malus).
const _rouletteItems = [
  ('double_points', false),
  ('reversed', true),
  ('plus_10s', false),
  ('minus_10s', true),
  ('free_pass', false),
  ('block_giver', true),
];

/// Un joueur du défi et son équipe. [teammates] : ceux à qui il passe le mime,
/// dans l'ordre (téléphone arabe).
class ChallengeContender {
  final String playerName;
  final String teamName;
  final Color teamColor;
  final List<String> teammates;

  const ChallengeContender({
    required this.playerName,
    required this.teamName,
    required this.teamColor,
    this.teammates = const [],
  });
}

/// La cartouche gagnée, déjà tirée par l'appelant.
class ChallengeReward {
  final String modifierId;
  final String name;
  final bool isMalus;

  const ChallengeReward({
    required this.modifierId,
    required this.name,
    required this.isMalus,
  });
}

/// Un défi surprise, de l'écran coupé VS à la cartouche gagnée. Autonome : ne
/// lit ni le provider ni l'état de la partie, et ne donne rien lui-même.
class SurpriseChallengeScreen extends StatefulWidget {
  final SurpriseChallenge challenge;
  final ChallengeContender first;
  final ChallengeContender second;
  final ChallengeReward firstReward;
  final ChallengeReward secondReward;

  /// Le mot à faire deviner : obligatoire pour le téléphone arabe.
  final String? word;

  /// « Continuer » après la roulette, avec le gagnant. Appelé une seule fois.
  final ValueChanged<ChallengeContender> onFinished;

  /// « Passer ce défi », possible jusqu'à « Continuer » : un gagnant choisi par
  /// erreur n'engage rien. Appelé une seule fois.
  final VoidCallback onSkipped;

  final ChallengeSound sound;

  /// Coupe les sons en cours et en préparation, à toute sortie de l'écran.
  final VoidCallback stopSounds;

  const SurpriseChallengeScreen({
    required this.challenge,
    required this.first,
    required this.second,
    required this.firstReward,
    required this.secondReward,
    required this.onFinished,
    required this.onSkipped,
    this.word,
    this.sound = ChallengeSounds.play,
    this.stopSounds = ChallengeSounds.stop,
    super.key,
  }) : assert(challenge != SurpriseChallenge.mimeRelay || word != null);

  @override
  State<SurpriseChallengeScreen> createState() =>
      _SurpriseChallengeScreenState();
}

enum _Scene { versus, rule, action, pick, result }

class _SurpriseChallengeScreenState extends State<SurpriseChallengeScreen> {
  final _timers = <Timer>[];
  var _scene = _Scene.versus;
  var _closed = false;
  bool _firstWon = true;
  var _rouletteStep = 0;
  var _rouletteDone = false;

  ChallengeContender get _winner => _firstWon ? widget.first : widget.second;
  ChallengeReward get _reward =>
      _firstWon ? widget.firstReward : widget.secondReward;

  @override
  void initState() {
    super.initState();
    widget.sound('whoosh-cinematic', volume: 0.8);
    _timers
      ..add(Timer(const Duration(milliseconds: 320),
          () => widget.sound('impact-bass-2')))
      ..add(Timer(kVersusDuration, () => _goTo(_Scene.rule)));
  }

  @override
  void dispose() {
    _cancelTimers();
    widget.stopSounds();
    super.dispose();
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _goTo(_Scene scene) {
    _cancelTimers();
    setState(() => _scene = scene);
    if (scene == _Scene.pick) widget.sound('whoosh-short', volume: 0.7);
  }

  void _onScreenTap() {
    switch (_scene) {
      case _Scene.versus:
        _goTo(_Scene.rule);
      case _Scene.action when widget.challenge != SurpriseChallenge.clapping:
        _goTo(_Scene.pick);
      default:
        break;
    }
  }

  void _pickWinner(bool firstWon) {
    _firstWon = firstWon;
    _goTo(_Scene.result);
    if (MediaQuery.disableAnimationsOf(context)) {
      _stopRoulette();
      return;
    }
    widget.sound('click-soft', volume: 0.6);
    _timers.add(Timer.periodic(
      const Duration(milliseconds: _rouletteTick),
      (timer) {
        if (_rouletteStep + 1 >= _rouletteTicks) {
          timer.cancel();
          _stopRoulette();
          return;
        }
        setState(() => _rouletteStep++);
        widget.sound('click-soft', volume: 0.6);
      },
    ));
  }

  void _stopRoulette() {
    setState(() => _rouletteDone = true);
    widget.sound('chime');
    widget.sound('sparkle', volume: 0.6);
  }

  void _close(VoidCallback notify) {
    if (_closed) return;
    _closed = true;
    _cancelTimers();
    notify();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundMain,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onScreenTap,
              child: KeyedSubtree(
                key: ValueKey(_scene),
                child: _buildScene(),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () => _close(widget.onSkipped),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0x66000000),
                    ),
                    child: const Text(
                      'Passer ce défi',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScene() => switch (_scene) {
        _Scene.versus => _VersusScene(
            first: widget.first,
            second: widget.second,
            title: widget.challenge.title,
          ),
        _Scene.rule => _SceneFadeIn(
            child: _SceneWithButton(
              buttonText: 'C\'est parti',
              onPressed: () => _goTo(_Scene.action),
              children: [
                _BangText(widget.challenge.title, fontSize: 34),
                Text(
                  widget.challenge.rule(
                    widget.first.playerName,
                    widget.second.playerName,
                  ),
                  textAlign: TextAlign.center,
                  style: _ruleStyle,
                ),
              ],
            ),
          ),
        _Scene.action => _SceneFadeIn(
            child: _SceneBody(children: _buildAction()),
          ),
        _Scene.pick => _SceneFadeIn(
            child: _SceneBody(
              children: [
                const _BangText('Qui a gagné ?', fontSize: 40),
                _PickButton(widget.first, onTap: () => _pickWinner(true)),
                _PickButton(widget.second, onTap: () => _pickWinner(false)),
              ],
            ),
          ),
        _Scene.result => _SceneFadeIn(child: _buildResult()),
      };

  List<Widget> _buildAction() => switch (widget.challenge) {
        SurpriseChallenge.thumbWar => const [
            _EmojiRow([_Wobble('👍'), _Wobble('👍', reverse: true)]),
            _BangText('Coincez ce pouce !', fontSize: 36),
            _Hint('Touchez l\'écran quand c\'est fini.'),
          ],
        SurpriseChallenge.wallSit => const [
            _ElapsedClock(),
            _Hint('Touchez l\'écran quand l\'un des deux lâche.'),
          ],
        SurpriseChallenge.mimeRelay => [
            const _Hint('Le mot'),
            _BangText(widget.word!, fontSize: 36),
            _RelayChain(widget.first),
            _RelayChain(widget.second),
            const _Hint('Touchez l\'écran quand une équipe a trouvé.'),
          ],
        SurpriseChallenge.rockPaperScissors => const [_ChifoumiCall()],
        SurpriseChallenge.clapping => [
            const _EmojiRow([_Pulse('👏')]),
            _Countdown(onDone: () => _goTo(_Scene.pick)),
          ],
      };

  Widget _buildResult() {
    final malus =
        _rouletteDone ? _reward.isMalus : _rouletteItems[_rouletteIndex].$2;
    final color = malus ? AppColors.malus : AppColors.success;
    return _SceneWithButton(
      buttonText: 'Continuer',
      buttonVisible: _rouletteDone,
      onPressed: () => _close(() => widget.onFinished(_winner)),
      children: [
        Text(
          '${_winner.teamName} gagnent !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 34,
            height: 1.05,
            letterSpacing: 1,
            color: _winner.teamColor,
          ),
        ),
        Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          child: ModifierIcon(
            _rouletteDone
                ? _reward.modifierId
                : _rouletteItems[_rouletteIndex].$1,
            size: 80,
            color: color,
          ),
        ),
        Text(
          _rouletteDone
              ? '${_reward.name}, dans la réserve de l\'équipe.'
              : 'Cartouche au hasard…',
          textAlign: TextAlign.center,
          style: _ruleStyle.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  int get _rouletteIndex => _rouletteStep % _rouletteItems.length;
}

const _ruleStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 17,
  height: 1.45,
  fontWeight: FontWeight.w500,
  color: Colors.white,
);

const _displayStyle = TextStyle(
  fontFamily: 'Bangers',
  fontSize: 72,
  color: Colors.white,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Titre de scène en Bangers, avec l'ombre rose de l'app.
class _BangText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _BangText(this.text, {required this.fontSize});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: fontSize,
          height: 1.05,
          letterSpacing: 1,
          color: Colors.white,
          shadows: const [
            Shadow(color: AppColors.primaryPinkDark, offset: Offset(2, 2)),
          ],
        ),
      );
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: Color(0xFFCBD5E1),
        ),
      );
}

/// Entrée d'une scène : fondu et léger zoom.
class _SceneFadeIn extends StatelessWidget {
  final Widget child;

  const _SceneFadeIn({required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      ),
      child: child,
    );
  }
}

/// Contenu centré, sous « Passer ce défi », qui défile plutôt que de déborder.
class _SceneBody extends StatelessWidget {
  final List<Widget> children;

  const _SceneBody({required this.children});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 60, 22, 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0) const SizedBox(height: 16),
                      child,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _SceneWithButton extends StatelessWidget {
  final List<Widget> children;
  final String buttonText;
  final VoidCallback onPressed;
  final bool buttonVisible;

  const _SceneWithButton({
    required this.children,
    required this.buttonText,
    required this.onPressed,
    this.buttonVisible = true,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(child: _SceneBody(children: children)),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Visibility(
              visible: buttonVisible,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: AppButton(
                text: buttonText,
                onPressed: onPressed,
                size: AppButtonSize.large,
                fullWidth: true,
              ),
            ),
          ),
        ],
      );
}

/// Écran coupé en deux par une diagonale : un joueur de chaque côté, le VS au
/// centre, le nom du défi en bas.
class _VersusScene extends StatefulWidget {
  final ChallengeContender first;
  final ChallengeContender second;
  final String title;

  const _VersusScene({
    required this.first,
    required this.second,
    required this.title,
  });

  @override
  State<_VersusScene> createState() => _VersusSceneState();
}

class _VersusSceneState extends State<_VersusScene>
    with SingleTickerProviderStateMixin {
  static const _slide = Cubic(0.2, 1.2, 0.4, 1);
  static const _pop = Cubic(0.3, 1.8, 0.5, 1);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Avancement de 0 à 1 entre [start] et [end] ms, selon [curve].
  double _phase(double start, double end, Curve curve) => Interval(
        start / 800,
        end / 800,
        curve: curve,
      ).transform(_controller.value);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pieceHeight = constraints.maxHeight * 0.56;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final slide = _phase(0, 350, _slide);
            final rise = _phase(450, 800, Curves.ease);
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: pieceHeight,
                  child: Transform.translate(
                    offset: Offset(-(1 - slide) * width, 0),
                    child: _VersusPiece(widget.first, top: true),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: pieceHeight,
                  child: Transform.translate(
                    offset: Offset((1 - slide) * width, 0),
                    child: _VersusPiece(widget.second, top: false),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: _phase(300, 700, _pop),
                    child: Container(
                      width: 74,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.backgroundMain,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 26,
                  child: SafeArea(
                    top: false,
                    child: Opacity(
                      opacity: rise,
                      child: Transform.translate(
                        offset: Offset(0, 26 * (1 - rise)),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 32,
                            height: 1.05,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0xFF0B1220),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VersusPiece extends StatelessWidget {
  final ChallengeContender contender;
  final bool top;

  const _VersusPiece(this.contender, {required this.top});

  @override
  Widget build(BuildContext context) {
    final color = contender.teamColor;
    return ClipPath(
      clipper: _DiagonalClipper(top: top),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? const Alignment(-0.34, -0.94) : Alignment(0.34, 0.94),
            end: top ? const Alignment(0.34, 0.94) : Alignment(-0.34, -0.94),
            colors: [
              color.withValues(alpha: 0.75),
              color.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            contender.playerName,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 58,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  final bool top;

  const _DiagonalClipper({required this.top});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    if (top) {
      path.addPolygon(
        [Offset.zero, Offset(w, 0), Offset(w, h * 0.78), Offset(0, h)],
        true,
      );
    } else {
      path.addPolygon(
        [Offset(0, h * 0.22), Offset(w, 0), Offset(w, h), Offset(0, h)],
        true,
      );
    }
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) => oldClipper.top != top;
}

class _PickButton extends StatelessWidget {
  final ChallengeContender contender;
  final VoidCallback onTap;

  const _PickButton(this.contender, {required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: contender.teamColor, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            contender.playerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: contender.teamColor,
            ),
          ),
        ),
      );
}

class _EmojiRow extends StatelessWidget {
  final List<Widget> children;

  const _EmojiRow(this.children);

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 72, height: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(width: 22),
              child,
            ],
          ],
        ),
      );
}

/// Boucle aller-retour, à l'arrêt si les animations sont réduites.
abstract class _LoopState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController loop = AnimationController(
    vsync: this,
    duration: period,
  );

  Duration get period;
  bool get reverses => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      loop.stop();
    } else if (!loop.isAnimating) {
      loop.repeat(reverse: reverses);
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

class _Wobble extends StatefulWidget {
  final String emoji;
  final bool reverse;

  const _Wobble(this.emoji, {this.reverse = false});

  @override
  State<_Wobble> createState() => _WobbleState();
}

class _WobbleState extends _LoopState<_Wobble> {
  @override
  Duration get period => const Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final emoji = Text(widget.emoji);
    if (MediaQuery.disableAnimationsOf(context)) return emoji;
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(loop.value);
        final swing = widget.reverse ? 1 - 2 * t : 2 * t - 1;
        return Transform.translate(
          offset: Offset(0, -4 * swing),
          child: Transform.rotate(angle: swing * 16 * pi / 180, child: child),
        );
      },
      child: emoji,
    );
  }
}

class _Pulse extends StatefulWidget {
  final String emoji;

  const _Pulse(this.emoji);

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends _LoopState<_Pulse> {
  @override
  Duration get period => const Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final emoji = Text(widget.emoji);
    if (MediaQuery.disableAnimationsOf(context)) return emoji;
    return ScaleTransition(
      scale: Tween<double>(begin: 0.82, end: 1.18)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(loop),
      child: emoji,
    );
  }
}

/// « Ana → Léo → Sam » en couleur d'équipe ; le mime passe de nom en nom.
class _RelayChain extends StatefulWidget {
  final ChallengeContender contender;

  const _RelayChain(this.contender);

  @override
  State<_RelayChain> createState() => _RelayChainState();
}

class _RelayChainState extends _LoopState<_RelayChain> {
  static const _delay = 1 / 3;

  @override
  Duration get period => const Duration(milliseconds: 1200);

  @override
  bool get reverses => false;

  /// Opacité d'un nom au temps [t] du cycle : il s'allume de 10 à 20 %.
  double _opacity(double t) {
    if (t < 0.1) return 0.35 + 0.65 * t / 0.1;
    if (t < 0.2) return 1;
    if (t < 0.3) return 1 - 0.65 * (t - 0.2) / 0.1;
    return 0.35;
  }

  @override
  Widget build(BuildContext context) {
    final names = [
      widget.contender.playerName,
      ...widget.contender.teammates,
    ];
    final reduced = MediaQuery.disableAnimationsOf(context);
    final style = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: widget.contender.teamColor,
    );
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          for (final (i, name) in names.indexed) ...[
            if (i > 0) Text('→', style: style),
            Opacity(
              opacity: reduced ? 1 : _opacity((loop.value - i * _delay) % 1),
              child: Text(name, style: style),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chrono de « La chaise », en vraies secondes.
class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock();

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  late final Timer _timer;
  var _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds++),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
        textAlign: TextAlign.center,
        style: _displayStyle,
      );
}

/// Les 10 secondes de « Taper dans ses mains », en vraies secondes.
class _Countdown extends StatefulWidget {
  final VoidCallback onDone;

  const _Countdown({required this.onDone});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer;
  var _left = 10;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _left--);
      if (_left == 0) {
        timer.cancel();
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text('$_left', textAlign: TextAlign.center, style: _displayStyle);
}

/// « Chi… Fou… Mi ! », pour lancer les mains en même temps. Les poings restent
/// neutres : le résultat se joue avec les vraies mains.
class _ChifoumiCall extends StatefulWidget {
  const _ChifoumiCall();

  @override
  State<_ChifoumiCall> createState() => _ChifoumiCallState();
}

class _ChifoumiCallState extends State<_ChifoumiCall> {
  static const _words = ['Chi…', 'Fou…', 'Mi !'];
  static const _hands = ['✊', '✋', '✌️'];

  late final Timer _timer;
  var _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 750), (timer) {
      setState(() => _step++);
      if (_step == _words.length - 1) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _step == _words.length - 1;
    final reduced = MediaQuery.disableAnimationsOf(context);
    String hand(int offset) =>
        done || reduced ? '✊' : _hands[(_step + offset) % _hands.length];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BangText(_words[_step], fontSize: 46),
        const SizedBox(height: 16),
        _EmojiRow([Text(hand(0)), Text(hand(2))]),
        const SizedBox(height: 16),
        Visibility(
          visible: done,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: const _Hint('Touchez l\'écran quand c\'est fini.'),
        ),
      ],
    );
  }
}
