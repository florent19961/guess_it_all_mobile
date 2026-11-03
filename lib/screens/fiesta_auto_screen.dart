import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fiesta/fiesta_rules.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import '../widgets/fiesta/fiesta_setup_widgets.dart';

/// Mode Auto : deux interrupteurs cumulables (au moins un allumé) et les
/// règles communes.
class FiestaAutoScreen extends StatefulWidget {
  const FiestaAutoScreen({super.key});

  @override
  State<FiestaAutoScreen> createState() => _FiestaAutoScreenState();
}

class _FiestaAutoScreenState extends State<FiestaAutoScreen> {
  // Revenir du Récap par « Modifier » retrouve les réglages en attente.
  late final FiestaRules? _previous = () {
    final pending = context.read<GameProvider>().pendingFiesta;
    return pending?.mode == FiestaMode.auto ? pending : null;
  }();
  late bool _symmetric = _previous?.symmetric ?? true;
  late bool _autoCalibrate = _previous?.autoCalibrate ?? true;
  late bool _oneAnswer = _previous?.oneAnswer ?? true;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    final none = !_symmetric && !_autoCalibrate;
    const auto = CatchUpRules.auto;
    return FiestaSetupScaffold(
      title: 'Mode Auto',
      subtitle: 'Aucun choix pendant la partie : l\'app s\'occupe de tout.',
      onBack: () => provider.goToScreen(AppConstants.screenFiestaChoice),
      content: [
        FiestaCard(
          title: 'Symétrique',
          trailing: _switch(_symmetric, (v) => _symmetric = v),
          children: const [
            FiestaHint(
              'Au début de chaque manche, l\'app tire 1 à 2 modificateurs qui '
              's\'appliquent à toutes les équipes. Pas de relance.',
            ),
          ],
        ),
        FiestaCard(
          title: 'Auto-calibrage (rattrapage)',
          trailing: _switch(_autoCalibrate, (v) => _autoCalibrate = v),
          children: [
            const FiestaHint(
              'L\'app aide automatiquement l\'équipe qui est derrière. L\'écart '
              'se mesure par rapport à l\'équipe en tête.',
            ),
            if (_autoCalibrate) ...[
              const SizedBox(height: 8),
              FiestaHint(
                'Équipes menées : +${auto.b1} s × écart après M1, '
                '+${auto.b2} s × écart après M2 (max +${auto.cap} s).\n'
                'Équipe en tête : −${auto.mal} s × écart sur son 1ᵉʳ tour '
                '(max −${auto.malCap} s).\n'
                'Selon l\'écart, l\'app peut aussi donner un bonus aux équipes '
                'menées et un malus à l\'équipe en tête.',
              ),
            ],
          ],
        ),
        FiestaCommonRulesCard(
          oneAnswer: _oneAnswer,
          onChanged: ({oneAnswer}) => setState(() {
            _oneAnswer = oneAnswer ?? _oneAnswer;
          }),
        ),
      ],
      bottom: Column(
        children: [
          if (none) ...[
            Text(
              'Active au moins un des deux interrupteurs pour continuer.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
            const SizedBox(height: 8),
          ],
          AppButton(
            text: 'Continuer',
            size: AppButtonSize.large,
            fullWidth: true,
            disabled: none,
            onPressed: none
                ? null
                : () {
                    provider.setPendingFiesta(
                      FiestaRules(
                        mode: FiestaMode.auto,
                        symmetric: _symmetric,
                        autoCalibrate: _autoCalibrate,
                        oneAnswer: _oneAnswer,
                      ),
                    );
                    provider.goToScreen(AppConstants.screenFiestaRecap);
                  },
          ),
        ],
      ),
    );
  }

  Widget _switch(bool value, void Function(bool) set) => Switch(
        value: value,
        onChanged: (v) => setState(() => set(v)),
        activeTrackColor: AppColors.secondaryCyan,
      );
}
