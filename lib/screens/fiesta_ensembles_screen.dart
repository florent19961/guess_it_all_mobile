import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../services/fiesta_ensemble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_confirm_dialog.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/fiesta/fiesta_ensemble_editor.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

/// « Fiesta personnalisée » : juste après les Paramètres, avant les joueurs
/// (Fiesta Personnalisé seulement). Un seul écran, sans page poussée : en
/// haut les ensembles prêts à jouer (un tap sélectionne), en dessous
/// l'éditeur, en bas « Suivant ».
///
/// L'écran ne connaît ni le provider ni la navigation : [onNext] reçoit les
/// règles de l'ensemble choisi (mode `custom`, `ensembleName` = nom), prêtes
/// à attendre dans `pendingFiesta`. [selected] (l'attente courante, ex. après
/// « Rejouer ») présélectionne l'ensemble aux mêmes règles.
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

  /// Ensemble fourni par l'app quand aucun n'est enregistré : les réglages
  /// par défaut d'un nouvel ensemble. Jamais écrit dans le stockage.
  static final builtIn = FiestaEnsemble(
    id: '_builtin',
    rules: defaultEnsembleRules('Fiesta classique'),
  );

  @override
  State<FiestaEnsemblesScreen> createState() => _FiestaEnsemblesScreenState();
}

class _FiestaEnsemblesScreenState extends State<FiestaEnsemblesScreen> {
  final _service = FiestaEnsembleService();
  final _readyKey = GlobalKey();
  final _editorKey = GlobalKey();
  final _nextKey = GlobalKey();

  EnsembleStore? _store;
  String? _selectedId;

  /// Ensemble chargé dans l'éditeur (nul = création).
  FiestaEnsemble? _editing;

  /// Change à chaque remise à zéro de l'éditeur (nouvelle `key`).
  int _editorRun = 0;

  /// L'éditeur diffère de ce qu'il a chargé (remonté par l'éditeur à chaque
  /// rendu ; simple champ, rien à redessiner).
  bool _dirty = false;

