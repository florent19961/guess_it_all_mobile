import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sons de la révélation des scores. Un échec de lecture reste silencieux : le
/// son ne bloque jamais la révélation.
///
/// Players dédiés : `AudioService` n'en a qu'un, qu'il coupe à chaque son.
class RevealSound {
  static const musicAsset = 'sounds/reveal_music.mp3';
  static const _fadeStep = Duration(milliseconds: 70);
  static const _fadeDelta = 0.06;

  @visibleForTesting
  static AudioPlayer Function() newPlayer = AudioPlayer.new;

  @visibleForTesting
  static void resetForTest() {
    _fade?.cancel();
    _fade = null;
    _music = null;
    _effects = null;
  }

  static AudioPlayer? _music;
  static AudioPlayer? _effects;
  static int _musicRun = 0;
  static int _effectRun = 0;
  static bool _effectsStopped = false;
  static Timer? _fade;

  /// La musique (`scripts/render_reveal_music.py`) : son gong tombe 4,5 s après
  /// le début, sa queue s'éteint seule. Rend la main quand la lecture démarre.
  Future<void> startMusic() async {
    final run = ++_musicRun;
    try {
      final player = _music ??= newPlayer();
      await player.setVolume(1);
      if (run != _musicRun) return;
      await player.play(AssetSource(musicAsset));
      if (run != _musicRun) await player.stop();
    } catch (_) {
      // Le son ne doit jamais bloquer la révélation.
    }
  }

  /// Baisse la musique jusqu'au silence : on passe la révélation avant le gong.
  /// Sans effet si un fondu est en cours ou sans musique.
  void fadeOutMusic() {
    _musicRun++;
    final player = _music;
    if (player == null || _fade != null) return;
    var volume = 1.0;
    _fade = Timer.periodic(_fadeStep, (timer) {
      volume -= _fadeDelta;
      if (volume > 0) {
        _quietly(() => player.setVolume(volume));
      } else {
        timer.cancel();
        _fade = null;
        _quietly(player.stop);
      }
    });
  }

  /// Coupe net : l'app passe en arrière-plan.
  void stopMusic() {
    _musicRun++;
    _fade?.cancel();
    _fade = null;
    final player = _music;
    if (player != null) _quietly(player.stop);
  }

  /// Sortie de la révélation : aucun effet ne continue ni ne part après.
  void stopEffects() {
    _effectRun++;
    _effectsStopped = true;
    final player = _effects;
    if (player != null) _quietly(player.stop);
  }

  /// Petit son d'une cartouche qui tombe.
  void playCartridge({required bool bonus}) =>
      _playEffect(bonus ? 'sounds/chime.mp3' : 'sounds/click-soft.mp3');

  void _playEffect(String asset) {
    final run = ++_effectRun;
    _effectsStopped = false;
    _quietly(() async {
      var player = _effects;
      if (player == null) {
        player = _effects = newPlayer();
        // Sans ça, sur Android, le focus audio de cet effet met la musique en
        // pause (`WrappedPlayer.onLoss`).
        await player.setAudioContext(AudioContext(
          android:
              const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        ));
      }
      if (run != _effectRun) return;
      await player.stop();
      if (run != _effectRun) return;
      await player.play(AssetSource(asset));
      if (_effectsStopped) await player.stop();
    });
  }

  static void _quietly(Future<void> Function() action) {
    unawaited(action().catchError((_) {}));
  }
}
