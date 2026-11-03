import 'fiesta_rules.dart';
import 'modifier_catalog.dart';

/// Un ensemble du mode Personnalisé : des `FiestaRules` nommées, enregistrées
/// sur le téléphone (`FiestaEnsembleService`).
///
/// Le nom vit dans `rules.ensembleName` (une seule source) : l'ensemble choisi
/// peut ainsi être gelé tel quel dans la partie par `startGame`.
class FiestaEnsemble {
  /// Identifiant stable : il survit à « Modifier » (remplacement sur place).
  final String id;
  final FiestaRules rules;

  const FiestaEnsemble({required this.id, required this.rules});

  String get name => rules.ensembleName ?? '';

  Map<String, dynamic> toJson() => {'id': id, 'rules': rules.toJson()};

  /// `null` si l'ensemble est illisible : l'appelant l'ignore seul.
  static FiestaEnsemble? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rawRules = json['rules'];
    if (id is! String || rawRules is! Map) return null;
    final rules = FiestaRules.tryFromJson(Map<String, dynamic>.from(rawRules));
    // Un ensemble est toujours Personnalisé : des règles Auto ici ne
    // viennent pas de l'éditeur, on ne les rend pas à `onUse`.
    if (rules == null || rules.mode != FiestaMode.custom) return null;
    return FiestaEnsemble(id: id, rules: rules);
  }
}

/// Règles d'un nouvel ensemble : les valeurs par défaut de la maquette
/// (`mkSet`). Tout le catalogue est actif ; les contraintes de mime arrivent en
/// manche 3 (« Dessiner » fixé dessus, les autres tirées), les bonus sont
/// proposés dès M2, les malus tirés dès M1.
FiestaRules defaultEnsembleRules(String name) => FiestaRules(
      mode: FiestaMode.custom,
      ensembleName: name,
      modifiers: {
        for (final def in kModifierCatalog)
          def.id: ModifierSetting(
            active: true,
            arrival: def.id == 'draw'
                ? ModifierArrival.fixed
                : def.nature == ModifierNature.bonus && !def.round3Only
                    ? ModifierArrival.offer
                    : ModifierArrival.draw,
            startRound: def.round3Only
                ? 3
                : def.nature == ModifierNature.bonus
                    ? 2
                    : 1,
            fixedRound: 3,
            charges: def.defaultCharges,
          ),
      },
      oneOfThree: true,
    );

/// Copie modifiée, pour l'éditeur et la duplication. Extension plutôt qu'un
/// `copyWith` dans `FiestaRules` : le type appartient à la story 2-2.
extension FiestaRulesCopy on FiestaRules {
  FiestaRules copyWith({
    String? ensembleName,
    Map<String, ModifierSetting>? modifiers,
    bool? oneOfThree,
    CatchUpRules? catchUp,
    bool? symmetric,
    int? drawCount,
    bool? oneAnswer,
    bool? carryOver,
  }) =>
      FiestaRules(
        mode: mode,
        symmetric: symmetric ?? this.symmetric,
        autoCalibrate: autoCalibrate,
        ensembleName: ensembleName ?? this.ensembleName,
        modifiers: modifiers ?? this.modifiers,
        oneOfThree: oneOfThree ?? this.oneOfThree,
        catchUp: catchUp ?? this.catchUp,
        drawCount: drawCount ?? this.drawCount,
        oneAnswer: oneAnswer ?? this.oneAnswer,
        carryOver: carryOver ?? this.carryOver,
      );
}

/// Le rattrapage d'un ensemble est « actif » dès qu'un de ses curseurs est
/// au-dessus de 0 : l'interrupteur de l'éditeur n'est pas un champ persisté
/// (`CatchUpRules` n'en a pas), il met tout à 0 ou rend `CatchUpRules.auto`.
bool catchUpOn(CatchUpRules c) =>
    c.b1 > 0 || c.b2 > 0 || c.cap > 0 || c.mal > 0 || c.malCap > 0;

/// Copie modifiée d'un réglage, pour l'éditeur (même raison que ci-dessus).
extension ModifierSettingCopy on ModifierSetting {
  ModifierSetting copyWith({
    bool? active,
    ModifierArrival? arrival,
    int? startRound,
    int? fixedRound,
    int? charges,
  }) =>
      ModifierSetting(
        active: active ?? this.active,
        arrival: arrival ?? this.arrival,
        startRound: startRound ?? this.startRound,
        fixedRound: fixedRound ?? this.fixedRound,
        charges: charges ?? this.charges,
      );
}
