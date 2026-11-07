import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Musique de la révélation des scores. Un échec de lecture reste silencieux :
/// le son ne bloque jamais la révélation.
///
/// Player dédié : `AudioService` n'en a qu'un, qu'il coupe à chaque son.
class RevealSound {
  static const musicAsset = 'sounds/reveal_music.mp3';
  static const _fadeStep = Duration(milliseconds: 70);
  static const _fadeDelta = 0.06;

  static AudioPlayer? _music;
  static int _musicRun = 0;
  static Timer? _fade;

  /// La musique (`scripts/render_reveal_music.py`) : son gong tombe 4,5 s après
  /// le début, sa queue s'éteint seule. Rend la main quand la lecture démarre.
  Future<void> startMusic() async {
    final run = ++_musicRun;
    try {
      final player = _music ??= AudioPlayer();
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

  static void _quietly(Future<void> Function() action) {
    unawaited(action().catchError((_) {}));
  }
}
