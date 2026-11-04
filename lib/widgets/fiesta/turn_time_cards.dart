import 'package:flutter/material.dart';
import '../../models/fiesta/turn_time.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import 'fiesta_setup_widgets.dart';

String _signed(int seconds) => '${seconds < 0 ? '−' : '+'}${seconds.abs()} s';

/// « Temps du tour » (maquette `cd` / `cd2`) : une ligne par composante, le
/// total. Avant le tour, sous les annonces Fiesta.
class TurnTimeCard extends StatelessWidget {
  final TurnTime time;

  const TurnTimeCard(this.time, {super.key});

  @override
  Widget build(BuildContext context) {
    final floored = time.total > time.lines.fold(0, (s, l) => s + l.seconds);
    return FiestaCard(
      title: 'Temps du tour',
      trailing: Text(
        '${time.total} s',
        style: const TextStyle(
            fontFamily: 'Bangers', fontSize: 24, color: AppColors.warning),
      ),
      children: [
        for (final line in time.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(line.label, style: AppTextStyles.bodySmall),
                Text(
                  line == time.lines.first
                      ? '${line.seconds} s'
                      : _signed(line.seconds),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: line.seconds < 0
                        ? AppColors.error
                        : line == time.lines.first
                            ? AppColors.gray400
                            : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        if (floored)
          const FiestaHint('Plancher : un tour ne descend pas sous 10 s.'),
      ],
    );
  }
}

/// « Rattrapage : A +20 s · B −10 s » sur la transition : ce que chaque
/// équipe aura en plus ou en moins à son premier tour de la manche suivante.
/// Sans l'écart chiffré : scores cachés jusqu'aux résultats.
class CatchUpLine extends StatelessWidget {
  final List<CatchUpEntry> entries;
  final List<Team> teams;

  const CatchUpLine({
    required this.entries,
    required this.teams,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return FiestaInfoLine(
      label: 'Rattrapage',
      spans: [
        for (final (i, e) in entries.indexed) ...[
          if (i > 0) const TextSpan(text: ' · '),
          _entry(e),
        ],
      ],
    );
  }

  TextSpan _entry(CatchUpEntry e) {
    final index = teams.indexWhere((t) => t.id == e.teamId);
    final name = index < 0 ? e.teamId : teams[index].name;
    return TextSpan(
      children: [
        TextSpan(
          text: '$name ',
          style:
              TextStyle(color: AppColors.getTeamColor(index < 0 ? 0 : index)),
        ),
        TextSpan(
          text: _signed(e.seconds),
          style: TextStyle(
            color: e.isLeader ? AppColors.error : AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
