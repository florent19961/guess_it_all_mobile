import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Joue le son [name] (`assets/sounds/<name>.mp3`).
typedef ChallengeSound = void Function(String name, {double volume});

/// Sons des défis surprises. Un échec de lecture reste silencieux : le son ne
/// bloque jamais le défi.
///
/// Un player par son : plusieurs se chevauchent (`AudioService` n'en a qu'un,
/// qu'il coupe à chaque son).
class ChallengeSounds {
  static final _players = <String, Future<AudioPlayer>>{};

  @visibleForTesting
  static AudioPlayer Function() newPlayer = AudioPlayer.new;

  @visibleForTesting
  static void resetForTest() => _players.clear();

  /// Incrémenté par [stop] : un son lancé avant ne part plus, ou s'arrête dès
  /// qu'il a démarré.
  static int _run = 0;

  /// Coupe les sons en cours et en préparation.
  static void stop() {
    _run++;
    for (final pending in _players.values) {
      unawaited(pending.then((player) => player.stop()).catchError((_) {}));
    }
  }

  static void play(String name, {double volume = 1}) {
    unawaited(_play(name, volume).catchError((_) {}));
  }

  static Future<void> _play(String name, double volume) async {
    final run = _run;
    final player = await _players.putIfAbsent(name, _createPlayer);
    if (run != _run) return;
    await player.stop();
    if (run != _run) return;
    await player.play(
      AssetSource('sounds/$name.mp3'),
      volume: volume,
      // Le cliquetis de la roulette revient toutes les 110 ms.
      mode: PlayerMode.lowLatency,
    );
    if (run != _run) await player.stop();
  }

  static Future<AudioPlayer> _createPlayer() async {
    final player = newPlayer();
    // Sans ça, sur Android, le focus audio d'un son coupe celui qui joue déjà.
    await player.setAudioContext(AudioContext(
      android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    ));
    return player;
  }
}
