import 'package:flutter/material.dart';

import '../models/fiesta/ensemble_validation.dart';
import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../services/fiesta_ensemble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_input.dart';
import '../widgets/common/app_slider.dart';

/// Éditeur d'un ensemble (maquette `edit`). Ouvert par `Navigator.push` depuis
/// « Mes ensembles » ; rend `true` à l'appelant quand il a enregistré.
///
/// [initial] nul = création (valeurs par défaut de la maquette), sinon
/// modification sur place. Le bouton reste grisé tant que
/// `validateEnsemble` rend des erreurs, affichées sous lui.
class FiestaEnsembleEditorScreen extends StatefulWidget {
  final FiestaEnsemble? initial;

  const FiestaEnsembleEditorScreen({this.initial, super.key});

  @override
  State<FiestaEnsembleEditorScreen> createState() =>
      _FiestaEnsembleEditorScreenState();
}

class _FiestaEnsembleEditorScreenState
    extends State<FiestaEnsembleEditorScreen> {
  late FiestaRules _rules;
  late final TextEditingController _name;
  String? _openModifier;
  bool _saving = false;

  static const _arrivalLabels = {
    ModifierArrival.draw: 'Tiré au sort pour tous',
    ModifierArrival.offer: 'Proposé à l\'équipe menée',
    ModifierArrival.fixed: 'Fixé sur la manche N',
  };

  @override
  void initState() {
    super.initState();
    _rules = widget.initial?.rules ?? defaultEnsembleRules('');
    _name = TextEditingController(text: _rules.ensembleName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Réglage affiché pour [def] : un id absent de l'ensemble est montré
  /// désactivé, avec les valeurs par défaut.
  ModifierSetting _settingFor(ModifierDef def) =>
      _rules.modifiers[def.id] ??
      defaultEnsembleRules('').modifiers[def.id]!.copyWith(active: false);

  void _setModifier(ModifierDef def, ModifierSetting setting) => setState(() {
        _rules = _rules.copyWith(
          modifiers: {..._rules.modifiers, def.id: setting},
        );
      });

  void _setCatchUp({int? b1, int? b2, int? cap, int? mal, int? malCap}) {
    final c = _rules.catchUp;
    setState(() {
      _rules = _rules.copyWith(
        catchUp: CatchUpRules(
          b1: b1 ?? c.b1,
          b2: b2 ?? c.b2,
          cap: cap ?? c.cap,
          mal: mal ?? c.mal,
          malCap: malCap ?? c.malCap,
        ),
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final service = FiestaEnsembleService();
    final rules = _rules.copyWith(ensembleName: _name.text.trim());
    final initial = widget.initial;
    final ok = initial == null
        ? await service.create(rules) != null
        : await service.update(FiestaEnsemble(id: initial.id, rules: rules));
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    // `create` rend aussi `null` sur une lecture en panne : on ne parle de la
    // limite que si la liste relue est vraiment pleine.
    final full = (await service.load()).ensembles.length >=
        FiestaEnsembleService.maxEnsembles;
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(initial == null && full
            ? 'Limite de ${FiestaEnsembleService.maxEnsembles} ensembles '
                'atteinte : rien n\'a été enregistré.'
            : 'Enregistrement impossible, réessaie.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errors = validateEnsemble(
      _rules.copyWith(ensembleName: _name.text),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundMain,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                    children: [
                      Text(
                        widget.initial == null
                            ? 'Nouvel ensemble'
                            : 'Modifier l\'ensemble',
                        style: AppTextStyles.subtitle(fontSize: 32),
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      _Card(
                        title: 'Catalogue',
                        child: Column(
                          children: [
                            for (final def in kModifierCatalog)
                              _buildModifier(def),
                          ],
                        ),
                      ),
                      _Card(
                        title: 'Choix 1 parmi 3',
                        trailing: _switch(
                          _rules.oneOfThree,
                          (v) => setState(
                            () => _rules = _rules.copyWith(oneOfThree: v),
                          ),
                        ),
                        child: const _Hint(
                          'À chaque fin de manche, chaque équipe non en tête '
                          'choisit 1 carte parmi 3 : un bonus pour elle ou un '
                          'malus pour l\'équipe en tête. Plus l\'écart est '
                          'grand, plus l\'offre est forte.',
                        ),
                      ),
                      _buildCatchUp(),
                      _buildDraw(),
                      _buildCommon(),
                    ],
                  ),
                ),
                _buildSaveBar(errors),
              ],
            ),
          ),
          AppBackButton(onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }

  Widget _buildModifier(ModifierDef def) {
    final s = _settingFor(def);
    final open = s.active && _openModifier == def.id;
    final round3 = def.round3Only;
    final summary = !s.active
        ? 'Désactivé'
        : [
            s.arrival == ModifierArrival.fixed
                ? 'Fixé manche ${s.fixedRound ?? 3}'
                : '${_arrivalLabels[s.arrival]} · dès M${s.startRound}',
            if (def.defaultCharges > 0) '${s.charges} charge(s)',
          ].join(' · ');

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
                      summary,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.gray400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (s.active)
                TextButton(
                  onPressed: () => setState(
                    () => _openModifier = open ? null : def.id,
                  ),
                  child: Text(
                    open ? 'Fermer' : 'Régler',
                    style: const TextStyle(color: AppColors.secondaryCyan),
                  ),
                ),
              _switch(s.active, (v) {
                if (v) _openModifier = def.id;
                _setModifier(def, s.copyWith(active: v));
              }),
            ],
          ),
          if (open) ...[
            const SizedBox(height: 8),
            _Choices<ModifierArrival>(
              values: ModifierArrival.values,
              selected: s.arrival,
              label: (a) => _arrivalLabels[a]!,
              onSelect: (a) => _setModifier(
                def,
                s.copyWith(
                  arrival: a,
                  // Le choix 1 parmi 3 a lieu entre deux manches : M2 au plus
                  // tôt (maquette).
                  startRound:
                      a == ModifierArrival.offer && s.startRound < 2 ? 2 : null,
                ),
              ),
            ),
            if (s.arrival == ModifierArrival.fixed)
              _line(
                'Manche',
                round3
                    ? const _Fixed('3')
                    : _Stepper(
                        value: s.fixedRound ?? 3,
                        min: 1,
                        max: 3,
                        onChanged: (v) =>
                            _setModifier(def, s.copyWith(fixedRound: v)),
                      ),
              )
            else
              _line(
                'À partir de la manche',
                round3
                    ? const _Fixed('3')
                    : _Stepper(
                        value: s.startRound,
                        min: s.arrival == ModifierArrival.offer ? 2 : 1,
                        max: 3,
                        onChanged: (v) =>
                            _setModifier(def, s.copyWith(startRound: v)),
                      ),
              ),
            if (round3) const _Hint('Manche 3 seulement (mime).'),
            if (def.defaultCharges > 0)
              _line(
                def.id == 'free_pass'
                    ? 'Passes gratuites (N)'
                    : 'Charges par équipe et par manche',
                _Stepper(
                  value: s.charges,
                  min: 1,
                  max: def.id == 'free_pass' ? 5 : 3,
                  onChanged: (v) => _setModifier(def, s.copyWith(charges: v)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatchUp() {
    final c = _rules.catchUp;
    Widget slider(String label, int value, int max, int step,
            void Function(int) set) =>
        AppSlider(
          label: label,
          min: 0,
          max: max.toDouble(),
          value: value.clamp(0, max).toDouble(),
          unit: ' s',
          onChanged: (v) => set((v / step).round() * step),
        );
    final on = catchUpOn(c);
    return _Card(
      title: 'Rattrapage',
      // Interrupteur d'interface (maquette) : off = tout à 0, on = valeurs
      // du mode Auto. Rien de plus n'est persisté.
      trailing: _switch(
        on,
        (v) => setState(() => _rules = _rules.copyWith(
              catchUp: v
                  ? CatchUpRules.auto
                  : const CatchUpRules(b1: 0, b2: 0, cap: 0, mal: 0, malCap: 0),
            )),
      ),
      child: !on
          ? const _Hint('Pas de temps en plus ni en moins selon le score.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                slider('Bonus après M1 (par point d\'écart)', c.b1, 10, 1,
                    (v) => _setCatchUp(b1: v)),
                slider('Bonus après M2 (par point d\'écart)', c.b2, 10, 1,
                    (v) => _setCatchUp(b2: v)),
                slider('Plafond du bonus', c.cap, 60, 5,
                    (v) => _setCatchUp(cap: v)),
                slider('Malus du leader (par point d\'écart)', c.mal, 5, 1,
                    (v) => _setCatchUp(mal: v)),
                slider('Plafond du malus', c.malCap, 30, 5,
                    (v) => _setCatchUp(malCap: v)),
                const _Hint(
                  'Le malus du leader s\'applique sur son 1er tour de la manche. '
                  'Écart mesuré par rapport à l\'équipe en tête.',
                ),
              ],
            ),
    );
  }

  Widget _buildDraw() {
    return _Card(
      title: 'Tirage symétrique',
      trailing: _switch(
        _rules.symmetric,
        (v) => setState(() => _rules = _rules.copyWith(symmetric: v)),
      ),
      child: _rules.symmetric
          ? _line(
              'Modificateurs tirés par manche',
              _Stepper(
                value: _rules.drawCount,
                min: 0,
                max: 2,
                onChanged: (v) =>
                    setState(() => _rules = _rules.copyWith(drawCount: v)),
              ),
            )
          : const _Hint('Aucun tirage pour tous en début de manche.'),
    );
  }

  Widget _buildCommon() {
    return _Card(
      title: 'Règles communes',
      child: Column(
        children: [
          _line(
            'Une seule réponse par mot',
            _switch(
              _rules.oneAnswer,
              (v) => setState(() => _rules = _rules.copyWith(oneAnswer: v)),
            ),
          ),
          _line(
            'Temps reporté de fin de manche',
            _switch(
              _rules.carryOver,
              (v) => setState(() => _rules = _rules.copyWith(carryOver: v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(List<String> errors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppColors.backgroundMain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: 'Enregistrer',
            fullWidth: true,
            disabled: errors.isNotEmpty || _saving,
            onPressed: _save,
          ),
          if (errors.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 96),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final error in errors)
                      Text(
                        error,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.warning, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
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
  final Widget? trailing;
  final Widget child;

  const _Card({required this.title, required this.child, this.trailing});

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.gray400, fontSize: 12),
                ),
              ),
              if (trailing != null) trailing!,
            ],
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

class _Fixed extends StatelessWidget {
  final String text;
  const _Fixed(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text, style: AppTextStyles.label),
      );
}

/// Compteur compact −/+ (l'`AppCounter` du design system est taillé pour un
/// écran de réglages plein, trop grand pour une ligne de liste).
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
    Widget button(IconData icon, int next, bool enabled) => IconButton(
          onPressed: enabled ? () => onChanged(next) : null,
          icon: Icon(icon, size: 18),
          color: Colors.white,
          disabledColor: AppColors.gray600,
          style: IconButton.styleFrom(backgroundColor: AppColors.gray700),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove, value - 1, value > min),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            style: AppTextStyles.label,
            textAlign: TextAlign.center,
          ),
        ),
        button(Icons.add, value + 1, value < max),
      ],
    );
  }
}

/// Choix exclusif entre quelques options (l'`AppToggle` n'en prend que deux).
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
