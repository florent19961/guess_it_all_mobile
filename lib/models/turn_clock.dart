import 'package:flutter/foundation.dart';

/// L'horloge d'un tour — **la seule autorité sur le temps de jeu**.
///
/// Historique : le temps avait trois représentations désynchronisées (un champ
/// local du widget, un `timeRemaining` poussé dix fois par seconde dans l'état
/// global, et une deadline en horloge murale) et **aucune n'était jamais gelée**.
/// La pause n'était qu'un booléen de widget : la deadline continuait de courir
/// pendant les dialogues, donc ouvrir « Interrompre la partie », recevoir un
/// appel ou verrouiller l'écran volait réellement du temps de tour — jusqu'à le
/// ramener à zéro et terminer le tour au retour.
///
/// Le type rend cet état impossible : une horloge **court** (elle a une deadline
/// absolue), ou elle est **gelée** (elle a un reste figé), ou elle est
/// **arrêtée** — jamais deux à la fois.
///
/// Toutes les méthodes prennent `nowMs` en paramètre plutôt que de lire
/// `DateTime.now()` : c'est ce qui rend la classe testable sans attendre, et
/// donc ce qui permettra de valider les modificateurs de temps du mode Fiesta
/// (malus, tours bonus) sans jouer une partie.
@immutable
class TurnClock {
  /// Deadline absolue en ms depuis l'epoch. Non nul ⟺ le tour court.
  final int? _endMs;

  /// Reste figé en ms. Non nul ⟺ le tour est en pause.
  final int? _frozenMs;

  const TurnClock._(this._endMs, this._frozenMs);

  /// Hors tour : ni deadline, ni gel.
  const TurnClock.stopped()
      : _endMs = null,
        _frozenMs = null;

  /// Démarre un tour de [durationMs] à l'instant [nowMs].
  factory TurnClock.running({required int nowMs, required int durationMs}) =>
      TurnClock._(nowMs + (durationMs < 0 ? 0 : durationMs), null);

  /// Tour gelé sur [remainingMs].
  factory TurnClock.frozen(int remainingMs) =>
      TurnClock._(null, remainingMs < 0 ? 0 : remainingMs);

  /// Reconstruit une horloge qui court depuis une deadline absolue déjà connue.
  ///
  /// Sert à réhydrater l'état persisté : `GameState` stocke la deadline, pas la
  /// durée d'origine.
  factory TurnClock.endingAt(int endMs) => TurnClock._(endMs, null);

  bool get isRunning => _endMs != null;
  bool get isPaused => _frozenMs != null;
  bool get isStopped => _endMs == null && _frozenMs == null;

  /// Deadline absolue, ou `null` si le tour ne court pas.
  ///
  /// 🔴 Une horloge en pause rend `null` **par construction** : c'est ce qui
  /// garantit qu'aucun ticker ne peut faire expirer un tour gelé.
  int? get endTimestampMs => _endMs;

  /// Reste figé en ms, ou `null` si le tour n'est pas en pause.
  int? get frozenRemainingMs => _frozenMs;

  /// Reste en ms à l'instant [nowMs]. Jamais négatif.
  int remainingMsAt(int nowMs) {
    final frozen = _frozenMs;
    if (frozen != null) return frozen;
    final end = _endMs;
    if (end == null) return 0;
    final remaining = end - nowMs;
    return remaining > 0 ? remaining : 0;
  }

  /// Secondes à AFFICHER : arrondi au supérieur (il reste « 1 » tant qu'il reste
  /// 1 ms). Sert uniquement au rendu — jamais aux calculs, sous peine de
  /// réintroduire la dérive que ce type élimine.
  int displayedSecondsAt(int nowMs) => (remainingMsAt(nowMs) / 1000).ceil();

  /// Vrai seulement si le tour COURT et que sa deadline est atteinte.
  ///
  /// Une horloge gelée n'expire jamais toute seule : c'est ce qui protège une
  /// partie dont l'app a été mise en arrière-plan en plein tour.
  bool isExpiredAt(int nowMs) => isRunning && remainingMsAt(nowMs) <= 0;

  /// Gèle le tour sur son reste courant. Idempotent.
  TurnClock pauseAt(int nowMs) =>
      isRunning ? TurnClock.frozen(remainingMsAt(nowMs)) : this;

  /// Repart du reste gelé à l'instant [nowMs]. Idempotent.
  TurnClock resumeAt(int nowMs) =>
      isPaused ? TurnClock._(nowMs + _frozenMs!, null) : this;

  /// Retire [penaltySeconds] au temps restant.
  ///
  /// 🔴 Le retrait porte sur la **deadline**, en millisecondes exactes. L'ancien
  /// calcul arrondissait le reste au supérieur *puis* ré-ancrait la deadline
  /// dessus : chaque passe rendait donc jusqu'à une seconde, et à pénalité 0 le
  /// chrono remontait au lieu de descendre.
  TurnClock applyPenalty(int penaltySeconds, int nowMs) {
    final penaltyMs = penaltySeconds * 1000;

    final frozen = _frozenMs;
    if (frozen != null) {
      // Une pénalité ne dégèle pas : on peut passer un mot depuis un état gelé
      // sans que le tour reparte.
      return TurnClock.frozen(frozen - penaltyMs);
    }

    final end = _endMs;
    if (end == null) return this;

    final newEnd = end - penaltyMs;
    return TurnClock._(newEnd < nowMs ? nowMs : newEnd, null);
  }

  Map<String, dynamic> toJson() => {
        'endMs': _endMs,
        'frozenMs': _frozenMs,
      };

  factory TurnClock.fromJson(Map<String, dynamic> json) => TurnClock._(
        json['endMs'] as int?,
        json['frozenMs'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is TurnClock &&
      other._endMs == _endMs &&
      other._frozenMs == _frozenMs;

  @override
  int get hashCode => Object.hash(_endMs, _frozenMs);

  @override
  String toString() => isPaused
      ? 'TurnClock.frozen(${_frozenMs}ms)'
      : isRunning
          ? 'TurnClock.running(end=$_endMs)'
          : 'TurnClock.stopped()';
}
