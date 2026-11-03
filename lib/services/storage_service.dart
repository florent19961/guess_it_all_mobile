import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'game_history_service.dart';
import 'persisted_schema.dart';

/// Accès à la persistance locale (`SharedPreferences`).
///
/// 🔴 Toutes les écritures passent par une **enveloppe versionnée** et toutes les
/// lectures par une **quarantaine** : voir `persisted_schema.dart` pour le
/// pourquoi (app publiée + mise à jour forcée = les données des joueurs sont
/// intouchables, et un blob illisible ne doit jamais casser l'app pour toujours).
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // ========== PRIMITIVES VERSIONNÉES ==========

  Future<void> _save(String key, Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(wrapWithSchema(payload)));
    } catch (e) {
      debugPrint('[Storage] Échec de sauvegarde ($key): $e');
    }
  }

  /// Lit [key], en supprimant le blob s'il est illisible ou venu d'une version
  /// plus récente.
  ///
  /// Rendre `null` couvre trois cas volontairement indistincts pour l'appelant —
  /// absent, illisible, futur — parce que dans les trois il n'y a rien
  /// d'exploitable et que la bonne réaction est la même : repartir des défauts.
  /// La différence est traitée ICI, où elle a un sens : la quarantaine.
  Future<Map<String, dynamic>?> _load(String key) async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // Panne de la couche de stockage : transitoire, on ne supprime RIEN.
      debugPrint('[Storage] Stockage indisponible ($key): $e');
      return null;
    }

    Object? decoded;
    var decodeFailed = false;
    try {
      final jsonString = prefs.getString(key);
      decoded = jsonString == null ? null : jsonDecode(jsonString);
    } catch (e) {
      decodeFailed = true;
      debugPrint('[Storage] Blob illisible ($key): $e');
    }

    final read = unwrapSchema(decoded, decodeFailed: decodeFailed);

    if (read.shouldQuarantine) {
      debugPrint('[Storage] Mise en quarantaine de $key (${read.status.name})');
      try {
        await prefs.remove(key);
      } catch (e) {
        debugPrint('[Storage] Quarantaine impossible ($key): $e');
      }
      return null;
    }

    return read.data;
  }

  Future<void> _clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[Storage] Échec de suppression ($key): $e');
    }
  }

  // ========== SETTINGS (permanent entre sessions) ==========

  Future<void> saveSettings(Map<String, dynamic> settings) =>
      _save(AppConstants.settingsKey, settings);

  Future<Map<String, dynamic>?> loadSettings() =>
      _load(AppConstants.settingsKey);

  // ========== GAME SESSION (joueurs/équipes sans mots) ==========

  Future<void> saveGameSession(Map<String, dynamic> session) =>
      _save(AppConstants.gameSessionKey, session);

  Future<Map<String, dynamic>?> loadGameSession() =>
      _load(AppConstants.gameSessionKey);

  Future<void> clearGameSession() => _clear(AppConstants.gameSessionKey);

  // ========== GAME STATE (partie en cours avec mots) ==========

  Future<void> saveGameState(Map<String, dynamic> state) =>
      _save(AppConstants.gameStateKey, state);

  Future<Map<String, dynamic>?> loadGameState() =>
      _load(AppConstants.gameStateKey);

  Future<void> clearGameState() => _clear(AppConstants.gameStateKey);

  // ========== FLAGS UI (onboarding, etc.) ==========

  Future<bool> hasSeenAdvancedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.advancedSettingsSeenKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> markAdvancedSettingsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.advancedSettingsSeenKey, true);
    } catch (e) {
      debugPrint('[Storage] Échec du marquage des paramètres avancés: $e');
    }
  }

  // Aides de prise en main : booléens autonomes, absents = false (clés neuves,
  // rien à migrer). Exception : tuto et première partie, absents chez un joueur
  // qui a déjà un historique de parties = déjà vus (voir [_readFlagOrInfer]).

  Future<bool> hasSeenTutorial() =>
      _readFlagOrInfer(AppConstants.tutorialSeenKey);
  Future<void> markTutorialSeen() =>
      _writeFlag(AppConstants.tutorialSeenKey, true);

  Future<bool> hasSeenFiestaTutorial() =>
      _readFlag(AppConstants.fiestaTutorialSeenKey);
  Future<void> markFiestaTutorialSeen() =>
      _writeFlag(AppConstants.fiestaTutorialSeenKey, true);

  /// Vrai après la première partie terminée sur ce téléphone. Tant qu'il est
  /// faux, chaque joueur voit les aides à son premier tour.
  Future<bool> isFirstGameDone() =>
      _readFlagOrInfer(AppConstants.firstGameDoneKey);
  Future<void> markFirstGameDone() =>
      _writeFlag(AppConstants.firstGameDoneKey, true);

  /// « Revoir les aides » (écran Règles).
  Future<void> resetFirstGameDone() =>
      _writeFlag(AppConstants.firstGameDoneKey, false);

  /// Clé absente + historique de parties non vide = joueur déjà venu : on
  /// rend vrai et on l'écrit une fois. Une valeur écrite (même `false`, posé
  /// par « Revoir les aides ») prime toujours.
  Future<bool> _readFlagOrInfer(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(key);
      if (stored != null) return stored;
      if ((await GameHistoryService().load()).isEmpty) return false;
      await prefs.setBool(key, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _readFlag(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _writeFlag(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('[Storage] Échec d\'écriture du flag $key: $e');
    }
  }
}
