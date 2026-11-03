import 'modifier_instance.dart';

/// Effets de tour (story 2-8) : règles pures sur les modificateurs qui pèsent
/// sur l'équipe qui joue. Le provider ne fait que brancher.

/// Clés des compteurs du tour dans `FiestaState.turn`. Absentes = valeur
/// initiale (0 passe gratuite utilisée, aucun devineur bloqué).
const String kFreePassesUsedKey = 'freePassesUsed';
const String kBlockedPlayerIdKey = 'blockedPlayerId';

/// `no_pass` actif : le bouton Passer est désactivé.
bool isPassBlocked(List<ModifierInstance> modifiers) =>
    modifiers.any((m) => m.catalogId == 'no_pass');

/// Nombre de passes gratuites du tour : les charges de `free_pass`.
int freePassAllowance(List<ModifierInstance> modifiers) => modifiers
    .where((m) => m.catalogId == 'free_pass')
    .fold(0, (sum, m) => sum + m.charges);

/// Pénalité EFFECTIVE de la prochaine passe : 0 tant qu'il reste une passe
/// gratuite, sinon la pénalité réglée.
int effectivePassPenalty({
  required int basePenalty,
  required int allowance,
  required int used,
}) =>
    used < allowance ? 0 : basePenalty;

/// `block_guesser` n'a d'effet que si l'équipe a au moins 3 joueurs : il faut
/// un devineur à bloquer ET un autre qui puisse encore répondre.
bool canBlockGuesser(int teamSize) => teamSize > 2;
