import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../services/fiesta_ensemble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_confirm_dialog.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';
import 'fiesta_ensemble_editor_screen.dart';

/// Brouillon de l'éditeur gardé en mémoire tant que l'app est ouverte
/// (jamais persisté) : [ensembleId] nul = un nouvel ensemble.
class EnsembleDraft {
  final String? ensembleId;
  final FiestaRules rules;
  const EnsembleDraft(this.ensembleId, this.rules);
}

/// « Fiesta personnalisée » : juste après les Paramètres, avant les joueurs
/// (Fiesta Personnalisé seulement). Les ensembles fournis par l'app puis les
/// miens (un tap sélectionne), « Créer un ensemble » qui POUSSE l'éditeur
/// (`FiestaEnsembleEditorScreen`), en bas « Suivant ».
///
/// L'écran ne connaît ni le provider ni la navigation de l'app : [onNext]
/// reçoit les règles de l'ensemble choisi (mode `custom`, `ensembleName` =
/// nom), prêtes à attendre dans `pendingFiesta`. [selected] (l'attente
/// courante, ex. après « Rejouer ») présélectionne l'ensemble aux mêmes
/// règles ; sinon le dernier utilisé, sinon « Fiesta classique ».
class FiestaEnsemblesScreen extends StatefulWidget {
  final FiestaRules? selected;
  final VoidCallback onBack;
  final ValueChanged<FiestaRules> onNext;

  const FiestaEnsemblesScreen({
    required this.onBack,
    required this.onNext,
    this.selected,
    super.key,
  });

  /// Brouillon de l'éditeur, en mémoire seulement (spec Fiesta v2 §4).
  static EnsembleDraft? draft;

  @override
  State<FiestaEnsemblesScreen> createState() => _FiestaEnsemblesScreenState();
}

class _FiestaEnsemblesScreenState extends State<FiestaEnsemblesScreen> {
  final _service = FiestaEnsembleService();
  final _readyKey = GlobalKey();
  final _createKey = GlobalKey();
  final _nextKey = GlobalKey();

  EnsembleStore? _store;
  String? _selectedId;

  /// Un double tap ne doit pas naviguer deux fois.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<FiestaEnsemble> get _mine => _store?.ensembles ?? const [];

  List<FiestaEnsemble> get _ready => [...kProvidedEnsembles, ..._mine];

  bool get _full => _mine.length >= FiestaEnsembleService.maxEnsembles;

  static String _sameRules(FiestaRules rules) => jsonEncode(rules.toJson());

  /// Premier affichage : l'ensemble aux règles de l'attente courante, sinon
  /// le dernier utilisé, sinon « Fiesta classique ».
  Future<void> _load() async {
    final store = await _service.load();
    if (!mounted) return;
    _store = store;
    final pending = widget.selected;
    final match = pending == null
        ? null
        : _ready
            .where((e) => _sameRules(e.rules) == _sameRules(pending))
            .firstOrNull;
    final lastUsed = _ready.where((e) => e.id == store.lastUsedId).firstOrNull;
    setState(() => _selectedId = (match ?? lastUsed)?.id ?? kClassicEnsembleId);
  }

  Future<void> _reload({String? select}) async {
    final store = await _service.load();
    if (!mounted) return;
    setState(() {
      _store = store;
      if (select != null) _selectedId = select;
      if (!_ready.any((e) => e.id == _selectedId)) {
        _selectedId = kClassicEnsembleId;
      }
    });
  }

