import '../../services/game_history_service.dart';
import '../../services/storage_service.dart';
import '../../services/word_history_service.dart';

/// Aides automatiques de la première partie sur ce téléphone : chaque joueur
/// les voit à SON premier tour, sur l'avant-tour et sur la vérification.
///
/// La première partie est identifiée par son `gameId` : tout persiste
/// (`guessItAll_firstGameId`, `guessItAll_firstGameHelpShown`), donc un kill
/// ne remontre rien, et une première partie abandonnée ne traîne pas : la
/// partie suivante (autre `gameId`) clôt la première.
class FirstGameHelp {
  FirstGameHelp._();

  static const String preTurn = 'preTurn';
  static const String verification = 'verification';

  /// Au démarrage (tâche locale de `main.dart`, après l'init de
  /// `WordHistoryService`) : un joueur déjà venu — historique des mots,
  /// présent depuis la version en store, ou historique des parties — ne revoit
  /// ni le tuto des règles ni les aides du premier tour. Décidé une seule fois.
  static Future<void> initAtStartup() async {
    final playedBefore = WordHistoryService().hasHistory ||
        (await GameHistoryService().load()).isNotEmpty;
    await StorageService().initHelpFlags(playedBefore: playedBefore);
  }

  /// Vrai une seule fois par joueur et par écran ([preTurn] ou
  /// [verification]), et seulement pendant la première partie : celle du
  /// premier [gameId] qui appelle `claim` après le démarrage des aides. Un
  /// autre [gameId] clôt la première partie et rend faux.
  static Future<bool> claim({
    required String gameId,
    required String playerId,
    required String screen,
  }) async {
    final storage = StorageService();
    if (await storage.isFirstGameDone()) return false;
    final firstGameId = await storage.loadFirstGameId();
    if (firstGameId == null) {
      await storage.saveFirstGameId(gameId);
    } else if (firstGameId != gameId) {
      await storage.markFirstGameDone();
      return false;
    }
    return storage.addFirstGameHelpShown('$screen:$playerId');
  }

  /// Fin normale : à l'arrivée sur les résultats de fin de partie.
  static Future<void> finishFirstGame() => StorageService().markFirstGameDone();

  /// « Revoir les aides » (écran Règles).
  static Future<void> reset() => StorageService().resetFirstGameDone();
}
