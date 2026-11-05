import 'modifier_catalog.dart';
import 'modifier_instance.dart';

/// Effets de tour (story 2-8) : règles pures sur les modificateurs qui pèsent
/// sur l'équipe qui joue. Le provider ne fait que brancher.

/// Bonus à charge activables avant le tour (stories 2-9, 2-11 ; Fiesta v3 :
/// tous les bonus, seulement en cartouche), par id de catalogue, avec leur clé
/// JSON dans `fiesta.turn`. Une cartouche = UN tour.
const Map<String, String> kChargeBonusKeys = {
  'double_points': 'doublePoints',
  'two_words': 'twoWords',
  'free_pass': 'freePass',
  'plus_10s': 'plus10s',
};

/// Une charge du tour : allumée à l'avant-tour ([armed]), puis dépensée au
/// départ du chrono ([spent]). Absente = éteinte. Le nom est la valeur JSON.
enum ChargeState { armed, spent }

/// État propre au tour en cours (`FiestaState.turn`), immuable et typé.
///
/// 🔴 C'est LUI qui dit ce qui survit : [afterRoundEnd] (la continuation en
/// N+1 est le même tour) et [FiestaTurnState.empty] à la vraie fin du tour.
/// JSON : clés omises quand elles valent la valeur initiale, lecture
/// tolérante clé par clé (une valeur mal typée = valeur initiale).
class FiestaTurnState {
  /// Passes gratuites déjà utilisées ce tour (2-8).
  final int freePassesUsed;

  /// Charges du tour par id de catalogue ([kChargeBonusKeys]).
  final Map<String, ChargeState> charges;

  /// Carte B de « Deux mots à la fois » (la carte A est `currentWord`).
  final String? secondWord;

  /// Carte B encore à l'écran quand le chrono est tombé, à vérifier.
  final String? secondExpiredWord;

  /// Ce qu'avait préparé le joueur qui vient de sauter son tour, à reprendre en
  /// un toucher par son remplaçant.
  final ReplacedChoices? replaced;

  FiestaTurnState({
    this.freePassesUsed = 0,
    Map<String, ChargeState> charges = const {},
    this.secondWord,
    this.secondExpiredWord,
    this.replaced,
  }) : charges = Map.unmodifiable(charges);

  static final empty = FiestaTurnState();

  bool get isEmpty => toJson().isEmpty;

  FiestaTurnState copyWith({
    int? freePassesUsed,
    Map<String, ChargeState>? charges,
    String? secondWord,
    bool clearSecondWord = false,
    String? secondExpiredWord,
    bool clearSecondExpiredWord = false,
    ReplacedChoices? replaced,
    bool clearReplaced = false,
  }) =>
      FiestaTurnState(
        freePassesUsed: freePassesUsed ?? this.freePassesUsed,
        charges: charges ?? this.charges,
        secondWord: clearSecondWord ? null : secondWord ?? this.secondWord,
        secondExpiredWord: clearSecondExpiredWord
            ? null
            : secondExpiredWord ?? this.secondExpiredWord,
        replaced: clearReplaced ? null : replaced ?? this.replaced,
      );

  /// La charge [catalogId] passée à [state] (nul = éteinte).
  FiestaTurnState withCharge(String catalogId, ChargeState? state) =>
      copyWith(charges: {
        for (final e in charges.entries)
          if (e.key != catalogId) e.key: e.value,
        if (state != null) catalogId: state,
      });

  /// Fin de manche : le tour continue en N+1 (continuation), tout survit sauf
  /// la carte B expirée, déjà dépouillée par la vérification.
  FiestaTurnState afterRoundEnd() => copyWith(clearSecondExpiredWord: true);

  Map<String, dynamic> toJson() => {
        if (freePassesUsed > 0) 'freePassesUsed': freePassesUsed,
        for (final MapEntry(key: id, value: key) in kChargeBonusKeys.entries)
          if (charges[id] != null) key: charges[id]!.name,
        if (secondWord != null) 'secondWord': secondWord,
        if (secondExpiredWord != null) 'secondExpiredWord': secondExpiredWord,
        if (replaced != null) 'replaced': replaced!.toJson(),
      };

  factory FiestaTurnState.fromJson(Map<String, dynamic> json) {
    String? string(String key) => json[key] is String ? json[key] : null;
    final used = json['freePassesUsed'];
    final replaced = json['replaced'];
    return FiestaTurnState(
      freePassesUsed: used is int ? used : 0,
      charges: {
        for (final MapEntry(key: id, value: key) in kChargeBonusKeys.entries)
          if (enumFromJson(ChargeState.values, json[key]) case final state?)
            id: state,
      },
      secondWord: string('secondWord'),
      secondExpiredWord: string('secondExpiredWord'),
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

  static ReplacedChoices? tryFromJson(Map<String, dynamic> json) {
    final playerId = json['playerId'];
    final bonuses = json['bonuses'];
    final sent = json['sent'];
    if (playerId is! String) return null;
    return ReplacedChoices(
      playerId: playerId,
      bonuses:
          bonuses is List ? bonuses.whereType<String>().toList() : const [],
      sent: sent is List
          ? sent
              .whereType<Map>()
              .map((e) =>
                  ModifierInstance.tryFromJson(Map<String, dynamic>.from(e)))
              .whereType<ModifierInstance>()
              .toList()
          : const [],
    );
  }
}

/// Remplaçant d'une carte « Deux mots » traitée : premier mot de [pool] (déjà
/// privé du mot traité) autre que [other], la carte qui reste. Pool épuisé :
/// les mots passés du tour (sauf [other]) y reviennent, comme le recyclage
/// d'un mot seul. `word` nul = plus aucun autre mot, une seule carte reste.
({String? word, List<String> pool}) drawOtherCard({
  required List<String> pool,
  required List<String> passed,
  required String other,
}) {
  for (final w in pool) {
    if (w != other) return (word: w, pool: pool);
  }
  final recycled = passed.where((w) => w != other).toList()..shuffle();
  if (recycled.isEmpty) return (word: null, pool: pool);
  return (word: recycled.first, pool: [...pool, ...recycled]);
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
