import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/fiesta_setup_widgets.dart';

/// Récapitulatif avant les Paramètres : la config Fiesta en attente, les
/// règles communes et les réglages de base (lus dans `GameSettings`).
class FiestaRecapScreen extends StatelessWidget {
  const FiestaRecapScreen({super.key});

  static const _arrivalLabels = {
    ModifierArrival.draw: 'tirage pour tous',
    ModifierArrival.offer: 'choix 1 parmi 3',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final rules = provider.pendingFiesta;
    // Rien en attente (ne devrait pas arriver) : retour au choix du mode.
    if (rules == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => provider.goToScreen(AppConstants.screenGameMode),
      );
      return const SizedBox.shrink();
    }
    final auto = rules.mode == FiestaMode.auto;
    final editScreen = auto
        ? AppConstants.screenFiestaAuto
        : AppConstants.screenFiestaEnsembles;
    final settings = provider.settings;

    return FiestaSetupScaffold(
      title: 'Prêts ?',
      onBack: () => provider.goToScreen(editScreen),
      content: [
        FiestaCard(
          title: 'Mode',
          trailing: AppButton(
            text: 'Modifier',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: () => provider.goToScreen(editScreen),
          ),
          children: [
            Text(
              auto
                  ? 'Fiesta · Auto'
                  : 'Fiesta · ${rules.ensembleName ?? 'Personnalisé'}',
              style: AppTextStyles.subtitle(fontSize: 26),
            ),
            const SizedBox(height: 4),
            ...auto ? _autoLines(rules) : _customLines(rules),
          ],
        ),
        FiestaCommonRulesCard(
          oneAnswer: rules.oneAnswer,
          carryOver: rules.carryOver,
        ),
        FiestaCard(
          title: 'Réglages de base',
          children: [
            _value('Équipes', '${settings.numberOfTeams}'),
            _value('Nombre total de mots', '${settings.totalWords}'),
            _value('Durée du tour', '${settings.turnDuration} s'),
            _value('Pénalité pour passer', '−${settings.passPenalty} s'),
          ],
        ),
      ],
      bottom: AppButton(
        text: 'Continuer',
        size: AppButtonSize.large,
        fullWidth: true,
        onPressed: () => provider.goToScreen(AppConstants.screenSettings),
      ),
    );
  }

  List<Widget> _autoLines(FiestaRules rules) {
    const c = CatchUpRules.auto;
    return [
      FiestaLine(
        label: 'Symétrique',
        detail: '1 à 2 modificateurs tirés par manche',
        value: rules.symmetric,
      ),
      FiestaLine(
        label: 'Auto-calibrage',
        detail: '+${c.b1} s / +${c.b2} s × écart (max +${c.cap} s) · '
            'leader −${c.mal} s × écart (max −${c.malCap} s) · '
            'coup de pouce du catalogue',
        value: rules.autoCalibrate,
      ),
    ];
  }

  List<Widget> _customLines(FiestaRules rules) {
    final c = rules.catchUp;
    final active = [
      for (final def in kModifierCatalog)
        if (rules.modifiers[def.id]?.active ?? false)
          (def, rules.modifiers[def.id]!),
    ];
    return [
      FiestaLine(
        label: 'Choix 1 parmi 3',
        detail: 'Équipe menée, à chaque fin de manche',
        value: rules.oneOfThree,
      ),
      FiestaLine(
        label: 'Rattrapage',
        detail: '+${c.b1} s / +${c.b2} s × écart (max +${c.cap} s) · '
            'leader −${c.mal} s × écart (max −${c.malCap} s)',
      ),
      FiestaLine(
        label: 'Tirage symétrique',
        detail:
            rules.drawCount > 0 ? '${rules.drawCount} par manche' : 'Désactivé',
        value: rules.drawCount > 0,
      ),
      FiestaLine(
        label: 'Modificateurs actifs (${active.length})',
        detail: active.isEmpty
            ? 'Aucun'
            : active
                .map((e) => '${e.$1.name} · '
                    '${e.$2.arrival == ModifierArrival.fixed ? 'manche ${e.$2.fixedRound ?? 3}' : _arrivalLabels[e.$2.arrival]}')
                .join('\n'),
      ),
    ];
  }

  Widget _value(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            Text(value, style: AppTextStyles.label),
          ],
        ),
      );
}
