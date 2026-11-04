import 'package:flutter/material.dart';
import '../../models/fiesta/turn_time.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import 'fiesta_setup_widgets.dart';

String _signed(int seconds) => '${seconds < 0 ? '−' : '+'}${seconds.abs()} s';

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
          // Le signe se lit à l'écran ; l'état est dit en toutes lettres aux
          // lecteurs d'écran (la couleur seule ne le porte pas). Sur ce span
          // à texte : un label posé sur le parent sans texte serait ignoré.
          semanticsLabel: '$name ${e.isLeader ? 'en tête' : 'en retard'}, ',
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
