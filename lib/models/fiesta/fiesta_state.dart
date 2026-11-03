import 'fiesta_rules.dart';
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

  /// Rattrapage DÛ par équipe (id → secondes, négatives pour le malus du
  /// leader), posé à l'entrée de la manche et consommé par l'équipe à son
  /// premier tour non-continuation (story 2-6). Une équipe absente n'a rien.
  final Map<String, int> catchUpDue;

  /// Charges dépensées dans la partie (story 2-9), dans l'ordre. Sert au
  /// décompte des charges de la manche en cours (une charge non dépensée est
  /// perdue en fin de manche : rien à remettre à zéro) et au récap « Bonus
  /// utilisés ». Clé omise tant que la liste est vide.
  final List<ChargeUse> chargesUsed;

  /// Cartes « 1 parmi 3 » choisies dans la partie (story 2-10), dans l'ordre.
  /// Celles de la transition en cours forment la file (déjà choisi = gardé
  /// après un kill) ; `nextRound` les rend actives. Relues ensuite pour le
  /// récap et pour savoir qui désigne le devineur bloqué. Clé omise si vide.
  final List<OfferChoice> offerChoices;

  FiestaState({
    required this.rules,
    List<ModifierInstance> active = const [],
    FiestaTurnState? turn,
    Map<String, int> catchUpDue = const {},
    List<ChargeUse> chargesUsed = const [],
    List<OfferChoice> offerChoices = const [],
  })  : active = List.unmodifiable(active),
        turn = turn ?? FiestaTurnState.empty,
        catchUpDue = Map.unmodifiable(catchUpDue),
        chargesUsed = List.unmodifiable(chargesUsed),
        offerChoices = List.unmodifiable(offerChoices);

  FiestaState copyWith({
    List<ModifierInstance>? active,
    FiestaTurnState? turn,
    Map<String, int>? catchUpDue,
    List<ChargeUse>? chargesUsed,
    List<OfferChoice>? offerChoices,
  }) =>
      FiestaState(
        rules: rules,
        active: active ?? this.active,
        turn: turn ?? this.turn,
        catchUpDue: catchUpDue ?? this.catchUpDue,
        chargesUsed: chargesUsed ?? this.chargesUsed,
        offerChoices: offerChoices ?? this.offerChoices,
      );

  Map<String, dynamic> toJson() => {
        'rules': rules.toJson(),
        // Clés vides omises : l'absence se relit comme le défaut.
        if (active.isNotEmpty) 'active': active.map((e) => e.toJson()).toList(),
        if (!turn.isEmpty) 'turn': turn.toJson(),
        if (catchUpDue.isNotEmpty) 'catchUpDue': catchUpDue,
        if (chargesUsed.isNotEmpty)
          'chargesUsed': chargesUsed.map((e) => e.toJson()).toList(),
        if (offerChoices.isNotEmpty)
          'offerChoices': offerChoices.map((e) => e.toJson()).toList(),
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
    final rawChoices = json['offerChoices'];
    return FiestaState(
      rules: rules,
      active: active,
      turn: rawTurn is Map
          ? FiestaTurnState.fromJson(Map<String, dynamic>.from(rawTurn))
          : null,
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
      offerChoices: rawChoices is List
          ? rawChoices
              .whereType<Map>()
              .map((e) => OfferChoice.tryFromJson(Map<String, dynamic>.from(e)))
              .whereType<OfferChoice>()
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

/// Une carte « 1 parmi 3 » : [chooserId] l'a choisie, [modifier] est
/// l'instance de la manche suivante (un malus vise le leader, d'où la clé de
/// celui qui a choisi).
class OfferChoice {
  final String chooserId;
  final ModifierInstance modifier;

  const OfferChoice({required this.chooserId, required this.modifier});

  Map<String, dynamic> toJson() =>
      {'chooserId': chooserId, 'modifier': modifier.toJson()};

  /// Variante tolérante : une entrée illisible est ignorée seule.
  static OfferChoice? tryFromJson(Map<String, dynamic> json) {
    final chooserId = json['chooserId'];
    final raw = json['modifier'];
    if (chooserId is! String || raw is! Map) return null;
    final modifier =
        ModifierInstance.tryFromJson(Map<String, dynamic>.from(raw));
    if (modifier == null) return null;
    return OfferChoice(chooserId: chooserId, modifier: modifier);
  }
}
