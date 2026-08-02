import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helpers de test pour la couche persistée.
///
/// Tout ce qui touche `SharedPreferences` passe par ici : les services du projet
/// sont des **singletons** qui appellent `SharedPreferences.getInstance()` en
/// interne, donc la seule façon de les piloter depuis un test est de remplacer le
/// store sous-jacent AVANT le premier accès.

/// Installe un `SharedPreferences` en mémoire, pré-rempli par [initial].
///
/// À appeler dans `setUp()` de chaque test qui touche la persistance : sans ça,
/// l'état d'un test précédent fuit dans le suivant (le store est un singleton
/// statique côté plugin).
Future<SharedPreferences> givenPrefs([
  Map<String, Object> initial = const {},
]) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(initial));
  return SharedPreferences.getInstance();
}

/// Lit une clé brute du store de test, sans passer par les services.
///
/// Sert à asserter ce qui a RÉELLEMENT été écrit sur disque — pas ce que l'objet
/// en mémoire prétend contenir. C'est la distinction qui compte pour tout ce qui
/// touche la persistance : une valeur correcte en RAM et fausse sur disque est
/// précisément le bug qu'on cherche.
Future<String?> rawString(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  return prefs.getString(key);
}

/// Lit une clé persistée en dénouant l'enveloppe de version.
///
/// À préférer à [rawString] dès qu'on veut asserter le CONTENU métier : les
/// écritures passent par `wrapWithSchema`, donc le JSON sur disque est
/// `{schemaVersion, data}` et non la charge utile directement.
Future<Map<String, dynamic>?> persistedData(String key) async {
  final raw = await rawString(key);
  if (raw == null) return null;
  return unwrapSchema(jsonDecode(raw)).data;
}
