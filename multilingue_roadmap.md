# Plan: Internationalisation Multi-Langue - Approche Méthodologique Complète

## Contexte et Objectifs

**Application actuelle**: Guess It All Mobile - 100% français, aucune infrastructure i18n
**Objectif**: Support multi-langue (FR, EN + futur ES, DE, IT, PT)
**Approche**: DIY complet, scalable, soigné (5-6 semaines)
**Contraintes**:
- Catégories culturelles (Expressions FR, Métro Parisien) → FR uniquement
- ~500 strings UI + ~3,700 mots de jeu à traduire
- Architecture évolutive pour 4+ langues futures

---

## Phase 1: Architecture et Infrastructure (Semaine 1)

### 1.1 Choix de l'Architecture Technique

**Stack Recommandé**: Flutter's Official i18n + Structure JSON Personnalisée

**Packages à Ajouter** (`pubspec.yaml`):
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  flutter_gen: ^5.7.0
```

**Pourquoi ce choix ?**
- ✅ Solution officielle, maintenue par Flutter team
- ✅ Support natif pluralization/interpolation
- ✅ Génération de code type-safe
- ✅ Scalable pour 10+ langues
- ✅ Pas de dépendance externe supplémentaire

**Alternative considérée** (non retenue):
- `easy_localization`: Plus simple mais moins flexible pour 6+ langues

### 1.2 Structure des Fichiers

**Nouvelle Arborescence**:
```
lib/
├── l10n/                              # Interface Utilisateur (ARB)
│   ├── app_fr.arb                    # Français (baseline)
│   ├── app_en.arb                    # Anglais
│   ├── app_es.arb                    # Espagnol (futur)
│   ├── app_de.arb                    # Allemand (futur)
│   ├── app_it.arb                    # Italien (futur)
│   ├── app_pt.arb                    # Portugais (futur)
│   └── l10n.yaml                     # Configuration
│
├── assets/translations/               # Contenu du Jeu (JSON)
│   ├── categories.json               # Metadata des catégories
│   └── words/
│       ├── fr/
│       │   ├── 7eme_art.json
│       │   ├── celebrites.json
│       │   ├── dictionnaire.json
│       │   ├── expressions.json      # FR uniquement
│       │   ├── geographie.json
│       │   ├── marques.json
│       │   ├── metiers_sports.json
│       │   ├── metro_parisien.json   # FR uniquement
│       │   ├── musique.json
│       │   ├── nature.json
│       │   ├── noms_communs.json
│       │   ├── science_medecine.json
│       │   └── univers_arcade.json
│       ├── en/
│       │   ├── 7eme_art.json
│       │   ├── celebrites.json
│       │   └── ... (11 catégories, sans expressions/metro)
│       ├── es/ (futur)
│       ├── de/ (futur)
│       ├── it/ (futur)
│       └── pt/ (futur)
│
├── services/
│   ├── localization_service.dart      # NOUVEAU
│   └── word_loader_service.dart       # NOUVEAU (remplace word_categories/)
│
└── utils/
    └── locale_manager.dart             # NOUVEAU
```

### 1.3 Configuration Initiale

**1.3.1 Créer `l10n.yaml`** à la racine:
```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

**1.3.2 Mettre à jour `pubspec.yaml`**:
```yaml
flutter:
  generate: true           # NOUVEAU
  uses-material-design: true
  assets:
    - assets/fonts/
    - assets/sounds/
    - assets/translations/  # NOUVEAU
    - assets/translations/words/fr/  # NOUVEAU
    - assets/translations/words/en/  # NOUVEAU
```

**1.3.3 Modifier `app.dart`** - Ajouter support localization:
```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guess It All',

      // NOUVEAU: Configuration localisation
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('fr'),  // Français
        Locale('en'),  // Anglais
        // Langues futures (décommenter au fur et à mesure):
        // Locale('es'),  // Espagnol
        // Locale('de'),  // Allemand
        // Locale('it'),  // Italien
        // Locale('pt'),  // Portugais
      ],

      // Stratégie de résolution de locale
      localeResolutionCallback: (locale, supportedLocales) {
        // 1. Vérifier si langue exacte supportée
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        // 2. Fallback vers français par défaut
        return supportedLocales.first;
      },

      theme: AppTheme.darkTheme,
      home: _buildCurrentScreen(provider.game.currentScreen),
    );
  }
}
```

