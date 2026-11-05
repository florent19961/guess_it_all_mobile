import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'turn_effects.dart';

/// État Fiesta d'une partie en cours, porté par `GameState.fiesta`.
///
/// Nul dans `GameState` = partie Classique. Tout ce qui est ici est persisté
/// avec la partie et restauré par le retour arrière (le snapshot de
/// `savePreValidationState` réutilise `GameState.toJson()`).
class FiestaState {
  /// Configuration gelée au lancement.
  final FiestaRules rules;

  /// Instances actives.
  final List<ModifierInstance> active;

  /// État propre au tour en cours ([FiestaTurnState]). Vidé à la fin du tour.
  final FiestaTurnState turn;

  /// Cartouches dépensées dans la partie (story 2-9), dans l'ordre, toutes
  /// manches : décompte du stock ([cartridgesLeft]) et récap « Cartouches
  /// utilisées ». Clé omise tant que la liste est vide.
  final List<ChargeUse> chargesUsed;

  /// Cartouches gagnées par le coup de pouce (Fiesta v3), dans l'ordre : stock
  /// et récap. Clé omise tant que la liste est vide (`readOr` : absente = vide).
  final List<EarnedCartridge> earned;

  FiestaState({
    required this.rules,
    List<ModifierInstance> active = const [],
    FiestaTurnState? turn,
    List<ChargeUse> chargesUsed = const [],
    List<EarnedCartridge> earned = const [],
  })  : active = List.unmodifiable(active),
        turn = turn ?? FiestaTurnState.empty,
        chargesUsed = List.unmodifiable(chargesUsed),
        earned = List.unmodifiable(earned);

  /// Cartouches [catalogId] de [teamId] pour toute la partie : celles de
  /// l'ensemble ([ModifierMode.cartridge]) plus celles gagnées.
  int cartridgesOwned(String catalogId, String teamId) {
    final setting = rules.activeSetting(catalogId);
    return (setting?.mode == ModifierMode.cartridge ? setting!.charges : 0) +
        earned
            .where((e) => e.catalogId == catalogId && e.teamId == teamId)
            .length;
  }

  /// Stock restant : possédées moins dépensées, toutes manches.
  int cartridgesLeft(String catalogId, String teamId) =>
      cartridgesOwned(catalogId, teamId) -
      chargesUsed
          .where((u) => u.catalogId == catalogId && u.teamId == teamId)
          .length;

  FiestaState copyWith({
    List<ModifierInstance>? active,
    FiestaTurnState? turn,
    List<ChargeUse>? chargesUsed,
    List<EarnedCartridge>? earned,
  }) =>
      FiestaState(
        rules: rules,
        active: active ?? this.active,
        turn: turn ?? this.turn,
        chargesUsed: chargesUsed ?? this.chargesUsed,
        earned: earned ?? this.earned,
      );

  Map<String, dynamic> toJson() => {
        'rules': rules.toJson(),
        // Clés vides omises : l'absence se relit comme le défaut.
        if (active.isNotEmpty) 'active': active.map((e) => e.toJson()).toList(),
        if (!turn.isEmpty) 'turn': turn.toJson(),
        if (chargesUsed.isNotEmpty)
          'chargesUsed': chargesUsed.map((e) => e.toJson()).toList(),
        if (earned.isNotEmpty) 'earned': earned.map((e) => e.toJson()).toList(),
      };

  /// Variante tolérante : `null` (= Classique) si les règles sont illisibles.
  /// Une instance illisible est ignorée seule (`ModifierInstance.tryFromJson`).
  static FiestaState? tryFromJson(Map<String, dynamic> json) {
    final rawRules = json['rules'];
    if (rawRules is! Map) return null;
    final rules = FiestaRules.tryFromJson(Map<String, dynamic>.from(rawRules));
    if (rules == null) return null;

    final rawActive = json['active'];
    // `whereType` et non `cast` : un cast est paresseux et lèverait à la
    // première lecture, pas ici.
    final active = rawActive is List
        ? rawActive
            .whereType<Map>()
            .map((e) =>
                ModifierInstance.tryFromJson(Map<String, dynamic>.from(e)))
            .whereType<ModifierInstance>()
            .toList()
        : <ModifierInstance>[];

    final rawTurn = json['turn'];
    final rawUsed = json['chargesUsed'];
    final rawEarned = json['earned'];
    return FiestaState(
      rules: rules,
      active: active,
      turn: rawTurn is Map
          ? FiestaTurnState.fromJson(Map<String, dynamic>.from(rawTurn))
          : null,
      chargesUsed: rawUsed is List
          ? rawUsed
              .whereType<Map>()
              .map((e) => ChargeUse.tryFromJson(Map<String, dynamic>.from(e)))
              .whereType<ChargeUse>()
              .toList()
          : const [],
      earned: rawEarned is List
          ? rawEarned
              .whereType<Map>()
              .map((e) =>
                  EarnedCartridge.tryFromJson(Map<String, dynamic>.from(e)))
              .whereType<EarnedCartridge>()
              .toList()
          : const [],
    );
  }
}

/// Une cartouche dépensée : [teamId] a utilisé [catalogId] en manche
/// [round] : un bonus pour elle, ou un malus infligé à [targetTeamId] (clé
/// `target` omise pour un bonus).
class ChargeUse {
  final String catalogId;
  final String teamId;
  final int round;
  final String? targetTeamId;

  const ChargeUse({
    required this.catalogId,
    required this.teamId,
    required this.round,
    this.targetTeamId,
  });

  Map<String, dynamic> toJson() => {
        'catalogId': catalogId,
        'teamId': teamId,
        'round': round,
        if (targetTeamId != null) 'target': targetTeamId,
      };

  /// Variante tolérante : une entrée illisible est ignorée seule.
  static ChargeUse? tryFromJson(Map<String, dynamic> json) {
    final catalogId = json['catalogId'];
    final teamId = json['teamId'];
    final round = json['round'];
    final target = json['target'];
    if (catalogId is! String ||
        teamId is! String ||
        round is! int ||
        target is! String?) {
      return null;
    }
    return ChargeUse(
        catalogId: catalogId,
        teamId: teamId,
        round: round,
        targetTeamId: target);
  }
}

/// Une cartouche gagnée par le coup de pouce à l'équipe menée : [teamId] la
/// détient dès la manche [round] et jusqu'à la fin de la partie. Écrite par
/// `nextRound` seulement (`RoundTransitionPlan.apply`) : ni un retour arrière
/// ni une app tuée sur la transition ne peuvent la doubler ou la perdre.
class EarnedCartridge {
  final String catalogId;
  final String teamId;
  final int round;

  const EarnedCartridge({
    required this.catalogId,
    required this.teamId,
    required this.round,
  });

  Map<String, dynamic> toJson() =>
      {'catalogId': catalogId, 'teamId': teamId, 'round': round};

  /// Variante tolérante : une entrée illisible (dont un id inconnu du
  /// catalogue) est ignorée seule.
  static EarnedCartridge? tryFromJson(Map<String, dynamic> json) {
    final catalogId = json['catalogId'];
    final teamId = json['teamId'];
    final round = json['round'];
    if (catalogId is! String ||
        modifierById(catalogId) == null ||
        teamId is! String ||
        round is! int) {
      return null;
    }
    return EarnedCartridge(catalogId: catalogId, teamId: teamId, round: round);
  }
}
