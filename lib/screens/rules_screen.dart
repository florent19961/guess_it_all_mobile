import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_modal.dart';
import '../widgets/effects/shooting_stars.dart';
import 'fiesta_tutorial_screen.dart';
import 'rules_tutorial_screen.dart';

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
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Revoir le tuto',
                    variant: AppButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => RulesTutorialScreen.show(context),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Revoir le tuto Fiesta',
                    variant: AppButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => FiestaTutorialScreen.show(context),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Revoir les aides',
                    variant: AppButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: () => _resetHelps(context),
                  ),
                  const SizedBox(height: 32),
                  _buildRuleSection(
                    title: 'But du jeu',
                    content:
                        'Faites deviner un maximum de mots à votre équipe ! '
                        'La partie se joue en 3 manches avec les mêmes mots, mais des règles différentes à chaque fois. '
                        'L\'équipe qui cumule le plus de points à la fin des 3 manches remporte la partie.',
                    icon: '🎯',
                  ),
                  _buildRuleSection(
                    title: 'Préparation',
                    content:
                        'Les joueurs forment des équipes (minimum 2 joueurs par équipe). '
                        'Ensuite, les mots à deviner sont choisis selon le mode sélectionné :\n\n'
                        '• Mode "Personnalisé" : chaque joueur écrit ses propres mots secrets.\n\n'
                        '• Mode "Aléatoire" : les mots sont tirés automatiquement parmi des catégories '
                        '(Célébrités, Objets, Lieux, Films...) et des niveaux de difficulté configurables.',
                    icon: '📝',
                  ),
                  _buildRuleSection(
                    title: 'Déroulement',
                    content:
                        'Les équipes jouent à tour de rôle. À chaque tour, un joueur de l\'équipe '
                        'fait deviner les mots pendant que ses coéquipiers tentent de trouver. '
                        'Le temps est limité ! Une fois le temps écoulé, c\'est au tour de l\'équipe suivante. '
                        'La manche se termine quand tous les mots ont été devinés.',
                    icon: '🔄',
                  ),
                  _buildRuleSection(
                    title: 'Manche 1 : Description',
                    content:
                        'Décrivez le mot avec autant de mots que vous voulez.\n\n'
                        'Interdit : dire le mot à deviner, ses dérivés, ou épeler des lettres.',
                    icon: '1️⃣',
                  ),
                  _buildRuleSection(
                    title: 'Manche 2 : Un seul mot',
                    content:
                        'Vous n\'avez droit qu\'à UN SEUL mot pour faire deviner. Choisissez-le bien !\n\n'
                        'Interdit : faire des gestes, mimer, ou donner plusieurs mots.',
                    icon: '2️⃣',
                  ),
                  _buildRuleSection(
                    title: 'Manche 3 : Mime',
                    content:
                        'Mimez le mot sans parler. L\'expression corporelle est votre seule arme !\n\n'
                        'Interdit : parler, faire des bruits, ou pointer des objets/personnes.',
                    icon: '3️⃣',
                  ),
                  _buildRuleSection(
                    title: 'Points',
                    content:
                        'Chaque mot correctement deviné rapporte 1 point à l\'équipe. '
                        'Les points s\'accumulent sur les 3 manches.',
                    icon: '⭐',
                  ),
                  _buildRuleSection(
                    title: 'Passer un mot',
                    content:
                        'Vous pouvez passer un mot difficile, mais attention : '
                        'cela coûte du temps (pénalité configurable dans les paramètres). '
                        'Le mot passé reviendra plus tard dans la manche.',
                    icon: '⏭️',
                  ),
                  _buildRuleSection(
                    title: 'Mots passés',
                    content:
                        'Un mot passé reste dans la manche et peut être deviné plus tard, '
                        'même s\'il revient à un autre joueur ou à un autre moment.\n\n'
                        'Exemple : Vous passez "Hippopotame" car trop difficile. Il reviendra '
                        'plus tard dans votre tour ou dans celui d\'un autre joueur de votre équipe.',
                    icon: '🔄',
                  ),
                  _buildRuleSection(
                    title: 'Interdictions strictes',
                    content:
                        'Certaines techniques sont interdites pour préserver l\'équité du jeu :\n\n'
                        '• Traduction : Vous ne pouvez pas traduire le mot dans une autre langue.\n'
                        '  Exemple : Pour "Chien", dire "Dog" est interdit.\n\n'
                        '• Phonétique : Interdiction d\'utiliser des sons ou rimes.\n'
                        '  Exemple : Pour "Bateau", dire "Ça rime avec château" est interdit.\n\n'
                        '• Mots de la même racine : Ne pas utiliser des mots dérivés.\n'
                        '  Exemple : Pour "Jardiner", dire "Jardin" ou "Jardinier" est interdit.',
                    icon: '🚫',
                  ),
                  _buildRuleSection(
                    title: 'Technique du rébus',
                    content:
                        'Pour les mots très difficiles, vous pouvez décomposer le mot en syllabes ou sons.\n\n'
                        'Exemple : Pour faire deviner "Parapluie" :\n'
                        '• "Para" : "Se protéger, se..."\n'
                        '• "Pluie" : "Eau qui tombe du ciel"\n\n'
                        'Cette technique est particulièrement utile en manche 1 (Description).',
                    icon: '🧩',
                  ),
                  _buildRuleSection(
                    title: 'Répétition autorisée',
                    content:
                        'Le joueur qui fait deviner peut répéter n\'importe quel mot déjà prononcé '
                        'par ses coéquipiers qui cherchent à deviner.\n\n'
                        'Exemple : Pour "Tigre", votre équipe propose "Lion, Félin, Chat".\n'
                        'Vous pouvez répondre : "Oui, félin !" pour les encourager dans cette direction.\n\n'
                        'Attention : Vous ne pouvez PAS dire un mot que personne n\'a encore prononcé.',
                    icon: '🔁',
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

  /// Rejoue les aides automatiques de la première partie : chaque joueur les
  /// reverra à son premier tour de la prochaine partie.
  Future<void> _resetHelps(BuildContext context) async {
    await StorageService().resetFirstGameDone();
    if (!context.mounted) return;
    AppModal.show<void>(
      context,
      title: 'Aides réactivées',
      child: const Text(
        'Pendant la prochaine partie, chaque joueur reverra les aides à son '
        'premier tour. Le bouton « ? » de chaque écran reste disponible à '
        'tout moment.',
        style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        textAlign: TextAlign.center,
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
