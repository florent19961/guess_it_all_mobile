import 'modifier_catalog.dart';

enum FiestaMode { auto, custom }

/// Mode d'un modificateur dans un ensemble (Fiesta v3), UN seul par
/// modificateur :
/// - [always] : actif pour toutes les équipes, toute la manche, sur chaque
///   manche cochée ;
/// - [draw] : candidat au tirage du début de chaque manche cochée ;
/// - [cartridge] : réserve de chaque équipe pour TOUTE LA PARTIE, jouée au
///   tour de son choix.
enum ModifierMode { always, draw, cartridge }

/// Les modes « règle de manche », les seuls où les manches cochées comptent.
bool isRoundRuleMode(ModifierMode mode) =>
    mode == ModifierMode.always || mode == ModifierMode.draw;

/// Réglage d'UN modificateur dans un ensemble.
class ModifierSetting {
  final bool active;

  /// Manches cochées, parmi {1, 2, 3}. Ne compte que pour [ModifierMode.always]
  /// et [ModifierMode.draw] (au moins une si [active]).
  final Set<int> rounds;
  final ModifierMode mode;

  /// [ModifierMode.cartridge] : cartouches par équipe pour TOUTE LA PARTIE.
  /// 0 = aucune au départ, elle ne s'obtient que par le coup de pouce.
  final int charges;

  ModifierSetting({
    required this.active,
    required Set<int> rounds,
    required this.mode,
    this.charges = 1,
  }) : rounds = Set.unmodifiable(rounds);

  ModifierSetting copyWith({
    bool? active,
    Set<int>? rounds,
    ModifierMode? mode,
    int? charges,
  }) =>
      ModifierSetting(
        active: active ?? this.active,
        rounds: rounds ?? this.rounds,
        mode: mode ?? this.mode,
        charges: charges ?? this.charges,
      );

  Map<String, dynamic> toJson() => {
        'active': active,
        // Trié : deux réglages égaux ont le même JSON (doublons, `_loaded`).
        'rounds': rounds.toList()..sort(),
        'mode': mode.name,
        'charges': charges,
      };

