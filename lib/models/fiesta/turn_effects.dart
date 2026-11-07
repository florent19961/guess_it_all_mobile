import 'modifier_catalog.dart';
import 'modifier_instance.dart';

/// Effets de tour (story 2-8) : règles pures sur les modificateurs qui pèsent
/// sur l'équipe qui joue. Le provider ne fait que brancher.

/// Bonus à charge activables avant le tour (stories 2-9, 2-11 ; Fiesta v3 :
/// tous les bonus, seulement en cartouche), par id de catalogue, avec leur clé
/// JSON dans `fiesta.turn`. Une cartouche = UN tour.
///
/// 🔴 Règle 7 : un `fiesta.turn` écrit avant le retrait de « Deux mots à la
/// fois » porte encore `twoWords`, `secondWord`, `secondExpiredWord` : ces clés
/// sont ignorées à la relecture (la carte B reste dans `remainingWords`).
const Map<String, String> kChargeBonusKeys = {
  'double_points': 'doublePoints',
  'free_pass': 'freePass',
  'plus_10s': 'plus10s',
};

/// Une charge du tour : allumée à l'avant-tour ([armed]), puis dépensée au
/// départ du chrono ([spent]). Absente = éteinte. Le nom est la valeur JSON.
enum ChargeState { armed, spent }

/// État propre au tour en cours (`FiestaState.turn`), immuable et typé.
///
/// 🔴 Une fin de manche le garde tel quel (la continuation en N+1 est le même
/// tour) ; [FiestaTurnState.empty] à la vraie fin du tour.
/// JSON : clés omises quand elles valent la valeur initiale, lecture
/// tolérante clé par clé (une valeur mal typée = valeur initiale).
class FiestaTurnState {
  /// Passes gratuites déjà utilisées ce tour (2-8).
  final int freePassesUsed;

  /// Charges du tour par id de catalogue ([kChargeBonusKeys]).
  final Map<String, ChargeState> charges;

  /// Ce qu'avait préparé le joueur qui vient de sauter son tour, à reprendre en
  /// un toucher par son remplaçant.
  final ReplacedChoices? replaced;

  FiestaTurnState({
    this.freePassesUsed = 0,
    Map<String, ChargeState> charges = const {},
    this.replaced,
  }) : charges = Map.unmodifiable(charges);

  static final empty = FiestaTurnState();

  bool get isEmpty => toJson().isEmpty;

  FiestaTurnState copyWith({
    int? freePassesUsed,
    Map<String, ChargeState>? charges,
    ReplacedChoices? replaced,
    bool clearReplaced = false,
  }) =>
      FiestaTurnState(
        freePassesUsed: freePassesUsed ?? this.freePassesUsed,
        charges: charges ?? this.charges,
        replaced: clearReplaced ? null : replaced ?? this.replaced,
      );

  /// La charge [catalogId] passée à [state] (nul = éteinte).
  FiestaTurnState withCharge(String catalogId, ChargeState? state) =>
      copyWith(charges: {
        for (final e in charges.entries)
          if (e.key != catalogId) e.key: e.value,
        if (state != null) catalogId: state,
      });

  Map<String, dynamic> toJson() => {
        if (freePassesUsed > 0) 'freePassesUsed': freePassesUsed,
        for (final MapEntry(key: id, value: key) in kChargeBonusKeys.entries)
          if (charges[id] != null) key: charges[id]!.name,
        if (replaced != null) 'replaced': replaced!.toJson(),
      };

  factory FiestaTurnState.fromJson(Map<String, dynamic> json) {
    final used = json['freePassesUsed'];
    final replaced = json['replaced'];
    return FiestaTurnState(
      freePassesUsed: used is int ? used : 0,
      charges: {
        for (final MapEntry(key: id, value: key) in kChargeBonusKeys.entries)
          if (enumFromJson(ChargeState.values, json[key]) case final state?)
            id: state,
      },
      replaced: replaced is Map
          ? ReplacedChoices.tryFromJson(Map<String, dynamic>.from(replaced))
          : null,
    );
  }
}

/// Ce qu'un joueur bloqué avait préparé pour son tour annulé : ses bonus
/// allumés et ses malus envoyés (id, équipe, joueur nommé).
class ReplacedChoices {
  final String playerId;
  final List<String> bonuses;
  final List<ModifierInstance> sent;

  const ReplacedChoices({
    required this.playerId,
    this.bonuses = const [],
    this.sent = const [],
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        if (bonuses.isNotEmpty) 'bonuses': bonuses,
        if (sent.isNotEmpty) 'sent': sent.map((m) => m.toJson()).toList(),
      };

  /// `null` si illisible, ou s'il ne reste rien à reprendre. Un bonus retiré du
  /// jeu (« Deux mots ») est ignoré : il ne doit pas se rallumer.
  static ReplacedChoices? tryFromJson(Map<String, dynamic> json) {
    final playerId = json['playerId'];
    final rawBonuses = json['bonuses'];
    final rawSent = json['sent'];
    if (playerId is! String) return null;
    final bonuses = rawBonuses is List
        ? rawBonuses
            .whereType<String>()
            .where(kChargeBonusKeys.containsKey)
            .toList()
        : const <String>[];
    final sent = rawSent is List
        ? rawSent
            .whereType<Map>()
            .map((e) =>
                ModifierInstance.tryFromJson(Map<String, dynamic>.from(e)))
            .whereType<ModifierInstance>()
            .toList()
        : const <ModifierInstance>[];
    if (bonuses.isEmpty && sent.isEmpty) return null;
    return ReplacedChoices(playerId: playerId, bonuses: bonuses, sent: sent);
  }
}

/// `block_guesser` n'a d'effet que si l'équipe a au moins 3 joueurs : il faut
/// un devineur à bloquer ET un autre qui puisse encore répondre.
bool canBlockGuesser(int teamSize) => teamSize > 2;

/// Une cartouche de la réserve de l'équipe qui joue (écran avant le tour) : [left] restantes pour la partie (0 = épuisée),
/// [blockedReason] (« incompatible avec … ») si elle ne peut pas servir ce
/// tour. Calculée par le provider, jamais persistée.
class Cartridge {
  final String catalogId;
  final int left;
  final String? blockedReason;

  const Cartridge(this.catalogId, {required this.left, this.blockedReason});

  ModifierNature get nature => modifierById(catalogId)!.nature;
  bool get usable => left > 0 && blockedReason == null;
}
