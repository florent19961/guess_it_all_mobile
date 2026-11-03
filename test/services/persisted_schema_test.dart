import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';

void main() {
  group('Enveloppe de schéma', () {
    test('un aller-retour préserve la donnée et pose la version courante', () {
      final wrapped = wrapWithSchema(const {'turnDuration': 45});

      expect(wrapped['schemaVersion'], kCurrentSchemaVersion);

      final read = unwrapSchema(wrapped);
      expect(read.status, PersistedReadStatus.ok);
      expect(read.data, const {'turnDuration': 45});
      expect(read.shouldQuarantine, isFalse);
    });

    test('une clé absente n\'est ni une erreur ni une mise en quarantaine', () {
      final read = unwrapSchema(null);

      expect(read.status, PersistedReadStatus.absent);
      expect(read.isUsable, isFalse);
      expect(read.shouldQuarantine, isFalse,
          reason:
              'ne rien avoir stocké est le cas NORMAL d\'une première ouverture');
    });
  });

  group('Rétro-compatibilité — le format actuellement en production', () {
    test('un blob SANS schemaVersion est lu tel quel, pas rejeté', () {
      // 🔴 C'est le format qui vit aujourd'hui sur les téléphones des joueurs.
      // Le rejeter, c'est perdre la partie en cours de tout le parc au moment où
      // `upgrader` pousse la mise à jour.
      final legacy = {'turnDuration': 45, 'passPenalty': 2};

      final read = unwrapSchema(legacy);

      expect(read.status, PersistedReadStatus.ok);
      expect(read.version, kLegacySchemaVersion);
      expect(read.data, legacy);
      expect(read.shouldQuarantine, isFalse);
    });
  });

  group('Quarantaine — un échec doit être transitoire, jamais permanent', () {
    test('un JSON illisible est mis en quarantaine', () {
      final read = unwrapSchema(null, decodeFailed: true);

      expect(read.status, PersistedReadStatus.corrupt);
      expect(read.shouldQuarantine, isTrue,
          reason: 'sans suppression, l\'app rééchouerait à CHAQUE démarrage');
    });

    test('une forme inattendue est mise en quarantaine', () {
      for (final bogus in <Object>[
        'une chaîne',
        42,
        <int>[1, 2, 3],
      ]) {
        final read = unwrapSchema(bogus);
        expect(read.status, PersistedReadStatus.corrupt,
            reason: 'entrée testée : $bogus');
        expect(read.shouldQuarantine, isTrue);
      }
    });

    test('une enveloppe sans charge utile exploitable est en quarantaine', () {
      final read = unwrapSchema({'schemaVersion': 1, 'data': 'pas un objet'});

      expect(read.status, PersistedReadStatus.corrupt);
      expect(read.shouldQuarantine, isTrue);
    });

    test('une version non entière est en quarantaine', () {
      final read = unwrapSchema({'schemaVersion': 'un', 'data': const {}});

      expect(read.status, PersistedReadStatus.corrupt);
    });
  });

  group('Version venue du futur', () {
    test('un blob écrit par une version PLUS RÉCENTE est refusé proprement',
        () {
      // Cas réel : l'utilisateur installe une bêta, revient à la version store.
      // On ne sait pas interpréter la donnée, mais on ne doit ni crasher, ni
      // rester bloqué.
      final read = unwrapSchema({
        'schemaVersion': kCurrentSchemaVersion + 1,
        'data': const {'nouveauChamp': true},
      });

      expect(read.status, PersistedReadStatus.fromFuture);
      expect(read.isUsable, isFalse);
      expect(read.shouldQuarantine, isTrue);
      expect(read.version, kCurrentSchemaVersion + 1);
    });

    test('la version courante, elle, est acceptée', () {
      // Pendant du test précédent : « refuse le futur » ne doit pas devenir
      // « refuse tout ce qui est versionné ».
      final read = unwrapSchema(wrapWithSchema(const {'x': 1}));

      expect(read.status, PersistedReadStatus.ok);
      expect(read.version, kCurrentSchemaVersion);
    });
  });
}
