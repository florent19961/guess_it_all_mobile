import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/challenge_sounds.dart';

class _FakePlayer extends Fake implements AudioPlayer {
  final List<String> calls;
  final Future<void> Function() prepare;
  final Future<void> Function() starting;

  _FakePlayer(this.calls, this.prepare, this.starting);

  @override
  Future<void> setAudioContext(AudioContext ctx) => prepare();

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> play(Source source,
      {double? volume,
      double? balance,
      AudioContext? ctx,
      Duration? position,
      PlayerMode? mode}) async {
    calls.add('play');
    await starting();
  }
}

void main() {
  late List<String> calls;
  late Completer<void> prepared;
  late Completer<void> started;

  setUp(() {
    calls = [];
    prepared = Completer()..complete();
    started = Completer()..complete();
    ChallengeSounds.resetForTest();
    ChallengeSounds.newPlayer =
        () => _FakePlayer(calls, () => prepared.future, () => started.future);
  });

  tearDown(() {
    ChallengeSounds.resetForTest();
    ChallengeSounds.newPlayer = AudioPlayer.new;
  });

  test('un son lancé joue', () async {
    ChallengeSounds.play('chime');
    await pumpEventQueue();
    expect(calls, ['stop', 'play']);
  });

  test('coupé en préparation : il ne part jamais', () async {
    prepared = Completer();
    ChallengeSounds.play('chime');
    await pumpEventQueue();
    ChallengeSounds.stop();
    prepared.complete();
    await pumpEventQueue();
    expect(calls, isNot(contains('play')));
  });

  test('coupé pendant le départ de la lecture : arrêté dès qu\'il a démarré',
      () async {
    started = Completer();
    ChallengeSounds.play('chime');
    await pumpEventQueue();
    expect(calls.last, 'play');
    ChallengeSounds.stop();
    await pumpEventQueue();
    started.complete();
    await pumpEventQueue();
    expect(calls.last, 'stop');
  });

  test('coupe tous les sons déjà lancés', () async {
    ChallengeSounds.play('chime');
    ChallengeSounds.play('sparkle');
    await pumpEventQueue();
    calls.clear();
    ChallengeSounds.stop();
    await pumpEventQueue();
    expect(calls, ['stop', 'stop']);
  });

  test('le défi suivant rejoue normalement', () async {
    ChallengeSounds.play('chime');
    await pumpEventQueue();
    ChallengeSounds.stop();
    await pumpEventQueue();
    calls.clear();
    ChallengeSounds.play('chime');
    await pumpEventQueue();
    expect(calls, ['stop', 'play']);
  });
}