### 1.4 Services de Gestion

**1.4.1 Créer `lib/services/localization_service.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _localeKey = 'app_locale';

  // Langues disponibles
  static const List<Locale> supportedLocales = [
    Locale('fr'),  // Français
    Locale('en'),  // English
    // Futures:
    // Locale('es'),  // Español
    // Locale('de'),  // Deutsch
    // Locale('it'),  // Italiano
    // Locale('pt'),  // Português
  ];

  // Noms de langues pour UI
  static const Map<String, String> languageNames = {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
  };

  // Drapeaux pour UI
  static const Map<String, String> languageFlags = {
    'fr': '🇫🇷',
    'en': '🇬🇧',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
  };

  // Sauvegarder préférence utilisateur
  static Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  // Charger préférence utilisateur
  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return null;
  }

  // Catégories disponibles par langue
  static List<String> getAvailableCategoriesForLocale(String languageCode) {
    const allCategories = [
      '7eme_art',
      'celebrites',
      'dictionnaire',
      'geographie',
      'marques',
      'metiers_sports',
      'musique',
      'nature',
      'noms_communs',
      'science_medecine',
      'univers_arcade',
    ];

    const frenchOnlyCategories = [
      'expressions',       // Expressions françaises
      'metro_parisien',    // Métro de Paris
    ];

    if (languageCode == 'fr') {
      return [...allCategories, ...frenchOnlyCategories];
    }

    return allCategories;
  }
}
```

**1.4.2 Créer `lib/services/word_loader_service.dart`**:
```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word_category.dart';

class WordLoaderService {
  static final Map<String, Map<String, WordCategory>> _cache = {};

  // Charger toutes les catégories pour une langue
  static Future<Map<String, WordCategory>> loadCategoriesForLocale(String languageCode) async {
    // Vérifier cache
    if (_cache.containsKey(languageCode)) {
      return _cache[languageCode]!;
    }

    // Obtenir liste des catégories disponibles
    final availableCategories = LocalizationService.getAvailableCategoriesForLocale(languageCode);

    final categories = <String, WordCategory>{};

    for (final categoryId in availableCategories) {
      try {
        final category = await _loadCategory(languageCode, categoryId);
        categories[categoryId] = category;
      } catch (e) {
        print('Erreur chargement catégorie $categoryId en $languageCode: $e');
      }
    }

    // Mettre en cache
    _cache[languageCode] = categories;

    return categories;
  }

  // Charger une catégorie spécifique
  static Future<WordCategory> _loadCategory(String languageCode, String categoryId) async {
    final path = 'assets/translations/words/$languageCode/$categoryId.json';
    final jsonString = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonString);

    return WordCategory.fromJson(jsonData);
  }

  // Vider le cache (utile lors du changement de langue)
  static void clearCache() {
    _cache.clear();
  }
}
```

---

## Phase 2: Migration du Code Existant (Semaine 2-3)

### 2.1 Extraction des Strings UI (Méthode Systématique)

**Étape 1**: Créer `app_fr.arb` avec TOUTES les strings actuelles

**Processus**:
1. Parcourir chaque fichier Dart dans `lib/screens/`
2. Identifier toutes les strings hardcodées
3. Créer clé unique et descriptive
4. Documenter contexte et pluralisation si besoin

