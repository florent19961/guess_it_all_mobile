import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/fiesta/ensemble_validation.dart';
import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../models/fiesta/symmetric_draw.dart';
import '../services/fiesta_ensemble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_confirm_dialog.dart';
import '../widgets/common/app_input.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/fiesta/modifier_badge.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

/// Ce que rend l'éditeur en se fermant.
sealed class EnsembleEditorResult {
  const EnsembleEditorResult();
}

/// Enregistré : la liste le sélectionne.
class EnsembleSaved extends EnsembleEditorResult {
  final FiestaEnsemble ensemble;
  const EnsembleSaved(this.ensemble);
}

/// Brouillon incomplet gardé en mémoire (tant que l'app est ouverte).
class EnsembleDraftKept extends EnsembleEditorResult {
  final FiestaRules rules;
  const EnsembleDraftKept(this.rules);
}

/// « Nouvel ensemble » / « Modifier » :
/// écran poussé depuis « Fiesta personnalisée ».
///
/// - [initial] nul = création, sinon modification sur place (renommage
///   compris). [draft] : brouillon à reprendre (réglages en cours).
/// - [others] : les autres ensembles (fournis + les miens, sans celui qu'on
///   modifie), pour l'unicité du nom et le refus d'un doublon de réglages.
/// - « Enregistrer » est toujours actif ; les erreurs précises ne s'affichent
///   qu'après un premier appui (sinon un éditeur vierge criait « Donne un
///   nom » avant toute saisie : bug Florent 2026-11-04).
/// - Retour (bouton ou Android) : rien modifié → sort ; incomplet → brouillon
///   gardé ([EnsembleDraftKept]) ; complet et valide → « Tu veux
///   l'enregistrer ? ».
class FiestaEnsembleEditorScreen extends StatefulWidget {
  final FiestaEnsemble? initial;
  final FiestaRules? draft;
  final List<FiestaEnsemble> others;

  const FiestaEnsembleEditorScreen({
    required this.others,
    this.initial,
    this.draft,
    super.key,
  });

  @override
  State<FiestaEnsembleEditorScreen> createState() =>
      _FiestaEnsembleEditorScreenState();
}

