import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app_bootstrap.dart';

void main() {
  group('runStartupTasks', () {
    test('rend la main même si une tâche réseau ne se termine JAMAIS',
        () async {
      // Le mode de défaillance réel : sur un Wi-Fi de portail captif, la Future
      // Firestore ne se résout ni en succès ni en erreur — elle pend. Si le
      // démarrage l'attend, `runApp()` n'est jamais atteint et l'utilisateur voit
      // une splash figée à vie.
      final jamais = Completer<void>();
      addTearDown(() => jamais.complete()); // libère la tâche en fin de test

      var localFait = false;

      await runStartupTasks(
        localTasks: [
          () async {
            localFait = true;
          },
        ],
        networkTasks: [() => jamais.future],
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail(
          'runStartupTasks a attendu une tâche réseau : le démarrage est bloquant',
        ),
      );

      expect(localFait, isTrue,
          reason: 'les tâches locales, elles, sont attendues');
    });

    test('attend réellement les tâches locales avant de rendre la main',
        () async {
      // Le pendant du test précédent : sans lui, « ne bloque pas » serait
      // satisfait par une implémentation qui n'attend RIEN, ce qui casserait le
      // chargement des mots et la restauration de la partie en cours.
      var etape = 0;

      await runStartupTasks(
        localTasks: [
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            etape = 1;
          },
        ],
        networkTasks: const [],
      );

      expect(etape, 1);
    });

    test(
        'une tâche locale qui échoue n\'empêche pas les suivantes ni le démarrage',
        () async {
      var suivanteExecutee = false;

      await runStartupTasks(
        localTasks: [
          () async => throw StateError('service indisponible'),
          () async {
            suivanteExecutee = true;
          },
        ],
        networkTasks: const [],
      );

      expect(suivanteExecutee, isTrue,
          reason:
              'un service optionnel cassé ne doit pas empêcher l\'app de démarrer');
    });

    test('une tâche réseau qui échoue ne remonte pas en erreur non capturée',
        () async {
      // Une Future d'erreur sans handler devient une unhandled async error qui
      // remonte à la zone — c'est exactement le défaut du catchError sans return.
      await runStartupTasks(
        localTasks: const [],
        networkTasks: [() async => throw StateError('réseau coupé')],
      );

      // Laisse le microtask queue s'écouler : si l'erreur n'était pas capturée,
      // le test échouerait ici.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
