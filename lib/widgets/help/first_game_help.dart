import '../../services/game_history_service.dart';
import '../../services/storage_service.dart';
import '../../services/word_history_service.dart';

/// Aides automatiques de la première partie sur ce téléphone : chaque joueur
/// les voit à SON premier tour, sur l'avant-tour et sur la vérification.
///
/// Le « déjà vu » par joueur reste en mémoire (une partie reprise après un
/// redémarrage de l'app peut remontrer l'aide une fois : sans gravité). Seul
/// `guessItAll_firstGameDone` est persisté.
class FirstGameHelp {
  FirstGameHelp._();

  static const String preTurn = 'preTurn';
  static const String verification = 'verification';

  static final Set<String> _shown = {};

  /// Au démarrage (tâche locale de `main.dart`, après l'init de
  /// `WordHistoryService`) : un joueur déjà venu — historique des mots,
  /// présent depuis la version en store, ou historique des parties — ne revoit
  /// ni le prompt ni les aides du premier tour. Décidé une seule fois.
  static Future<void> initAtStartup() async {
    final playedBefore = WordHistoryService().hasHistory ||
        (await GameHistoryService().load()).isNotEmpty;
    await StorageService().initHelpFlags(playedBefore: playedBefore);
  }

  /// Vrai une seule fois par joueur et par écran ([preTurn] ou
  /// [verification]), et seulement tant que la première partie n'est pas finie.
  static Future<bool> claim(String screen, String playerId) async {
    if (await StorageService().isFirstGameDone()) return false;
    return _shown.add('$screen:$playerId');
  }

  /// À appeler à l'arrivée sur les résultats de fin de partie.
  static Future<void> finishFirstGame() {
    _shown.clear();
    return StorageService().markFirstGameDone();
  }

  /// « Revoir les aides » (écran Règles).
  static Future<void> reset() {
    _shown.clear();
    return StorageService().resetFirstGameDone();
  }
}
