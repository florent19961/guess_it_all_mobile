// ============================================================
// SCRIPT DE CONVERSION : Dart → JSON
// ============================================================
//
// Convertit les catégories de mots de constantes Dart vers JSON
// pour préparer l'internationalisation future.
//
// Usage : dart run tools/convert_words_to_json.dart
//
// ============================================================

import 'dart:io';
import 'dart:convert';

// Structure pour stocker les métadonnées extraites des en-têtes
class CategoryMetadata {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<String> sections;
  final List<String> enrichmentIdeas;
  final Map<String, String> difficultyCriteria;

  CategoryMetadata({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.sections,
    required this.enrichmentIdeas,
    required this.difficultyCriteria,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'sections': sections,
    'enrichmentIdeas': enrichmentIdeas,
    'difficultyCriteria': difficultyCriteria,
  };
}

void main() async {
  print('=== Conversion des catégories de mots Dart → JSON ===\n');

  final categoriesDir = Directory('lib/utils/word_categories/backup');
  final outputDir = Directory('assets/translations');
  final wordsOutputDir = Directory('assets/translations/words/fr');

  // Créer les répertoires de sortie
  await wordsOutputDir.create(recursive: true);
  print('✓ Répertoires de sortie créés\n');

  final categories = <Map<String, dynamic>>[];
  int totalWords = 0;

  // Traiter chaque fichier .dart
  final dartFiles = categoriesDir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  print('Fichiers trouvés: ${dartFiles.length}\n');

  for (final file in dartFiles) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    print('Traitement de $fileName...');

    final result = await processCategoryFile(file, wordsOutputDir);
    if (result != null) {
      categories.add(result['metadata']);
      totalWords += result['wordCount'] as int;
      print('  ✓ ${result['wordCount']} mots extraits\n');
    }
  }

  // Générer categories.json
  await generateCategoriesJson(categories, outputDir);

  print('\n=== Conversion terminée avec succès ===');
  print('Fichiers générés:');
  print('  - assets/translations/categories.json');
  print('  - assets/translations/words/fr/*.json (${dartFiles.length} fichiers)');
  print('\nStatistiques:');
  print('  - Catégories: ${categories.length}');
  print('  - Mots totaux: $totalWords');
}

Future<Map<String, dynamic>?> processCategoryFile(
  File dartFile,
  Directory outputDir,
) async {
  final fileName = dartFile.path.split(Platform.pathSeparator).last;
  final categoryId = fileName.replaceAll('.dart', '');

  final content = await dartFile.readAsString();
  final lines = content.split('\n');

  // Parser les métadonnées
  final metadata = parseHeaderMetadata(lines, categoryId);

  // Parser les mots
  final words = parseWords(lines);

  // Générer le fichier JSON des mots
  final wordsJson = {
    'categoryId': categoryId,
    'words': words,
  };

  final outputFile = File('${outputDir.path}/$categoryId.json');
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(wordsJson),
    encoding: utf8,
  );

  // Retourner les métadonnées pour categories.json
  return {
    'metadata': {
      'id': categoryId,
      'icon': metadata.icon,
      'names': {'fr': metadata.name},
      'availableLocales': ['fr'],
      'metadata': metadata.toJson(),
    },
    'wordCount': words.length,
  };
}

