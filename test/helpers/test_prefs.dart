import 'package:flutter_test/flutter_test.dart';
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
