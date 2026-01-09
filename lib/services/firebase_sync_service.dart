import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'connectivity_service.dart';

/// Résultat d'une opération de synchronisation
class SyncResult {
  final int synced;
  final int failed;
  final int pending;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.pending,
  });

  @override
  String toString() => 'SyncResult(synced: $synced, failed: $failed, pending: $pending)';
}

/// Service de synchronisation des analytics vers Firebase Firestore.
///
/// Gère la queue de synchronisation et l'upload des parties vers le cloud.
/// Fonctionne en mode offline-first : les parties sont d'abord stockées localement,
/// puis synchronisées quand le réseau est disponible.
class FirebaseSyncService {
  // Singleton
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  // Clé de stockage pour la liste des parties en attente de sync
  static const String _pendingSyncKey = 'guessItAll_pending_sync';

  // Collection Firestore pour les parties
  static const String _gamesCollection = 'games';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final ConnectivityService _connectivity = ConnectivityService();

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isInitialized = false;

  /// Indique si le service est en train de synchroniser
  bool get isSyncing => _isSyncing;

  /// Indique si le service a été initialisé
  bool get isInitialized => _isInitialized;

  /// Vérifie si Firebase est configuré et disponible
  bool get _isFirebaseAvailable {
    try {
      final available = Firebase.apps.isNotEmpty;
      return available;
    } catch (e) {
      print('[Firebase] Error checking availability: $e');
      return false;
    }
  }