**Exemple de Structure ARB**:
```json
{
  "@@locale": "fr",

  "appTitle": "Guess It All",
  "@appTitle": {
    "description": "Titre de l'application"
  },

  "homeButtonPlay": "Jouer",
  "@homeButtonPlay": {
    "description": "Bouton principal écran d'accueil"
  },

  "homeButtonResume": "Reprendre",
  "homeButtonNewGame": "Nouvelle partie",
  "homeButtonRules": "Règles",

  "settingsTitle": "Paramètres",
  "settingsPlayers": "Joueurs",
  "settingsTeams": "Équipes",
  "settingsWordChoice": "Choix des mots",

  "wordChoiceCustom": "Personnalisé",
  "wordChoiceRandom": "Aléatoire",

  "difficultyEasy": "Facile",
  "difficultyMedium": "Moyen",
  "difficultyHard": "Difficile",

  "roundMode1": "Description libre",
  "roundMode2": "Un seul mot",
  "roundMode3": "Mime",

  "wordsRemaining": "{count, plural, =0{Aucun mot} =1{1 mot restant} other{{count} mots restants}}",
  "@wordsRemaining": {
    "description": "Nombre de mots restants",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },

  "scorePoints": "{points, plural, =0{0 point} =1{1 point} other{{points} points}}",
  "@scorePoints": {
    "placeholders": {
      "points": {
        "type": "int"
      }
    }
  },

  "roundNumber": "Manche {number}",
  "@roundNumber": {
    "placeholders": {
      "number": {
        "type": "int"
      }
    }
  }
}
```

**Étape 2**: Créer script d'extraction automatique

Créer `tools/extract_strings.dart`:
```dart
// Script pour scanner les fichiers et suggérer les strings à extraire
// Recherche patterns: Text('...'), 'string', etc.
// Génère liste de suggestions pour ARB
```

**Étape 3**: Mise à jour des Widgets

**AVANT**:
```dart
Text('Manche $currentRound'),
AppButton(text: 'Commencer le tour'),
```

**APRÈS**:
```dart
Text(AppLocalizations.of(context)!.roundNumber(currentRound)),
AppButton(text: AppLocalizations.of(context)!.gameButtonStartTurn),
```

**Helper Widget** (optionnel, pour réduire verbosité):
```dart
// lib/utils/l10n_helper.dart
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// Usage:
Text(context.l10n.roundNumber(currentRound))
```

### 2.2 Migration des Constantes

**Fichier**: `lib/utils/constants.dart`

**AVANT**:
```dart
static const wordChoiceCustom = 'Personnalisé';
static const wordChoiceRandom = 'Aléatoire';

static const difficultyLabels = {
  1: 'Facile',
  2: 'Moyen',
  3: 'Difficile',
};
```

**APRÈS**:
```dart
// Supprimer constantes hardcodées
// Utiliser AppLocalizations à la place
// Dans les widgets:
final labels = {
  1: context.l10n.difficultyEasy,
  2: context.l10n.difficultyMedium,
  3: context.l10n.difficultyHard,
};
```

### 2.3 Migration des Mots de Jeu

**Étape 1**: Créer schéma JSON pour categories

**Format** (`assets/translations/categories.json`):
```json
{
  "categories": [
    {
      "id": "7eme_art",
      "icon": "🎬",
      "names": {
        "fr": "7ème Art",
        "en": "7th Art",
        "es": "7º Arte",
        "de": "7. Kunst",
        "it": "7a Arte",
        "pt": "7ª Arte"
      },
      "availableLocales": ["fr", "en", "es", "de", "it", "pt"]
    },
    {
      "id": "expressions",
      "icon": "🇫🇷",
      "names": {
        "fr": "Expressions françaises"
      },
      "availableLocales": ["fr"]
    },
    {
      "id": "metro_parisien",
      "icon": "🚇",
      "names": {
        "fr": "Métro Parisien"
      },
      "availableLocales": ["fr"]
    }
  ]
}
```

**Étape 2**: Convertir fichiers Dart → JSON

**Script de Migration** (`tools/convert_words_to_json.dart`):
```dart
// Lit les fichiers .dart dans word_categories/categories/
// Extrait WordWithDifficulty(...)
// Génère JSON formaté

// Exemple sortie pour 7eme_art.json (FR):
{
  "categoryId": "7eme_art",
  "words": [
    {"word": "Titanic", "difficulty": 1},
    {"word": "Star Wars", "difficulty": 1},
    {"word": "Avatar", "difficulty": 1},
    // ... ~500 mots
  ]
}
```