  /// Ouvre l'éditeur : création (reprend le brouillon s'il y en a un) ou
  /// modification de [ensemble] (reprend son brouillon s'il en a un).
  Future<void> _openEditor({FiestaEnsemble? ensemble}) async {
    if (_busy) return;
    _busy = true;
    try {
      final draft = FiestaEnsemblesScreen.draft;
      final resumed =
          draft != null && draft.ensembleId == ensemble?.id ? draft : null;
      final result = await Navigator.of(context).push<EnsembleEditorResult>(
        MaterialPageRoute(
          builder: (_) => FiestaEnsembleEditorScreen(
            initial: ensemble,
            draft: resumed?.rules,
            others: [
              for (final e in _ready)
                if (e.id != ensemble?.id) e,
            ],
          ),
        ),
      );
      if (!mounted) return;
      switch (result) {
        case EnsembleSaved(:final ensemble):
          FiestaEnsemblesScreen.draft = null;
          await _reload(select: ensemble.id);
        case EnsembleDraftKept(:final rules):
          setState(() =>
              FiestaEnsemblesScreen.draft = EnsembleDraft(ensemble?.id, rules));
          if (mounted) {
            // Flottant au-dessus de « Suivant », qu'il ne doit pas masquer.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Brouillon gardé'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.fromLTRB(20, 0, 20, 90),
            ));
          }
        case null:
          // Sorti sans rien garder : un brouillon repris est abandonné.
          if (resumed != null) {
            setState(() => FiestaEnsemblesScreen.draft = null);
          }
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _duplicate(FiestaEnsemble ensemble) async {
    final copy = await _service.duplicate(ensemble);
    await _reload(select: copy?.id);
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
    if (FiestaEnsemblesScreen.draft?.ensembleId == ensemble.id) {
      FiestaEnsemblesScreen.draft = null;
    }
    await _reload();
  }

  Future<void> _next() async {
    final chosen = _ready.where((e) => e.id == _selectedId).firstOrNull;
    if (chosen == null || _busy) return;
    _busy = true;
    try {
      await _service.markUsed(chosen.id);
      if (mounted) widget.onNext(chosen.rules);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    // Retour système (Android) = [onBack], pas la sortie de l'app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundMain,
        body: ShootingStars(
          child: Stack(
            children: [
              SafeArea(
                child: store == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryCyan,
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildBody()),
                          _buildNextBar(),
                        ],
                      ),
              ),
              AppBackButton(onPressed: widget.onBack),
              HelpButton(
                onPressed: () => CoachMarks.show(
                  context,
                  fiestaEnsemblesHelp(
                    ready: _readyKey,
                    create: _createKey,
                    next: _nextKey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final newDraft = FiestaEnsemblesScreen.draft?.ensembleId == null &&
        FiestaEnsemblesScreen.draft != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
      children: [
        Text(
          'Fiesta personnalisée',
          style: AppTextStyles.subtitle(fontSize: 34),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        KeyedSubtree(
          key: _readyKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PRÊTS À JOUER',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.gray400, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${_mine.length} / ${FiestaEnsembleService.maxEnsembles}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gray400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final ensemble in _ready)
                _EnsembleCard(
                  ensemble: ensemble,
                  selected: ensemble.id == _selectedId,
                  canDuplicate: !_full,
                  onTap: () => setState(() => _selectedId = ensemble.id),
                  onEdit: () => _openEditor(ensemble: ensemble),
                  onDuplicate: () => _duplicate(ensemble),
                  onDelete: () => _delete(ensemble),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _createKey,
          child: _full && !newDraft
              ? _Alert(
                  'Limite de ${FiestaEnsembleService.maxEnsembles} ensembles '
                  'atteinte. Supprime un ensemble pour en créer un nouveau.',
                )
              : AppButton(
                  text:
                      newDraft ? 'Reprendre le brouillon' : 'Créer un ensemble',
                  icon: const Icon(Icons.add, size: 20),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  fullWidth: true,
                  onPressed: () => _openEditor(),
                ),
        ),
      ],
    );
  }

  Widget _buildNextBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: AppColors.backgroundMain,
      child: AppButton(
        key: _nextKey,
        text: 'Suivant',
        variant: AppButtonVariant.primary,
        size: AppButtonSize.large,
        fullWidth: true,
        disabled: _selectedId == null,
        onPressed: _selectedId == null ? null : _next,
      ),
    );
  }
}

class _EnsembleCard extends StatelessWidget {
  final FiestaEnsemble ensemble;
  final bool selected;
  final bool canDuplicate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _EnsembleCard({
    required this.ensemble,
    required this.selected,
    required this.canDuplicate,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  /// « N malus · M bonus » (maquette `summaryOf`).
  String get _summary {
    var malus = 0;
    var bonus = 0;
    for (final def in kModifierCatalog) {
      if (ensemble.rules.activeSetting(def.id) == null) continue;
      def.nature == ModifierNature.malus ? malus++ : bonus++;
    }
    return '$malus malus · $bonus bonus';
  }

  @override
  Widget build(BuildContext context) {
    final provided = ensemble.isProvided;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondaryCyan.withValues(alpha: 0.12)
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.secondaryCyan : AppColors.gray700,
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
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        selected ? AppColors.secondaryCyan : AppColors.gray500,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                provided ? 'Fourni par l\'app · $_summary' : _summary,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.gray400, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!provided)
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
                  if (!provided)
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
        ),
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