  /// Initialise le service et configure l'écoute de la connectivité
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[Firebase] Service already initialized, skipping');
      return;
    }

    print('[Firebase] ══════════════════════════════════════════');
    print('[Firebase] Initializing FirebaseSyncService...');
    print('[Firebase] Firebase available: $_isFirebaseAvailable');

    if (_isFirebaseAvailable) {
      print('[Firebase] Firebase apps: ${Firebase.apps.map((a) => a.name).toList()}');
    }

    // S'assurer que le service de connectivité est initialisé
    if (!_connectivity.isInitialized) {
      print('[Firebase] Connectivity service not ready, initializing...');
      await _connectivity.initialize();
    }

    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivity.connectionStatus.listen((isConnected) {
      print('[Firebase] Connectivity changed -> isConnected: $isConnected');
      if (isConnected) {
        print('[Firebase] Network restored, triggering sync...');
        syncPendingGames();
      }
    });

    _isInitialized = true;

    // Afficher l'état de la queue
    final pendingCount = await getPendingCount();
    print('[Firebase] Pending games in queue: $pendingCount');

    // Synchronisation initiale si online
    if (_connectivity.isConnected) {
      print('[Firebase] Online at startup, attempting initial sync...');
      await syncPendingGames();
    } else {
      print('[Firebase] Offline at startup, sync will happen when connected');
    }

    print('[Firebase] Service initialized successfully');
    print('[Firebase] ══════════════════════════════════════════');
  }

  /// Marque une partie pour synchronisation
  ///
  /// Ajoute le gameId à la liste des parties en attente et tente
  /// une synchronisation immédiate si le réseau est disponible.
  /// Si Firebase n'est pas configuré, la partie est quand même ajoutée
  /// à la liste pour sync ultérieure.
  Future<void> markForSync(String gameId) async {
    print('[Firebase] ──────────────────────────────────────────');
    print('[Firebase] markForSync called for gameId: $gameId');

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingSyncKey) ?? [];

    if (!pending.contains(gameId)) {
      pending.add(gameId);
      await prefs.setStringList(_pendingSyncKey, pending);
      print('[Firebase] Game added to sync queue (${pending.length} total pending)');
    } else {
      print('[Firebase] Game already in sync queue');
    }

    // Tenter sync immédiat si Firebase disponible et online
    print('[Firebase] Checking sync conditions:');
    print('[Firebase]   - Firebase available: $_isFirebaseAvailable');
    print('[Firebase]   - Network connected: ${_connectivity.isConnected}');

    if (_isFirebaseAvailable && _connectivity.isConnected) {
      print('[Firebase] Conditions met, attempting immediate sync...');
      // Fire-and-forget : ne bloque pas l'appelant
      syncGame(gameId).then((success) {
        if (success) {
          print('[Firebase] Sync completed in background');
        }
      }).catchError((e) {
        print('[Firebase] Background sync error: $e');
      });
    } else if (!_isFirebaseAvailable) {
      print('[Firebase] Firebase NOT configured - game queued for later');
      print('[Firebase] Run "flutterfire configure" to setup Firebase');
    } else {
      print('[Firebase] Offline - game queued for sync when connected');
    }
    print('[Firebase] ──────────────────────────────────────────');
  }

  /// Synchronise une partie spécifique vers Firestore
  ///
  /// Retourne true si la synchronisation a réussi, false sinon.
  Future<bool> syncGame(String gameId) async {
    print('[Firebase] syncGame: $gameId');

    // Vérifier que Firebase est disponible
    if (!_isFirebaseAvailable) {
      print('[Firebase] SKIP: Firebase not available');
      return false;
    }

    try {
      // Charger les données depuis le stockage local
      print('[Firebase] Loading game data from local storage...');
      final game = await _analytics.loadGameAnalytics(gameId);

      if (game == null) {
        print('[Firebase] ERROR: Game not found locally, removing from queue');
        await _removeFromPending(gameId);
        return false;
      }

      print('[Firebase] Game loaded:');
      print('[Firebase]   - gameId: ${game.gameId}');
      print('[Firebase]   - userId: ${game.userId}');
      print('[Firebase]   - Events: ${game.events.length}');
      print('[Firebase]   - Words: ${game.wordStats.length}');
      print('[Firebase]   - Started: ${game.startedAt}');

      // Convertir en Map et ajouter le timestamp de synchronisation
      final data = game.toJson();
      data['syncedAt'] = FieldValue.serverTimestamp();

      // Upload vers Firestore
      print('[Firebase] Uploading to Firestore collection: $_gamesCollection');
      print('[Firebase] Document ID: $gameId');

      await _firestore.collection(_gamesCollection).doc(gameId).set(data);

      // Retirer de la liste pending
      await _removeFromPending(gameId);

      print('[Firebase] SUCCESS: Game synced to Firestore!');
      return true;
    } catch (e, stackTrace) {
      print('[Firebase] ERROR syncing game: $e');
      print('[Firebase] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Synchronise toutes les parties en attente
  ///
  /// Retourne un [SyncResult] avec le nombre de parties synchronisées,
  /// échouées et restantes.
  Future<SyncResult> syncPendingGames() async {
    // Éviter les synchronisations concurrentes
    if (_isSyncing) {
      print('[Firebase] Sync already in progress, skipping');
      return SyncResult(synced: 0, failed: 0, pending: await getPendingCount());
    }

    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(_pendingSyncKey) ?? [];

      if (pending.isEmpty) {
        print('[Firebase] No pending games to sync');
        return SyncResult(synced: 0, failed: 0, pending: 0);
      }

      print('[Firebase] ══════════════════════════════════════════');
      print('[Firebase] Starting batch sync of ${pending.length} games...');

      int synced = 0;
      int failed = 0;

      // Copie pour éviter modification pendant itération
      final toSync = List<String>.from(pending);

      for (int i = 0; i < toSync.length; i++) {
        final gameId = toSync[i];
        print('[Firebase] [${i + 1}/${toSync.length}] Syncing: $gameId');

        final success = await syncGame(gameId);
        if (success) {
          synced++;
          print('[Firebase] [${i + 1}/${toSync.length}] OK');
        } else {
          failed++;
          print('[Firebase] [${i + 1}/${toSync.length}] FAILED');
        }
      }

      final remaining = await getPendingCount();

      print('[Firebase] ══════════════════════════════════════════');
      print('[Firebase] Batch sync completed:');
      print('[Firebase]   - Synced: $synced');
      print('[Firebase]   - Failed: $failed');
      print('[Firebase]   - Remaining: $remaining');
      print('[Firebase] ══════════════════════════════════════════');

      return SyncResult(synced: synced, failed: failed, pending: remaining);
    } finally {
      _isSyncing = false;
    }
  }

  /// Retourne le nombre de parties en attente de synchronisation
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingSyncKey)?.length ?? 0;
  }

  /// Retourne la liste des gameIds en attente de synchronisation
  Future<List<String>> getPendingGameIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingSyncKey) ?? [];
  }

  /// Retire un gameId de la liste des parties en attente
  Future<void> _removeFromPending(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingSyncKey) ?? [];
    pending.remove(gameId);
    await prefs.setStringList(_pendingSyncKey, pending);
    print('[Firebase] Removed from pending queue: $gameId');
  }

  /// Force une tentative de synchronisation
  ///
  /// Utile pour déclencher manuellement une sync (ex: bouton refresh).
  Future<SyncResult> forceSyncNow() async {
    print('[Firebase] Force sync requested');

    if (!_connectivity.isConnected) {
      print('[Firebase] Cannot sync - no network connection');
      return SyncResult(synced: 0, failed: 0, pending: await getPendingCount());
    }

    return syncPendingGames();
  }

  /// Libère les ressources du service
  void dispose() {
    print('[Firebase] Disposing FirebaseSyncService');
    _connectivitySubscription?.cancel();
    _isInitialized = false;
  }
}
