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
import 'app_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase. C'est un appel local (lecture de la config embarquée),
  // pas un aller-retour réseau : il peut rester sur le chemin de démarrage.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    // Firebase non disponible, mode offline
  }

  // 🔴 La séparation local / réseau est un INVARIANT, pas un détail
  // d'organisation : voir app_bootstrap.dart. Ne jamais déplacer une tâche
  // réseau dans `localTasks` — c'est la splash figée à vie derrière un portail
  // captif.
  await runStartupTasks(
    localTasks: [
      () => WordLoaderService().initialize(locale: 'fr'),
      () => WordHistoryService().initialize(),
      () async {
        await AnalyticsService().finalizeOrphanedGames();
      },
    ],
    networkTasks: firebaseReady
        ? [
            () async {
              await ConnectivityService().initialize();
              await FirebaseSyncService().initialize();
            },
          ]
        : const [],
  );

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
