import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Joue le son [name] (`assets/sounds/<name>.mp3`).
typedef ChallengeSound = void Function(String name, {double volume});

/// Sons des défis surprises. Un échec de lecture reste silencieux : le son ne
/// bloque jamais le défi.
///
/// Un player par son : plusieurs se chevauchent (`AudioService` n'en a qu'un,
/// qu'il coupe à chaque son).
class ChallengeSounds {
  static final _players = <String, Future<AudioPlayer>>{};

  static void play(String name, {double volume = 1}) {
    unawaited(_play(name, volume).catchError((_) {}));
  }

  static Future<void> _play(String name, double volume) async {
    final player = await _players.putIfAbsent(name, _createPlayer);
    await player.stop();
    await player.play(
      AssetSource('sounds/$name.mp3'),
      volume: volume,
      // Le cliquetis de la roulette revient toutes les 110 ms.
      mode: PlayerMode.lowLatency,
    );
  }

  static Future<AudioPlayer> _createPlayer() async {
    final player = AudioPlayer();
    // Sans ça, sur Android, le focus audio d'un son coupe celui qui joue déjà.
    await player.setAudioContext(AudioContext(
      android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    ));
    return player;
  }
}
