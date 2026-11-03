import 'modifier_instance.dart';

/// Effets de tour (story 2-8) : règles pures sur les modificateurs qui pèsent
/// sur l'équipe qui joue. Le provider ne fait que brancher.

/// Clés des compteurs du tour dans `FiestaState.turn`. Absentes = valeur
/// initiale (0 passe gratuite utilisée, aucun devineur bloqué).
const String kFreePassesUsedKey = 'freePassesUsed';
const String kBlockedPlayerIdKey = 'blockedPlayerId';

/// « Mot compte double » du tour (story 2-9) : [kDoubleArmed] tant que
/// l'interrupteur de l'avant-tour est allumé, [kDoubleSpent] une fois la
/// charge dépensée au départ du tour. Absent = éteint.
const String kDoublePointsKey = 'doublePoints';
const String kDoubleArmed = 'armed';
const String kDoubleSpent = 'spent';

/// « Deux mots à la fois » du tour (story 2-11) : mêmes valeurs que
/// [kDoublePointsKey] ([kDoubleArmed] puis [kDoubleSpent]). La carte B vit
/// sous [kSecondWordKey] (la carte A reste `GameState.currentWord`), et B
/// encore à l'écran quand le chrono tombe sous [kSecondExpiredWordKey]. Clés
/// absentes = un seul mot, comme en Classique.
const String kTwoWordsKey = 'twoWords';
const String kSecondWordKey = 'secondWord';
const String kSecondExpiredWordKey = 'secondExpiredWord';

/// Nombre de passes gratuites du tour : les charges de `free_pass`.
int freePassAllowance(List<ModifierInstance> modifiers) => modifiers
    .where((m) => m.catalogId == 'free_pass')
    .fold(0, (sum, m) => sum + m.charges);

/// Charges de « Mot compte double » de la manche : les charges des instances
/// `double_points`.
int doublePointsAllowance(List<ModifierInstance> modifiers) => modifiers
    .where((m) => m.catalogId == 'double_points')
    .fold(0, (sum, m) => sum + m.charges);

/// Charges de « Deux mots à la fois » de la manche (instances `two_words`).
int twoWordsAllowance(List<ModifierInstance> modifiers) => modifiers
    .where((m) => m.catalogId == 'two_words')
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
