import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  // Son quand un mot est validé (trouvé)
  static Future<void> playDing() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/ding.wav'));
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

  // Impact du passage de manche
  static Future<void> playImpact() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/impact-bass-1.mp3'));
    } catch (e) {
      // Ignorer les erreurs audio sur web
    }
  }

  // Arrivée du texte de la manche suivante
  static Future<void> playWhooshShort() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/whoosh-short.mp3'));
    } catch (e) {
      // Ignorer les erreurs audio sur web
    }
  }

  // Son de fin de tour
  static Future<void> playKlaxon() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/end_of_turn.wav'));
    } catch (e) {
      // Ignorer les erreurs audio sur web
    }
  }
}
