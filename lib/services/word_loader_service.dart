import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/word_categories/models.dart';
import '../models/category_metadata.dart';

/// Service de chargement des catégories de mots depuis JSON
///
/// Pattern Singleton avec cache en mémoire pour optimiser les performances.
/// Charge les métadonnées au démarrage et les catégories complètes à la demande.
class WordLoaderService {
  // Singleton pattern
  static final WordLoaderService _instance = WordLoaderService._internal();
  factory WordLoaderService() => _instance;
  WordLoaderService._internal();

  // Cache en mémoire
  List<CategoryMetadata>? _categoriesMetadata;
  final Map<String, WordCategory> _loadedCategories = {};
  String _currentLocale = 'fr';

  // Getters
  String get currentLocale => _currentLocale;
  bool get isInitialized => _categoriesMetadata != null;

  /// Initialiser le service (charger categories.json)
  ///
  /// Doit être appelé une fois au démarrage de l'application.
  /// Charge les métadonnées de toutes les catégories en mémoire.
  Future<void> initialize({String locale = 'fr'}) async {
    _currentLocale = locale;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/categories.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      _categoriesMetadata = (json['categories'] as List<dynamic>)
          .map((c) => CategoryMetadata.fromJson(c as Map<String, dynamic>))
          .toList();

      print('WordLoaderService initialisé: ${_categoriesMetadata!.length} catégories');
    } catch (e) {
      print('Erreur lors du chargement de categories.json: $e');
      rethrow;
    }
  }

  /// Obtenir la liste des métadonnées de catégories
  ///
  /// Retourne uniquement les métadonnées (id, nom, icône) sans les mots.
  /// Rapide car déjà en mémoire après initialize().
  List<CategoryMetadata> getCategoriesMetadata() {
    if (_categoriesMetadata == null) {
      throw StateError(
        'WordLoaderService non initialisé. Appelez initialize() d\'abord.',
      );
    }
    return _categoriesMetadata!;
  }

  /// Charger une catégorie complète (avec ses mots)
  ///
  /// Charge les mots depuis le fichier JSON si ce n'est pas déjà en cache.
  /// Les chargements ultérieurs utilisent le cache pour optimiser les performances.
  Future<WordCategory> loadCategory(String categoryId) async {
    // Vérifier le cache
    if (_loadedCategories.containsKey(categoryId)) {
      return _loadedCategories[categoryId]!;
    }

    // Charger depuis les assets
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/words/$_currentLocale/$categoryId.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Trouver les métadonnées correspondantes
      final metadata = _categoriesMetadata?.firstWhere(
        (m) => m.id == categoryId,
        orElse: () => throw StateError('Métadonnées introuvables pour $categoryId'),
      );

      if (metadata == null) {
        throw StateError('Catégorie $categoryId introuvable dans categories.json');
      }

      // Créer l'objet WordCategory
      final category = WordCategory(
        id: categoryId,
        name: metadata.getLocalizedName(_currentLocale),
        icon: metadata.icon,
        words: (json['words'] as List<dynamic>)
            .map((w) => WordWithDifficulty.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

      // Mettre en cache
      _loadedCategories[categoryId] = category;

      return category;
    } catch (e) {
      print('Erreur lors du chargement de $categoryId: $e');
      rethrow;
    }
  }

  /// Charger toutes les catégories
  ///
  /// Charge toutes les catégories disponibles dans la locale actuelle.
  /// Utilise le cache pour éviter les rechargements inutiles.
  Future<Map<String, WordCategory>> loadAllCategories() async {
    if (_categoriesMetadata == null) {
      throw StateError('WordLoaderService non initialisé.');
    }

    for (final metadata in _categoriesMetadata!) {
      if (!_loadedCategories.containsKey(metadata.id)) {
        await loadCategory(metadata.id);
      }
    }

    return Map.from(_loadedCategories);
  }

  /// Vider le cache (utile lors du changement de langue)
  ///
  /// Supprime toutes les catégories chargées du cache.
  /// Les métadonnées sont préservées.
  void clearCache() {
    _loadedCategories.clear();
  }

  /// Changer de locale et recharger
  ///
  /// Change la langue courante et vide le cache pour forcer
  /// le rechargement des mots dans la nouvelle langue.
  Future<void> changeLocale(String newLocale) async {
    if (newLocale == _currentLocale) return;

    _currentLocale = newLocale;
    clearCache();

    // Les métadonnées restent les mêmes, seuls les mots seront rechargés à la demande
  }
}
