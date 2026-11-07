import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/surprise_challenge.dart';
import 'package:guess_it_all_mobile/screens/surprise_challenge_screen.dart';
import 'package:guess_it_all_mobile/services/challenge_sounds.dart';
import 'package:guess_it_all_mobile/theme/app_theme.dart';
import 'package:guess_it_all_mobile/widgets/fiesta/modifier_badge.dart';

const _ana = ChallengeContender(
  playerName: 'Ana',
  teamName: 'Les Moulins',
  teamColor: AppColors.team1,
  teammates: ['Léo', 'Sam'],
);
const _bob = ChallengeContender(
  playerName: 'Bob',
  teamName: 'Les Génies',
  teamColor: AppColors.team2,
  teammates: ['Alice', 'Frank'],
);
const _doublePoints = ChallengeReward(
  modifierId: 'double_points',
  name: 'Mot compte double',
  isMalus: false,
);
const _reversed = ChallengeReward(
  modifierId: 'reversed',
  name: 'Mots à l\'envers',
  isMalus: true,
);

Finder _icon(String id) =>
    find.byWidgetPredicate((w) => w is ModifierIcon && w.id == id);

Future<void> _loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await (FontLoader('Bangers')
        ..addFont(rootBundle.load('assets/fonts/Bangers-Regular.ttf')))
      .load();
  await (FontLoader('Poppins')
        ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf')))
      .load();
}

class _Harness {
  final sounds = <String>[];
  ChallengeContender? winner;
  var finishedCalls = 0;
  var skippedCalls = 0;
  var stopCalls = 0;

  Future<void> pump(
    WidgetTester tester, {
    SurpriseChallenge challenge = SurpriseChallenge.thumbWar,
    String? word,
    bool reduced = false,
    ChallengeContender first = _ana,
    ChallengeContender second = _bob,
    ChallengeSound? sound,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 640),
          disableAnimations: reduced,
        ),
        child: SurpriseChallengeScreen(
          challenge: challenge,
          first: first,
          second: second,
          firstReward: _doublePoints,
          secondReward: _reversed,
          word: word,
          onFinished: (w) {
            winner = w;
            finishedCalls++;
          },
          onSkipped: () => skippedCalls++,
          sound: sound ??
              (name, {double volume = 1}) => sounds.add('$name@$volume'),
          stopSounds: () => stopCalls++,
        ),
      ),
    ));
  }
}

