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

1. **Configuration** : Nombre d'équipes, joueurs, nombre total de mots (20-100), durée du tour, pénalité de passe
2. **Inscription joueurs** : Saisie des noms
3. **Formation équipes** : Attribution manuelle ou aléatoire (composition en cache)
4. **Saisie des mots** : Chaque joueur entre ses mots (répartition dynamique selon totalWords)
5. **Partie** : 3 manches avec tous les mots remis dans le pool à chaque manche
6. **Résultats** : Affichage des scores par équipe et par manche

## Paramètres de jeu

- **totalWords** (20-100, défaut 40) : Nombre total de mots à deviner
  - Répartition : Les premiers joueurs ont 1 mot de plus si répartition inégale
  - Ex: 40 mots / 6 joueurs = 7+7+7+7+6+6
- **Cache équipes** : Composition et noms des équipes sont persistés
  - Si le nombre de joueurs change : les nouveaux sont ajoutés aléatoirement

## Catégories de mots

Le jeu propose **13 catégories de mots** avec environ **5 711 mots** au total :

1. **7ème Art** (🎬) - Films, séries, anime, personnages
2. **Géographie** (🌍) - Pays, villes, monuments, fleuves
3. **Nature et Gastronomie** (🌿) - Animaux, plantes, plats du monde, fromages, vins, boissons
4. **Métiers & Sports** (💼) - Professions et tous les sports
5. **Célébrités** (⭐) - Sportifs, acteurs, chanteurs, influenceurs
6. **Noms communs** (🔧) - Objets quotidiens, instruments, électroménager, vêtements
7. **Univers Arcade** (🎮) - Jeux vidéo, Pokémon, Clash Royale, jeux de société
8. **Expressions** (🇫🇷) - Expressions françaises
9. **Dictionnaire** (📖) - Vocabulaire général, émotions, adjectifs, verbes
10. **Musique** (🎵) - Chansons, genres, artistes
11. **Marques** (🏷️) - Vêtements, tech, alimentation
12. **Science et Médecine** (🔬) - Anatomie, maladies, éléments chimiques, astronomie
13. **Métro Parisien** (🚇) - Stations de métro

### Détail par catégorie

| Catégorie | Icône | Nombre de mots |
|-----------|-------|----------------|
| Nature et Gastronomie | 🌿 | 883 |
| Dictionnaire | 📖 | 870 |
| Noms communs | 🔧 | 728 |
| 7ème Art | 🎬 | 491 |
| Science et Médecine | 🔬 | 484 |
| Marques | 🏷️ | 465 |
| Géographie | 🌍 | 384 |
| Célébrités | ⭐ | 361 |
| Univers Arcade | 🎮 | 324 |
| Métiers & Sports | 💼 | 284 |
| Musique | 🎵 | 224 |
| Expressions | 🇫🇷 | 118 |
| Métro Parisien | 🚇 | 105 |
| **TOTAL** | | **5 711** |

### Catégories enrichies (Janvier 2026)

#### Science et Médecine (anciennement Médecine)
- **ID** : `science_medecine` (renommé de `medecine`)
- **Icône** : 🔬
- **484 mots** répartis en :
  - **Section Médecine** : Anatomie, maladies, symptômes, traitements, spécialités médicales, équipements, traumatismes, pathologies, santé mentale, cancers, premiers secours, professions paramédicales
  - **Section Science** : Éléments chimiques, domaines scientifiques, théories et lois, espace et astronomie, inventions et découvertes, scientifiques célèbres, phénomènes physiques, unités de mesure, biologie cellulaire, chimie, géologie

#### Nature et Gastronomie
- **ID** : `nature`
- **Icône** : 🌿
- **883 mots** répartis en :
  - **Section Nature** : Animaux (sauvages, domestiques, marins, oiseaux communs, insectes, reptiles, rongeurs, cervidés, bovidés), plantes et fleurs, arbres, arbustes, plantes d'intérieur, plantes grimpantes, fruits et légumes, champignons, phénomènes naturels, météo, minéraux, géologie, astres, écosystèmes, éléments naturels
  - **Section Gastronomie** : Plats italiens, plats asiatiques, plats français traditionnels, plats du monde, techniques culinaires, ustensiles spécialisés, sauces célèbres, condiments, pâtisseries et desserts internationaux, confiseries, fromages, vins et cépages, pains du monde, termes culinaires, boissons chaudes et froides, boissons alcoolisées, cocktails, ingrédients cuisine, produits laitiers, viandes, charcuterie

#### Noms communs
- **ID** : `noms_communs`
- **Icône** : 🔧
- **728 mots** répartis en :
  - Objets électroniques, objets quotidiens, mobilier, ustensiles cuisine
  - Outils, moyens de transport, véhicules spécifiques
  - Vêtements, sous-vêtements, chaussures, accessoires mode
  - Instruments de musique, maison et habitat, jouets
  - Électroménager (gros et petit), équipements sportifs
  - Objets plage/vacances, matériel camping, matériel médical
  - Matériel informatique, textiles maison, contenants et emballages
  - Objets de décoration, bijoux, objets divers

#### Dictionnaire
- **ID** : `dictionnaire`
- **Icône** : 📖
- **870 mots** répartis en :
  - Émotions positives et négatives, états physiques, états mentaux
  - Adjectifs descriptifs, adjectifs de personnalité, adjectifs taille/forme
  - Verbes du quotidien, verbes créatifs, verbes de communication
  - Verbes domestiques, verbes de mouvement, actions physiques et mentales
  - Couleurs, formes géométriques, nombres et quantités
  - Temporalité, expressions temporelles, expressions de lieu
  - Météo, relations et liens, textures et sensations
  - Goûts et saveurs, odeurs, sons et bruits
  - Concepts philosophiques, valeurs morales, noms abstraits
  - Contraires et opposés, matériaux

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

## Règles de Développement

### Maintien de la documentation
- **Toute modification du projet** (ajout, suppression, modification de fichiers ou fonctionnalités) **doit être reflétée dans ce fichier CLAUDE.md**
- Mettre à jour l'arborescence si des fichiers sont ajoutés/supprimés
- Documenter les nouvelles fonctionnalités ou changements de flux

### Vérification des impacts
- **Avant toute modification** (ajout, suppression, refactoring), **vérifier les implications sur les autres parties du projet**
- Rechercher les usages/dépendances du code concerné
- S'assurer que les modifications n'introduisent pas de régressions
- Tester les écrans et fonctionnalités impactés
