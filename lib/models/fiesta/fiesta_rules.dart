import 'modifier_catalog.dart';

enum FiestaMode { auto, custom }

/// Mode d'un modificateur dans un ensemble (Fiesta v2), UN seul par
/// modificateur, en deux familles :
/// - « Toute la manche, pour tous » (règle de manche, personne ne décide) :
///   [always] actif toute la manche sur chaque manche cochée ; [draw]
///   candidat au tirage du début de chaque manche cochée.
/// - « Cartouche · un tour » : [stock] N cartouches par équipe au début de
///   chaque manche cochée ; [offer] gagnée entre deux manches (1 parmi 3).
enum ModifierMode { always, draw, stock, offer }

/// Les modes « Toute la manche, pour tous ».
bool isRoundRuleMode(ModifierMode mode) =>
    mode == ModifierMode.always || mode == ModifierMode.draw;

/// Réglage d'UN modificateur dans un ensemble.
class ModifierSetting {
  final bool active;

  /// Manches cochées, parmi {1, 2, 3} (au moins une si [active]).
  final Set<int> rounds;
  final ModifierMode mode;

  /// [ModifierMode.stock] : nombre de cartouches par équipe (au moins 1).
  final int charges;

  /// [ModifierMode.stock] : `true` = [charges] pour toute la partie, `false`
  /// = remises à [charges] à chaque manche cochée.
  final bool perGame;

  ModifierSetting({
    required this.active,
    required Set<int> rounds,
    required this.mode,
    this.charges = 1,
    this.perGame = false,
  }) : rounds = Set.unmodifiable(rounds);

  ModifierSetting copyWith({
    bool? active,
    Set<int>? rounds,
    ModifierMode? mode,
    int? charges,
    bool? perGame,
  }) =>
      ModifierSetting(
        active: active ?? this.active,
        rounds: rounds ?? this.rounds,
        mode: mode ?? this.mode,
        charges: charges ?? this.charges,
        perGame: perGame ?? this.perGame,
      );

  Map<String, dynamic> toJson() => {
        'active': active,
        // Trié : deux réglages égaux ont le même JSON (doublons, `_loaded`).
        'rounds': rounds.toList()..sort(),
        'mode': mode.name,
        'charges': charges,
        'perGame': perGame,
      };