  /// Un double tap sur « Suivant » ne doit pas naviguer deux fois.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<FiestaEnsemble> get _ready {
    final saved = _store?.ensembles ?? const [];
    return saved.isEmpty ? [FiestaEnsemblesScreen.builtIn] : saved;
  }

  bool get _full =>
      (_store?.ensembles.length ?? 0) >= FiestaEnsembleService.maxEnsembles;

  static String _sameRules(FiestaRules rules) => jsonEncode(rules.toJson());

  /// Premier affichage : l'ensemble aux règles de l'attente courante, sinon
  /// le dernier utilisé.
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
    setState(() => _selectedId = (match ?? lastUsed)?.id);
  }

  Future<void> _reload({String? select}) async {
    final store = await _service.load();
    if (!mounted) return;
    setState(() {
      _store = store;
      if (select != null) _selectedId = select;
      if (!_ready.any((e) => e.id == _selectedId)) _selectedId = null;
    });
  }

  /// LA porte unique de l'éditeur. Toute action qui change la sélection ou
  /// le contenu de l'éditeur (sélectionner, Modifier, Dupliquer, Supprimer,
  /// Annuler, Retour, Suivant) passe par ici : si la saisie diffère de ce qui
  /// a été chargé — brouillon neuf ou modification, peu importe —, on demande
  /// avant de la jeter. Accepté (ou rien en cours) : l'éditeur repart vierge,
  /// [editing] y est chargé, et l'action continue. L'éditeur ne contredit
  /// donc jamais la sélection, et rien n'est perdu en silence.
  Future<bool> _leaveDraft({FiestaEnsemble? editing}) async {
    if (_dirty &&
        !await AppConfirmDialog.show(
          context,
          title: 'Abandonner les modifications ?',
          message: 'L\'ensemble en cours n\'est pas enregistré.',
          confirmText: 'Abandonner',
          accentColor: AppColors.warning,
        )) {
      return false;
    }
    if (!mounted) return false;
    setState(() {
      _editing = editing;
      _editorRun++;
      _dirty = false;
    });
    return true;
  }

  Future<void> _back() async {
    if (await _leaveDraft()) widget.onBack();
  }

  Future<void> _select(FiestaEnsemble ensemble) async {
    if (await _leaveDraft()) setState(() => _selectedId = ensemble.id);
  }

  /// Modifier sélectionne aussi l'ensemble (éditeur et sélection d'accord).
  Future<void> _edit(FiestaEnsemble ensemble) async {
    if (!await _leaveDraft(editing: ensemble)) return;
    setState(() => _selectedId = ensemble.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _editorKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(target,
            duration: const Duration(milliseconds: 300));
      }
    });
  }

  Future<void> _duplicate(FiestaEnsemble ensemble) async {
    if (!await _leaveDraft()) return;
    final copy = await _service.duplicate(ensemble.id);
    await _reload(select: copy?.id);
  }

  Future<void> _delete(FiestaEnsemble ensemble) async {
    if (!await _leaveDraft() || !mounted) return;
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

  /// Enregistré : pas de brouillon à abandonner, l'éditeur repart vierge.
  Future<void> _onSaved(FiestaEnsemble ensemble) async {
    setState(() {
      _editing = null;
      _editorRun++;
      _dirty = false;
    });
    await _reload(select: ensemble.id);
  }

  Future<void> _next() async {
    final chosen = _ready.where((e) => e.id == _selectedId).firstOrNull;
    if (chosen == null || _leaving) return;
    _leaving = true;
    try {
      if (!await _leaveDraft()) return;
      if (chosen.id != FiestaEnsemblesScreen.builtIn.id) {
        await _service.markUsed(chosen.id);
      }
      if (mounted) widget.onNext(chosen.rules);
    } finally {
      _leaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    // Retour système (Android) = [onBack], pas la sortie de l'app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
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
                          Expanded(child: _buildBody(store)),
                          _buildNextBar(),
                        ],
                      ),
              ),
              AppBackButton(onPressed: _back),
              HelpButton(
                onPressed: () => CoachMarks.show(
                  context,
                  fiestaEnsemblesHelp(
                    ready: _readyKey,
                    editor: _editorKey,
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

  Widget _buildBody(EnsembleStore store) {
    final builtIn = store.ensembles.isEmpty;
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
                  if (!builtIn)
                    Text(
                      '${store.ensembles.length} / '
                      '${FiestaEnsembleService.maxEnsembles}',
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
                  builtIn: builtIn,
                  canDuplicate: !_full,
                  onTap: () => _select(ensemble),
                  onEdit: () => _edit(ensemble),
                  onDuplicate: () => _duplicate(ensemble),
                  onDelete: () => _delete(ensemble),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _editorKey,
          child: _editing == null && _full
              ? _Alert(
                  'Limite de ${FiestaEnsembleService.maxEnsembles} ensembles '
                  'atteinte. Supprime un ensemble pour en créer un nouveau.',
                )
              : FiestaEnsembleEditor(
                  key: ValueKey(_editorRun),
                  initial: _editing,
                  onSaved: _onSaved,
                  onCancel: _editing == null ? null : _leaveDraft,
                  onDirty: (dirty) => _dirty = dirty,
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
  final bool builtIn;
  final bool canDuplicate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _EnsembleCard({
    required this.ensemble,
    required this.selected,
    required this.builtIn,
    required this.canDuplicate,
    required this.onTap,
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
        '${catchUpOn(rules.catchUp) ? 'rattrapage' : 'sans rattrapage'} · $draw'
        '${rules.oneAnswer ? ' · une seule réponse' : ''}';
  }

  @override
  Widget build(BuildContext context) {
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
                builtIn ? 'Fourni par l\'app · $_summary' : _summary,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.gray400, fontSize: 12),
              ),
              if (!builtIn) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
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
