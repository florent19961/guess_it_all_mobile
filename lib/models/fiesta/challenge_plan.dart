import 'dart:math';

import 'cartridge_gifts.dart';
import 'fiesta_state.dart';
import 'surprise_challenge.dart';
import 'symmetric_draw.dart';

/// Un camp du défi : le joueur, son équipe et la cartouche qu'elle gagnerait.
class ChallengeSide {
  final String teamId;
  final String playerId;
  final String prizeId;

  const ChallengeSide({
    required this.teamId,
    required this.playerId,
    required this.prizeId,
  });
}

/// Le défi qui suit la manche [finishedRound], entièrement tiré.
///
/// 🔴 Recalculé depuis l'état de fin de manche, jamais persisté : une app tuée
/// pendant le défi retrouve le même. Seule l'issue s'écrit
/// ([FiestaState.challenges]).
class ChallengePlan {
  final int finishedRound;
  final SurpriseChallenge challenge;
  final ChallengeSide first;
  final ChallengeSide second;

  /// Le mot du téléphone arabe, `null` pour les autres défis.
  final String? word;

  const ChallengePlan({
    required this.finishedRound,
    required this.challenge,
    required this.first,
    required this.second,
    this.word,
  });
}

/// Le défi à jouer après [finishedRound], `null` s'il n'y en a pas : réglage
/// coupé, pas au programme, déjà terminé (même passé), vivier d'une des deux
/// équipes vide, ou téléphone arabe sans mot deviné.
///
/// [scores] et [rosters] : dans l'ordre des équipes. Le vivier et les poids sont
/// ceux des cartouches au hasard ([giftPool], [drawWeightedGift]) ; la graine est
/// propre au défi.
ChallengePlan? planChallenge({
  required FiestaState fiesta,
  required String gameId,
  required int finishedRound,
  required Map<String, int> scores,
  required Map<String, List<String>> rosters,
  required List<TurnPace> turns,
  required Iterable<String> guessedWords,
  required Set<String> blockableTeamIds,
}) {
  if (!fiesta.rules.challenges ||
      fiesta.challenges.any((c) => c.finishedRound == finishedRound)) {
    return null;
  }
  final challenge = drawChallengeSchedule(gameId)[finishedRound];
  if (challenge == null) return null;

  final word = challenge == SurpriseChallenge.mimeRelay
      ? pickGuessedWord(
          gameId: gameId,
          finishedRound: finishedRound,
          guessedWords: guessedWords,
        )
      : null;
  if (challenge == SurpriseChallenge.mimeRelay && word == null) return null;

  final teams = trailingTeams(scores);
  if (teams.length < 2) return null;

  final next = finishedRound + 1;
  final roundRules = roundModifiers(fiesta.rules, gameId: gameId, round: next);
  ChallengeSide? side(String teamId) {
    final pool = giftPool(
      rules: fiesta.rules,
      nextRound: next,
      roundRules: roundRules,
      teamId: teamId,
      blockableTeamIds: blockableTeamIds,
    );
    if (pool.isEmpty) return null;
    return ChallengeSide(
      teamId: teamId,
      playerId: slowestPlayer(roster: rosters[teamId]!, turns: turns),
      prizeId: drawWeightedGift(
        pool,
        Random(giftSeed('$gameId#challenge', finishedRound, teamId)),
      ).id,
    );
  }

  final first = side(teams[0]);
  final second = side(teams[1]);
  if (first == null || second == null) return null;
  return ChallengePlan(
    finishedRound: finishedRound,
    challenge: challenge,
    first: first,
    second: second,
    word: word,
  );
}
