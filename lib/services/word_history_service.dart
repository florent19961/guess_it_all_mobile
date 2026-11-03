import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Vrai quand la lecture de l'historique a échoué pour une raison
  /// TRANSITOIRE (stockage indisponible), par opposition à un contenu corrompu.
  ///
  /// 🔴 Tant que ce drapeau est levé, on refuse d'ÉCRIRE. Avant, une lecture
  /// ratée rendait `{}`, et la première sauvegarde suivante écrasait
  /// l'historique accumulé de l'utilisateur — des centaines de mots perdus
  /// définitivement, sur un simple incident de lecture. Ne pas persister est
  /// toujours préférable à écraser.
  bool _degraded = false;

  /// Exposé pour les tests et le diagnostic.
  bool get isDegraded => _degraded;

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
      return {
        'totalTracked': 0,
        'maxSeenCount': 0,
        'distribution': <int, int>{}
      };
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

      final raw = jsonDecode(jsonString);
      // 🔴 Un JSON valide mais de forme inattendue (`[]`, une chaîne…) faisait
      // lever le cast avec un TypeError, PAS une FormatException : il tombait
      // donc dans la branche « panne transitoire », qui arme `_degraded` à vie.
      // Résultat : la clé n'était jamais nettoyée et plus aucun incrément
      // n'était sauvegardé, à chaque démarrage, pour toujours.
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('historique des mots : forme inattendue');
      }
      final decoded = raw;
      // Une entrée non entière est ignorée plutôt que de faire échouer tout le
      // chargement.
      final result = <String, int>{};
      decoded.forEach((k, v) {
        if (v is int) result[k] = v;
      });
      return result;
    } on FormatException catch (e) {
      // Contenu réellement illisible : la donnée est déjà perdue. On met en
      // QUARANTAINE pour que l'échec ne se rejoue pas à chaque démarrage, et on
      // repart d'un historique vide — qui pourra, lui, être sauvegardé.
      debugPrint('[WordHistory] Historique corrompu, mise en quarantaine: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_historyKey);
      } catch (_) {
        // Si même la suppression échoue, on reste en mode dégradé.
        _degraded = true;
      }
      return {};
    } catch (e) {
      // Panne TRANSITOIRE (stockage indisponible) : le contenu du disque est
      // probablement intact. On refuse d'écrire par-dessus.
      debugPrint('[WordHistory] Lecture impossible, mode dégradé: $e');
      _degraded = true;
      return {};
    }
  }

  /// Sauvegarde l'historique dans SharedPreferences
  Future<void> _saveHistory() async {
    if (_degraded) {
      // Voir `_degraded` : écrire ici écraserait un historique intact par un
      // cache vide né d'un incident de lecture.
      debugPrint('[WordHistory] Mode dégradé : sauvegarde ignorée');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(_historyCache));
    } catch (e) {
      debugPrint('[WordHistory] Error saving history: $e');
    }
  }
}
