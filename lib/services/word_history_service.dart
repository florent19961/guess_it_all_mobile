import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de tracking de l'historique des mots joués.
///
/// Singleton qui gère :
/// - La persistance de l'historique (mot → nombre de fois vu)
/// - La sélection prioritaire des mots jamais vus
/// - L'incrémentation des compteurs après chaque partie
class WordHistoryService {
  // Singleton
  static final WordHistoryService _instance = WordHistoryService._internal();
  factory WordHistoryService() => _instance;
  WordHistoryService._internal();

  // Clé de stockage
  static const String _historyKey = 'guessItAll_word_history';

  // Cache mémoire pour performance
  Map<String, int>? _historyCache;
  bool _isInitialized = false;

  /// Indique si le service a été initialisé
  bool get isInitialized => _isInitialized;

  // ========== PUBLIC METHODS ==========

  /// Initialise le service et charge l'historique en cache
  Future<void> initialize() async {
    if (_isInitialized) return;

    _historyCache = await _loadHistory();
    _isInitialized = true;
  }

  /// Retourne le nombre de fois qu'un mot a été vu (case-insensitive)
  int getSeenCount(String word) {
    final normalized = _normalizeWord(word);
    return _historyCache?[normalized] ?? 0;
  }

  /// Incrémente le compteur pour une liste de mots (appelé après une partie)
  Future<void> incrementWords(List<String> words) async {
    if (words.isEmpty) return;

    _historyCache ??= {};

    for (final word in words) {
      final normalized = _normalizeWord(word);
      _historyCache![normalized] = (_historyCache![normalized] ?? 0) + 1;
    }

    await _saveHistory();
  }

  /// Sélectionne des mots avec priorité (jamais vus d'abord, puis les moins vus)
  ///
  /// Algorithme :
  /// 1. Grouper les mots disponibles par seenCount
  /// 2. Trier par seenCount croissant (0 d'abord)
  /// 3. Pour chaque niveau, mélanger et prendre ce qu'il faut
  List<String> selectWordsByPriority(List<String> availableWords, int count) {
    if (availableWords.isEmpty || count <= 0) return [];
    if (availableWords.length <= count) {
      // Pas assez de mots, retourner tous (mélangés)
      final shuffled = List<String>.from(availableWords)..shuffle();
      return shuffled;
    }

    // Grouper les mots par seenCount
    final byCount = <int, List<String>>{};
    for (final word in availableWords) {
      final seenCount = getSeenCount(word);
      byCount.putIfAbsent(seenCount, () => []).add(word);
    }

    // Trier les clés par ordre croissant (0, 1, 2, ...)
    final sortedCounts = byCount.keys.toList()..sort();

    final selected = <String>[];

    for (final seenCount in sortedCounts) {
      if (selected.length >= count) break;

      final wordsAtThisCount = byCount[seenCount]!;
      wordsAtThisCount.shuffle(); // Randomiser au sein du même niveau

      final remaining = count - selected.length;
      final toTake = wordsAtThisCount.take(remaining).toList();
      selected.addAll(toTake);
    }

    return selected;
  }

  /// Retourne les statistiques de l'historique (pour debug/UI)
  Map<String, dynamic> getStats() {
    if (_historyCache == null || _historyCache!.isEmpty) {
      return {'totalTracked': 0, 'maxSeenCount': 0, 'distribution': <int, int>{}};
    }

    final distribution = <int, int>{};
    int maxCount = 0;

    for (final count in _historyCache!.values) {
      distribution[count] = (distribution[count] ?? 0) + 1;
      if (count > maxCount) maxCount = count;
    }

    return {
      'totalTracked': _historyCache!.length,
      'maxSeenCount': maxCount,
      'distribution': distribution,
    };
  }

  /// Efface tout l'historique (pour tests/reset)
  Future<void> clearHistory() async {
    _historyCache = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // ========== PRIVATE METHODS ==========

  /// Normalise un mot pour un matching cohérent (lowercase, trimmed)
  String _normalizeWord(String word) {
    return word.trim().toLowerCase();
  }

  /// Charge l'historique depuis SharedPreferences
  Future<Map<String, int>> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);

      if (jsonString == null) {
        return {};
      }

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (e) {
      print('[WordHistory] Error loading history: $e');
      return {};
    }
  }

  /// Sauvegarde l'historique dans SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(_historyCache));
    } catch (e) {
      print('[WordHistory] Error saving history: $e');
    }
  }
}
