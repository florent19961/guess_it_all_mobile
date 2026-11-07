import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/fiesta/ensemble_validation.dart';
import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../models/fiesta/symmetric_draw.dart' show canBeRoundRule;
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
/// écran poussé depuis la liste des ensembles.
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
  final _introKey = GlobalKey();
  final _tabsKey = GlobalKey();
  final _menuKey = GlobalKey();
  final _noDrawKey = GlobalKey();
  final _lockedKey = GlobalKey();
  final _challengesKey = GlobalKey();
  final _saveKey = GlobalKey();

  late FiestaRules _rules;
  late bool _moreOpen;
  late final TextEditingController _name;

  /// Ce qui a été chargé (JSON) : « rien modifié » = identique.
  late final String _loaded;

  late EnsembleMenu _tab;
  bool _tried = false;
  bool _saving = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initial?.rules ?? FiestaRules(ensembleName: '');
    _loaded = jsonEncode(start.toJson());
    _rules = widget.draft ?? start;
    _tab = _firstTab(_rules);
    _moreOpen = _rules.challenges;
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

  /// Le menu où l'ensemble a quelque chose à montrer (maquette `load`).
  static EnsembleMenu _firstTab(FiestaRules r) {
    final draws = kModifierCatalog.any((d) => r.settingOf(d.id).draw);
    if (draws) return EnsembleMenu.draw;
    final always = kModifierCatalog.any((d) => r.isAlways(d.id));
    return always && r.trailingCount == 0 && r.allCount == 0
        ? EnsembleMenu.always
        : EnsembleMenu.cartridge;
  }

  void _setting(String id, ModifierSetting Function(ModifierSetting) change) =>
      setState(() {
        _rules = _rules.copyWith(modifiers: {
          ..._rules.modifiers,
          id: change(_rules.settingOf(id)),
        });
      });

  void _info(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// « Toujours » allumé : ce qu'il met de côté dans les autres menus est gardé
  /// en mémoire, et le joueur le sait.
  void _toggleAlways(ModifierDef def, bool on) {
    final before = _rules;
    _setting(def.id, (s) => s.copyWith(always: on));
    if (!on) return;
    if (def.mimeFamily) {
      final hit = kModifierCatalog
          .where((m) =>
              m.mimeFamily &&
              m.id != def.id &&
              !areCompatible(m.id, def.id) &&
              (before.settingOf(m.id).draw ||
                  before.settingOf(m.id).charges > 0))
          .length;
      if (hit > 0) {
        final s = hit > 1 ? 's' : '';
        _info('${def.name} est en Toujours : $hit autre$s mime$s bloqué$s. '
            '${hit > 1 ? 'Ils reviennent' : 'Il revient'} si tu le décoches.');
      }
    } else if (before.settingOf(def.id).draw ||
        before.settingOf(def.id).charges > 0) {
      _info('${def.name} passe en Toujours : son réglage dans les autres menus '
          'est mis de côté.');
    }
  }

  /// Un interrupteur aléatoire allumé sans rien à tirer serait sans effet : le
  /// premier fait passer « Combien par manche » de 0 à 1.
  void _setDraw(Iterable<ModifierDef> defs, bool on) => setState(() {
        _rules = _rules.copyWith(
          drawCount: on && _rules.drawCount == 0 ? 1 : _rules.drawCount,
          modifiers: {
            ..._rules.modifiers,
            for (final def in defs)
              def.id: _rules.settingOf(def.id).copyWith(draw: on),
          },
        );
      });

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
                    // La bande des boutons retour et « ? » : la page défile
                    // en dessous, les onglets épinglés ne passent pas dessous.
                    const SizedBox(height: _cornerButtonsHeight),
                    Expanded(
                      child: CustomScrollView(
                        controller: _scroll,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                                20, _introTopPadding, 20, 0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                key: _introKey,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                      maxLength:
                                          FiestaEnsembleService.maxNameLength,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      error: nameError,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _TabsHeader(
                              child: KeyedSubtree(
                                key: _tabsKey,
                                child: _tabs(),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            sliver: SliverToBoxAdapter(
                              child: KeyedSubtree(
                                key: _menuKey,
                                child: switch (_tab) {
                                  EnsembleMenu.always => _menuAlways(),
                                  EnsembleMenu.draw => _menuDraw(),
                                  EnsembleMenu.cartridge => _menuCartridges(),
                                },
                              ),
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
                    tabs: _tabsKey,
                    menu: _menuKey,
                    noDraw: _noDrawKey,
                    locked: _lockedKey,
                    challenges: _challengesKey,
                    save: _saveKey,
                    tab: _tab,
                    hasCounts: EnsembleMenu.values.any((m) => _count(m) > 0),
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

  // ---------- Les 3 menus ----------

  int _count(EnsembleMenu menu) => switch (menu) {
        EnsembleMenu.always =>
          kModifierCatalog.where((d) => _rules.isAlways(d.id)).length,
        EnsembleMenu.draw =>
          kModifierCatalog.where((d) => _rules.drawsFrom(d.id)).length,
        EnsembleMenu.cartridge => kModifierCatalog.fold<int>(
                0, (sum, d) => sum + _rules.chargesOf(d.id)) +
            (_rules.balance ? 1 : _rules.trailingCount) +
            _rules.allCount +
            (_rules.challenges ? 1 : 0),
      };

  /// Page défilée au-delà de l'épinglage des onglets : retour à ce point, le
  /// nouveau menu s'ouvre à son début. Sinon, elle ne bouge pas.
  void _selectTab(EnsembleMenu menu) {
    final pinAt = _introKey.currentContext!.size!.height + _introTopPadding;
    if (_scroll.offset > pinAt) _scroll.jumpTo(pinAt);
    setState(() => _tab = menu);
  }

  Widget _tabs() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF17202F),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final (menu, label) in const [
              (EnsembleMenu.always, 'Toujours'),
              (EnsembleMenu.draw, 'Aléatoire par manche'),
              (EnsembleMenu.cartridge, 'Cartouches'),
            ])
              Expanded(
                child: _TabButton(
                  label: label,
                  count: _count(menu),
                  selected: _tab == menu,
                  onTap: () => _selectTab(menu),
                ),
              ),
          ],
        ),
      );

  /// Les modificateurs de [group], maquette `M`.
  static const _talkMalus = [
    'no_pass',
    'reversed',
    'other_language',
    'one_answer',
    'minus_10s',
    'block_guesser',
    'block_giver',
  ];

  static List<ModifierDef> _inGroup(_Group group) => switch (group) {
        _Group.malus => [for (final id in _talkMalus) modifierById(id)!],
        _Group.mimes => kModifierCatalog.where((d) => d.mimeFamily).toList(),
        _Group.bonus => kModifierCatalog
            .where((d) => d.nature == ModifierNature.bonus)
            .toList(),
      };

  static String? _roundsLabel(ModifierDef def) => def.round3Only
      ? 'Manche 3 seulement'
      : def.notInRound3
          ? 'Manches 1 et 2 seulement'
          : null;

  /// La première ligne verrouillée de [menu], où pointe l'aide.
  String? _firstLockedId(EnsembleMenu menu) => [
        _Group.malus,
        _Group.mimes,
        if (menu == EnsembleMenu.cartridge) _Group.bonus,
      ]
          .expand((group) => _available(group, menu))
          .where((def) => _rules.lockReason(def.id, menu) != null)
          .firstOrNull
          ?.id;

  /// Ligne d'un modificateur : verrouillée, elle dit pourquoi.
  Widget _modifierRow(ModifierDef def, EnsembleMenu menu, Widget control) {
    final lock = _rules.lockReason(def.id, menu);
    final color = modifierColor(def.nature);
    final sub = lock ?? _roundsLabel(def);
    return Opacity(
      key: def.id == _firstLockedId(menu) ? _lockedKey : null,
      opacity: lock == null ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2536),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color, width: 1.5),
              ),
              child: ModifierIcon(def.id, size: 26, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(def.name,
                      style: AppTextStyles.label.copyWith(fontSize: 13.5)),
                  if (sub != null)
                    Text(
                      sub,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: lock != null
                            ? AppColors.warning
                            : AppColors.gray400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            control,
          ],
        ),
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool>? onChanged) => Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeTrackColor: AppColors.secondaryCyan,
      );

  Widget _groupHead(_Group group, Widget? trailing) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: group == _Group.bonus
                        ? AppColors.success
                        : AppColors.malus,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      );

  Widget _groupControl(String label, Widget control) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 11, color: AppColors.gray400)),
          const SizedBox(width: 8),
          control,
        ],
      );

  Widget _menuAlways() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Frame(
            title: 'Modificateur de toute la partie',
            subtitle:
                'Actif du début à la fin de la partie, pour toutes les équipes.',
          ),
          for (final group in const [_Group.malus, _Group.mimes])
            ..._groupRows(group, EnsembleMenu.always),
          const _Hint('Jamais en Toujours : les 4 bonus, Malus de 10 s, '
              'Bloquer un devineur, Interdit de faire deviner.'),
        ],
      );

  /// Modificateurs d'un groupe qui existent dans [menu] : Toujours et Aléatoire
  /// excluent ce qui n'est que cartouche.
  Iterable<ModifierDef> _available(_Group group, EnsembleMenu menu) =>
      _inGroup(group).where(
          (def) => menu == EnsembleMenu.cartridge || canBeRoundRule(def));

  List<Widget> _groupRows(_Group group, EnsembleMenu menu) {
    final defs = _available(group, menu);
    final free = defs.where((d) => _rules.lockReason(d.id, menu) == null);
    return [
      _groupHead(
        group,
        switch (menu) {
          EnsembleMenu.always => defs.any((d) => _rules.isAlways(d.id))
              ? TextButton(
                  onPressed: () => setState(() {
                    _rules = _rules.copyWith(modifiers: {
                      ..._rules.modifiers,
                      for (final def in defs)
                        def.id:
                            _rules.settingOf(def.id).copyWith(always: false),
                    });
                  }),
                  child: const Text(
                    'Tout décocher',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.secondaryCyan),
                  ),
                )
              : null,
          EnsembleMenu.draw => free.isEmpty
              ? null
              : _groupControl(
                  'Tout',
                  _switch(
                    free.every((d) => _rules.settingOf(d.id).draw),
                    (on) => _setDraw(free, on),
                  ),
                ),
          EnsembleMenu.cartridge => free.isEmpty
              ? null
              : _groupControl(
                  'Tous',
                  _Stepper(
                    value: _commonCharges(free),
                    onChanged: (v) => setState(() {
                      _rules = _rules.copyWith(modifiers: {
                        ..._rules.modifiers,
                        for (final def in free)
                          def.id: _rules.settingOf(def.id).copyWith(charges: v),
                      });
                    }),
                  ),
                ),
        },
      ),
      for (final def in defs)
        _modifierRow(
            def,
            menu,
            switch (menu) {
              EnsembleMenu.always => _switch(
                  _rules.isAlways(def.id),
                  _rules.lockReason(def.id, menu) != null
                      ? null
                      : (on) => _toggleAlways(def, on),
                ),
              EnsembleMenu.draw => _switch(
                  _rules.drawsFrom(def.id),
                  _rules.lockReason(def.id, menu) != null
                      ? null
                      : (on) => _setDraw([def], on),
                ),
              EnsembleMenu.cartridge => _Stepper(
                  value: _rules.chargesOf(def.id),
                  enabled: _rules.lockReason(def.id, menu) == null,
                  onChanged: (v) =>
                      _setting(def.id, (s) => s.copyWith(charges: v)),
                ),
            }),
    ];
  }

  /// Valeur affichée par « Tous » : la valeur commune, sinon 0.
  int _commonCharges(Iterable<ModifierDef> defs) {
    final values = {for (final d in defs) _rules.settingOf(d.id).charges};
    return values.length == 1 ? values.single : 0;
  }

  Widget _menuDraw() {
    final missing = roundsWithoutDraw(_rules);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Frame(
          title: 'Modificateur aléatoire de manche',
          info: () => _info('Au début de chaque manche, l\'app tire au sort '
              'parmi ceux que tu actives. Il vaut toute la manche, pour toutes '
              'les équipes.'),
          children: [
            _line(
              'Combien par manche',
              _Stepper(
                value: _rules.drawCount,
                onChanged: (v) =>
                    setState(() => _rules = _rules.copyWith(drawCount: v)),
              ),
            ),
            if (missing.isNotEmpty)
              Padding(
                key: _noDrawKey,
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Rien à tirer en manche ${missing.join(' et ')}.',
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 11, color: AppColors.warning),
                ),
              ),
          ],
        ),
        for (final group in const [_Group.malus, _Group.mimes])
          ..._groupRows(group, EnsembleMenu.draw),
        const _Hint('Jamais en aléatoire de manche : les 4 bonus, Malus de '
            '10 s, Bloquer un devineur, Interdit de faire deviner.'),
      ],
    );
  }

  Widget _menuCartridges() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text(
              'Une cartouche est à usage unique : elle vaut pour un seul tour.',
              style: AppTextStyles.label.copyWith(fontSize: 13),
            ),
          ),
          _Frame(
            title: 'Au hasard',
            subtitle: 'L\'app choisit parmi tous les bonus / malus.',
            children: [
              _line(
                'Équilibrer la partie',
                _switch(
                  _rules.balance,
                  (on) => setState(() => _rules = _rules.copyWith(balance: on)),
                ),
                info: () => _info('Plus une équipe est distancée, plus elle '
                    'reçoit de cartouches.'),
              ),
              if (!_rules.balance)
                _line(
                  'Aux équipes menées',
                  _Stepper(
                    value: _rules.trailingCount,
                    onChanged: (v) => setState(
                        () => _rules = _rules.copyWith(trailingCount: v)),
                  ),
                  sub: 'Nombre fixe après les manches 1 et 2',
                ),
              _line(
                'À tous, à chaque manche',
                _Stepper(
                  value: _rules.allCount,
                  max: kMaxAllCount,
                  onChanged: (v) =>
                      setState(() => _rules = _rules.copyWith(allCount: v)),
                ),
              ),
            ],
          ),
          _Frame(
            title: 'Pour tout le monde',
            subtitle: 'Tu choisis : chaque équipe reçoit exactement ça au '
                'début de la partie.',
            children: [
              for (final group in _Group.values)
                ..._groupRows(group, EnsembleMenu.cartridge),
            ],
          ),
          OutlinedButton(
            onPressed: () => setState(() => _moreOpen = !_moreOpen),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.gray500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Si tu veux vraiment pousser plus loin ${_moreOpen ? '▴' : '▾'}',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(fontSize: 13),
            ),
          ),
          if (_moreOpen) ...[
            const SizedBox(height: 10),
            _Frame(
              key: _challengesKey,
              title: 'Défis surprises',
              subtitle: '1 ou 2 fois dans la partie, entre deux joueurs des '
                  'équipes les plus en retard.',
              trailing: _switch(
                _rules.challenges,
                (on) =>
                    setState(() => _rules = _rules.copyWith(challenges: on)),
              ),
            ),
          ],
        ],
      );

  Widget _line(String label, Widget trailing,
          {String? sub, VoidCallback? info}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(label,
                            style:
                                AppTextStyles.label.copyWith(fontSize: 13.5)),
                      ),
                      if (info != null) _InfoButton(onTap: info),
                    ],
                  ),
                  if (sub != null)
                    Text(sub,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 11, color: AppColors.gray400)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      );
}

