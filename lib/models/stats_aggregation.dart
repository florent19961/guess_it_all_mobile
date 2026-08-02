import 'game_state.dart';

/// Agrégations pures des statistiques de partie.
///
/// 🔴 Elles vivaient inlinées dans `stats_screen.dart`, recopiées une fois pour
/// « la partie entière » et une fois pour « la manche N » — les deux versions
/// ne différant que par un `.where((e) => e.round == round)`. Aucune règle de
/// classement n'était donc atteignable sans monter l'écran, et une correction
/// sur l'une passait silencieusement à côté de l'autre.
///
/// Ici, `round == null` signifie « toute la partie ». C'est le seul axe de
/// variation, et il est maintenant un paramètre plutôt qu'une copie.

/// Une ligne de classement : un joueur, une valeur, et de quoi l'afficher.
class StatRow {
  final String playerId;

  /// La valeur classée (nombre de mots, ou secondes par mot).
  final double value;

  /// Ce qui s'affiche à droite de la barre.
  final String label;

  const StatRow({
    required this.playerId,
    required this.value,
    required this.label,
  });
}

List<HistoryEntry> _scope(List<HistoryEntry> history, int? round) =>
    round == null
        ? history
        : history.where((entry) => entry.round == round).toList();

/// Mots devinés par joueur, du plus prolifique au moins.
///
/// À égalité, l'ordre suit l'identifiant du joueur : sans ça, l'affichage
/// changerait d'une ouverture de l'écran à l'autre.
List<StatRow> guessedWordsRanking(List<HistoryEntry> history, {int? round}) {
  final total = <String, int>{};
  for (final entry in _scope(history, round)) {
    total[entry.playerId] =
        (total[entry.playerId] ?? 0) + entry.wordsGuessed.length;
  }

  final rows = total.entries
      .map((e) => StatRow(
            playerId: e.key,
            value: e.value.toDouble(),
            label: '${e.value}',
          ))
      .toList()
    ..sort((a, b) {
      final parValeur = b.value.compareTo(a.value);
      return parValeur != 0 ? parValeur : a.playerId.compareTo(b.playerId);
    });

  return rows;
}

/// Temps moyen par mot deviné, du plus rapide au plus lent.
///
/// Les tours sans aucun mot deviné sont **exclus** : y compter leur durée
/// pénaliserait un joueur pour un tour où il n'a rien pu marquer, et une
/// division par zéro serait sinon inévitable.
List<StatRow> averageTimePerWordRanking(List<HistoryEntry> history,
    {int? round}) {
  final temps = <String, int>{};
  final mots = <String, int>{};

  for (final entry in _scope(history, round)) {
    final devines = entry.wordsGuessed.length;
    if (devines == 0) continue;
    temps[entry.playerId] = (temps[entry.playerId] ?? 0) + entry.timeSpent;
    mots[entry.playerId] = (mots[entry.playerId] ?? 0) + devines;
  }

  final rows = mots.keys.map((playerId) {
    final moyenne = (temps[playerId] ?? 0) / mots[playerId]!;
    return StatRow(
      playerId: playerId,
      value: moyenne,
      label: '${moyenne.toStringAsFixed(1)}s',
    );
  }).toList()
    ..sort((a, b) {
      final parValeur = a.value.compareTo(b.value);
      return parValeur != 0 ? parValeur : a.playerId.compareTo(b.playerId);
    });

  return rows;
}
