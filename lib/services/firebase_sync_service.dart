import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // Lazy-loaded pour éviter crash sur web sans Firebase configuré
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

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
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Initialise le service et configure l'écoute de la connectivité
  Future<void> initialize() async {
    // Ignorer Firebase sur web (non configuré)
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    if (_isInitialized) {
      return;
    }

    // S'assurer que le service de connectivité est initialisé
    if (!_connectivity.isInitialized) {
      await _connectivity.initialize();
    }

    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivity.connectionStatus.listen((isConnected) {
      if (isConnected) {
        syncPendingGames();
      }
    });

    _isInitialized = true;

    // Synchronisation initiale si online
    if (_connectivity.isConnected) {
      await syncPendingGames();
    }
  }

  /// Marque une partie pour synchronisation
  ///
  /// Ajoute le gameId à la liste des parties en attente et tente
  /// une synchronisation immédiate si le réseau est disponible.
  /// Si Firebase n'est pas configuré, la partie est quand même ajoutée
  /// à la liste pour sync ultérieure.
  Future<void> markForSync(String gameId) async {
    // Ignorer Firebase sur web (non configuré)
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingSyncKey) ?? [];

    if (!pending.contains(gameId)) {
      pending.add(gameId);
      await prefs.setStringList(_pendingSyncKey, pending);
    }

    // Tenter sync immédiat si Firebase disponible et online
    if (_isFirebaseAvailable && _connectivity.isConnected) {
      // Fire-and-forget : ne bloque pas l'appelant
      syncGame(gameId).catchError((e) {
        // Erreur silencieuse, la partie reste dans la queue
      });
    }
  }

  /// Synchronise une partie spécifique vers Firestore
  ///
  /// Retourne true si la synchronisation a réussi, false sinon.
  Future<bool> syncGame(String gameId) async {
    // Vérifier que Firebase est disponible
    if (!_isFirebaseAvailable) {
      return false;
    }

    try {
      // Charger les données depuis le stockage local
      final game = await _analytics.loadGameAnalytics(gameId);

      if (game == null) {
        await _removeFromPending(gameId);
        return false;
      }

      // Convertir en Map et ajouter le timestamp de synchronisation
      final data = game.toJson();
      data['syncedAt'] = FieldValue.serverTimestamp();

      // Upload vers Firestore
      await _firestore.collection(_gamesCollection).doc(gameId).set(data);

      // Retirer de la liste pending
      await _removeFromPending(gameId);

      return true;
    } catch (e) {
      // Erreur de sync, la partie reste dans la queue
      return false;
    }
  }

  /// Synchronise toutes les parties en attente
  ///
  /// Retourne un [SyncResult] avec le nombre de parties synchronisées,
  /// échouées et restantes.
  Future<SyncResult> syncPendingGames() async {
    // Ignorer Firebase sur web (non configuré)
    if (kIsWeb) {
      return SyncResult(synced: 0, failed: 0, pending: 0);
    }

    // Éviter les synchronisations concurrentes
    if (_isSyncing) {
      return SyncResult(synced: 0, failed: 0, pending: await getPendingCount());
    }

    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(_pendingSyncKey) ?? [];

      if (pending.isEmpty) {
        return SyncResult(synced: 0, failed: 0, pending: 0);
      }

      int synced = 0;
      int failed = 0;

      // Copie pour éviter modification pendant itération
      final toSync = List<String>.from(pending);

      for (final gameId in toSync) {
        final success = await syncGame(gameId);
        if (success) {
          synced++;
        } else {
          failed++;
        }
      }

      final remaining = await getPendingCount();

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
  }

  /// Force une tentative de synchronisation
  ///
  /// Utile pour déclencher manuellement une sync (ex: bouton refresh).
  Future<SyncResult> forceSyncNow() async {
    if (!_connectivity.isConnected) {
      return SyncResult(synced: 0, failed: 0, pending: await getPendingCount());
    }

    return syncPendingGames();
  }

  /// Libère les ressources du service
  void dispose() {
    _connectivitySubscription?.cancel();
    _isInitialized = false;
  }
}
