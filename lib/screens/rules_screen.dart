import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();

    return ShootingStars(
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      'Règles du jeu',
                      style: AppTextStyles.subtitle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildRuleSection(
                    title: 'But du jeu',
                    content: 'Faites deviner un maximum de mots à votre équipe ! '
                        'La partie se joue en 3 manches avec les mêmes mots, mais des règles différentes à chaque fois. '
                        'L\'équipe qui cumule le plus de points à la fin des 3 manches remporte la partie.',
                    icon: '🎯',
                  ),

                  _buildRuleSection(
                    title: 'Préparation',
                    content: 'Les joueurs forment des équipes (minimum 2 joueurs par équipe). '
                        'Ensuite, les mots à deviner sont choisis selon le mode sélectionné :\n\n'
                        '• Mode "Personnalisé" : chaque joueur écrit ses propres mots secrets.\n\n'
                        '• Mode "Aléatoire" : les mots sont tirés automatiquement parmi des catégories '
                        '(Célébrités, Objets, Lieux, Films...) et des niveaux de difficulté configurables.',
                    icon: '📝',
                  ),

                  _buildRuleSection(
                    title: 'Déroulement',
                    content: 'Les équipes jouent à tour de rôle. À chaque tour, un joueur de l\'équipe '
                        'fait deviner les mots pendant que ses coéquipiers tentent de trouver. '
                        'Le temps est limité ! Une fois le temps écoulé, c\'est au tour de l\'équipe suivante. '
                        'La manche se termine quand tous les mots ont été devinés.',
                    icon: '🔄',
                  ),

                  _buildRuleSection(
                    title: 'Manche 1 : Description',
                    content: 'Décrivez le mot avec autant de mots que vous voulez.\n\n'
                        'Interdit : dire le mot à deviner, ses dérivés, ou épeler des lettres.',
                    icon: '1️⃣',
                  ),

                  _buildRuleSection(
                    title: 'Manche 2 : Un seul mot',
                    content: 'Vous n\'avez droit qu\'à UN SEUL mot pour faire deviner. Choisissez-le bien !\n\n'
                        'Interdit : faire des gestes, mimer, ou donner plusieurs mots.',
                    icon: '2️⃣',
                  ),

                  _buildRuleSection(
                    title: 'Manche 3 : Mime',
                    content: 'Mimez le mot sans parler. L\'expression corporelle est votre seule arme !\n\n'
                        'Interdit : parler, faire des bruits, ou pointer des objets/personnes.',
                    icon: '3️⃣',
                  ),

                  _buildRuleSection(
                    title: 'Points',
                    content: 'Chaque mot correctement deviné rapporte 1 point à l\'équipe. '
                        'Les points s\'accumulent sur les 3 manches.',
                    icon: '⭐',
                  ),

                  _buildRuleSection(
                    title: 'Passer un mot',
                    content: 'Vous pouvez passer un mot difficile, mais attention : '
                        'cela coûte du temps (pénalité configurable dans les paramètres). '
                        'Le mot passé reviendra plus tard dans la manche.',
                    icon: '⏭️',
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          AppBackButton(
            onPressed: () => provider.goToScreen(AppConstants.screenHome),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection({
    required String title,
    required String content,
    String? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray600, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
