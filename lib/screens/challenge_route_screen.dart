import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fiesta/challenge_plan.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import 'surprise_challenge_screen.dart';

/// Branche [SurpriseChallengeScreen], autonome, sur la partie : traduit le plan
/// du provider en noms et couleurs, et lui rend l'issue.
class ChallengeRouteScreen extends StatelessWidget {
  const ChallengeRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final plan = provider.currentChallenge;
    if (plan == null) {
      // Sauvegarde qui n'a plus de défi à proposer : ne jamais rester bloqué ici.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => provider.finishChallenge());
      return const ColoredBox(color: AppColors.backgroundMain);
    }
    final first = _contender(provider, plan.first);
    final second = _contender(provider, plan.second);
    return SurpriseChallengeScreen(
      key: ValueKey(plan.finishedRound),
      challenge: plan.challenge,
      first: first,
      second: second,
      firstReward: _reward(plan.first.prizeId),
      secondReward: _reward(plan.second.prizeId),
      word: plan.word,
      onFinished: (winner) => provider.finishChallenge(
        winnerTeamId:
            identical(winner, first) ? plan.first.teamId : plan.second.teamId,
      ),
      onSkipped: provider.finishChallenge,
    );
  }

  ChallengeContender _contender(GameProvider provider, ChallengeSide side) {
    final teamIndex = provider.teams.indexWhere((t) => t.id == side.teamId);
    final team = provider.teams[teamIndex];
    final at = team.playerIds.indexOf(side.playerId);
    String nameOf(String id) => provider.getPlayerById(id)?.name ?? '';
    return ChallengeContender(
      playerName: nameOf(side.playerId),
      teamName: team.name,
      teamColor: AppColors.getTeamColor(teamIndex),
      // Dans l'ordre de l'équipe, à partir du joueur qui suit.
      teammates: [
        for (final id in [
          ...team.playerIds.skip(at + 1),
          ...team.playerIds.take(at),
        ])
          nameOf(id),
      ],
    );
  }

  ChallengeReward _reward(String id) {
    final def = modifierById(id)!;
    return ChallengeReward(
      modifierId: id,
      name: def.name,
      isMalus: def.nature == ModifierNature.malus,
    );
  }
}
