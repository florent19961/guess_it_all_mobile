import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // ========== SETTINGS (permanent entre sessions) ==========

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.settingsKey, jsonEncode(settings));
    } catch (e) {
      print('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(AppConstants.settingsKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
      return null;
    }
  }

  // ========== GAME SESSION (joueurs/équipes sans mots) ==========

  Future<void> saveGameSession(Map<String, dynamic> session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.gameSessionKey, jsonEncode(session));
    } catch (e) {
      print('Erreur lors de la sauvegarde de la session: $e');
    }
  }

  Future<Map<String, dynamic>?> loadGameSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(AppConstants.gameSessionKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors du chargement de la session: $e');
      return null;
    }
  }

  Future<void> clearGameSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.gameSessionKey);
    } catch (e) {
      print('Erreur lors de la suppression de la session: $e');
    }
  }

  // ========== GAME STATE (partie en cours avec mots) ==========

  Future<void> saveGameState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.gameStateKey, jsonEncode(state));
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'état: $e');
    }
  }

  Future<Map<String, dynamic>?> loadGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(AppConstants.gameStateKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors du chargement de l\'état: $e');
      return null;
    }
  }

  Future<void> clearGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.gameStateKey);
    } catch (e) {
      print('Erreur lors de la suppression de l\'état: $e');
    }
  }
}
