# Guess It All Mobile

## Description
Jeu mobile multijoueur de devinettes de mots en équipe, inspiré du jeu "Time's Up". Les joueurs forment des équipes et doivent faire deviner des mots à leurs coéquipiers à travers 3 manches avec des règles différentes.

## Stack Technique
- **Framework** : Flutter (Dart SDK ^3.10.1)
- **State Management** : Provider
- **Stockage local** : shared_preferences
- **Polices** : Bangers, Poppins

## Architecture

```
lib/
├── main.dart              # Point d'entrée, configuration système
├── app.dart               # Widget racine de l'application
├── models/                # Modèles de données
│   ├── game_settings.dart # Paramètres de jeu (équipes, durée, mots)
│   ├── game_state.dart    # État de la partie en cours
│   ├── player.dart        # Modèle joueur
│   └── team.dart          # Modèle équipe
├── providers/
│   └── game_provider.dart # Provider principal (logique métier)
├── screens/               # Écrans de l'application
│   ├── home_screen.dart
│   ├── settings_screen.dart
│   ├── players_screen.dart
│   ├── teams_screen.dart
│   ├── game_screen.dart
│   ├── countdown_screen.dart
│   ├── turn_screen.dart
│   ├── verification_screen.dart
│   ├── transition_screen.dart
│   ├── results_screen.dart
│   └── rules_screen.dart
├── services/
│   └── storage_service.dart  # Persistance locale
├── theme/
│   └── app_theme.dart     # Thème et styles
├── utils/
│   ├── constants.dart     # Constantes de l'app
│   └── word_categories.dart # Catégories de mots
└── widgets/
    ├── common/            # Widgets réutilisables (boutons, inputs, etc.)
    └── effects/           # Effets visuels (shooting_stars)
```

## Flux de Jeu

1. **Configuration** : Nombre d'équipes, joueurs, durée du tour, pénalité de passe
2. **Inscription joueurs** : Saisie des noms
3. **Formation équipes** : Attribution manuelle ou aléatoire
4. **Saisie des mots** : Chaque joueur entre ses mots (ou mots aléatoires par catégorie)
5. **Partie** : 3 manches avec tous les mots remis dans le pool à chaque manche
6. **Résultats** : Affichage des scores par équipe et par manche

## Commandes

```bash
# Installer les dépendances
flutter pub get

# Lancer en mode debug
flutter run

# Build Android
flutter build apk

# Build iOS
flutter build ios
```

## Conventions

- Langue du code : Anglais
- Messages UI : Français
- Pattern : Provider pour la gestion d'état globale
- Modèles immuables avec `copyWith()`
- Persistance automatique après chaque modification d'état
