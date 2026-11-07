import 'modifier_catalog.dart';

/// Les trois menus de l'éditeur, où un modificateur peut être verrouillé.
enum EnsembleMenu { always, draw, cartridge }

/// Réglage d'UN modificateur dans un ensemble (Fiesta v4) : trois réglages
/// INDÉPENDANTS. Un modificateur peut être à la fois en aléatoire et en
/// cartouche. Ce qui est réglé mais verrouillé est gardé sans jouer
/// ([FiestaRules.lockReason]) : décocher le « Toujours » le restaure.
class ModifierSetting {
  /// Actif pour toutes les équipes, à toutes les manches où il existe.
  final bool always;

  /// Candidat au tirage du début de chaque manche où il existe.
  final bool draw;

  /// Cartouches données à chaque équipe au début de la partie, de 0 à
  /// [kMaxCount].
  final int charges;

  const ModifierSetting({
    this.always = false,
    this.draw = false,
    this.charges = 0,
  });

  ModifierSetting copyWith({bool? always, bool? draw, int? charges}) =>
      ModifierSetting(
        always: always ?? this.always,
        draw: draw ?? this.draw,
        charges: charges ?? this.charges,
      );

  Map<String, dynamic> toJson() =>
      {'always': always, 'draw': draw, 'charges': charges};

