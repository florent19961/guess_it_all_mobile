import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> saveGameState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.gameStateKey, jsonEncode(state));
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<Map<String, dynamic>?> loadGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(AppConstants.gameStateKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors du chargement: $e');
      return null;
    }
  }

  Future<void> clearGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.gameStateKey);
    } catch (e) {
      print('Erreur lors de la suppression: $e');
    }
  }
}
