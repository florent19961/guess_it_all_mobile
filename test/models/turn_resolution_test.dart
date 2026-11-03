import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/turn_resolution.dart';

TurnResolution resolve({
  List<String> validated = const [],
  List<String> guessed = const [],
  List<String> passed = const [],
  String? expired,
  List<String> pool = const [],
}) =>
    resolveTurn(
      validatedWords: validated,
      guessedThisTurn: guessed,
      passedThisTurn: passed,
      expiredWords: [if (expired != null) expired],
      currentPool: pool,
    );

void main() {
  group('Dépouillement — score', () {
    test('le score est le nombre de mots validés', () {
      expect(resolve(validated: const ['a', 'b', 'c']).pointsScored, 3);
      expect(resolve(validated: const []).pointsScored, 0);
    });

    test('un mot coché puis refusé ne rapporte rien', () {
      final r = resolve(
        validated: const ['chat'],
        guessed: const ['chat', 'chien'],
      );

      expect(r.pointsScored, 1);
      expect(r.invalidatedGuessed, ['chien']);
    });
  });

  group('Dépouillement — retour au pool', () {
    test('les mots refusés retournent dans le pool', () {
      final r = resolve(
        validated: const ['chat'],
        guessed: const ['chat', 'chien'],
        passed: const ['souris'],
        pool: const ['lapin'],
      );

      expect(
          r.remainingPool, containsAll(<String>['lapin', 'chien', 'souris']));
      expect(r.remainingPool, isNot(contains('chat')));
    });

    test('un mot passé PUIS validé sort du pool même s\'il y avait été recyclé',
        () {
      // Cas réel : le joueur passe « souris », le pool se vide, « souris » est
      // recyclée et réaffichée, l'équipe la devine. Elle est donc à la fois dans
      // passedThisTurn ET dans le pool courant — sans le retrait explicite, elle
      // resterait à faire deviner alors qu'elle a rapporté un point.
      final r = resolve(
        validated: const ['souris'],
        passed: const ['souris'],
        pool: const ['souris', 'lapin'],
      );

      expect(r.validatedPassed, ['souris']);
      expect(r.remainingPool, ['lapin']);
    });

    test('le pool ne contient jamais de doublon', () {
      // Propriété DÉRIVÉE : on compare à l'ensemble, on n'énumère pas les cas.
      final r = resolve(
        validated: const [],
        guessed: const ['chat'],
        passed: const ['chat'],
        pool: const ['chat', 'chien'],
      );

      expect(r.remainingPool.length, r.remainingPool.toSet().length);
    });
  });

  group('Dépouillement — mot expiré', () {
    test('validé, il rapporte un point et sort du pool', () {
      final r = resolve(
        validated: const ['tigre'],
        expired: 'tigre',
        pool: const ['tigre', 'lion'],
      );

      expect(r.expiredValidated, ['tigre']);
      expect(r.expiredInvalidated, isEmpty);
      expect(r.pointsScored, 1);
      expect(r.remainingPool, ['lion']);
      expect(r.allInvalidated, isEmpty);
    });

    test('refusé, il compte parmi les mots invalidés et reste à faire deviner',
        () {
      final r = resolve(
        validated: const [],
        expired: 'tigre',
        pool: const ['tigre', 'lion'],
      );

      expect(r.expiredInvalidated, ['tigre']);
      expect(r.allInvalidated, contains('tigre'));
      expect(r.remainingPool, contains('tigre'));
    });

    test('sans mot expiré, aucun des deux drapeaux n\'est levé', () {
      final r = resolve(validated: const ['a'], guessed: const ['a']);

      expect(r.expiredValidated, isEmpty);
      expect(r.expiredInvalidated, isEmpty);
      expect(r.allInvalidated, isEmpty);
    });
  });

  group('Dépouillement — fin de manche', () {
    test('la manche se termine quand le pool est vide', () {
      final r = resolve(validated: const ['a'], guessed: const ['a']);
      expect(r.isRoundOver, isTrue);
    });

    test('elle ne se termine PAS s\'il reste un mot refusé à redeviner', () {
      // Point de règle important : invalider un mot RALLONGE la manche.
      final r = resolve(
        validated: const [],
        guessed: const ['chat'],
      );

      expect(r.isRoundOver, isFalse);
      expect(r.remainingPool, ['chat']);
    });
  });

  group('Dépouillement — pureté', () {
    test('les listes d\'entrée ne sont jamais mutées', () {
      final validated = ['chat'];
      final guessed = ['chat', 'chien'];
      final passed = ['souris'];
      final pool = ['lapin'];

      resolve(
        validated: validated,
        guessed: guessed,
        passed: passed,
        pool: pool,
      );

      expect(validated, ['chat']);
      expect(guessed, ['chat', 'chien']);
      expect(passed, ['souris']);
      expect(pool, ['lapin'], reason: 'le pool d\'entrée doit rester intact');
    });

    test('deux appels identiques donnent le même résultat', () {
      List<String> poolOf() => resolve(
            validated: const ['chat'],
            guessed: const ['chat', 'chien'],
            passed: const ['souris'],
            pool: const ['lapin'],
          ).remainingPool;

      expect(poolOf(), poolOf());
    });
  });
}
