import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/help/tutorial_pager.dart';

/// Tuto Fiesta, 3 cartes. Ouvert par `Navigator.push` (premier choix de
/// Fiesta, ou « Revoir le tuto Fiesta » dans Règles).
class FiestaTutorialScreen extends StatelessWidget {
  const FiestaTutorialScreen({super.key});

  /// Ouvre le tuto et le marque vu.
  static Future<void> show(BuildContext context) {
    StorageService().markFiestaTutorialSeen();
    return Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const FiestaTutorialScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return const TutorialPager(
      accent: AppColors.secondaryCyan,
      tag: 'Fiesta',
      cards: [
        TutorialCard(
          symbol: '✦',
          title: 'Bonus et malus',
          text: 'Fiesta, ce sont les 3 manches habituelles avec des '
              'modificateurs : des bonus (Mot compte double, Deux mots à la '
              'fois, Passe gratuite) et des malus (Interdit de passer, Mot à '
              'l\'envers, mimes sans les bras…).',
        ),
        TutorialCard(
          symbol: '⇄',
          title: 'Comment ils arrivent',
          rows: [
            TutorialRow('1', 'Tirés au sort pour tous',
                'En début de manche, pour toutes les équipes.'),
            TutorialRow('2', 'Choix 1 parmi 3',
                'Entre deux manches, l\'équipe menée choisit une carte.'),
            TutorialRow(
                '3', 'Rattrapage', 'Du temps en plus pour l\'équipe menée.'),
          ],
        ),
        TutorialCard(
          symbol: 'A',
          title: 'Auto ou Personnalisé',
          text: 'Auto : l\'app décide de tout, personne ne choisit. '
              'Personnalisé : vous réglez chaque modificateur et vous '
              'enregistrez vos réglages sous un nom, pour les réutiliser.',
        ),
      ],
    );
  }
}
