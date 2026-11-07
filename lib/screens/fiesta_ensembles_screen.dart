import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/fiesta/ensemble_summary.dart';
import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../services/fiesta_ensemble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_confirm_dialog.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/fiesta/modifier_badge.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';
import 'fiesta_ensemble_editor_screen.dart';
import 'fiesta_ensemble_view_screen.dart';

/// Icône d'un ensemble : choisie à la main pour les fournis, déduite des règles
/// pour les miens (ni étape dans l'éditeur, ni stockage).
IconData ensembleIcon(FiestaEnsemble ensemble) {
  final provided = _providedIcons[ensemble.id];
  if (provided != null) return provided;
  if (rulesDraw(ensemble.rules)) return Icons.casino_outlined;
  if (rulesHaveCartridges(ensemble.rules)) return Icons.bolt;
  return _crown;
}

/// Material Icons n'a pas de couronne : la coupe, au plus près.
const IconData _crown = Icons.emoji_events_outlined;

const Map<String, IconData> _providedIcons = {
  kClassicEnsembleId: Icons.casino_outlined,
  '${kProvidedIdPrefix}last': Icons.trending_up,
  '${kProvidedIdPrefix}pro': _crown,
  '${kProvidedIdPrefix}straight': Icons.track_changes,
  '${kProvidedIdPrefix}pictionary': Icons.edit_outlined,
  '${kProvidedIdPrefix}bilingual': Icons.language,
  '${kProvidedIdPrefix}explosive': Icons.bolt,
  '${kProvidedIdPrefix}expert': Icons.volume_up_outlined,
};

/// La liste des ensembles : ouverte depuis Avancés sur les Paramètres (Fiesta
/// seulement). Les ensembles fournis par l'app puis les
/// miens (un tap sélectionne et déplie), « Créer un ensemble » qui POUSSE l'éditeur
/// (`FiestaEnsembleEditorScreen`), en bas « Valider ».
///
/// L'écran ne connaît ni le provider ni la navigation de l'app : [onValidate]
/// reçoit les règles de l'ensemble choisi (`ensembleName` = nom), prêtes à attendre dans `pendingFiesta`. [selected] (l'attente
/// courante, ex. après « Rejouer ») présélectionne l'ensemble aux mêmes
/// règles ; sinon le dernier utilisé, sinon « Fiesta classique ».
class FiestaEnsemblesScreen extends StatefulWidget {
  final FiestaRules? selected;
  final VoidCallback onBack;
  final ValueChanged<FiestaRules> onValidate;

  const FiestaEnsemblesScreen({
    required this.onBack,
    required this.onValidate,
    this.selected,
    super.key,
  });

  /// Brouillons de l'éditeur, en mémoire seulement tant que l'app est
  /// ouverte (spec Fiesta v2 §4) : un par ensemble modifié (son id), et un
  /// pour la création ([newDraftKey]). Chaque éditeur ne lit, n'écrit et
  /// n'efface que le sien : aucun brouillon n'en écrase un autre.
  static final Map<String, FiestaRules> drafts = {};

  /// Clé du brouillon d'un nouvel ensemble (jamais un id : ids uuid ou
  /// `provided_*`).
  static const newDraftKey = '';

  @override
  State<FiestaEnsemblesScreen> createState() => _FiestaEnsemblesScreenState();
}

/// Bande des boutons retour et « ? » : la liste défile sous elle, jamais dessous.
const double _buttonsBand = 72;

class _FiestaEnsemblesScreenState extends State<FiestaEnsemblesScreen> {
  final _service = FiestaEnsembleService();
  final _readyKey = GlobalKey();
  final _firstMineKey = GlobalKey();
  final _createKey = GlobalKey();
  final _validateKey = GlobalKey();
  final _selectedRowKey = GlobalKey();
  final _scroll = ScrollController();

  EnsembleStore? _store;
  String? _selectedId;

