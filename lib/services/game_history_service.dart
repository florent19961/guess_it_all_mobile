import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_result.dart';
import 'persisted_schema.dart';

/// Historique des dernières parties terminées (scores + composition).
///
/// Stocké à part des analytics : c'est une donnée **d'affichage**, petite et
/// bornée, alors que `GameAnalytics` est une donnée d'analyse, volumineuse
/// (tous les events atomiques) et soumise à sa propre rétention. Les mélanger
/// ferait grossir un blob qu'on relit à chaque ouverture de l'écran.
class GameHistoryService {
  static final GameHistoryService _instance = GameHistoryService._internal();
  factory GameHistoryService() => _instance;
  GameHistoryService._internal();

  static const String storageKey = 'guessItAll_game_results';

  /// Nombre de parties conservées.
  ///
  /// Borne DURE : au-delà, les plus anciennes sont supprimées à l'écriture. Sans
  /// plafond, la clé grossirait indéfiniment sur le téléphone d'un joueur
  /// régulier — le défaut exact que l'audit a relevé sur l'historique des mots.
  static const int maxEntries = 10;

  /// Enregistre une partie terminée, en tête d'historique.
  Future<void> record(GameResult result) async {
    final existing = await load();

    // Un même gameId ne doit pas apparaître deux fois : la fin de partie peut
    // être atteinte plusieurs fois (retour arrière depuis l'écran de résultats,
    // reprise d'une partie suspendue).
    final deduped = existing.where((r) => r.gameId != result.gameId).toList();
    final updated = [result, ...deduped].take(maxEntries).toList();

    await _write(updated);
  }

  /// Les parties archivées, de la plus récente à la plus ancienne.
  Future<List<GameResult>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null) return const [];

      final read = unwrapSchema(jsonDecode(raw));
      if (read.shouldQuarantine) {
        await prefs.remove(storageKey);
        return const [];
      }
      if (!read.isUsable) return const [];

      final entries = read.data!['entries'];
      if (entries is! List) return const [];

      // Les entrées illisibles sont ignorées une par une : une seule abîmée ne
      // doit pas effacer tout l'historique de l'écran.
      return entries
          .whereType<Map<String, dynamic>>()
          .map(GameResult.tryFromJson)
          .whereType<GameResult>()
          .toList();
    } on FormatException catch (e) {
      debugPrint('[GameHistory] Historique illisible, quarantaine: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(storageKey);
      } catch (_) {}
      return const [];
    } catch (e) {
      // Panne transitoire : on n'efface rien, on rend simplement vide.
      debugPrint('[GameHistory] Lecture impossible: $e');
      return const [];
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (e) {
      debugPrint('[GameHistory] Échec de suppression: $e');
    }
  }

  Future<void> _write(List<GameResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode(wrapWithSchema({
          'entries': results.map((r) => r.toJson()).toList(),
        })),
      );
    } catch (e) {
      debugPrint('[GameHistory] Échec de sauvegarde: $e');
    }
  }
}

/// Tendances agrégées sur les parties archivées.
///
/// Calcul **pur** : il prend la liste et rend les agrégats, sans toucher au
/// stockage. C'est ce qui le rend testable, et réutilisable tel quel si on
/// change un jour de support de stockage.
@immutable
class HistoryTrends {
  /// Nombre de parties prises en compte.
  final int gamesPlayed;

  /// Score moyen par partie, toutes équipes confondues.
  final double averageScorePerGame;

  /// Meilleur score d'équipe jamais réalisé, et l'équipe qui l'a fait.
  final int bestScore;
  final String? bestScoreTeam;

  /// Nombre de victoires par nom d'équipe (les égalités comptent pour chacune).
  final Map<String, int> winsByTeam;

  /// Nombre d'apparitions par joueur, du plus régulier au moins régulier.
  final List<MapEntry<String, int>> playerAppearances;

  const HistoryTrends({
    required this.gamesPlayed,
    required this.averageScorePerGame,
    required this.bestScore,
    required this.bestScoreTeam,
    required this.winsByTeam,
    required this.playerAppearances,
  });

  static const HistoryTrends empty = HistoryTrends(
    gamesPlayed: 0,
    averageScorePerGame: 0,
    bestScore: 0,
    bestScoreTeam: null,
    winsByTeam: {},
    playerAppearances: [],
  );
}

/// Calcule les tendances sur [results].
HistoryTrends computeTrends(List<GameResult> results) {
  if (results.isEmpty) return HistoryTrends.empty;

  var totalGuessed = 0;
  var bestScore = 0;
  String? bestScoreTeam;
  final wins = <String, int>{};
  final appearances = <String, int>{};

  for (final game in results) {
    totalGuessed += game.totalGuessed;

    for (final team in game.teams) {
      if (team.score > bestScore) {
        bestScore = team.score;
        bestScoreTeam = team.name;
      }
      for (final player in team.playerNames) {
        appearances[player] = (appearances[player] ?? 0) + 1;
      }
    }

    // En cas d'égalité, chaque équipe en tête compte une victoire : le jeu ne
    // départage pas, donc l'historique ne doit pas trancher à sa place.
    for (final winner in game.winners) {
      wins[winner.name] = (wins[winner.name] ?? 0) + 1;
    }
  }

  final sortedAppearances = appearances.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      // Départage par nom pour rendre l'ordre déterministe — sinon l'affichage
      // change d'une ouverture à l'autre à égalité.
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });

  return HistoryTrends(
    gamesPlayed: results.length,
    averageScorePerGame: totalGuessed / results.length,
    bestScore: bestScore,
    bestScoreTeam: bestScoreTeam,
    winsByTeam: wins,
    playerAppearances: sortedAppearances,
  );
}
