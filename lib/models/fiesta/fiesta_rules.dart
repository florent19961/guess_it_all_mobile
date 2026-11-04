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
        if (fixedRound != null) 'fixedRound': fixedRound,
        'charges': charges,
      };

  static ModifierSetting? tryFromJson(Map<String, dynamic> json) {
    final active = json['active'];
    final arrival = enumFromJson(ModifierArrival.values, json['arrival']);
    final startRound = readOr(json, 'startRound', 1);
    final fixedRound = json['fixedRound'];
    final charges = readOr(json, 'charges', 0);
    if (active is! bool ||
        arrival == null ||
        startRound == null ||
        fixedRound is! int? ||
        charges == null) {
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
    final b1 = readOr(json, 'b1', auto.b1);
    final b2 = readOr(json, 'b2', auto.b2);
    final cap = readOr(json, 'cap', auto.cap);
    final mal = readOr(json, 'mal', auto.mal);
    final malCap = readOr(json, 'malCap', auto.malCap);
    if (b1 == null ||
        b2 == null ||
        cap == null ||
        mal == null ||
        malCap == null) {
      return null;
    }
    return CatchUpRules(b1: b1, b2: b2, cap: cap, mal: mal, malCap: malCap);
  }
}

/// Lit [key] en tolérant son ABSENCE : absent (ou `null`) → [fallback] ;
/// présent et mal typé → `null` (blob illisible).
///
/// 🔴 Règle 7 : un champ ajouté à ces types après la 1ʳᵉ release Fiesta doit se
/// relire « clé absente = défaut documenté », sinon toute partie Fiesta en cours
/// au moment de la mise à jour retomberait silencieusement en Classique.
T? readOr<T extends Object>(Map<String, dynamic> json, String key, T fallback) {
  final raw = json[key];
  if (raw == null) return fallback;
  return raw is T ? raw : null;
}

/// La configuration Fiesta d'une partie, GELÉE dans `GameState` au lancement.
///
/// Immuable : les collections sont copiées en lecture seule à la construction,
/// donc modifier l'ensemble source après `startGame` ne touche pas la partie.
class FiestaRules {
  final FiestaMode mode;

  // `symmetric` : tirage pour tous, lu par les DEUX modes (en Personnalisé, le
  // tirage est actif seulement si `symmetric && drawCount > 0`).
  // `autoCalibrate` : mode Auto ; au moins un des deux allumé en Auto.
  final bool symmetric;
  final bool autoCalibrate;

  // Mode Personnalisé.
  final String? ensembleName;

  /// Réglage par id de catalogue. Un id absent = modificateur non réglé.
  final Map<String, ModifierSetting> modifiers;
  final bool oneOfThree;
  final CatchUpRules catchUp;

  /// Nombre de modificateurs tirés pour tous à chaque manche, 0 à 3
  /// (plafond `maxModifiersPerTeam`).
  final int drawCount;

  /// Modificateur « Une seule réponse » (`kOneAnswer`) pour TOUTE la partie :
  /// coché dans l'ensemble en Personnalisé, tiré au lancement en Auto. Même
  /// clé JSON qu'à l'époque où c'était une « règle commune » : un blob relu
  /// garde son sens (absente = `true`, l'ancien défaut). Le report du temps
  /// de fin de manche n'est PAS un réglage (epic : « conservé ») ; l'ancienne
  /// clé `carryOver` d'un blob est ignorée.
  final bool oneAnswer;

  FiestaRules({
    required this.mode,
    this.symmetric = true,
    this.autoCalibrate = true,
    this.ensembleName,
    Map<String, ModifierSetting> modifiers = const {},
    this.oneOfThree = false,
    this.catchUp = CatchUpRules.auto,
    this.drawCount = 1,
    this.oneAnswer = false,
  }) : modifiers = Map.unmodifiable(modifiers);

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'symmetric': symmetric,
        'autoCalibrate': autoCalibrate,
        if (ensembleName != null) 'ensembleName': ensembleName,
        'modifiers':
            modifiers.map((id, setting) => MapEntry(id, setting.toJson())),
        'oneOfThree': oneOfThree,
        'catchUp': catchUp.toJson(),
        'drawCount': drawCount,
        'oneAnswer': oneAnswer,
      };

  /// Variante tolérante : `null` si la structure est illisible (`mode` inconnu,
  /// champ présent mais mal typé). Un champ ABSENT prend la valeur par défaut
  /// du constructeur ([readOr], règle 7). Un réglage de modificateur d'id
  /// inconnu ou mal formé est ignoré seul, pas l'ensemble.
  static FiestaRules? tryFromJson(Map<String, dynamic> json) {
    final mode = enumFromJson(FiestaMode.values, json['mode']);
    final symmetric = readOr(json, 'symmetric', true);
    final autoCalibrate = readOr(json, 'autoCalibrate', true);
    final ensembleName = json['ensembleName'];
    final rawModifiers = readOr<Map>(json, 'modifiers', const {});
    final oneOfThree = readOr(json, 'oneOfThree', false);
    final rawCatchUp = readOr<Map>(json, 'catchUp', const {});
    final drawCount = readOr(json, 'drawCount', 1);
    final oneAnswer = readOr(json, 'oneAnswer', true);
    if (mode == null ||
        symmetric == null ||
        autoCalibrate == null ||
        ensembleName is! String? ||
        rawModifiers == null ||
        oneOfThree == null ||
        rawCatchUp == null ||
        drawCount == null ||
        oneAnswer == null) {
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
    );
  }
}