/// Du VS à l'écran « Qui a gagné ? », pour un défi fini au toucher.
Future<void> _reachPick(WidgetTester tester) async {
  await tester.pump(kVersusDuration);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.text('C\'est parti'));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tapAt(const Offset(180, 400));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('parcours complet : VS, règle, action, choix, roulette',
      (tester) async {
    final h = _Harness();
    await h.pump(tester);

    expect(find.text('VS'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Bras de fer chinois'), findsOneWidget);

    await tester.pump(kVersusDuration);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        find.textContaining('pouce reste coincé 3 secondes'), findsOneWidget);

    await tester.tap(find.text('C\'est parti'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Coincez ce pouce !'), findsOneWidget);

    await tester.tapAt(const Offset(180, 400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Qui a gagné ?'), findsOneWidget);

    await tester.tap(find.text('Ana'));
    await tester.pump();
    expect(find.text('Les Moulins gagnent !'), findsOneWidget);
    expect(find.text('Cartouche au hasard…'), findsOneWidget);

    await tester.tap(find.text('Continuer'), warnIfMissed: false);
    expect(h.finishedCalls, 0, reason: 'la roulette tourne encore');

    await tester.pump(kRouletteDuration);
    await tester.pump();
    expect(_icon('double_points'), findsOneWidget);
    expect(
      find.text('Mot compte double, dans la réserve de l\'équipe.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Continuer'));
    await tester.tap(find.text('Continuer'));
    expect(h.finishedCalls, 1);
    expect(h.winner, _ana);
    expect(h.skippedCalls, 0);
  });

  testWidgets('chaque issue donne la cartouche de son équipe', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await _reachPick(tester);

    await tester.tap(find.text('Bob'));
    await tester.pump(kRouletteDuration);
    await tester.pump();

    expect(find.text('Les Génies gagnent !'), findsOneWidget);
    expect(_icon('reversed'), findsOneWidget);
    expect(
      find.text('Mots à l\'envers, dans la réserve de l\'équipe.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuer'));
    expect(h.winner, _bob);
  });

  testWidgets('le titre du gagnant : couleur d\'équipe, sans ombre',
      (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await _reachPick(tester);
    await tester.tap(find.text('Bob'));
    await tester.pump();

    final title = tester.widget<Text>(find.text('Les Génies gagnent !'));
    expect(title.style?.color, AppColors.team2);
    expect(title.style?.shadows ?? const <Shadow>[], isEmpty);
  });

  testWidgets('« Passer ce défi » marche jusqu\'au choix du gagnant, une fois',
      (tester) async {
    Future<void> expectSkip(
      Future<void> Function(WidgetTester) goTo,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await goTo(tester);
      final button = find.text('Passer ce défi');
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      expect(h.skippedCalls, 1);
      expect(h.finishedCalls, 0);
      await tester.pumpWidget(const SizedBox());
    }

    await expectSkip((_) async {});
    await expectSkip((t) async {
      await t.pump(kVersusDuration);
      await t.pump(const Duration(milliseconds: 500));
    });
    await expectSkip((t) async {
      await t.pump(kVersusDuration);
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.text('C\'est parti'));
      await t.pump(const Duration(milliseconds: 500));
    });
    await expectSkip(_reachPick);
  });

  testWidgets('erreur d\'appui : « Passer » reste possible pendant la roulette',
      (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await _reachPick(tester);
    await tester.tap(find.text('Ana'));
    await tester.pump();

    await tester.tap(find.text('Passer ce défi'));
    expect(h.skippedCalls, 1);
    expect(h.finishedCalls, 0);
  });

  testWidgets('« Passer » reste possible sur « Continuer », sans gain',
      (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await _reachPick(tester);
    await tester.tap(find.text('Ana'));
    await tester.pump(kRouletteDuration);
    await tester.pump();

    await tester.tap(find.text('Passer ce défi'));
    await tester.tap(find.text('Continuer'));
    expect(h.skippedCalls, 1);
    expect(h.finishedCalls, 0, reason: 'déjà passé');
  });

  testWidgets('« Continuer » touché : plus de retour', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await _reachPick(tester);
    await tester.tap(find.text('Ana'));
    await tester.pump(kRouletteDuration);
    await tester.pump();

    await tester.tap(find.text('Continuer'));
    await tester.tap(find.text('Passer ce défi'));
    expect(h.finishedCalls, 1);
    expect(h.skippedCalls, 0);
  });

  testWidgets('sortie de l\'écran : les sons sont coupés', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    expect(h.stopCalls, 0);
    await tester.pumpWidget(const SizedBox());
    expect(h.stopCalls, 1);
  });

  testWidgets('sons de chaque scène, comme la maquette', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    expect(h.sounds, ['whoosh-cinematic@0.8']);
    await tester.pump(const Duration(milliseconds: 320));
    expect(h.sounds, ['whoosh-cinematic@0.8', 'impact-bass-2@1.0']);

    await tester.pump(kVersusDuration);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('C\'est parti'));
    await tester.pump(const Duration(milliseconds: 500));
    h.sounds.clear();

    await tester.tapAt(const Offset(180, 400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.sounds, ['whoosh-short@0.7']);
    h.sounds.clear();

    await tester.tap(find.text('Ana'));
    await tester.pump(kRouletteDuration);
    await tester.pump();
    expect(h.sounds.where((s) => s == 'click-soft@0.6').length, 14);
    expect(h.sounds, containsAllInOrder(['chime@1.0', 'sparkle@0.6']));
  });

  testWidgets('animations réduites : VS fixe, roulette déjà arrêtée',
      (tester) async {
    final h = _Harness();
    await h.pump(tester, reduced: true);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0, reason: 'rien n\'anime');
    expect(find.text('VS'), findsOneWidget);

    await tester.pump(kVersusDuration);
    await tester.pump();
    await tester.tap(find.text('C\'est parti'));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0, reason: 'rien n\'anime');

    await tester.tapAt(const Offset(180, 400));
    await tester.pump();
    h.sounds.clear();
    await tester.tap(find.text('Ana'));
    await tester.pump();
    expect(_icon('double_points'), findsOneWidget);
    expect(h.sounds, ['chime@1.0', 'sparkle@0.6']);

    await tester.tap(find.text('Continuer'));
    expect(h.finishedCalls, 1);
  });

  testWidgets('taper dans ses mains : le choix arrive à 10 s pile',
      (tester) async {
    final h = _Harness();
    await h.pump(tester, challenge: SurpriseChallenge.clapping);
    await tester.pump(kVersusDuration);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('C\'est parti'));
    await tester.pump();

    expect(find.text('10'), findsOneWidget);
    await tester.tapAt(const Offset(180, 400));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Qui a gagné ?'), findsNothing,
        reason: 'un toucher ne coupe pas les 10 secondes');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Qui a gagné ?'), findsOneWidget);
  });

  testWidgets('téléphone arabe : le mot et les équipes, même très longues',
      (tester) async {
    final h = _Harness();
    await h.pump(
      tester,
      challenge: SurpriseChallenge.mimeRelay,
      word: 'Chauffeur poids lourd',
      first: ChallengeContender(
        playerName: 'Maximilien-Alexandre de la Tour',
        teamName: 'Les Moulins de la Grande Vallée du Sud',
        teamColor: AppColors.team1,
        teammates: [for (var i = 0; i < 9; i++) 'Coéquipier long $i'],
      ),
    );
    await tester.pump(kVersusDuration);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('découvrent un mot déjà joué'), findsOneWidget);
    await tester.tap(find.text('C\'est parti'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Chauffeur poids lourd'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(180, 620));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Qui a gagné ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un son qui échoue ne bloque rien (lecteur réel)',
      (tester) async {
    // La plateforme audio refuse tout, comme un appareil sans sortie son.
    final messenger = tester.binding.defaultBinaryMessenger;
    const players = MethodChannel('xyz.luan/audioplayers');
    const global = MethodChannel('xyz.luan/audioplayers.global');
    const globalEvents = MethodChannel('xyz.luan/audioplayers.global/events');
    Future<Object?> refuse(MethodCall call) async =>
        throw PlatformException(code: 'audio-off');
    messenger.setMockMethodCallHandler(players, refuse);
    messenger.setMockMethodCallHandler(global, (_) async => null);
    messenger.setMockMethodCallHandler(globalEvents, (_) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(players, null);
      messenger.setMockMethodCallHandler(global, null);
      messenger.setMockMethodCallHandler(globalEvents, null);
    });

    final h = _Harness();
    await h.pump(tester, sound: ChallengeSounds.play);
    // Le lecteur réel, à la sortie aussi.
    addTearDown(ChallengeSounds.stop);
    await _reachPick(tester);
    await tester.tap(find.text('Ana'));
    await tester.pump(kRouletteDuration);
    await tester.pump();
    await tester.tap(find.text('Continuer'));
    expect(h.finishedCalls, 1);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(tester.takeException(), isNull);
  });
}
