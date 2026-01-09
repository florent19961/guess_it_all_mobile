import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service de détection de connectivité réseau.
///
/// Singleton qui surveille l'état de la connexion et notifie
/// les autres services lorsque le réseau devient disponible.
class ConnectivityService {
  // Singleton
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  /// Stream des changements de connectivité (true = online, false = offline)
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isConnected = false;
  bool _isInitialized = false;

  /// État actuel de la connexion
  bool get isConnected => _isConnected;

  /// Indique si le service a été initialisé
  bool get isInitialized => _isInitialized;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Initialise le service et commence à écouter les changements de réseau
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('[Connectivity] Initializing service...');

    // Vérifier l'état initial
    final results = await _connectivity.checkConnectivity();
    print('[Connectivity] Initial check: $results');
    _updateConnectionStatus(results);

    // Écouter les changements
    _subscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);

    _isInitialized = true;
    print('[Connectivity] Service initialized - isConnected: $_isConnected');
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    print('[Connectivity] Network change detected: $results');
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;

    // Considérer comme connecté si wifi, mobile ou ethernet
    _isConnected = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    // Log si changement d'état
    if (wasConnected != _isConnected) {
      print('[Connectivity] Status changed: ${wasConnected ? "ONLINE" : "OFFLINE"} -> ${_isConnected ? "ONLINE" : "OFFLINE"}');
    }

    // Notifier le stream
    _connectionStatusController.add(_isConnected);
  }

  /// Libère les ressources du service
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
    _isInitialized = false;
  }
}