  /// `null` si illisible (champ manquant ou mal typé, manche hors 1-3).
  static ModifierSetting? tryFromJson(Map<String, dynamic> json) {
    final active = json['active'];
    final rawRounds = json['rounds'];
    final mode = enumFromJson(ModifierMode.values, json['mode']);
    final charges = readOr(json, 'charges', 1);
    final perGame = readOr(json, 'perGame', false);
    if (active is! bool ||
        rawRounds is! List ||
        mode == null ||
        charges == null ||
        perGame == null) {
      return null;
    }
    final rounds = <int>{};
    for (final r in rawRounds) {
      if (r is! int || r < 1 || r > 3) return null;
      rounds.add(r);
    }
    return ModifierSetting(
      active: active,
      rounds: rounds,
      mode: mode,
      charges: charges,
      perGame: perGame,
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

/// Rattrapage coupé : tous les curseurs à 0 (voir [catchUpOn]).
const kCatchUpOff = CatchUpRules(b1: 0, b2: 0, cap: 0, mal: 0, malCap: 0);

/// Le rattrapage est « actif » dès qu'un de ses curseurs est au-dessus de 0 :
/// l'interrupteur de l'éditeur n'est pas un champ persisté, il met tout à 0
/// ou rend `CatchUpRules.auto`.
bool catchUpOn(CatchUpRules c) =>
    c.b1 > 0 || c.b2 > 0 || c.cap > 0 || c.mal > 0 || c.malCap > 0;

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

/// Bornes des règles de la partie (éditeur et relecture).
const int kMaxDrawCount = 5;
const int kMaxPick3Choices = 3;

/// La configuration Fiesta d'une partie, GELÉE dans `GameState` au lancement.
///
/// Immuable : les collections sont copiées en lecture seule à la construction,
/// donc modifier l'ensemble source après `startGame` ne touche pas la partie.
///
/// Forme v2 (Fiesta v2, 2026-11-04) : JSON marqué `format: 2`. Un blob sans
/// cette marque (forme v1 : `symmetric`, `oneOfThree`, `oneAnswer`,
/// `arrival`…) est ILLISIBLE : la Fiesta n'a jamais été publiée, on ne
/// traduit pas, l'appelant ignore l'ensemble ou abandonne la partie.
class FiestaRules {
  static const int format = 2;

  final FiestaMode mode;

  /// Auto : rattrapage auto-calibré et coup de pouce de l'app.
  final bool autoCalibrate;

  /// Personnalisé : nom de l'ensemble.
  final String? ensembleName;

  /// Réglage par id de catalogue. Un id absent = modificateur non réglé
  /// (inactif).
  final Map<String, ModifierSetting> modifiers;

  /// Modificateurs tirés pour tous à chaque manche, 0 (aucun tirage) à
  /// [kMaxDrawCount], parmi ceux en [ModifierMode.draw]. Ignoré en Auto
  /// (1 ou 2 par manche, au hasard de la graine).
  final int drawCount;

  /// Cartes prises par équipe à chaque choix « 1 parmi 3 » : autant de
  /// rangées de 3 cartes, 1 à [kMaxPick3Choices].
  final int pick3Choices;
  final CatchUpRules catchUp;

  FiestaRules({
    required this.mode,
    this.autoCalibrate = true,
    this.ensembleName,
    Map<String, ModifierSetting> modifiers = const {},
    this.drawCount = 1,
    this.pick3Choices = 1,
    this.catchUp = CatchUpRules.auto,
  }) : modifiers = Map.unmodifiable(modifiers);

  FiestaRules copyWith({
    String? ensembleName,
    Map<String, ModifierSetting>? modifiers,
    int? drawCount,
    int? pick3Choices,
    CatchUpRules? catchUp,
  }) =>
      FiestaRules(
        mode: mode,
        autoCalibrate: autoCalibrate,
        ensembleName: ensembleName ?? this.ensembleName,
        modifiers: modifiers ?? this.modifiers,
        drawCount: drawCount ?? this.drawCount,
        pick3Choices: pick3Choices ?? this.pick3Choices,
        catchUp: catchUp ?? this.catchUp,
      );

  /// Réglage actif de [id], `null` s'il est absent ou coupé.
  ModifierSetting? activeSetting(String id) {
    final s = modifiers[id];
    return s != null && s.active ? s : null;
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'mode': mode.name,
        'autoCalibrate': autoCalibrate,
        if (ensembleName != null) 'ensembleName': ensembleName,
        'modifiers':
            modifiers.map((id, setting) => MapEntry(id, setting.toJson())),
        'drawCount': drawCount,
        'pick3Choices': pick3Choices,
        'catchUp': catchUp.toJson(),
      };

  /// Variante tolérante : `null` si la structure est illisible (forme v1,
  /// `mode` inconnu, champ présent mais mal typé, compteur hors bornes). Un
  /// champ ABSENT prend la valeur par défaut du constructeur ([readOr],
  /// règle 7). Un réglage de modificateur d'id inconnu ou mal formé est
  /// ignoré seul, pas l'ensemble.
  static FiestaRules? tryFromJson(Map<String, dynamic> json) {
    if (json['format'] != format) return null;
    final mode = enumFromJson(FiestaMode.values, json['mode']);
    final autoCalibrate = readOr(json, 'autoCalibrate', true);
    final ensembleName = json['ensembleName'];
    final rawModifiers = readOr<Map>(json, 'modifiers', const {});
    final drawCount = readOr(json, 'drawCount', 1);
    final pick3Choices = readOr(json, 'pick3Choices', 1);
    final rawCatchUp = readOr<Map>(json, 'catchUp', const {});
    if (mode == null ||
        autoCalibrate == null ||
        ensembleName is! String? ||
        rawModifiers == null ||
        drawCount == null ||
        drawCount < 0 ||
        drawCount > kMaxDrawCount ||
        pick3Choices == null ||
        pick3Choices < 1 ||
        pick3Choices > kMaxPick3Choices ||
        rawCatchUp == null) {
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
      autoCalibrate: autoCalibrate,
      ensembleName: ensembleName,
      modifiers: modifiers,
      drawCount: drawCount,
      pick3Choices: pick3Choices,
      catchUp: catchUp,
    );
  }
}