class _FiestaEnsembleEditorScreenState
    extends State<FiestaEnsembleEditorScreen> {
  final _scroll = ScrollController();
  final _rulesKey = GlobalKey();
  final _malusKey = GlobalKey();
  final _saveKey = GlobalKey();

  late FiestaRules _rules;
  late final TextEditingController _name;

  /// Ce qui a été chargé (JSON) : « rien modifié » = identique.
  late final String _loaded;

  String? _open;
  bool _tried = false;
  bool _saving = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initial?.rules ?? defaultEnsembleRules('');
    _loaded = jsonEncode(start.toJson());
    _rules = widget.draft ?? start;
    _name = TextEditingController(text: _rules.ensembleName ?? '');
    // Le nom est lu sur le contrôleur, jamais recopié : une seule source.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  FiestaRules get _current => _rules.copyWith(ensembleName: _name.text);

  bool get _dirty => jsonEncode(_current.toJson()) != _loaded;

  ModifierSetting _settingFor(ModifierDef def) =>
      _rules.modifiers[def.id] ?? defaultSetting(def);

  void _set(ModifierDef def, ModifierSetting setting) => setState(() {
        _rules =
            _rules.copyWith(modifiers: {..._rules.modifiers, def.id: setting});
      });

  void _toggle(ModifierDef def, bool on) {
    setState(() {
      final modifiers = {
        ..._rules.modifiers,
        def.id: _settingFor(def).copyWith(active: on),
      };
      // Famille « Mime » : un seul à la fois, allumer l'un coupe les autres.
      if (on && def.mimeFamily) {
        for (final other in kModifierCatalog) {
          if (other.mimeFamily && other.id != def.id) {
            modifiers[other.id] = _settingFor(other).copyWith(active: false);
          }
        }
      }
      _rules = _rules.copyWith(modifiers: modifiers);
      if (on) _open = def.id;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final rules = _current.copyWith(ensembleName: _name.text.trim());
    final errors = validateEnsemble(rules, others: widget.others);
    if (errors.isNotEmpty) {
      setState(() => _tried = true);
      if (ensembleNameError(rules, others: widget.others) != null) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      return;
    }
    setState(() => _saving = true);
    final service = FiestaEnsembleService();
    final initial = widget.initial;
    final FiestaEnsemble? saved;
    if (initial == null) {
      saved = await service.create(rules);
    } else {
      final edited = FiestaEnsemble(id: initial.id, rules: rules);
      saved = await service.update(edited) ? edited : null;
    }
    if (!mounted) return;
    if (saved != null) {
      _leaving = true;
      Navigator.of(context).pop(EnsembleSaved(saved));
      return;
    }
    // `create` rend aussi `null` sur une lecture en panne : on ne parle de la
    // limite que si la liste relue est vraiment pleine.
    final full = (await service.load()).ensembles.length >=
        FiestaEnsembleService.maxEnsembles;
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(initial == null && full
          ? 'Limite de ${FiestaEnsembleService.maxEnsembles} ensembles '
              'atteinte : supprime un ensemble pour en créer un nouveau.'
          : 'Enregistrement impossible, réessaie.'),
    ));
  }

  Future<void> _back() async {
    if (_leaving) return;
    final navigator = Navigator.of(context);
    if (!_dirty) {
      _leaving = true;
      navigator.pop();
      return;
    }
    final rules = _current;
    if (validateEnsemble(rules.copyWith(ensembleName: _name.text.trim()),
            others: widget.others)
        .isNotEmpty) {
      _leaving = true;
      navigator.pop(EnsembleDraftKept(rules));
      return;
    }
    final save = await AppConfirmDialog.show(
      context,
      title: 'Tu veux l\'enregistrer ?',
      message: '« ${_name.text.trim()} » n\'est pas encore enregistré.',
      confirmText: 'Enregistrer',
      cancelText: 'Quitter sans enregistrer',
      accentColor: AppColors.secondaryCyan,
      barrierDismissible: false,
    );
    if (!mounted) return;
    if (save) {
      await _save();
    } else {
      _leaving = true;
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final errors = _tried
        ? validateEnsemble(current.copyWith(ensembleName: _name.text.trim()),
            others: widget.others)
        : const <String>[];
    final nameError =
        _tried ? ensembleNameError(current, others: widget.others) : null;
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
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                        children: [
                          Text(
                            widget.initial == null
                                ? 'Nouvel ensemble'
                                : 'Modifier l\'ensemble',
                            style: AppTextStyles.subtitle(fontSize: 34),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          _Card(
                            title: 'Nom de l\'ensemble',
                            child: AppInput(
                              controller: _name,
                              placeholder: 'ex. Soirée chez Max',
                              maxLength: FiestaEnsembleService.maxNameLength,
                              textCapitalization: TextCapitalization.sentences,
                              error: nameError,
                            ),
                          ),
                          KeyedSubtree(key: _rulesKey, child: _rulesCard()),
                          KeyedSubtree(
                            key: _malusKey,
                            child: _Card(
                              title: 'Malus',
                              color: AppColors.malus,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final def in kModifierCatalog)
                                    if (def.nature == ModifierNature.malus &&
                                        !def.mimeFamily)
                                      _modifierRow(def),
                                  const _SubHead('MIMES · UN SEUL À LA FOIS'),
                                  for (final def in kModifierCatalog)
                                    if (def.mimeFamily) _modifierRow(def),
                                ],
                              ),
                            ),
                          ),
                          _Card(
                            title: 'Bonus',
                            color: AppColors.success,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final def in kModifierCatalog)
                                  if (def.nature == ModifierNature.bonus)
                                    _modifierRow(def),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _saveBar(errors),
                  ],
                ),
              ),
              AppBackButton(onPressed: _back),
              HelpButton(
                onPressed: () => CoachMarks.show(
                  context,
                  fiestaEditorHelp(
                    rules: _rulesKey,
                    modifiers: _malusKey,
                    save: _saveKey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveBar(List<String> errors) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        color: AppColors.backgroundMain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final error in errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  error,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error, fontSize: 12.5),
                ),
              ),
            AppButton(
              key: _saveKey,
              text: 'Enregistrer',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              fullWidth: true,
              onPressed: _save,
            ),
          ],
        ),
      );

  Widget _rulesCard() {
    final r = _rules;
    return _Card(
      title: 'Règles de la partie',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SubHead('AU TIRAGE', first: true),
          _line(
            'Modificateurs tirés par manche',
            _Stepper(
              value: r.drawCount,
              min: 0,
              max: kMaxDrawCount,
              onChanged: (v) =>
                  setState(() => _rules = _rules.copyWith(drawCount: v)),
            ),
          ),
          const _Hint('Parmi ceux en « Au tirage », incompatibles sautés. '
              '0 = aucun tirage.'),
          const _SubHead('TOUTE LA PARTIE'),
          _line(
            'Coup de pouce à l\'équipe menée',
            _switch(
              r.trailingBoost,
              (v) => setState(() => _rules = _rules.copyWith(trailingBoost: v)),
            ),
          ),
          const _Hint('Après les manches 1 et 2, chaque équipe non en tête '
              'reçoit une cartouche au hasard, parmi celles en Cartouche.'),
        ],
      ),
    );
  }

  static const _modeLabels = {
    ModifierMode.always: 'Toujours',
    ModifierMode.draw: 'Au tirage',
    ModifierMode.cartridge: 'Cartouche',
  };

  static const _modeHints = {
    ModifierMode.always: 'Actif pour toutes les équipes, toute la manche, sur '
        'les manches cochées.',
    ModifierMode.draw: 'Entre dans le tirage du début de manche (nombre réglé '
        'dans « Règles de la partie »).',
    ModifierMode.cartridge: 'Dans la réserve de chaque équipe pour toute la '
        'partie : elle la joue au tour de son choix.',
  };

  String _chargesLabel(int charges) => charges == 0
      ? 'Gagnées seulement'
      : '$charges cartouche${charges > 1 ? 's' : ''} pour la partie';

  String _summary(ModifierSetting s) {
    if (!s.active) return 'Désactivé';
    if (s.mode == ModifierMode.cartridge) return _chargesLabel(s.charges);
    final rounds = s.rounds.toList()..sort();
    return [
      rounds.isEmpty
          ? 'Aucune manche'
          : '${rounds.length > 1 ? 'Manches' : 'Manche'} ${rounds.join(', ')}',
      _modeLabels[s.mode]!,
    ].join(' · ');
  }

  /// Compteur de cartouches pour la partie (0 = seulement par le coup de
  /// pouce).
  Widget _chargesLine(ModifierDef def, ModifierSetting s) {
    final maxCharges = maxCartridges(def.id);
    return _line(
      'Cartouches pour la partie',
      _Stepper(
        value: s.charges.clamp(0, maxCharges),
        min: 0,
        max: maxCharges,
        onChanged: (v) => _set(def, s.copyWith(charges: v)),
      ),
    );
  }

  Widget _modifierRow(ModifierDef def) {
    final s = _settingFor(def);
    // Seulement en cartouche : un interrupteur et un compteur, rien à régler.
    final cartridgeOnly = !canBeRoundRule(def);
    final open = s.active && _open == def.id && !cartridgeOnly;
    final color = modifierColor(def.nature);
    final allowed = allowedRounds(def);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundMain,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: s.active ? 0.18 : 0.08),
                  border: Border.all(
                      color: color.withValues(alpha: s.active ? 0.6 : 0.25)),
                ),
                child: Text(
                  modifierIcon(def.id),
                  style: TextStyle(
                    fontSize: 14,
                    color: s.active ? color : AppColors.gray500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      style: AppTextStyles.label.copyWith(
                        color: s.active ? Colors.white : AppColors.gray500,
                      ),
                    ),
                    Text(
                      _summary(s),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.gray400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (s.active && !cartridgeOnly)
                TextButton(
                  onPressed: () => setState(() => _open = open ? null : def.id),
                  child: Text(
                    open ? 'Fermer' : 'Régler',
                    style: const TextStyle(color: AppColors.secondaryCyan),
                  ),
                ),
              _switch(s.active, (v) => _toggle(def, v)),
            ],
          ),
          if (s.active && cartridgeOnly) _chargesLine(def, s),
          if (open) ...[
            const SizedBox(height: 8),
            _Choices<ModifierMode>(
              values: [
                ModifierMode.always,
                ModifierMode.draw,
                if (canBeCartridge(def)) ModifierMode.cartridge,
              ],
              selected: s.mode,
              label: (m) => _modeLabels[m]!,
              onSelect: (m) => _set(def, s.copyWith(mode: m)),
            ),
            const SizedBox(height: 4),
            _Hint(_modeHints[s.mode]!),
            if (s.mode == ModifierMode.cartridge)
              _chargesLine(def, s)
            else ...[
              _line(
                'Manches',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var r = 1; r <= 3; r++)
                      if (def.round3Only)
                        if (r == 3)
                          const _RoundBox(round: 3, on: true, locked: true)
                        else
                          const SizedBox.shrink()
                      else
                        _RoundBox(
                          round: r,
                          on: s.rounds.contains(r),
                          enabled: allowed.contains(r),
                          onTap: () => _set(
                            def,
                            s.copyWith(
                              rounds: s.rounds.contains(r)
                                  ? (s.rounds.toSet()..remove(r))
                                  : {...s.rounds, r},
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              if (def.round3Only) const _Hint('Manche 3 seulement (mime).'),
              if (def.notInRound3)
                const _Hint('Jamais en manche 3 (on y mime).'),
            ],
          ],
        ],
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) => Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.secondaryCyan,
      );

  Widget _line(String label, Widget trailing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            trailing,
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  final String title;
  final Color? color;
  final Widget child;

  const _Card({required this.title, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.label
                .copyWith(color: color ?? AppColors.gray400, fontSize: 12),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SubHead extends StatelessWidget {
  final String text;
  final bool first;
  const _SubHead(this.text, {this.first = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: first ? 0 : 12, bottom: 4),
        child: Text(
          text,
          style: AppTextStyles.label
              .copyWith(color: AppColors.gray400, fontSize: 11),
        ),
      );
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.gray400, fontSize: 12),
      );
}

/// Case d'une manche (1, 2, 3) : cochée, décochée, interdite (grisée) ou
/// verrouillée (mime : manche 3 d'office).
class _RoundBox extends StatelessWidget {
  final int round;
  final bool on;
  final bool enabled;
  final bool locked;
  final VoidCallback? onTap;

  const _RoundBox({
    required this.round,
    required this.on,
    this.enabled = true,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !locked;
    return Semantics(
      button: active,
      checked: on,
      enabled: active,
      label: locked ? 'Manche $round, verrouillée' : 'Manche $round',
      child: GestureDetector(
        onTap: active ? onTap : null,
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on && enabled
                ? AppColors.secondaryCyan
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: enabled ? AppColors.gray600 : AppColors.gray700),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$round',
                style: AppTextStyles.label.copyWith(
                  color: !enabled
                      ? AppColors.gray600
                      : on
                          ? AppColors.backgroundMain
                          : Colors.white,
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock,
                    size: 13, color: AppColors.backgroundMain),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compteur compact −/+.
class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, int next, bool enabled, String label) =>
        IconButton(
          tooltip: label,
          onPressed: enabled ? () => onChanged(next) : null,
          icon: Icon(icon, size: 18),
          color: Colors.white,
          disabledColor: AppColors.gray600,
          style: IconButton.styleFrom(backgroundColor: AppColors.gray700),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove, value - 1, value > min, 'Moins'),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            style: AppTextStyles.label,
            textAlign: TextAlign.center,
          ),
        ),
        button(Icons.add, value + 1, value < max, 'Plus'),
      ],
    );
  }
}

/// Choix exclusif entre quelques options.
class _Choices<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final value in values)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: value == selected
                      ? AppColors.secondaryCyan
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label(value),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: value == selected
                        ? AppColors.backgroundMain
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
