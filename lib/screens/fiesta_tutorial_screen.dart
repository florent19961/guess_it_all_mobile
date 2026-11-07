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
              'modificateurs : des bonus (Mot compte double, Passe gratuite, '
              'Bonus de 10 s) et des malus (Interdit de passer, Mot à '
              'l\'envers, Une seule réponse, mimes sans les bras…).',
        ),
        TutorialCard(
          symbol: '⇄',
          title: 'Comment ils arrivent',
          rows: [
            TutorialRow('1', 'Toujours',
                'Toute la partie, dans les manches où il existe, pour toutes les équipes.'),
            TutorialRow('2', 'Tirés au sort pour tous',
                'En début de manche, pour toutes les équipes.'),
            TutorialRow(
                '3',
                'Cartouches',
                'Chaque équipe garde les siennes toute la partie : un bonus '
                    'pour son tour, ou un malus à infliger.'),
            TutorialRow(
                '4',
                'Cartouches au hasard',
                'Selon l\'ensemble : à chaque manche, ou pour les équipes '
                    'menées après les manches 1 et 2.'),
            TutorialRow(
                '5',
                'Défis surprises',
                'Selon l\'ensemble : 1 ou 2 fois dans la partie, une cartouche '
                    'à gagner.'),
          ],
        ),
        TutorialCard(
          symbol: '★',
          title: 'Les ensembles',
          text: 'Tu joues en Fiesta classique, puis avec ton dernier ensemble '
              'de règles. Pour en changer : la roue crantée des Paramètres, '
              'puis « Changer ». Prends un de ceux fournis par l\'app, ou le '
              'tien, enregistré sous un nom pour le réutiliser.',
        ),
      ],
    );
  }
}
