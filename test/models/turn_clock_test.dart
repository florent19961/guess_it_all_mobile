import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/turn_clock.dart';

const int t0 = 1000000; // instant de référence arbitraire, en ms

void main() {
  group('TurnClock — états mutuellement exclusifs', () {
    test('un tour ne peut pas courir ET être gelé en même temps', () {
      final running = TurnClock.running(nowMs: t0, durationMs: 30000);
      expect(running.isRunning, isTrue);
      expect(running.isPaused, isFalse);

      final paused = running.pauseAt(t0 + 5000);
      expect(paused.isPaused, isTrue);
      expect(paused.isRunning, isFalse,
          reason:
              'geler doit RETIRER la deadline, pas la laisser courir en fond');
      expect(paused.endTimestampMs, isNull);
    });

    test('une horloge arrêtée ne rend ni temps ni deadline', () {
      const stopped = TurnClock.stopped();
      expect(stopped.isStopped, isTrue);
      expect(stopped.remainingMsAt(t0), 0);
      expect(stopped.endTimestampMs, isNull);
    });
  });

  group('TurnClock — le temps gelé ne s\'écoule pas', () {
    test('le reste est identique quel que soit le temps passé en pause', () {
      // C'est LE bug corrigé : la pause ne gelait que l'affichage, la deadline
      // continuait de courir, et tout le temps passé dans le dialogue était
      // décompté au retour.
      final paused =
          TurnClock.running(nowMs: t0, durationMs: 30000).pauseAt(t0 + 10000);

      expect(paused.remainingMsAt(t0 + 10000), 20000);
      expect(paused.remainingMsAt(t0 + 60000), 20000,
          reason: '50 s passées en pause ne doivent rien coûter');
      expect(paused.remainingMsAt(t0 + 3600000), 20000,
          reason: 'même une heure plus tard (appel entrant, écran verrouillé)');
    });

    test('reprendre repart exactement du reste gelé', () {
      final resumed = TurnClock.running(nowMs: t0, durationMs: 30000)
          .pauseAt(t0 + 10000)
          .resumeAt(t0 + 60000);

      expect(resumed.isRunning, isTrue);
      expect(resumed.remainingMsAt(t0 + 60000), 20000);
      expect(resumed.endTimestampMs, t0 + 60000 + 20000);
    });

    test('pause et resume sont idempotents', () {
      final c = TurnClock.running(nowMs: t0, durationMs: 30000);

      final p = c.pauseAt(t0 + 5000).pauseAt(t0 + 50000);
      expect(p.remainingMsAt(t0 + 99999), 25000,
          reason:
              'une 2e pause ne doit pas re-geler sur une valeur déjà gelée');

      final r = c.resumeAt(t0 + 5000);
      expect(r.endTimestampMs, c.endTimestampMs,
          reason: 'reprendre une horloge qui court ne doit rien changer');
    });
  });

  group('TurnClock — pénalité de passe', () {
    test('une pénalité de 0 ne change RIEN au temps restant', () {
      // Régression : l'ancien calcul faisait ceil(reste) puis ré-ancrait la
      // deadline dessus. À pénalité 0, chaque passe rendait donc du temps, et le
      // chrono pouvait remonter au lieu de descendre.
      final c = TurnClock.running(nowMs: t0, durationMs: 30000);
      final now = t0 + 10500; // 19 500 ms restantes, volontairement non rond

      final after = c.applyPenalty(0, now);

      expect(after.remainingMsAt(now), 19500,
          reason:
              'aucune pénalité => aucun changement, à la milliseconde près');
    });

    test('N passes retirent exactement N x pénalité, sans dérive', () {
      // Propriété DÉRIVÉE plutôt qu'énumérée : c'est l'absence de dérive
      // cumulée qui compte, pas le résultat d'un cas particulier.
      const penalty = 5;
      const passes = 4;
      var c = TurnClock.running(nowMs: t0, durationMs: 60000);
      var now = t0;

      for (var i = 0; i < passes; i++) {
        now += 1234; // du temps s'écoule entre deux passes, non aligné
        c = c.applyPenalty(penalty, now);
      }

      final ecoule = now - t0;
      expect(c.remainingMsAt(now), 60000 - ecoule - (passes * penalty * 1000));
    });

    test('la pénalité ne peut pas rendre le temps restant négatif', () {
      final c = TurnClock.running(nowMs: t0, durationMs: 3000);
      final after = c.applyPenalty(10, t0);

      expect(after.remainingMsAt(t0), 0);
      expect(after.isExpiredAt(t0), isTrue);
    });

    test('la pénalité s\'applique aussi à une horloge gelée', () {
      final paused =
          TurnClock.running(nowMs: t0, durationMs: 30000).pauseAt(t0 + 10000);
      final after = paused.applyPenalty(5, t0 + 10000);

      expect(after.isPaused, isTrue,
          reason: 'appliquer une pénalité ne dégèle pas');
      expect(after.remainingMsAt(t0 + 99999), 15000);
    });
  });

  group('TurnClock — affichage et expiration', () {
    test('les secondes affichées arrondissent au SUPÉRIEUR', () {
      final c = TurnClock.running(nowMs: t0, durationMs: 30000);

      expect(c.displayedSecondsAt(t0), 30);
      expect(c.displayedSecondsAt(t0 + 1), 30,
          reason: '29,999 s s\'affiche 30');
      expect(c.displayedSecondsAt(t0 + 29001), 1,
          reason: '0,999 s s\'affiche 1');
      expect(c.displayedSecondsAt(t0 + 30000), 0);
    });

    test('expire quand la deadline est atteinte, et jamais avant', () {
      final c = TurnClock.running(nowMs: t0, durationMs: 30000);

      expect(c.isExpiredAt(t0 + 29999), isFalse);
      expect(c.isExpiredAt(t0 + 30000), isTrue);
      expect(c.isExpiredAt(t0 + 99999), isTrue);
    });

    test('une horloge gelée n\'expire jamais toute seule', () {
      // Sinon backgrounder l'app pendant un tour terminerait le tour au retour.
      final paused =
          TurnClock.running(nowMs: t0, durationMs: 30000).pauseAt(t0 + 29000);

      expect(paused.isExpiredAt(t0 + 3600000), isFalse);
      expect(paused.remainingMsAt(t0 + 3600000), 1000);
    });

    test('une horloge gelée à 0 reste expirée une fois reprise', () {
      final paused =
          TurnClock.running(nowMs: t0, durationMs: 30000).pauseAt(t0 + 30000);
      expect(paused.remainingMsAt(t0 + 30000), 0);

      final resumed = paused.resumeAt(t0 + 60000);
      expect(resumed.isExpiredAt(t0 + 60000), isTrue);
    });
  });

  group('TurnClock — sérialisation', () {
    test('un aller-retour préserve l\'état, en cours comme gelé', () {
      final running = TurnClock.running(nowMs: t0, durationMs: 30000);
      final paused = running.pauseAt(t0 + 7000);
      const stopped = TurnClock.stopped();

      for (final c in [running, paused, stopped]) {
        final restored = TurnClock.fromJson(c.toJson());
        expect(restored.toJson(), equals(c.toJson()));
        expect(restored.remainingMsAt(t0 + 7000), c.remainingMsAt(t0 + 7000));
      }
    });
  });
}
