import 'modifier_catalog.dart';

enum FiestaMode { auto, custom }

/// Comment un modificateur arrive en jeu (mode Personnalisé).
enum ModifierArrival { draw, offer, fixed }

/// Réglage d'UN modificateur dans un ensemble Personnalisé.
class ModifierSetting {
  final bool active;
  final ModifierArrival arrival;

  /// Manche à partir de laquelle il peut arriver (`draw` / `offer`).
  final int startRound;

  /// Manche sur laquelle il est fixé (`fixed`).
  final int? fixedRound;
  final int charges;

  const ModifierSetting({
    required this.active,
    required this.arrival,
    required this.startRound,
    this.fixedRound,
    required this.charges,
  });

  Map<String, dynamic> toJson() => {
        'active': active,
        'arrival': arrival.name,
        'startRound': startRound,
        'fixedRound': fixedRound,
        'charges': charges,
      };

  static ModifierSetting? tryFromJson(Map<String, dynamic> json) {
    final active = json['active'];
    final arrival = enumFromJson(ModifierArrival.values, json['arrival']);
    final startRound = json['startRound'];
    final fixedRound = json['fixedRound'];
    final charges = json['charges'];
    if (active is! bool ||
        arrival == null ||
        startRound is! int ||
        fixedRound is! int? ||
        charges is! int) {
      return null;
    }
    return ModifierSetting(
      active: active,
      arrival: arrival,
      startRound: startRound,
      fixedRound: fixedRound,
      charges: charges,
    );
  }
}

/// Curseurs du rattrapage, en secondes.
class CatchUpRules {
  /// Bonus par point d'écart après M1 / après M2, et son plafond.
  final int b1;
  final int b2;
  final int cap;

  /// Malus du leader par point d'écart, et son plafond.
  final int mal;
  final int malCap;

  const CatchUpRules({
    required this.b1,
    required this.b2,
    required this.cap,
    required this.mal,
    required this.malCap,
  });

  /// Valeurs du mode Auto (cadrage figé) : +3/+5 s, plafond 30 s ; −1 s,
  /// plafond 15 s.
  static const auto = CatchUpRules(b1: 3, b2: 5, cap: 30, mal: 1, malCap: 15);

  Map<String, dynamic> toJson() =>
      {'b1': b1, 'b2': b2, 'cap': cap, 'mal': mal, 'malCap': malCap};

  static CatchUpRules? tryFromJson(Map<String, dynamic> json) {
    final values = [
      json['b1'],
      json['b2'],
      json['cap'],
      json['mal'],
      json['malCap'],
    ];
    if (values.any((v) => v is! int)) return null;
    return CatchUpRules(
      b1: values[0] as int,
      b2: values[1] as int,
      cap: values[2] as int,
      mal: values[3] as int,
      malCap: values[4] as int,
    );
  }
}

/// La configuration Fiesta d'une partie, GELÉE dans `GameState` au lancement.
///
/// Immuable : les collections sont copiées en lecture seule à la construction,
/// donc modifier l'ensemble source après `startGame` ne touche pas la partie.
class FiestaRules {
  final FiestaMode mode;

  // Mode Auto : au moins un des deux allumé.
  final bool symmetric;
  final bool autoCalibrate;

  // Mode Personnalisé.
  final String? ensembleName;

  /// Réglage par id de catalogue. Un id absent = modificateur non réglé.
  final Map<String, ModifierSetting> modifiers;
  final bool oneOfThree;
  final CatchUpRules catchUp;

  /// Nombre de modificateurs tirés pour tous à chaque manche, 0 à 2.
  final int drawCount;

  // Règles communes.
  final bool oneAnswer;
  final bool carryOver;

  FiestaRules({
    required this.mode,
    this.symmetric = true,
    this.autoCalibrate = true,
    this.ensembleName,
    Map<String, ModifierSetting> modifiers = const {},
    this.oneOfThree = false,
    this.catchUp = CatchUpRules.auto,
    this.drawCount = 1,
    this.oneAnswer = true,
    this.carryOver = true,
  }) : modifiers = Map.unmodifiable(modifiers);

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'symmetric': symmetric,
        'autoCalibrate': autoCalibrate,
        'ensembleName': ensembleName,
        'modifiers':
            modifiers.map((id, setting) => MapEntry(id, setting.toJson())),
        'oneOfThree': oneOfThree,
        'catchUp': catchUp.toJson(),
        'drawCount': drawCount,
        'oneAnswer': oneAnswer,
        'carryOver': carryOver,
      };

  /// Variante tolérante : `null` si la structure est illisible. Un réglage de
  /// modificateur d'id inconnu ou mal formé est ignoré seul, pas l'ensemble.
  static FiestaRules? tryFromJson(Map<String, dynamic> json) {
    final mode = enumFromJson(FiestaMode.values, json['mode']);
    final symmetric = json['symmetric'];
    final autoCalibrate = json['autoCalibrate'];
    final ensembleName = json['ensembleName'];
    final rawModifiers = json['modifiers'];
    final oneOfThree = json['oneOfThree'];
    final rawCatchUp = json['catchUp'];
    final drawCount = json['drawCount'];
    final oneAnswer = json['oneAnswer'];
    final carryOver = json['carryOver'];
    if (mode == null ||
        symmetric is! bool ||
        autoCalibrate is! bool ||
        ensembleName is! String? ||
        rawModifiers is! Map ||
        oneOfThree is! bool ||
        rawCatchUp is! Map ||
        drawCount is! int ||
        oneAnswer is! bool ||
        carryOver is! bool) {
      return null;
    }
    final catchUp =
        CatchUpRules.tryFromJson(Map<String, dynamic>.from(rawCatchUp));
    if (catchUp == null) return null;

    final modifiers = <String, ModifierSetting>{};
    for (final entry in rawModifiers.entries) {
      final id = entry.key;
      final raw = entry.value;
      if (id is! String || modifierById(id) == null || raw is! Map) continue;
      final setting =
          ModifierSetting.tryFromJson(Map<String, dynamic>.from(raw));
      if (setting != null) modifiers[id] = setting;
    }

    return FiestaRules(
      mode: mode,
      symmetric: symmetric,
      autoCalibrate: autoCalibrate,
      ensembleName: ensembleName,
      modifiers: modifiers,
      oneOfThree: oneOfThree,
      catchUp: catchUp,
      drawCount: drawCount,
      oneAnswer: oneAnswer,
      carryOver: carryOver,
    );
  }
}
