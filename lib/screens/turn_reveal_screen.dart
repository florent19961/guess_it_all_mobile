import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fiesta/modifier_catalog.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/modifier_badge.dart';

/// « Ce qui t'attend » : entre « Commencer le tour » et le décompte, ce que le
/// joueur découvre (cartouche tombée, malus reçus qui jouent à ce tour) puis
/// ce qu'il connaissait déjà (règles de la manche, ses bonus). Pas de retour : l'avant-tour
/// permettrait de réarmer en connaissant les malus. Une app tuée y revient.
class TurnRevealScreen extends StatelessWidget {
  const TurnRevealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final drop = provider.droppedThisTurn;
    // « Bloquer un devineur » : qui ne répond pas.
    String? title(String id) => id == 'block_guesser'
        ? '${provider.blockedGuesser?.name ?? ''} '
            '${modifierById(id)!.turnLabel}'
        : null;
    final known = [
      for (final m in provider.roundRulesThisTurn)
        _Line(m.catalogId, 'Règle de la manche', Colors.white, filled: false),
      for (final id in provider.bonusesThisTurn)
        _Line(id, 'Ton bonus', AppColors.success),
    ];
    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.backgroundMain,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CE QUI T\'ATTEND',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(fontSize: 34),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Section('ON VIENT DE T\'INFLIGER',
                            color: AppColors.malus),
                        // Cartouche tombée du ciel (D4) : en tête, même un
                        // bonus.
                        if (drop != null)
                          _Line(
                              drop.catalogId,
                              'Tombée du ciel',
                              modifierColor(
                                  modifierById(drop.catalogId)!.nature),
                              originColor: AppColors.warning,
                              title: title(drop.catalogId)),
                        for (final m in provider.receivedThisTurn)
                          _Line(m.catalogId, provider.malusSender(m),
                              AppColors.malus,
                              title: title(m.catalogId)),
                        if (known.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const _Section('DÉJÀ ACTIVÉ',
                              color: AppColors.gray400),
                          ...known,
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'C\'est parti',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: provider.leaveTurnReveal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  final Color color;

  const _Section(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: color,
          ),
        ),
      );
}

/// Une ligne : cercle d'icône, nom du modificateur, provenance.
class _Line extends StatelessWidget {
  final String id;
  final String origin;
  final Color color;
  final bool filled;
  final String? title;
  final Color originColor;

  const _Line(this.id, this.origin, this.color,
      {this.filled = true, this.title, this.originColor = AppColors.gray400});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? color.withValues(alpha: 0.18) : null,
                border: Border.all(color: color, width: 2),
              ),
              child: ModifierIcon(id, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? modifierById(id)?.name ?? id,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    origin,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: originColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
