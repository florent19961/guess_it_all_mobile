import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'services/analytics_service.dart';
import 'services/word_loader_service.dart';
import 'services/connectivity_service.dart';
import 'services/firebase_sync_service.dart';
import 'app.dart';

/// Indique si Firebase a été initialisé avec succès
bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('');
  print('╔════════════════════════════════════════════════════════════╗');
  print('║           GUESS IT ALL - APPLICATION STARTUP               ║');
  print('╚════════════════════════════════════════════════════════════╝');
  print('');

  // Initialiser Firebase
  print('[Main] Step 1/4: Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;
    print('[Main] Firebase initialized successfully');
    print('[Main] Firebase project: ${Firebase.app().options.projectId}');
  } catch (e) {
    print('[Main] Firebase initialization FAILED: $e');
    print('[Main] App will run in OFFLINE-ONLY mode');
    print('[Main] To enable sync, run: flutterfire configure');
  }

  // Initialiser les services de connectivité et sync (si Firebase OK)
  if (_firebaseInitialized) {
    print('[Main] Step 2/4: Initializing ConnectivityService...');
    try {
      await ConnectivityService().initialize();
      print('[Main] ConnectivityService ready');
    } catch (e) {
      print('[Main] ConnectivityService FAILED: $e');
    }

    print('[Main] Step 3/4: Initializing FirebaseSyncService...');
    try {
      await FirebaseSyncService().initialize();
      print('[Main] FirebaseSyncService ready');
    } catch (e) {
      print('[Main] FirebaseSyncService FAILED: $e');
    }
  } else {
    print('[Main] Step 2/4: SKIPPED (Firebase not available)');
    print('[Main] Step 3/4: SKIPPED (Firebase not available)');
  }

  // Initialiser le service de chargement de mots
  print('[Main] Step 4/4: Initializing WordLoaderService...');
  try {
    await WordLoaderService().initialize(locale: 'fr');
    print('[Main] WordLoaderService ready');
  } catch (e) {
    print('[Main] WordLoaderService FAILED: $e');
  }

  // Récupérer les parties orphelines (après un kill)
  print('[Main] Checking for orphaned games...');
  try {
    final orphanedCount = await AnalyticsService().finalizeOrphanedGames();
    if (orphanedCount > 0) {
      print('[Main] Recovered $orphanedCount orphaned game(s)');
    } else {
      print('[Main] No orphaned games found');
    }
  } catch (e) {
    print('[Main] Orphaned games check FAILED: $e');
  }

  print('');
  print('[Main] ════════════════════════════════════════════════════════');
  print('[Main] Startup complete - Launching app...');
  print('[Main] Firebase enabled: $_firebaseInitialized');
  print('[Main] ════════════════════════════════════════════════════════');
  print('');

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
