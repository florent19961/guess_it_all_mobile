import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import 'persisted_schema.dart';

/// Ce que contient la clé des ensembles.
class EnsembleStore {
  final List<FiestaEnsemble> ensembles;

  /// Dernier ensemble « Utilisé » (Q10 : il vit dans cette clé, pas ailleurs).
  final String? lastUsedId;

  const EnsembleStore(this.ensembles, this.lastUsedId);

  static const empty = EnsembleStore([], null);
}

/// Les ensembles du mode Personnalisé, enregistrés sur le téléphone.
///
/// Sur le modèle de `GameHistoryService` : écriture enveloppée
/// (`wrapWithSchema`), quarantaine d'un blob illisible ou venu du futur,
/// tolérance par ensemble. Clé NOUVELLE : rien à migrer aujourd'hui.
class FiestaEnsembleService {
  static final FiestaEnsembleService _instance =
      FiestaEnsembleService._internal();
  factory FiestaEnsembleService() => _instance;
  FiestaEnsembleService._internal();

  static const String storageKey = 'guessItAll_fiestaEnsembles';

  /// Borne DURE, tenue ici et pas seulement à l'écran.
  static const int maxEnsembles = 10;
  static const int maxNameLength = 30;

  /// Sérialise les modifications : chacune relit la liste puis la réécrit.
  /// Sans file, deux taps rapides liraient tous deux 9 ensembles et
  /// passeraient la borne (ou l'un écraserait l'autre).
  Future<void> _queue = Future.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Les ensembles, dans l'ordre d'affichage. Ne lève jamais.
  Future<EnsembleStore> load() async {
    try {
      return await _read();
    } catch (e) {
      // Panne transitoire : on n'efface rien, on rend simplement vide.
      debugPrint('[FiestaEnsembles] Lecture impossible: $e');
      return EnsembleStore.empty;
    }
  }

  /// Nouvel ensemble en fin de liste. `null` si la borne est atteinte.
  Future<FiestaEnsemble?> create(FiestaRules rules) => _mutate((store) {
        if (store.ensembles.length >= maxEnsembles) return null;
        final created = FiestaEnsemble(id: const Uuid().v4(), rules: rules);
        return (
          EnsembleStore([...store.ensembles, created], store.lastUsedId),
          created
        );
      });

  /// Remplace SUR PLACE (même id, même position). `false` si l'id a disparu.
  Future<bool> update(FiestaEnsemble ensemble) async =>
      await _mutate((store) {
        final index = store.ensembles.indexWhere((e) => e.id == ensemble.id);
        if (index < 0) return null;
        final list = [...store.ensembles]..[index] = ensemble;
        return (EnsembleStore(list, store.lastUsedId), true);
      }) ??
      false;

  /// Copie « <nom> (copie) » juste après l'original. `null` si la borne est
  /// atteinte ou l'original introuvable.
  Future<FiestaEnsemble?> duplicate(String id) => _mutate((store) {
        if (store.ensembles.length >= maxEnsembles) return null;
        final index = store.ensembles.indexWhere((e) => e.id == id);
        if (index < 0) return null;
        final source = store.ensembles[index];
        final copy = FiestaEnsemble(
          id: const Uuid().v4(),
          rules: source.rules.copyWith(ensembleName: copyName(source.name)),
        );
        final list = [...store.ensembles]..insert(index + 1, copy);
        return (EnsembleStore(list, store.lastUsedId), copy);
      });

  /// Supprime, et oublie le « dernier utilisé » s'il s'agissait de lui.
  Future<void> delete(String id) => _mutate((store) {
        final list = store.ensembles.where((e) => e.id != id).toList();
        final lastUsed = store.lastUsedId == id ? null : store.lastUsedId;
        return (EnsembleStore(list, lastUsed), null);
      });

  Future<void> markUsed(String id) =>
      _mutate((store) => (EnsembleStore(store.ensembles, id), null));

  /// Q13 : pas d'unicité imposée, tronqué à la longueur maximale.
  static String copyName(String name) {
    final copy = '$name (copie)';
    return copy.length <= maxNameLength
        ? copy
        : copy.substring(0, maxNameLength);
  }

  /// Relit, applique [change], réécrit. [change] rend `null` pour ne rien
  /// écrire. Une lecture en panne fait échouer la modification au lieu
  /// d'écraser des ensembles qu'on n'a pas pu lire.
  Future<T?> _mutate<T>(
    (EnsembleStore, T)? Function(EnsembleStore store) change,
  ) =>
      _serialized(() async {
        try {
          final result = change(await _read());
          if (result == null) return null;
          await _write(result.$1);
          return result.$2;
        } catch (e) {
          debugPrint('[FiestaEnsembles] Échec de modification: $e');
          return null;
        }
      });

  Future<EnsembleStore> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return EnsembleStore.empty;

    PersistedRead read;
    try {
      read = unwrapSchema(jsonDecode(raw));
    } on FormatException {
      read = unwrapSchema(null, decodeFailed: true);
    }
    if (read.shouldQuarantine) {
      debugPrint('[FiestaEnsembles] Blob illisible (${read.status}), '
          'quarantaine');
      await prefs.remove(storageKey);
      return EnsembleStore.empty;
    }
    if (!read.isUsable) return EnsembleStore.empty;

    final data = read.data!;
    final entries = data['ensembles'];
    final lastUsedId = data['lastUsedId'];
    // Un ensemble illisible est ignoré seul : un seul abîmé ne doit pas
    // effacer tous ceux de l'utilisateur.
    final ensembles = entries is List
        ? entries
            .whereType<Map>()
            .map(
                (e) => FiestaEnsemble.tryFromJson(Map<String, dynamic>.from(e)))
            .whereType<FiestaEnsemble>()
            .toList()
        : <FiestaEnsemble>[];
    return EnsembleStore(
      ensembles,
      lastUsedId is String ? lastUsedId : null,
    );
  }

  Future<void> _write(EnsembleStore store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(wrapWithSchema({
        'ensembles': store.ensembles.map((e) => e.toJson()).toList(),
        'lastUsedId': store.lastUsedId,
      })),
    );
  }
}
