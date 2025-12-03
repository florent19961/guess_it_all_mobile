import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playDing() async {
    await _player.play(AssetSource('sounds/ding.mp3'));
  }
}
