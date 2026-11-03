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

  FiestaState({
    required this.rules,
    List<ModifierInstance> active = const [],
    Map<String, dynamic> turn = const {},
    Map<String, int> catchUpDue = const {},
  })  : active = List.unmodifiable(active),
        turn = Map.unmodifiable(turn),
        catchUpDue = Map.unmodifiable(catchUpDue);

  FiestaState copyWith({
    List<ModifierInstance>? active,
    Map<String, dynamic>? turn,
    Map<String, int>? catchUpDue,
  }) =>
      FiestaState(
        rules: rules,
        active: active ?? this.active,
        turn: turn ?? this.turn,
        catchUpDue: catchUpDue ?? this.catchUpDue,
      );

  Map<String, dynamic> toJson() => {
        'rules': rules.toJson(),
        'active': active.map((e) => e.toJson()).toList(),
        'turn': turn,
        'catchUpDue': catchUpDue,
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
    );
  }
}
