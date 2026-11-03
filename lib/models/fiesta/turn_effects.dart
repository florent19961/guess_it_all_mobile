import 'modifier_catalog.dart';
import 'modifier_instance.dart';

/// Effets de tour (story 2-8) : règles pures sur les modificateurs qui pèsent
/// sur l'équipe qui joue. Le provider ne fait que brancher.

/// Bonus à charge activables avant le tour (stories 2-9, 2-11), par id de
/// catalogue, avec leur clé JSON dans `fiesta.turn`. Une 3ᵉ charge = une ligne.
const Map<String, String> kChargeBonusKeys = {
  'double_points': 'doublePoints',
  'two_words': 'twoWords',
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

  /// Devineur bloqué, désigné avant le tour (2-8, 2-10).
  final String? blockedPlayerId;

  /// Charges du tour par id de catalogue ([kChargeBonusKeys]).
  final Map<String, ChargeState> charges;

  /// Carte B de « Deux mots à la fois » (la carte A est `currentWord`).
  final String? secondWord;

  /// Carte B encore à l'écran quand le chrono est tombé, à vérifier.
  final String? secondExpiredWord;

  FiestaTurnState({
    this.freePassesUsed = 0,
    this.blockedPlayerId,
    Map<String, ChargeState> charges = const {},
    this.secondWord,
    this.secondExpiredWord,
  }) : charges = Map.unmodifiable(charges);

  static final empty = FiestaTurnState();

  bool get isEmpty => toJson().isEmpty;

  FiestaTurnState copyWith({
    int? freePassesUsed,
    String? blockedPlayerId,
    Map<String, ChargeState>? charges,
    String? secondWord,
    bool clearSecondWord = false,
    String? secondExpiredWord,
    bool clearSecondExpiredWord = false,
  }) =>
      FiestaTurnState(
        freePassesUsed: freePassesUsed ?? this.freePassesUsed,
        blockedPlayerId: blockedPlayerId ?? this.blockedPlayerId,
        charges: charges ?? this.charges,
        secondWord: clearSecondWord ? null : secondWord ?? this.secondWord,
        secondExpiredWord: clearSecondExpiredWord
            ? null
            : secondExpiredWord ?? this.secondExpiredWord,
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
        if (blockedPlayerId != null) 'blockedPlayerId': blockedPlayerId,
        for (final MapEntry(key: id, value: key) in kChargeBonusKeys.entries)
          if (charges[id] != null) key: charges[id]!.name,
        if (secondWord != null) 'secondWord': secondWord,
        if (secondExpiredWord != null) 'secondExpiredWord': secondExpiredWord,
      };

  factory FiestaTurnState.fromJson(Map<String, dynamic> json) {
    String? string(String key) => json[key] is String ? json[key] : null;
    final used = json['freePassesUsed'];
    return FiestaTurnState(
      freePassesUsed: used is int ? used : 0,
      blockedPlayerId: string('blockedPlayerId'),
      charges: {
        for (final MapEntry(key: id, value: key) in kChargeBonusKeys.entries)
          if (enumFromJson(ChargeState.values, json[key]) case final state?)
            id: state,
      },
      secondWord: string('secondWord'),
      secondExpiredWord: string('secondExpiredWord'),
    );
  }
}

/// Charges de [catalogId] posées par [modifiers] (passes gratuites,
/// « Mot compte double », « Deux mots à la fois »).
int chargeAllowance(List<ModifierInstance> modifiers, String catalogId) =>
    modifiers
        .where((m) => m.catalogId == catalogId)
        .fold(0, (sum, m) => sum + m.charges);

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