enum _Group {
  malus('MALUS'),
  mimes('MIMES'),
  bonus('BONUS');

  final String label;
  const _Group(this.label);
}

/// Hauteur des boutons retour et « ? » en haut d'écran : 16 de marge + 48.
const double _cornerButtonsHeight = 64;

/// Au-dessus du titre, dans la page qui défile sous cette bande.
const double _introTopPadding = 72 - _cornerButtonsHeight;

/// Onglets épinglés en haut pendant le défilement.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _TabsHeader({required this.child});

  static const _height = 78.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) =>
      ColoredBox(color: AppColors.backgroundMain, child: child);

  @override
  bool shouldRebuild(_TabsHeader oldDelegate) => true;
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.backgroundMain : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 58,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondaryCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cadre vert d'un menu (maquette `.frame`).
class _Frame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? info;
  final Widget? trailing;
  final List<Widget> children;

  const _Frame({
    required this.title,
    this.subtitle,
    this.info,
    this.trailing,
    this.children = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x8C263348),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.success, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  fit: trailing != null ? FlexFit.tight : FlexFit.loose,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 22,
                      letterSpacing: 0.6,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            offset: Offset(1, 1),
                            color: AppColors.primaryPinkDark),
                      ],
                    ),
                  ),
                ),
                if (info != null) _InfoButton(onTap: info!),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null)
              Text(subtitle!,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 12, color: const Color(0xFFCBD5E1))),
            if (children.isNotEmpty) const SizedBox(height: 6),
            ...children,
          ],
        ),
      );
}

/// Petit « i » : l'explication s'affiche en bas de l'écran.
class _InfoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _InfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Explication',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(left: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gray400, width: 1.5),
            ),
            child: const Text(
              'i',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray400),
            ),
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

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
                .copyWith(color: AppColors.gray400, fontSize: 12),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
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

/// Compteur compact −/+ de 0 à [max].
class _Stepper extends StatelessWidget {
  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.onChanged,
    this.max = kMaxCount,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, int next, bool can, String label) =>
        IconButton(
          tooltip: label,
          onPressed: enabled && can ? () => onChanged(next) : null,
          icon: Icon(icon, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          color: Colors.white,
          disabledColor: AppColors.gray600,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.gray700,
            disabledBackgroundColor: AppColors.gray700,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove, value - 1, value > 0, 'Moins'),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            style: AppTextStyles.label
                .copyWith(color: value == 0 ? AppColors.gray500 : Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        button(Icons.add, value + 1, value < max, 'Plus'),
      ],
    );
  }
}
