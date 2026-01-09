import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/game_analytics.dart';

/// Service de gestion de l'identité utilisateur et des informations device
///
/// Ce service est un singleton qui fournit :
/// - Un userId persistant (UUID v4 créé au premier lancement)
/// - Les informations sur le device et l'application
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _userIdKey = 'guessItAll_userId';

  String? _cachedUserId;
  DeviceInfo? _cachedDeviceInfo;

  /// Récupère ou crée l'userId persistant
  ///
  /// L'userId est créé une seule fois au premier lancement
  /// et reste le même pour toujours sur ce device.
  Future<String> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_userIdKey, userId);
    }

    _cachedUserId = userId;
    return userId;
  }

  /// Récupère les informations sur le device et l'application
  ///
  /// Ces informations sont collectées pour l'analytics :
  /// - Version de l'app
  /// - Plateforme (android, ios, web, etc.)
  /// - Locale
  /// - Modèle du device
  Future<DeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceModel = await _getDeviceModel();

    _cachedDeviceInfo = DeviceInfo(
      appVersion: packageInfo.version,
      platform: _getPlatformName(),
      locale: _getLocale(),
      deviceModel: deviceModel,
    );

    return _cachedDeviceInfo!;
  }

  /// Retourne le nom de la plateforme
  String _getPlatformName() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
      if (Platform.isFuchsia) return 'fuchsia';
    } catch (_) {
      return 'unknown';
    }
    return 'unknown';
  }

  /// Retourne la locale actuelle
  String _getLocale() {
    if (kIsWeb) return 'en_US'; // Web n'a pas accès à Platform.localeName
    try {
      return Platform.localeName;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Récupère le modèle du device
  Future<String?> _getDeviceModel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return '${webInfo.browserName.name} on ${webInfo.platform}';
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.utsname.machine;
      }

      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      }

      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.model;
      }

      if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.prettyName;
      }
    } catch (e) {
      // Silently fail - device model is optional
      return null;
    }
    return null;
  }

  /// Génère un nouveau gameId unique
  String generateGameId() => const Uuid().v4();

  /// Efface le cache (utile pour les tests)
  void clearCache() {
    _cachedUserId = null;
    _cachedDeviceInfo = null;
  }
}
