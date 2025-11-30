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
                    title: 'Objectif',
                    content: 'Faites deviner un maximum de mots à votre équipe en 3 manches différentes.',
                  ),

                  _buildRuleSection(
                    title: 'Manche 1 : Description libre',
                    content: 'Décrivez le mot avec autant de mots que vous voulez, sans utiliser le mot à deviner ni ses dérivés.',
                    icon: '1️⃣',
                  ),

                  _buildRuleSection(
                    title: 'Manche 2 : Un seul mot',
                    content: 'Vous n\'avez droit qu\'à UN SEUL mot pour faire deviner. Choisissez-le bien !',
                    icon: '2️⃣',
                  ),

                  _buildRuleSection(
                    title: 'Manche 3 : Mime',
                    content: 'Mimez le mot sans parler ni faire de bruit. L\'expression corporelle est votre seule arme !',
                    icon: '3️⃣',
                  ),

                  _buildRuleSection(
                    title: 'Points',
                    content: 'Chaque mot deviné rapporte 1 point à votre équipe. L\'équipe avec le plus de points à la fin des 3 manches gagne !',
                    icon: '⭐',
                  ),

                  _buildRuleSection(
                    title: 'Passer un mot',
                    content: 'Vous pouvez passer un mot, mais cela coûte du temps (pénalité configurable). Le mot passé reviendra en jeu.',
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