  /// `null` si illisible (champ mal typé, charges hors bornes). Clé absente =
  /// valeur par défaut ([readOr], règle 7).
  static ModifierSetting? tryFromJson(Map<String, dynamic> json) {
    final always = readOr(json, 'always', false);
    final draw = readOr(json, 'draw', false);
    final charges = readOr(json, 'charges', 0);
    if (always == null ||
        draw == null ||
        charges == null ||
        charges < 0 ||
        charges > kMaxCount) {
      return null;
    }
    return ModifierSetting(always: always, draw: draw, charges: charges);
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

/// Borne des compteurs des règles (éditeur et relecture) : cartouches d'un
/// modificateur, tirés par manche, aux équipes menées.
const int kMaxCount = 5;

/// Borne de « À tous, à chaque manche » (éditeur et relecture) : Explosif en
/// donne 10.
const int kMaxAllCount = 10;

/// La configuration Fiesta d'une partie, GELÉE dans `GameState` au lancement.
///
/// Immuable : les collections sont copiées en lecture seule à la construction,
/// donc modifier l'ensemble source après `startGame` ne touche pas la partie.
///
/// Forme v4 (Fiesta v4, 2026-11-05) : JSON marqué `format: 4`. Un blob d'un
/// autre format est ILLISIBLE : la Fiesta n'a jamais été publiée, on ne
/// traduit pas, l'appelant ignore l'ensemble ou abandonne la partie.
class FiestaRules {
  static const int format = 4;

  /// Nom de l'ensemble.
  final String? ensembleName;

  /// Réglage par id de catalogue. Un id absent = rien de réglé.
  final Map<String, ModifierSetting> modifiers;

  /// Modificateurs tirés pour tous à chaque manche, de 0 à [kMaxCount].
  final int drawCount;

  /// « À tous, à chaque manche » : cartouches au hasard pour chaque équipe au
  /// début de chaque manche, M1 comprise, de 0 à [kMaxAllCount].
  final int allCount;

  /// « Aux équipes menées » : cartouches au hasard pour chaque équipe non en
  /// tête après M1 et M2. Sans effet si [balance].
  final int trailingCount;

  /// « Équilibrer la partie » : remplace [trailingCount], le nombre de
  /// cartouches suit l'écart avec le leader (`balanceGiftCount`).
  final bool balance;

  /// « Défis surprises » : 1 ou 2 défis entre les manches. Clé omise si coupé.
  final bool challenges;

  FiestaRules({
    this.ensembleName,
    Map<String, ModifierSetting> modifiers = const {},
    this.drawCount = 0,
    this.allCount = 0,
    this.trailingCount = 0,
    this.balance = false,
    this.challenges = false,
  }) : modifiers = Map.unmodifiable(modifiers);

  FiestaRules copyWith({
    String? ensembleName,
    Map<String, ModifierSetting>? modifiers,
    int? drawCount,
    int? allCount,
    int? trailingCount,
    bool? balance,
    bool? challenges,
  }) =>
      FiestaRules(
        ensembleName: ensembleName ?? this.ensembleName,
        modifiers: modifiers ?? this.modifiers,
        drawCount: drawCount ?? this.drawCount,
        allCount: allCount ?? this.allCount,
        trailingCount: trailingCount ?? this.trailingCount,
        balance: balance ?? this.balance,
        challenges: challenges ?? this.challenges,
      );

  ModifierSetting settingOf(String id) =>
      modifiers[id] ?? const ModifierSetting();

  bool isAlways(String id) => modifiers[id]?.always ?? false;

  /// Pourquoi [id] est verrouillé dans [menu], `null` s'il ne l'est pas.
  /// Verrouillé = réglages gardés, mais sans effet en partie :
  /// - en « Toujours », un modificateur l'est dans les 2 autres menus ;
  /// - un mime en « Toujours » y verrouille les autres mimes, partout, sauf la
  ///   paire Bruitages / drap ;
  /// - « Interdit de passer » en « Toujours » verrouille Passe gratuite en
  ///   cartouche, qui ne servirait jamais.
  String? lockReason(String id, EnsembleMenu menu) {
    if (menu != EnsembleMenu.always && isAlways(id)) return 'Actif en Toujours';
    final def = modifierById(id);
    if (def != null && def.mimeFamily) {
      for (final other in kModifierCatalog) {
        if (other.id != id &&
            other.mimeFamily &&
            isAlways(other.id) &&
            !areCompatible(other.id, id)) {
          return '${other.name} est en Toujours';
        }
      }
    }
    if (menu == EnsembleMenu.cartridge &&
        isAlways('no_pass') &&
        !areCompatible('no_pass', id)) {
      return '${modifierById('no_pass')!.name} est en Toujours';
    }
    return null;
  }

  /// [id] est candidat au tirage (activé et non verrouillé).
  bool drawsFrom(String id) =>
      settingOf(id).draw && lockReason(id, EnsembleMenu.draw) == null;

  /// Cartouches [id] données à chaque équipe en début de partie (0 si
  /// verrouillé).
  int chargesOf(String id) => lockReason(id, EnsembleMenu.cartridge) == null
      ? settingOf(id).charges
      : 0;

  Map<String, dynamic> toJson() => {
        'format': format,
        if (ensembleName != null) 'ensembleName': ensembleName,
        'modifiers':
            modifiers.map((id, setting) => MapEntry(id, setting.toJson())),
        'drawCount': drawCount,
        'allCount': allCount,
        'trailingCount': trailingCount,
        'balance': balance,
        if (challenges) 'challenges': true,
      };

  /// Variante tolérante : `null` si la structure est illisible (autre format,
  /// champ présent mais mal typé, compteur hors bornes). Un champ ABSENT prend
  /// la valeur par défaut du constructeur ([readOr], règle 7). Un réglage de
  /// modificateur d'id inconnu ou mal formé est ignoré seul, pas l'ensemble.
  static FiestaRules? tryFromJson(Map<String, dynamic> json) {
    if (json['format'] != format) return null;
    final ensembleName = json['ensembleName'];
    final rawModifiers = readOr<Map>(json, 'modifiers', const {});
    final drawCount = _readCount(json, 'drawCount');
    final allCount = _readCount(json, 'allCount', max: kMaxAllCount);
    final trailingCount = _readCount(json, 'trailingCount');
    final balance = readOr(json, 'balance', false);
    final challenges = readOr(json, 'challenges', false);
    if (ensembleName is! String? ||
        rawModifiers == null ||
        drawCount == null ||
        allCount == null ||
        trailingCount == null ||
        balance == null ||
        challenges == null) {
      return null;
    }

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
      ensembleName: ensembleName,
      modifiers: modifiers,
      drawCount: drawCount,
      allCount: allCount,
      trailingCount: trailingCount,
      balance: balance,
      challenges: challenges,
    );
  }

  static int? _readCount(Map<String, dynamic> json, String key,
      {int max = kMaxCount}) {
    final count = readOr(json, key, 0);
    return count == null || count < 0 || count > max ? null : count;
  }
}