  /// `null` si illisible (champ manquant ou mal typé, manche hors 1-3, charges
  /// négatives ; la borne haute dépend de l'id : `FiestaRules.tryFromJson`).
  static ModifierSetting? tryFromJson(Map<String, dynamic> json) {
    final active = json['active'];
    final rawRounds = json['rounds'];
    final mode = enumFromJson(ModifierMode.values, json['mode']);
    final charges = readOr(json, 'charges', 1);
    if (active is! bool ||
        rawRounds is! List ||
        mode == null ||
        charges == null ||
        charges < 0) {
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
    );
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

/// Borne des règles de la partie (éditeur et relecture).
const int kMaxDrawCount = 5;

/// Borne du coup de pouce : cartouches reçues après chaque manche (éditeur et
/// relecture).
const int kMaxBoostCount = 3;

/// Cartouches par équipe au plus pour le modificateur [id] (éditeur et
/// relecture) : la Passe gratuite va plus loin, chacune ne vaut qu'un tour.
int maxCartridges(String id) => id == 'free_pass' ? 5 : 3;

/// La configuration Fiesta d'une partie, GELÉE dans `GameState` au lancement.
///
/// Immuable : les collections sont copiées en lecture seule à la construction,
/// donc modifier l'ensemble source après `startGame` ne touche pas la partie.
///
/// Forme v3 (Fiesta v3, 2026-11-05) : JSON marqué `format: 3`. Un blob d'un
/// autre format est ILLISIBLE : la Fiesta n'a jamais été publiée, on ne
/// traduit pas, l'appelant ignore l'ensemble ou abandonne la partie.
class FiestaRules {
  static const int format = 3;

  final FiestaMode mode;

  /// Personnalisé : nom de l'ensemble.
  final String? ensembleName;

  /// Réglage par id de catalogue. Un id absent = modificateur non réglé
  /// (inactif).
  final Map<String, ModifierSetting> modifiers;

  /// Modificateurs tirés pour tous à chaque manche, 0 (aucun tirage) à
  /// [kMaxDrawCount], parmi ceux en [ModifierMode.draw]. Ignoré en Auto
  /// (1 ou 2 par manche, au hasard de la graine).
  final int drawCount;

  /// Coup de pouce à l'équipe menée : après M1 et M2, chaque équipe non en tête
  /// reçoit [boostCount] cartouches au hasard (`trailing_boost.dart`), de 0
  /// (éteint) à [kMaxBoostCount]. 1 en Auto (`autoRules`).
  final int boostCount;

  FiestaRules({
    required this.mode,
    this.ensembleName,
    Map<String, ModifierSetting> modifiers = const {},
    this.drawCount = 1,
    this.boostCount = 0,
  }) : modifiers = Map.unmodifiable(modifiers);

  FiestaRules copyWith({
    String? ensembleName,
    Map<String, ModifierSetting>? modifiers,
    int? drawCount,
    int? boostCount,
  }) =>
      FiestaRules(
        mode: mode,
        ensembleName: ensembleName ?? this.ensembleName,
        modifiers: modifiers ?? this.modifiers,
        drawCount: drawCount ?? this.drawCount,
        boostCount: boostCount ?? this.boostCount,
      );

  /// Réglage actif de [id], `null` s'il est absent ou coupé.
  ModifierSetting? activeSetting(String id) {
    final s = modifiers[id];
    return s != null && s.active ? s : null;
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'mode': mode.name,
        if (ensembleName != null) 'ensembleName': ensembleName,
        'modifiers':
            modifiers.map((id, setting) => MapEntry(id, setting.toJson())),
        'drawCount': drawCount,
        'boostCount': boostCount,
      };

  /// Variante tolérante : `null` si la structure est illisible (autre format,
  /// `mode` inconnu, champ présent mais mal typé, compteur hors bornes). Un
  /// champ ABSENT prend la valeur par défaut du constructeur ([readOr],
  /// règle 7). Un réglage de modificateur d'id inconnu ou mal formé est
  /// ignoré seul, pas l'ensemble.
  static FiestaRules? tryFromJson(Map<String, dynamic> json) {
    if (json['format'] != format) return null;
    final mode = enumFromJson(FiestaMode.values, json['mode']);
    final ensembleName = json['ensembleName'];
    final rawModifiers = readOr<Map>(json, 'modifiers', const {});
    final drawCount = readOr(json, 'drawCount', 1);
    final boostCount = _readBoostCount(json);
    if (mode == null ||
        ensembleName is! String? ||
        rawModifiers == null ||
        drawCount == null ||
        drawCount < 0 ||
        drawCount > kMaxDrawCount ||
        boostCount == null) {
      return null;
    }

    final modifiers = <String, ModifierSetting>{};
    for (final entry in rawModifiers.entries) {
      final id = entry.key;
      final raw = entry.value;
      if (id is! String || modifierById(id) == null || raw is! Map) continue;
      final setting =
          ModifierSetting.tryFromJson(Map<String, dynamic>.from(raw));
      if (setting != null && setting.charges <= maxCartridges(id)) {
        modifiers[id] = setting;
      }
    }

    return FiestaRules(
      mode: mode,
      ensembleName: ensembleName,
      modifiers: modifiers,
      drawCount: drawCount,
      boostCount: boostCount,
    );
  }

  /// `boostCount` ; absent, l'ancien booléen `trailingBoost` (vrai = 1). `null`
  /// si mal typé ou hors bornes, comme `drawCount`.
  static int? _readBoostCount(Map<String, dynamic> json) {
    if (json['boostCount'] == null) {
      final legacy = readOr(json, 'trailingBoost', false);
      return legacy == null ? null : (legacy ? 1 : 0);
    }
    final count = readOr(json, 'boostCount', 0);
    return count == null || count < 0 || count > kMaxBoostCount ? null : count;
  }
}
