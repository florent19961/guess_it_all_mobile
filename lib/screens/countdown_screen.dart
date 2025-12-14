import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int _countdown = 3;
  bool _showGo = false;
  Timer? _timer;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late bool _isFirstTurnOfRound;

  @override
  void initState() {
    super.initState();

    // Vérifier si c'est le premier tour de la manche
    final provider = context.read<GameProvider>();
    _isFirstTurnOfRound = provider.game.currentTurnIndex == 0;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _scaleController.forward(from: 0);

    // Durée entre chaque chiffre : 1s pour le premier tour, 500ms sinon
    final tickDuration = _isFirstTurnOfRound
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 500);

    _timer = Timer.periodic(tickDuration, (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
        _scaleController.forward(from: 0);
      } else {
        timer.cancel();
        setState(() {
          _showGo = true;
        });
        _scaleController.forward(from: 0);

        // Attendre un peu puis démarrer le tour (800ms pour premier tour, 400ms sinon)
        final goDelay = _isFirstTurnOfRound
            ? const Duration(milliseconds: 800)
            : const Duration(milliseconds: 400);
        Future.delayed(goDelay, () {
          if (mounted) {
            context.read<GameProvider>().startTurnTimer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final currentTeam = provider.getCurrentTeam();
    final currentPlayer = provider.getCurrentPlayer();
    final teamColor = AppColors.getTeamColor(provider.game.currentTeamIndex);

    return Material(
      color: AppColors.backgroundMain,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Team and player info
            Text(
              currentTeam?.name ?? '',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 28,
                color: teamColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentPlayer?.name ?? '',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 48),

            // Countdown or GO
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: _showGo
                  ? Text(
                      'GO !',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 120,
                        color: AppColors.secondaryCyan,
                        shadows: [
                          Shadow(
                            offset: const Offset(4, 4),
                            color: AppColors.secondaryCyanDark,
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    )
                  : Text(
                      '$_countdown',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 160,
                        color: AppColors.getTeamColor(0),
                        shadows: [
                          Shadow(
                            offset: const Offset(4, 4),
                            color: AppColors.getTeamColor(0).withOpacity(0.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 48),

            // Round mode reminder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Manche ${provider.game.currentRound}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.roundModes[provider.game.currentRound] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
}
