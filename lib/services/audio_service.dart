import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  // Son quand un mot est validé (trouvé)
  static Future<void> playDing() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/ding.mp3'));
    } catch (e) {
      // Ignorer les erreurs audio sur web (interruption play/pause)
    }
  }

  // Son quand un mot est passé
  static Future<void> playWhoosh() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/whoosh.mp3'));
    } catch (e) {
      // Ignorer les erreurs audio sur web
    }
  }

  // Son de fin de tour
  static Future<void> playKlaxon() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/klaxon.mp3'));
    } catch (e) {
      // Ignorer les erreurs audio sur web
    }
  }
}
