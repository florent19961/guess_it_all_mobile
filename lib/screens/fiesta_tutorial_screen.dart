import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/help/tutorial_pager.dart';

/// Tuto Fiesta, 3 cartes. Ouvert par `Navigator.push` (premier choix de
/// Fiesta sur l'interrupteur des Paramètres, ou « Revoir le tuto Fiesta »
/// dans Règles).
class FiestaTutorialScreen extends StatelessWidget {
  const FiestaTutorialScreen({super.key});

  static bool _isOpen = false;

  /// Ouvre le tuto et le marque vu. Déjà ouvert (double tap, « Continuer »
  /// puis « ? ») : ne rouvre rien.
  static Future<void> show(BuildContext context) async {
    if (_isOpen) return;
    _isOpen = true;
    try {
      StorageService().markFiestaTutorialSeen();
      await Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const FiestaTutorialScreen(),
      ));
    } finally {
      _isOpen = false;
    }
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
              'l\'envers, mimes sans les bras…). Parfois, pour toute la '
              'partie : une seule réponse par mot.',
        ),
        TutorialCard(
          symbol: '⇄',
          title: 'Comment ils arrivent',
          rows: [
            TutorialRow('1', 'Tirés au sort pour tous',
                'En début de manche, pour toutes les équipes.'),
            TutorialRow(
                '2',
                'Entre deux manches',
                'Personnalisé : les équipes menées choisissent 1 carte parmi 3. '
                    'Auto : l\'app leur donne un coup de pouce.'),
            TutorialRow(
                '3', 'Rattrapage', 'Du temps en plus pour l\'équipe menée.'),
          ],
        ),
        TutorialCard(
          symbol: 'A',
          title: 'Auto ou Personnalisé',
          text: 'Auto : l\'app décide de tout, personne ne choisit. '
              'Personnalisé (roue crantée des Paramètres) : après les '
              'équipes, tu choisis tes réglages, enregistrés sous un nom '
              'pour les réutiliser.',
        ),
      ],
    );
  }
}
