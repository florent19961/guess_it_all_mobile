import 'dart:math';

import 'symmetric_draw.dart';

/// Défis surprises entre deux manches (Fiesta v4, lot 2B).
///
/// Tout est pur et DÉTERMINISTE par partie : une app tuée ou un retour arrière
/// retrouvent le même défi, les mêmes joueurs et le même mot, sans rien stocker
/// de plus. Le tirage de la cartouche gagnée reste du côté de l'appelant.

/// 🔴 Ordre figé : [drawChallengeSchedule] tire dans cet ordre, le changer
/// changerait le défi d'une partie en cours.
enum SurpriseChallenge {
  thumbWar('Bras de fer chinois'),
  wallSit('La chaise'),
  mimeRelay('Téléphone arabe de mime'),
  rockPaperScissors('Chifoumi en 1 point'),
  clapping('Taper dans ses mains 10 s');

  final String title;

  const SurpriseChallenge(this.title);

  String rule(String firstPlayer, String secondPlayer) => switch (this) {
        thumbWar => 'Doigts crochetés, pouces levés. Le premier dont le pouce '
            'reste coincé 3 secondes a perdu.',
        wallSit => 'Dos au mur, cuisses à l\'horizontale, sans les mains. '
            'Le premier qui lâche a perdu.',
        mimeRelay => '$firstPlayer et $secondPlayer découvrent un mot déjà '
            'joué. Chacun le mime au suivant de son équipe. La première équipe '
            'qui trouve gagne.',
        rockPaperScissors => 'Une seule manche. En cas d\'égalité, on rejoue '
            'tout de suite.',
        clapping => '10 secondes pour taper le plus de fois possible. Chacun '
            'compte les coups de l\'autre.',
      };
}

/// Un tour joué, réduit à ce qui mesure la vitesse.
class TurnPace {
  final String playerId;
  final int words;
  final int seconds;

  const TurnPace({
    required this.playerId,
    required this.words,
    required this.seconds,
  });
}

/// Les 2 équipes les plus en retard, la dernière d'abord. À score égal, l'ordre
/// de [scores] (tri stable), co-leaders compris si l'égalité l'impose.
List<String> trailingTeams(Map<String, int> scores) {
  final indexed = scores.entries.indexed.toList()
    ..sort((a, b) {
      final byScore = a.$2.value.compareTo(b.$2.value);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
  return [for (final (_, entry) in indexed.take(2)) entry.key];
}

/// Le joueur de [roster] au plus faible nombre de mots par seconde, sur tous
/// ses tours. Un joueur sans temps de jeu n'est pas mesuré ; sans aucune mesure,
/// le premier de l'équipe. À égalité, l'ordre de [roster].
String slowestPlayer({
  required List<String> roster,
  required List<TurnPace> turns,
}) {
  final words = <String, int>{};
  final seconds = <String, int>{};
  for (final turn in turns) {
    words[turn.playerId] = (words[turn.playerId] ?? 0) + turn.words;
    seconds[turn.playerId] = (seconds[turn.playerId] ?? 0) + turn.seconds;
  }

  String? slowest;
  for (final id in roster) {
    if ((seconds[id] ?? 0) == 0) continue;
    // Produit en croix : une égalité exacte le reste, sans arrondi de double.
    if (slowest == null ||
        words[id]! * seconds[slowest]! < words[slowest]! * seconds[id]!) {
      slowest = id;
    }
  }
  return slowest ?? roster.first;
}

/// Le programme de la partie [gameId] : manche qui vient de finir (1 ou 2) →
/// défi. Une ou deux entrées, deux défis toujours différents.
Map<int, SurpriseChallenge> drawChallengeSchedule(String gameId) {
  final random = Random(drawSeed('$gameId#challenges', 0));
  final challenges = [...SurpriseChallenge.values]..shuffle(random);
  final rounds = random.nextBool()
      ? const [1, 2]
      : [
          if (random.nextBool()) 1 else 2,
        ];
  return {for (final (i, round) in rounds.indexed) round: challenges[i]};
}

/// Le mot du téléphone arabe, parmi [guessedWords]. Ne dépend ni de leur ordre
/// ni de leurs doublons (un retour arrière peut les réordonner). `null` si
/// aucun mot n'a été deviné.
String? pickGuessedWord({
  required String gameId,
  required int finishedRound,
  required Iterable<String> guessedWords,
}) {
  final words = guessedWords.toSet().toList()..sort();
  if (words.isEmpty) return null;
  final random = Random(drawSeed('$gameId#word', finishedRound));
  return words[random.nextInt(words.length)];
}