CategoryMetadata parseHeaderMetadata(List<String> lines, String categoryId) {
  String description = '';
  List<String> sections = [];
  List<String> enrichmentIdeas = [];
  Map<String, String> difficultyCriteria = {};

  bool inDescription = false;
  bool inSections = false;
  bool inEnrichment = false;
  bool inDifficulty = false;

  for (final line in lines) {
    final trimmed = line.trim();

    // Arrêter au début du code Dart
    if (trimmed.startsWith('import ')) break;

    // Détecter les sections
    if (trimmed.contains('DESCRIPTION')) {
      inDescription = true;
      inSections = false;
      inEnrichment = false;
      inDifficulty = false;
      continue;
    }
    if (trimmed.contains('SECTIONS EXISTANTES')) {
      inDescription = false;
      inSections = true;
      inEnrichment = false;
      inDifficulty = false;
      continue;
    }
    if (trimmed.contains('IDÉES D\'ENRICHISSEMENT') || trimmed.contains('IDEES D\'ENRICHISSEMENT')) {
      inDescription = false;
      inSections = false;
      inEnrichment = true;
      inDifficulty = false;
      continue;
    }
    if (trimmed.contains('CRITÈRES DE DIFFICULTÉ') || trimmed.contains('CRITERES DE DIFFICULTE')) {
      inDescription = false;
      inSections = false;
      inEnrichment = false;
      inDifficulty = true;
      continue;
    }

    // Extraire le contenu
    if (trimmed.startsWith('// -')) {
      final content = trimmed.substring(4).trim();
      if (inSections) sections.add(content);
      if (inEnrichment) enrichmentIdeas.add(content);
    } else if (inDescription && trimmed.startsWith('//')) {
      final content = trimmed.substring(2).trim();
      if (content.isNotEmpty &&
          !content.startsWith('=') &&
          !content.startsWith('CATÉGORIE') &&
          !content.startsWith('CATEGORIE')) {
        description += (description.isEmpty ? '' : ' ') + content;
      }
    } else if (inDifficulty && trimmed.startsWith('// -')) {
      final content = trimmed.substring(4).trim();
      // Parser "1 (Facile) : Description" ou "1 (Facile): Description"
      final match = RegExp(r'(\d+)\s*\(([^)]+)\)\s*:?\s*(.+)').firstMatch(content);
      if (match != null) {
        difficultyCriteria[match.group(1)!] = match.group(3)!;
      }
    }
  }

  // Obtenir name et icon du categoryId
  final categoryInfo = getCategoryInfo(categoryId);

  return CategoryMetadata(
    id: categoryId,
    name: categoryInfo['name']!,
    icon: categoryInfo['icon']!,
    description: description,
    sections: sections,
    enrichmentIdeas: enrichmentIdeas,
    difficultyCriteria: difficultyCriteria,
  );
}

List<Map<String, dynamic>> parseWords(List<String> lines) {
  final words = <Map<String, dynamic>>[];

  for (final line in lines) {
    final trimmed = line.trim();

    // Chercher les lignes WordWithDifficulty avec language
    // Pattern : WordWithDifficulty('Mot', difficulty: 1, language: 'international')
    final matchWithLang = RegExp(
      "WordWithDifficulty\\(['\"](.+?)['\"]\\s*,\\s*difficulty:\\s*(\\d+)\\s*,\\s*language:\\s*['\"](.+?)['\"]\\)"
    ).firstMatch(trimmed);

    if (matchWithLang != null) {
      var word = matchWithLang.group(1)!;
      word = word.replaceAll(r"\'", "'");

      words.add({
        'word': word,
        'difficulty': int.parse(matchWithLang.group(2)!),
        'language': matchWithLang.group(3)!,
      });
    } else {
      // Fallback: ancien format sans language
      final match = RegExp(
        "WordWithDifficulty\\(['\"](.+?)['\"]\\s*,\\s*difficulty:\\s*(\\d+)\\)"
      ).firstMatch(trimmed);

      if (match != null) {
        var word = match.group(1)!;
        word = word.replaceAll(r"\'", "'");

        words.add({
          'word': word,
          'difficulty': int.parse(match.group(2)!),
          'language': 'international',
        });
      }
    }
  }

  return words;
}

Map<String, String> getCategoryInfo(String categoryId) {
  // Mapping basé sur registry.dart
  final mapping = {
    '7eme_art': {'name': '7ème Art', 'icon': '🎬'},
    'celebrites': {'name': 'Célébrités', 'icon': '⭐'},
    'dictionnaire': {'name': 'Dictionnaire', 'icon': '📖'},
    'expressions': {'name': 'Expressions', 'icon': '🇫🇷'},
    'geographie': {'name': 'Géographie', 'icon': '🌍'},
    'marques': {'name': 'Marques', 'icon': '🏷️'},
    'metiers_sports': {'name': 'Métiers & Sports', 'icon': '💼'},
    'metro_parisien': {'name': 'Métro Parisien', 'icon': '🚇'},
    'musique': {'name': 'Musique', 'icon': '🎵'},
    'nature': {'name': 'Nature et Gastronomie', 'icon': '🌿'},
    'noms_communs': {'name': 'Noms communs', 'icon': '🔧'},
    'science_medecine': {'name': 'Science et Médecine', 'icon': '🔬'},
    'univers_arcade': {'name': 'Univers Arcade', 'icon': '🎮'},
  };

  return mapping[categoryId] ?? {'name': categoryId, 'icon': '❓'};
}

Future<void> generateCategoriesJson(
  List<Map<String, dynamic>> categories,
  Directory outputDir,
) async {
  final categoriesJson = {'categories': categories};

  final outputFile = File('${outputDir.path}/categories.json');
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(categoriesJson),
    encoding: utf8,
  );

  print('\n✓ Fichier categories.json généré');
}