  /// Un double tap ne doit pas naviguer deux fois.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
    _revealSelected();
  }

  void _select(String id) {
    setState(() => _selectedId = id);
    _revealSelected();
  }

  /// Après le dépliage, la ligne sélectionnée doit tenir dans la liste. Plus
  /// haute que la liste : son haut d'abord.
  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _selectedRowKey.currentContext?.findRenderObject();
      if (row == null || !_scroll.hasClients) return;
      final viewport = RenderAbstractViewport.of(row);
      final position = _scroll.position;
      final showBottom = viewport.getOffsetToReveal(row, 1).offset;
      final showTop = viewport.getOffsetToReveal(row, 0).offset;
      final target = math
          .min(math.max(position.pixels, showBottom), showTop)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (target == position.pixels) return;
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
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
    _revealSelected();
  }

  /// Ouvre l'éditeur : création (reprend le brouillon s'il y en a un) ou
  /// modification de [ensemble] (reprend son brouillon s'il en a un).
  Future<void> _openEditor({FiestaEnsemble? ensemble}) async {
    if (_busy) return;
    _busy = true;
    try {
      final drafts = FiestaEnsemblesScreen.drafts;
      final key = ensemble?.id ?? FiestaEnsemblesScreen.newDraftKey;
      final resumed = drafts[key];
      final result = await Navigator.of(context).push<EnsembleEditorResult>(
        MaterialPageRoute(
          builder: (_) => FiestaEnsembleEditorScreen(
            initial: ensemble,
            draft: resumed,
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
          // Seul le brouillon de cet éditeur (enregistré) disparaît.
          drafts.remove(key);
          await _reload(select: ensemble.id);
        case EnsembleDraftKept(:final rules):
          setState(() => drafts[key] = rules);
          if (mounted) {
            // Flottant au-dessus de « Valider », qu'il ne doit pas masquer.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Brouillon gardé'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.fromLTRB(20, 0, 20, 90),
            ));
          }
        case null:
          // Sorti sans rien garder : le brouillon de cet éditeur, s'il en
          // avait un, est abandonné.
          if (resumed != null) setState(() => drafts.remove(key));
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _duplicate(FiestaEnsemble ensemble) async {
    final copy = await _service.duplicate(ensemble);
    await _reload(select: copy?.id);
  }

  /// Page « Voir » : son bouton « Dupliquer » revient ici pour dupliquer.
  Future<void> _view(FiestaEnsemble ensemble) async {
    final duplicate = await FiestaEnsembleViewScreen.show(context,
        ensemble: ensemble, canDuplicate: !_full);
    if (duplicate && mounted) await _duplicate(ensemble);
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
    FiestaEnsemblesScreen.drafts.remove(ensemble.id);
    await _reload();
  }

  Future<void> _validate() async {
    final chosen = _ready.where((e) => e.id == _selectedId).firstOrNull;
    if (chosen == null || _busy) return;
    _busy = true;
    try {
      await _service.markUsed(chosen.id);
      if (mounted) widget.onValidate(chosen.rules);
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
                          const SizedBox(height: _buttonsBand),
                          Expanded(child: _buildBody()),
                          _buildValidateBar(),
                        ],
                      ),
              ),
              AppBackButton(onPressed: widget.onBack),
              HelpButton(
                onPressed: () => CoachMarks.show(
                  context,
                  fiestaEnsemblesHelp(
                    ready: _readyKey,
                    firstMine: _firstMineKey,
                    create: _createKey,
                    validate: _validateKey,
                    hasMine: _mine.isNotEmpty,
                    full: _full,
                    selectedHasModifiers: _ready
                        .where((e) => e.id == _selectedId)
                        .any((e) => ensembleSummary(e)
                            .chips
                            .whereType<ModifierChip>()
                            .isNotEmpty),
                    hasDraft: FiestaEnsemblesScreen.drafts
                        .containsKey(FiestaEnsemblesScreen.newDraftKey),
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
    final newDraft = FiestaEnsemblesScreen.drafts
        .containsKey(FiestaEnsemblesScreen.newDraftKey);
    final count = '${_mine.length} / ${FiestaEnsembleService.maxEnsembles}';
    // Pas de ListView : l'aide vise « Créer un ensemble », à monter même sous
    // une longue liste.
    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ensembles Fiesta',
            style: AppTextStyles.subtitle(fontSize: 34),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          KeyedSubtree(
            key: _readyKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final ensemble in _ready)
                  _EnsembleCard(
                    key: ensemble == _mine.firstOrNull ? _firstMineKey : null,
                    rowKey: ensemble.id == _selectedId ? _selectedRowKey : null,
                    ensemble: ensemble,
                    selected: ensemble.id == _selectedId,
                    canDuplicate: !_full,
                    onTap: () => _select(ensemble.id),
                    onView: () => _view(ensemble),
                    onEdit: () => _openEditor(ensemble: ensemble),
                    onDuplicate: () => _duplicate(ensemble),
                    onDelete: () => _delete(ensemble),
                  ),
              ],
            ),
          ),
          KeyedSubtree(
            key: _createKey,
            child: _full && !newDraft
                ? _Alert(
                    'Limite de ${FiestaEnsembleService.maxEnsembles} ensembles '
                    'atteinte. Supprime un ensemble pour en créer un nouveau.',
                    count: count,
                  )
                : _CreateButton(
                    text: '${newDraft ? 'Reprendre le brouillon' : 'Créer un '
                        'ensemble'} · $count',
                    onPressed: () => _openEditor(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidateBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: AppColors.backgroundMain,
      child: AppButton(
        key: _validateKey,
        text: 'Valider',
        variant: AppButtonVariant.primary,
        size: AppButtonSize.large,
        fullWidth: true,
        disabled: _selectedId == null,
        onPressed: _selectedId == null ? null : _validate,
      ),
    );
  }
}

class _EnsembleCard extends StatelessWidget {
  /// Posée sur la ligne sélectionnée, que l'écran garde visible.
  final Key? rowKey;
  final FiestaEnsemble ensemble;
  final bool selected;
  final bool canDuplicate;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _EnsembleCard({
    required this.rowKey,
    required this.ensemble,
    required this.selected,
    required this.canDuplicate,
    required this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final summary = ensembleSummary(ensemble);
    return Container(
      key: rowKey,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.secondaryCyan.withValues(alpha: 0.12)
            : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.secondaryCyan : AppColors.gray700,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            selected: selected,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: _header(summary),
            ),
          ),
          if (selected) _details(summary),
        ],
      ),
    );
  }

  Widget _header(EnsembleSummary summary) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.secondaryCyan
                    : AppColors.secondaryCyan.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                ensembleIcon(ensemble),
                size: 30,
                color: selected
                    ? AppColors.backgroundMain
                    : AppColors.secondaryCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        ensemble.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label
                            .copyWith(fontSize: 15, height: 1.25),
                      ),
                      if (!ensemble.isProvided) const _PersoBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.short,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12, height: 1.3, color: AppColors.gray300),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.secondaryCyan : null,
                border: Border.all(
                  color: selected ? AppColors.secondaryCyan : AppColors.gray500,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 14, color: AppColors.backgroundMain)
                  : null,
            ),
          ],
        ),
      );

  /// Ce qui ne s'affiche que sur la ligne sélectionnée.
  Widget _details(EnsembleSummary summary) {
    final rules = ensemble.rules;
    final always = kModifierCatalog
        .where((d) => rules.isAlways(d.id))
        .map((d) => d.id)
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  summary.long,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 13, height: 1.45),
                ),
                if (summary.chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final chip in summary.chips)
                        switch (chip) {
                          ModifierChip(:final id, :final count) =>
                            ModifierBadge.catalog(
                              id,
                              nature: modifierById(id)!.nature,
                              count: count,
                              playingWith: count == null ? always : const [],
                            ),
                          InfoChip(:final label) => _InfoChip(label),
                        },
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _Action(Icons.visibility_outlined, 'Voir', onView),
              if (!ensemble.isProvided)
                _Action(Icons.edit_outlined, 'Modifier', onEdit),
              _Action(Icons.content_copy, 'Dupliquer',
                  canDuplicate ? onDuplicate : null),
              if (!ensemble.isProvided)
                _Action(Icons.delete_outline, 'Supprimer', onDelete,
                    color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pastille neutre, à la forme de `ModifierBadge`.
class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.gray400.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.gray300.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray300,
          ),
        ),
      );
}

/// Une action d'ensemble : icône seule, libellé pour l'accessibilité, 44 px.
class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _Action(this.icon, this.label, this.onPressed,
      {this.color = AppColors.gray300});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 20),
        tooltip: label,
        color: color,
        disabledColor: AppColors.gray600,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onPressed: onPressed,
      );
}

class _PersoBadge extends StatelessWidget {
  const _PersoBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warning),
        ),
        child: const Text(
          'Perso',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
      );
}

/// « Créer un ensemble », en contour pointillé.
class _CreateButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _CreateButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.secondaryCyan.withValues(alpha: 0.08),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: CustomPaint(
            painter: _DashedBorderPainter(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add,
                        size: 20, color: AppColors.secondaryCyan),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        text,
                        style: AppTextStyles.label.copyWith(
                            fontSize: 15, color: AppColors.secondaryCyan),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final border = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      const Radius.circular(15),
    );
    for (final metric in (Path()..addRRect(border)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

class _Alert extends StatelessWidget {
  final String text;
  final String count;
  const _Alert(this.text, {required this.count});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodySmall
        .copyWith(color: AppColors.warning, fontSize: 13);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(text, style: style)),
          const SizedBox(width: 12),
          Text(count, style: style.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
