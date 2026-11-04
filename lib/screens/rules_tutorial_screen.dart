import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/storage_service.dart';
import '../widgets/help/help_content.dart';
import '../widgets/help/tutorial_pager.dart';

/// Tuto des règles, 4 cartes. Ouvert par `Navigator.push` (prompt
/// d'office au premier « Jouer » d'un téléphone neuf, ou « Revoir le tuto »
/// dans Règles).
class RulesTutorialScreen extends StatelessWidget {
  final int passPenalty;

  const RulesTutorialScreen({required this.passPenalty, super.key});

  /// Ouvre le tuto avec la pénalité de passe enregistrée. Une fois la route
  /// poussée, l'onboarding des règles de première partie est marqué traité
  /// (`guessItAll_tutorialSeen`) : un kill avant ne le saute pas pour toujours.
  static Future<void> show(BuildContext context) {
    final passPenalty = context.read<GameProvider>().settings.passPenalty;
    final closed = Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RulesTutorialScreen(passPenalty: passPenalty),
    ));
    StorageService().markTutorialSeen();
    return closed;
  }

  @override
  Widget build(BuildContext context) {
    return TutorialPager(cards: [
      const TutorialCard(
        symbol: '?',
        title: 'Le principe',
        text: 'Les mots sont soit tirés au hasard par l\'app, soit écrits à la '
            'main par les joueurs. Le but : les faire deviner à ton équipe, '
            'manche après manche, avec les mêmes mots à chaque manche.',
      ),
      const TutorialCard(
        symbol: '3',
        title: 'Trois manches',
        rows: [
          TutorialRow('1', 'Décrire', 'Tout est permis, sauf dire le mot.'),
          TutorialRow('2', 'Un seul mot', 'Un mot d\'indice, pas plus.'),
          TutorialRow('3', 'Mimer', 'Sans un son.'),
        ],
      ),
      TutorialCard(
        symbol: '✓',
        title: 'Trouvé ou Passer',
        text: 'Trouvé : 1 point, et le mot suivant arrive. Passer : le mot '
            'retourne dans le chapeau. ${passPenaltySentence(passPenalty)} '
            'Seul celui qui fait deviner regarde le téléphone.',
      ),
      const TutorialCard(
        symbol: '★',
        title: 'Le score',
        text: 'Les points des 3 manches s\'additionnent, et on découvre les '
            'scores à la fin de la partie. Astuce : retiens bien les mots de '
            'la manche 1, ils reviennent.',
      ),
    ]);
  }
}
