import 'package:flutter/material.dart';

import '../models/fiesta/fiesta_ensemble.dart';
import '../services/fiesta_ensemble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_confirm_dialog.dart';
import '../widgets/help/help_button.dart';
import 'fiesta_ensemble_editor_screen.dart';
import 'fiesta_tutorial_screen.dart';

/// « Mes ensembles » (maquette `perso`) : les ensembles du mode Personnalisé.
///
/// Point d'entrée de la story 2-4 : l'écran ne connaît ni le provider ni la
/// navigation de l'app. [onUse] reçoit l'ensemble choisi (déjà marqué
/// « dernier utilisé ») ; [onBack] ramène à l'écran précédent.
class FiestaEnsemblesScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<FiestaEnsemble> onUse;

  const FiestaEnsemblesScreen({
    required this.onBack,
    required this.onUse,
    super.key,
  });

  @override
  State<FiestaEnsemblesScreen> createState() => _FiestaEnsemblesScreenState();
}

class _FiestaEnsemblesScreenState extends State<FiestaEnsemblesScreen> {
  final _service = FiestaEnsembleService();
  EnsembleStore? _store;

  /// Un double tap sur « Utiliser » ne doit pas naviguer deux fois.
  bool _using = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final store = await _service.load();
    if (mounted) setState(() => _store = store);
  }

  bool get _full =>
      (_store?.ensembles.length ?? 0) >= FiestaEnsembleService.maxEnsembles;

  Future<void> _openEditor([FiestaEnsemble? ensemble]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FiestaEnsembleEditorScreen(initial: ensemble),
      ),
    );
    if (saved == true) await _reload();
  }

  Future<void> _use(FiestaEnsemble ensemble) async {
    if (_using) return;
    _using = true;
    try {
      await _service.markUsed(ensemble.id);
      if (mounted) widget.onUse(ensemble);
    } finally {
      _using = false;
    }
  }

  Future<void> _duplicate(FiestaEnsemble ensemble) async {
    await _service.duplicate(ensemble.id);
    await _reload();
  }

  Future<void> _delete(FiestaEnsemble ensemble) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Supprimer ?',
      message: '« ${ensemble.name} » sera supprimé définitivement.',
      confirmText: 'Supprimer',
      accentColor: AppColors.error,
    );
    if (!confirmed) return;
    await _service.delete(ensemble.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Material(
      color: AppColors.backgroundMain,
      child: Stack(
        children: [
          SafeArea(
            child: store == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryCyan,
                    ),
                  )
                : _buildList(store),
          ),
          AppBackButton(onPressed: widget.onBack),
          HelpButton(onPressed: () => FiestaTutorialScreen.show(context)),
        ],
      ),
    );
  }

  Widget _buildList(EnsembleStore store) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
      children: [
        Text(
          'Mes ensembles',
          style: AppTextStyles.subtitle(fontSize: 36),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(
          text: '+ Créer un ensemble',
          fullWidth: true,
          disabled: _full,
          onPressed: () => _openEditor(),
        ),
        if (_full) ...[
          const SizedBox(height: 12),
          _Alert(
            'Limite de ${FiestaEnsembleService.maxEnsembles} ensembles '
            'atteinte. Supprime un ensemble pour en créer un nouveau.',
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '${store.ensembles.length} / ${FiestaEnsembleService.maxEnsembles}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        if (store.ensembles.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'Aucun ensemble. Crée le premier !',
              style: AppTextStyles.body.copyWith(color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
          ),
        for (final ensemble in store.ensembles)
          _EnsembleCard(
            ensemble: ensemble,
            lastUsed: ensemble.id == store.lastUsedId,
            canDuplicate: !_full,
            onUse: () => _use(ensemble),
            onEdit: () => _openEditor(ensemble),
            onDuplicate: () => _duplicate(ensemble),
            onDelete: () => _delete(ensemble),
          ),
      ],
    );
  }
}

class _EnsembleCard extends StatelessWidget {
  final FiestaEnsemble ensemble;
  final bool lastUsed;
  final bool canDuplicate;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _EnsembleCard({
    required this.ensemble,
    required this.lastUsed,
    required this.canDuplicate,
    required this.onUse,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  String get _summary {
    final rules = ensemble.rules;
    final active = rules.modifiers.values.where((m) => m.active).length;
    final draw = rules.symmetric && rules.drawCount > 0
        ? 'tirage ${rules.drawCount}/manche'
        : 'sans tirage';
    return '$active modificateurs · '
        '${rules.oneOfThree ? 'choix 1 parmi 3' : 'pas de choix'} · '
        '${catchUpOn(rules.catchUp) ? 'rattrapage' : 'sans rattrapage'} · $draw';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lastUsed ? AppColors.secondaryCyan : AppColors.gray700,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ensemble.name, style: AppTextStyles.label),
              ),
              if (lastUsed)
                Text(
                  'dernier utilisé',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryCyan,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _summary,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.gray400, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                text: 'Utiliser',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: onUse,
              ),
              AppButton(
                text: 'Modifier',
                size: AppButtonSize.small,
                variant: AppButtonVariant.ghost,
                onPressed: onEdit,
              ),
              AppButton(
                text: 'Dupliquer',
                size: AppButtonSize.small,
                variant: AppButtonVariant.ghost,
                disabled: !canDuplicate,
                onPressed: onDuplicate,
              ),
              AppButton(
                text: 'Supprimer',
                size: AppButtonSize.small,
                variant: AppButtonVariant.danger,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Alert extends StatelessWidget {
  final String text;
  const _Alert(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.warning, fontSize: 13),
      ),
    );
  }
}
