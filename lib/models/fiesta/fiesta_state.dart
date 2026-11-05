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

  /// Cartouches au hasard reçues, dans l'ordre : stock et récap. Clé omise tant
  /// que la liste est vide (`readOr` : absente = vide).
  final List<EarnedCartridge> earned;

  /// Tours sautés par équipe (« Interdit de faire deviner ») : décalage de sa
  /// rotation de joueurs (`playerIndexAtTurn`). Clé omise tant que la table est
  /// vide.
  final Map<String, int> skips;

  /// Défis surprises terminés, gagnés ou passés. Clé omise tant que la liste est
  /// vide.
  final List<ChallengeResult> challenges;

  FiestaState({
    required this.rules,
    List<ModifierInstance> active = const [],
    FiestaTurnState? turn,
    List<ChargeUse> chargesUsed = const [],
    List<EarnedCartridge> earned = const [],
    Map<String, int> skips = const {},
    List<ChallengeResult> challenges = const [],
  })  : active = List.unmodifiable(active),
        turn = turn ?? FiestaTurnState.empty,
        chargesUsed = List.unmodifiable(chargesUsed),
        earned = List.unmodifiable(earned),
        skips = Map.unmodifiable(skips),
        challenges = List.unmodifiable(challenges);

  /// Cartouches [catalogId] de [teamId] pour toute la partie : celles de
  /// l'ensemble plus celles gagnées.
  int cartridgesOwned(String catalogId, String teamId) =>
      rules.chargesOf(catalogId) +
      earned
          .where((e) => e.catalogId == catalogId && e.teamId == teamId)
          .length;

  /// Stock restant : possédées moins dépensées, toutes manches.
  int cartridgesLeft(String catalogId, String teamId) =>
      cartridgesOwned(catalogId, teamId) -
      chargesUsed
          .where((u) => u.catalogId == catalogId && u.teamId == teamId)
          .length;

  /// Le défi de la manche [finishedRound] terminé, sa cartouche [prize] donnée.
  FiestaState withChallengeDone(int finishedRound, EarnedCartridge? prize) =>
      copyWith(
        challenges: [
          ...challenges,
          ChallengeResult(finishedRound: finishedRound, prize: prize),
        ],
        earned: [...earned, if (prize != null) prize],
      );

  /// Un état restauré par le retour arrière, avec les défis terminés depuis dans
  /// [later] : un défi joué ne se rejoue pas et sa cartouche reste acquise. Ceux
  /// que l'état connaît déjà ne sont pas redonnés.
  FiestaState keepingChallengesOf(FiestaState? later) {
    var kept = this;
    for (final result in later?.challenges ?? const <ChallengeResult>[]) {
      if (!challenges.any((c) => c.finishedRound == result.finishedRound)) {
        kept = kept.withChallengeDone(result.finishedRound, result.prize);
      }
    }
    return kept;
  }

  /// Le malus envoyé [sent] retiré de sa cible, sa cartouche rendue à
  /// l'envoyeur.
  FiestaState withoutSent(ModifierInstance sent) {
    final used = chargesUsed.lastIndexWhere((u) =>
        u.catalogId == sent.catalogId &&
        u.teamId == sent.fromTeamId &&
        u.targetTeamId == sent.teamId &&
        u.round == sent.round);
    return copyWith(
      active: [...active]..remove(sent),
      chargesUsed: [
        for (var i = 0; i < chargesUsed.length; i++)
          if (i != used) chargesUsed[i],
      ],
    );
  }

  FiestaState copyWith({
    List<ModifierInstance>? active,
    FiestaTurnState? turn,
    List<ChargeUse>? chargesUsed,
    List<EarnedCartridge>? earned,
    Map<String, int>? skips,
    List<ChallengeResult>? challenges,
  }) =>
      FiestaState(
        rules: rules,
        active: active ?? this.active,
        turn: turn ?? this.turn,
        chargesUsed: chargesUsed ?? this.chargesUsed,
        earned: earned ?? this.earned,
        skips: skips ?? this.skips,
        challenges: challenges ?? this.challenges,
      );

  Map<String, dynamic> toJson() => {
        'rules': rules.toJson(),
        // Clés vides omises : l'absence se relit comme le défaut.
        if (active.isNotEmpty) 'active': active.map((e) => e.toJson()).toList(),
        if (!turn.isEmpty) 'turn': turn.toJson(),
        if (chargesUsed.isNotEmpty)
          'chargesUsed': chargesUsed.map((e) => e.toJson()).toList(),
        if (earned.isNotEmpty) 'earned': earned.map((e) => e.toJson()).toList(),
        if (skips.isNotEmpty) 'skips': skips,
        if (challenges.isNotEmpty)
          'challenges': challenges.map((e) => e.toJson()).toList(),
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
    final rawSkips = json['skips'];
    final rawChallenges = json['challenges'];
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
      skips: rawSkips is Map
          ? {
              for (final MapEntry(:key, :value) in rawSkips.entries)
                if (key is String && value is int) key: value,
            }
          : const {},
      challenges: rawChallenges is List
          ? rawChallenges
              .whereType<Map>()
              .map((e) =>
                  ChallengeResult.tryFromJson(Map<String, dynamic>.from(e)))
              .whereType<ChallengeResult>()
              .toList()
          : const [],
    );
  }
}

/// Une cartouche dépensée : [teamId] a utilisé [catalogId] en manche
/// [round] : un bonus pour elle, ou un malus infligé à [targetTeamId] (clé
/// `target` omise pour un bonus). [turn] = numéro du tour où elle a été jouée
/// (révélation des scores) ; nul sur une partie antérieure, clé alors absente.
class ChargeUse {
  final String catalogId;
  final String teamId;
  final int round;
  final String? targetTeamId;
  final int? turn;

  const ChargeUse({
    required this.catalogId,
    required this.teamId,
    required this.round,
    this.targetTeamId,
    this.turn,
  });

  Map<String, dynamic> toJson() => {
        'catalogId': catalogId,
        'teamId': teamId,
        'round': round,
        if (targetTeamId != null) 'target': targetTeamId,
        if (turn != null) 'turn': turn,
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
        targetTeamId: target,
        turn: json['turn'] is int ? json['turn'] as int : null);
  }
}

/// Un défi surprise terminé, après la manche [finishedRound]. [prize] : la
/// cartouche gagnée, `null` si le défi a été passé.
class ChallengeResult {
  final int finishedRound;
  final EarnedCartridge? prize;

  const ChallengeResult({required this.finishedRound, this.prize});

  Map<String, dynamic> toJson() => {
        'round': finishedRound,
        if (prize != null) 'prize': prize!.toJson(),
      };

  /// Variante tolérante : une entrée illisible est ignorée seule.
  static ChallengeResult? tryFromJson(Map<String, dynamic> json) {
    final round = json['round'];
    final prize = json['prize'];
    if (round is! int) return null;
    return ChallengeResult(
      finishedRound: round,
      prize: prize is Map
          ? EarnedCartridge.tryFromJson(Map<String, dynamic>.from(prize))
          : null,
    );
  }
}

/// Une cartouche au hasard : [teamId] la détient dès la manche [round] et jusqu'à la fin de la partie. Écrite par
/// `nextRound` (`RoundTransitionPlan.apply`) et par la fin d'un défi
/// ([FiestaState.withChallengeDone]) : ni un retour arrière ni une app tuée ne
/// peuvent la doubler ou la perdre.
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