**Étape 3**: Mise à jour des Models

**Nouveau** `lib/models/word_category.dart`:
```dart
class WordCategory {
  final String id;
  final String icon;
  final Map<String, String> names;  // locale → name
  final List<String> availableLocales;
  final List<WordWithDifficulty> words;

  const WordCategory({
    required this.id,
    required this.icon,
    required this.names,
    required this.availableLocales,
    required this.words,
  });

  // Obtenir nom localisé
  String getName(String locale) {
    return names[locale] ?? names['fr'] ?? id;
  }

  // Vérifier si disponible dans locale
  bool isAvailableInLocale(String locale) {
    return availableLocales.contains(locale);
  }

  factory WordCategory.fromJson(Map<String, dynamic> json) {
    return WordCategory(
      id: json['categoryId'],
      icon: json['icon'] ?? '',
      names: Map<String, String>.from(json['names'] ?? {}),
      availableLocales: List<String>.from(json['availableLocales'] ?? []),
      words: (json['words'] as List)
          .map((w) => WordWithDifficulty.fromJson(w))
          .toList(),
    );
  }
}
```

### 2.4 Ordre de Migration des Écrans

**Priorisation** (du plus simple au plus complexe):

1. ✅ **home_screen.dart** (~5 strings, aucune pluralisation)
2. ✅ **countdown_screen.dart** (~0 strings, juste nombres)
3. ✅ **transition_screen.dart** (~15 strings, pluralisation simple)
4. ⚠️ **settings_screen.dart** (~30 strings, plusieurs modals)
5. ⚠️ **players_screen.dart** (~40 strings, validation complexe)
6. ⚠️ **game_screen.dart** (~25 strings, logique métier)
7. 🔥 **rules_screen.dart** (~150 lignes de prose, texte long)
8. 🔥 **results_screen.dart** (~30 strings, statistiques)

**Stratégie**: Commencer par les écrans simples pour valider l'architecture avant d'attaquer les complexes.

---

## Phase 3: Traduction DIY (Semaine 3-4)

### 3.1 Outils Gratuits Recommandés

**Pour UI Strings (500 strings)**:

1. **Google Translate API** (gratuit jusqu'à 500k caractères/mois)
   - Premier jet automatique
   - Puis révision manuelle

2. **DeepL Free** (meilleure qualité que Google)
   - Limite: 500k caractères/mois
   - Traductions plus naturelles

3. **ARB Translator Tools**:
   - `arb-translator` (npm package)
   - `flutter_arb_translator` (Python script)

4. **Vérification Communautaire**:
   - r/FlutterDev (Reddit)
   - Discord Flutter FR/EN
   - GitHub Issues pour review

**Pour Mots du Jeu (3,700 mots)**:

1. **Spreadsheet Collaboratif** (Google Sheets):
   ```
   | Français       | English          | Difficulty | Category      |
   |----------------|------------------|-----------|---------------|
   | Titanic        | Titanic          | 1         | 7eme_art      |
   | Le Roi Lion    | The Lion King    | 1         | 7eme_art      |
   | Pomme de terre | Potato           | 1         | nature        |
   ```

2. **Batch Translation**:
   - Utiliser DeepL/Google Translate par lots
   - Exporter CSV, traduire, réimporter

3. **Validation**:
   - Vérifier doublons
   - Vérifier cohérence (majuscules, accents)
   - Tester dans l'app

### 3.2 Workflow de Traduction UI

**Étape 1**: Traduction automatique baseline
```bash
# Installer outil
npm install -g arb-translator

# Traduire FR → EN
arb-translator translate \
  --source lib/l10n/app_fr.arb \
  --target lib/l10n/app_en.arb \
  --locale en \
  --provider deepl
```

**Étape 2**: Révision manuelle prioritaire

**Strings critiques à réviser en premier**:
- Titres d'écrans
- Boutons d'action
- Messages d'erreur
- Règles du jeu (rules_screen.dart)

**Checklist Révision**:
- [ ] Longueur similaire (layout)
- [ ] Ton cohérent (formel vs casual)
- [ ] Pluralisation correcte
- [ ] Interpolation fonctionne
- [ ] Contexte préservé

**Étape 3**: Test dans l'app

**Créer écran de test** `lib/screens/translation_test_screen.dart`:
```dart
// Affiche toutes les strings ARB côte à côte (FR/EN)
// Permet de voir longueur, layout, cohérence
// Bouton pour switcher langue rapidement
```

### 3.3 Workflow de Traduction Mots

**Étape 1**: Créer Google Sheet maître

**Colonnes**:
- ID unique
- Catégorie
- Mot FR
- Mot EN
- Difficulté
- Notes (si traduction complexe)
- Status (À traduire / Traduit / Vérifié)

**Étape 2**: Traduction par catégorie

**Ordre recommandé** (par difficulté):

1. ✅ **Marques** (465 mots) → Noms propres, peu de traduction
2. ✅ **7ème Art** (491 mots) → Titres internationaux
3. ✅ **Géographie** (384 mots) → Noms de lieux standards
4. ⚠️ **Nature** (626 mots) → Noms communs, attention traduction
5. ⚠️ **Dictionnaire** (492 mots) → Vocabulaire général
6. ⚠️ **Célébrités** (361 mots) → Vérifier notoriété internationale
7. 🔥 **Noms communs** (345 mots) → Attention contexte
8. 🔥 **Univers Arcade** (324 mots) → Termes gaming
9. 🔥 **Science & Médecine** (484 mots) → Termes techniques
10. 🔥 **Métiers & Sports** (284 mots) → Métiers peuvent varier
11. 🔥 **Musique** (224 mots) → Titres de chansons
12. ❌ **Expressions** (118 mots) → FR uniquement
13. ❌ **Métro Parisien** (105 mots) → FR uniquement

**Total à traduire**: ~3,580 mots (excluant FR-only)

**Étape 3**: Scripts de conversion

**Google Sheets → JSON**:
```python
# tools/sheets_to_json.py
import pandas as pd
import json

# Lire Google Sheet exporté en CSV
df = pd.read_csv('translations_export.csv')

# Grouper par catégorie
categories = df.groupby('Category')

for category_id, words in categories:
    # Français
    fr_data = {
        'categoryId': category_id,
        'words': [
            {'word': row['Mot FR'], 'difficulty': row['Difficulty']}
            for _, row in words.iterrows()
        ]
    }
    with open(f'assets/translations/words/fr/{category_id}.json', 'w', encoding='utf-8') as f:
        json.dump(fr_data, f, ensure_ascii=False, indent=2)

    # Anglais
    en_data = {
        'categoryId': category_id,
        'words': [
            {'word': row['Mot EN'], 'difficulty': row['Difficulty']}
            for _, row in words.iterrows()
            if pd.notna(row['Mot EN'])
        ]
    }
    with open(f'assets/translations/words/en/{category_id}.json', 'w', encoding='utf-8') as f:
        json.dump(en_data, f, ensure_ascii=False, indent=2)
```

### 3.4 Validation et Tests

**Tests Automatisés**:
```dart
// test/localization_test.dart
void main() {
  test('Toutes les clés ARB existent en FR et EN', () {
    // Charger app_fr.arb
    // Charger app_en.arb
    // Vérifier clés identiques
  });

  test('Aucun mot dupliqué par catégorie', () {
    // Pour chaque fichier JSON
    // Vérifier pas de doublons
  });

  test('Nombre de mots cohérent par catégorie', () {
    // FR: 491 mots pour 7eme_art
    // EN: ~491 mots pour 7eme_art
    // Tolérance ±5%
  });
}
```

**Tests Manuels**:
- Jouer une partie complète en anglais
- Tester tous les écrans
- Vérifier layout (texte ne déborde pas)
- Tester changement de langue à chaud

---

## Phase 4: Interface de Sélection de Langue (Semaine 4)

### 4.1 Ajout dans Settings Screen

**Modifier** `lib/screens/settings_screen.dart`:

```dart
// Ajouter section "Langue / Language"
_buildSection(
  title: context.l10n.settingsLanguageTitle,
  icon: '🌐',
  child: _buildLanguageSelector(),
),

Widget _buildLanguageSelector() {
  final currentLocale = Localizations.localeOf(context).languageCode;

  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: LocalizationService.supportedLocales.map((locale) {
        final isSelected = locale.languageCode == currentLocale;

        return GestureDetector(
          onTap: () => _changeLanguage(locale),
          child: Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                ? AppColors.primaryPink.withOpacity(0.2)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                  ? AppColors.primaryPink
                  : AppColors.gray600,
              ),
            ),
            child: Row(
              children: [
                Text(
                  LocalizationService.languageFlags[locale.languageCode]!,
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: 12),
                Text(
                  LocalizationService.languageNames[locale.languageCode]!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primaryPink : Colors.white,
                  ),
                ),
                Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primaryPink),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

Future<void> _changeLanguage(Locale locale) async {
  // Sauvegarder préférence
  await LocalizationService.saveLocale(locale.languageCode);

  // Vider cache des mots
  WordLoaderService.clearCache();

  // Afficher dialog de confirmation
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.languageChangeTitle),
      content: Text(context.l10n.languageChangeMessage),
      actions: [
        AppButton(
          text: context.l10n.buttonRestart,
          onPressed: () {
            // Redémarrer l'app (nécessaire pour recharger tout)
            Phoenix.rebirth(context); // Utiliser package flutter_phoenix
          },
        ),
      ],
    ),
  );
}
```

### 4.2 Package Flutter Phoenix

**Ajouter** `pubspec.yaml`:
```yaml
dependencies:
  flutter_phoenix: ^1.1.1
```

**Wrapper dans** `main.dart`:
```dart
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() {
  runApp(
    Phoenix(
      child: MyApp(),
    ),
  );
}
```

**Utilité**: Permet de redémarrer l'app proprement après changement de langue.

---

## Phase 5: Déploiement Multi-Langue (Semaine 5-6)

### 5.1 Préparation Assets Store

**5.1.1 Google Play Store**

**Metadata Requis par Langue**:

**Français** (baseline existant):
- Titre court (30 chars): "Guess It All"
- Titre complet (50 chars): "Guess It All - Jeu de Devinettes"
- Description courte (80 chars): "Jeu multijoueur de devinettes de mots en équipe, inspiré de Time's Up !"
- Description longue (4000 chars): [Texte marketing détaillé]
- Captures d'écran: 8 images (1080x1920)
- Vidéo promo (optionnel)

**Anglais** (nouveau):
- Short title: "Guess It All"
- Full title: "Guess It All - Word Guessing Game"
- Short description: "Multiplayer word guessing game in teams, inspired by Time's Up!"
- Long description: [Translated marketing text]
- Screenshots: 8 images (EN interface)
- Promo video (optional)

**Template Description Longue EN**:
```
🎯 GUESS IT ALL - The Ultimate Word Guessing Game!

Challenge your friends and family in this exciting multiplayer word guessing game inspired by the classic Time's Up format!

🎮 HOW TO PLAY
• Form teams (2+ players per team)
• Each player enters secret words
• 3 rounds with different rules:
  - Round 1: Describe with unlimited words
  - Round 2: Only ONE word allowed
  - Round 3: Mime without speaking!

✨ FEATURES
• 4,700+ words across 11 categories
• Customizable game settings
• Difficulty levels (Easy/Medium/Hard)
• Score tracking and statistics
• Beautiful dark theme interface
• Offline play - no internet required

📚 CATEGORIES
🎬 Movies & TV Shows
🌍 Geography
🌿 Nature & Food
💼 Jobs & Sports
⭐ Celebrities
🎮 Video Games
📖 Dictionary
🎵 Music
🏷️ Brands
🔬 Science & Medicine
🔧 Common Objects

Perfect for parties, family gatherings, or game nights!

Download now and start guessing! 🎉
```

**5.1.2 Apple App Store**

**Metadata Similaire** + spécificités:
- Keywords (100 chars/langue): "word game, party game, guessing, multiplayer, time's up, family"
- App Preview Screenshots (6.5" + 5.5")
- Privacy Policy URL (multilangue si possible)
- Support URL (multilangue)

### 5.2 Captures d'Écran Localisées

**Outils Recommandés**:

1. **Screenshot Automation**:
   - `flutter_driver` pour captures auto
   - `screenshot` package
   - Ou manuel dans émulateurs

2. **Template Figma/Canva**:
   - Créer template avec device mockup
   - Remplacer screenshots par langue
   - Ajouter texte marketing overlay

**Écrans à Capturer** (8 par langue):
1. Home Screen (accueil)
2. Settings Screen (paramètres)
3. Categories Selection (choix catégories)
4. Turn Screen (écran de jeu actif)
5. Verification Screen (validation mots)
6. Transition Screen (scores inter-manches)
7. Results Screen (podium final)
8. Rules Screen (règles du jeu)

**Script Automatisation**:
```dart
// test_driver/screenshot_test.dart
import 'package:flutter_driver/flutter_driver.dart';

void main() {
  group('Screenshots', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    test('Capture all screens in French', () async {
      // Set locale to FR
      // Navigate through app
      // Take screenshots with driver.screenshot()
    });

    test('Capture all screens in English', () async {
      // Set locale to EN
      // Navigate through app
      // Take screenshots
    });
  });
}
```

### 5.3 Processus de Release

**5.3.1 Préparation Build**

**Android** (`android/app/build.gradle`):
```gradle
android {
    defaultConfig {
        // Locales supportés (réduit taille app)
        resConfigs "fr", "en"  // Ajouter "es", "de", "it", "pt" plus tard
    }
}
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleLocalizations</key>
<array>
    <string>fr</string>
    <string>en</string>
</array>
```

**5.3.2 Checklist Pre-Release**

**Tests Fonctionnels**:
- [ ] Changement de langue fonctionne
- [ ] Toutes catégories chargent (FR/EN)
- [ ] Catégories FR-only invisibles en EN
- [ ] Pas de crash si mots manquants
- [ ] Layout correct (texte ne déborde pas)
- [ ] Pluralisation correcte (0, 1, 2+ mots)
- [ ] Persistance locale préservée

**Tests UI/UX**:
- [ ] Screenshots cohérents avec metadata
- [ ] Descriptions store attractives
- [ ] Pas de texte tronqué sur petits écrans
- [ ] Emojis s'affichent correctement
- [ ] Performance identique (temps chargement)

**Tests Stores**:
- [ ] Metadata remplis pour FR + EN
- [ ] Screenshots uploadés (8 par langue)
- [ ] Rating correct (PEGI 3 / Everyone)
- [ ] Privacy policy accessible
- [ ] Support email valide

**5.3.3 Stratégie de Rollout**

**Phase 1: Release Beta** (1-2 semaines)
- Google Play: Internal Testing (100 testeurs)
- TestFlight: Invited Testers (100 testeurs)
- Feedback sur traductions
- Correction bugs

**Phase 2: Release Progressive**
- Google Play: Open Beta (5%)
- App Store: Phased Release (Day 1: 1%)
- Monitorer crash reports
- Ajuster si problèmes

**Phase 3: Release Complète**
- Rollout 100% après 1 semaine stable
- Promouvoir dans stores (Featured?)
- Marketing bilingue (Reddit, Twitter, ProductHunt)

### 5.4 Monitoring Post-Release

**Métriques à Suivre**:

**Analytics** (Firebase/Mixpanel):
- Répartition langues utilisées (% FR vs EN)
- Taux de changement de langue
- Catégories populaires par langue
- Crash rate par locale
- Engagement (parties jouées, durée)

**Feedback Utilisateurs**:
- Reviews stores filtrés par langue
- Support tickets par langue
- Suggestions de traduction (formulaire in-app?)

**Optimisations Futures**:
- A/B test titres stores
- Tester différentes captures d'écran
- Adapter marketing par marché

---

## Phase 6: Scalabilité Futures Langues (Post-Release)

### 6.1 Ajout Espagnol (ES)

**Effort Estimé**: 2-3 semaines (avec expérience FR/EN)

**Checklist Rapide**:
1. Créer `app_es.arb` (traduire 500 strings UI)
2. Créer `assets/translations/words/es/` (traduire 3,580 mots)
3. Ajouter `Locale('es')` dans MaterialApp
4. Mettre à jour `categories.json` avec noms espagnols
5. Captures d'écran ES
6. Metadata Google Play/App Store ES
7. Beta testing avec hispanophonesAjouter autres langues (DE, IT, PT) → même processus

**Optimisation**: Créer pipeline de traduction automatisée
- Scripts pour générer baseline DeepL
- Interface web pour community review
- CI/CD pour validation automatique

### 6.2 Gestion Catégories Locale-Specific

**Concept**: Ajouter catégories culturelles par langue

**Exemples**:
- **FR**: Expressions Françaises, Métro Parisien
- **EN**: English Idioms, London Underground
- **ES**: Modismos Españoles, Metro de Madrid
- **DE**: Deutsche Redewendungen, Berliner U-Bahn

**Architecture**:
```json
// categories.json
{
  "id": "idioms_fr",
  "icon": "🇫🇷",
  "names": {"fr": "Expressions Françaises"},
  "availableLocales": ["fr"]
},
{
  "id": "idioms_en",
  "icon": "🇬🇧",
  "names": {"en": "English Idioms"},
  "availableLocales": ["en"]
}
```

**UI**: Catégories s'affichent/cachent automatiquement selon langue active

---

## Résumé Timeline Complète

| Phase | Durée | Tâches Principales | Livrables |
|-------|-------|-------------------|-----------|
| **Phase 1** | Semaine 1 | Infrastructure i18n | ARB setup, Services, Config |
| **Phase 2** | Semaine 2-3 | Migration code | Tous écrans localisés (FR) |
| **Phase 3** | Semaine 3-4 | Traductions DIY | app_en.arb + 3,580 mots EN |
| **Phase 4** | Semaine 4 | UI Langue | Sélecteur dans Settings |
| **Phase 5** | Semaine 5-6 | Release Stores | Build, Screenshots, Deploy |
| **Phase 6** | Post-Release | Langues futures | ES, DE, IT, PT (itératif) |

**Total**: 5-6 semaines pour FR + EN complet, puis +2-3 semaines par langue supplémentaire

---

## Outils et Ressources DIY

### Traduction UI
- DeepL Free: https://www.deepl.com/translator
- Google Translate: https://translate.google.com
- ARB Translator: https://pub.dev/packages/arb_translator

### Traduction Mots
- Google Sheets (collaboration)
- LibreOffice Calc (offline)
- ChatGPT/Claude (batch translation + review)

### Validation
- Grammarly (EN)
- LanguageTool (multi-langue)
- Community review (Reddit, Discord)

### Assets Store
- Canva (screenshots)
- Figma (device mockups)
- Unsplash (images promo)

### Testing
- BrowserStack (device testing)
- Firebase Test Lab (automatisé)
- TestFlight/Internal Testing (beta)

---

## Prochaines Étapes Immédiates

1. **Valider ce plan** avec stakeholders
2. **Créer repo Git branch** `feature/i18n`
3. **Installer packages** Flutter (semaine 1, jour 1)
4. **Créer structure fichiers** (l10n/, assets/translations/)
5. **Commencer extraction strings** home_screen.dart (test pilote)
6. **Setup Google Sheet** pour tracking mots
7. **Définir conventions** (naming, formatage, review process)

**Question finale**: Voulez-vous que je commence l'implémentation de la Phase 1 (Infrastructure), ou préférez-vous d'abord créer une version détaillée de ce plan en français pour documentation interne ?
