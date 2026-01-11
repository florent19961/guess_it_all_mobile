import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'services/analytics_service.dart';
import 'services/word_loader_service.dart';
import 'services/word_history_service.dart';
import 'services/connectivity_service.dart';
import 'services/firebase_sync_service.dart';
import 'app.dart';

/// Indique si Firebase a été initialisé avec succès
bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;
  } catch (e) {
    // Firebase non disponible, mode offline
  }

  // Initialiser les services de connectivité et sync (si Firebase OK)
  if (_firebaseInitialized) {
    try {
      await ConnectivityService().initialize();
    } catch (e) {
      // Erreur silencieuse
    }

    try {
      await FirebaseSyncService().initialize();
    } catch (e) {
      // Erreur silencieuse
    }
  }

  // Initialiser le service de chargement de mots
  try {
    await WordLoaderService().initialize(locale: 'fr');
  } catch (e) {
    // Erreur silencieuse
  }

  // Initialiser le service d'historique des mots
  try {
    await WordHistoryService().initialize();
  } catch (e) {
    // Erreur silencieuse
  }

  // Récupérer les parties orphelines (après un kill)
  try {
    await AnalyticsService().finalizeOrphanedGames();
  } catch (e) {
    // Erreur silencieuse
  }

  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1E293B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: const GuessItAllApp(),
    ),
  );
}
