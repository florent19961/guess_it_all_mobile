import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  // Son quand un mot est validé (trouvé)
  static Future<void> playDing() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/ding.mp3'));
  }

  // Son quand un mot est passé
  static Future<void> playWhoosh() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/whoosh.mp3'));
  }

  // Son de fin de tour
  static Future<void> playKlaxon() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/klaxon.mp3'));
  }
}
