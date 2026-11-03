import 'fiesta_rules.dart';
import 'modifier_instance.dart';

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

  /// Compteurs propres au tour en cours (clés dans `turn_effects.dart` :
  /// passes gratuites utilisées, devineur bloqué). Vidés à la fin du tour.
  final Map<String, dynamic> turn;

  /// Rattrapage DÛ par équipe (id → secondes, négatives pour le malus du
  /// leader), posé à l'entrée de la manche et consommé par l'équipe à son
  /// premier tour non-continuation (story 2-6). Une équipe absente n'a rien.
  final Map<String, int> catchUpDue;

  /// Charges dépensées dans la partie (story 2-9), dans l'ordre. Sert au
  /// décompte des charges de la manche en cours (une charge non dépensée est
  /// perdue en fin de manche : rien à remettre à zéro) et au récap « Bonus
  /// utilisés ». Clé omise tant que la liste est vide.
  final List<ChargeUse> chargesUsed;

  FiestaState({
    required this.rules,
    List<ModifierInstance> active = const [],
    Map<String, dynamic> turn = const {},
    Map<String, int> catchUpDue = const {},
    List<ChargeUse> chargesUsed = const [],
  })  : active = List.unmodifiable(active),
        turn = Map.unmodifiable(turn),
        catchUpDue = Map.unmodifiable(catchUpDue),
        chargesUsed = List.unmodifiable(chargesUsed);

  FiestaState copyWith({
    List<ModifierInstance>? active,
    Map<String, dynamic>? turn,
    Map<String, int>? catchUpDue,
    List<ChargeUse>? chargesUsed,
  }) =>
      FiestaState(
        rules: rules,
        active: active ?? this.active,
        turn: turn ?? this.turn,
        catchUpDue: catchUpDue ?? this.catchUpDue,
        chargesUsed: chargesUsed ?? this.chargesUsed,
      );

  Map<String, dynamic> toJson() => {
        'rules': rules.toJson(),
        'active': active.map((e) => e.toJson()).toList(),
        'turn': turn,
        'catchUpDue': catchUpDue,
        if (chargesUsed.isNotEmpty)
          'chargesUsed': chargesUsed.map((e) => e.toJson()).toList(),
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
    final rawDue = json['catchUpDue'];
    final rawUsed = json['chargesUsed'];
    return FiestaState(
      rules: rules,
      active: active,
      turn: rawTurn is Map ? Map<String, dynamic>.from(rawTurn) : const {},
      catchUpDue: rawDue is Map
          ? {
              for (final e in rawDue.entries)
                if (e.key is String && e.value is int)
                  e.key as String: e.value as int,
            }
          : const {},
      chargesUsed: rawUsed is List
          ? rawUsed
              .whereType<Map>()
              .map((e) => ChargeUse.tryFromJson(Map<String, dynamic>.from(e)))
              .whereType<ChargeUse>()
              .toList()
          : const [],
    );
  }
}

/// Une charge dépensée : [teamId] a utilisé [catalogId] en manche [round].
class ChargeUse {
  final String catalogId;
  final String teamId;
  final int round;

  const ChargeUse({
    required this.catalogId,
    required this.teamId,
    required this.round,
  });

  Map<String, dynamic> toJson() =>
      {'catalogId': catalogId, 'teamId': teamId, 'round': round};

  /// Variante tolérante : une entrée illisible est ignorée seule.
  static ChargeUse? tryFromJson(Map<String, dynamic> json) {
    final catalogId = json['catalogId'];
    final teamId = json['teamId'];
    final round = json['round'];
    if (catalogId is! String || teamId is! String || round is! int) {
      return null;
    }
    return ChargeUse(catalogId: catalogId, teamId: teamId, round: round);
  }
}
