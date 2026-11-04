import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/offers.dart';

/// Personnalisé, 1 parmi 3 allumé, tout le catalogue « proposé » dès M1,
/// sauf `minus_10s` (tiré pour tous) et `reversed` (dès M3).
final rules = FiestaRules(
  mode: FiestaMode.custom,
  oneOfThree: true,
  modifiers: {
    for (final def in kModifierCatalog)
      def.id: ModifierSetting(
        active: true,
        arrival: def.id == 'minus_10s'
            ? ModifierArrival.draw
            : ModifierArrival.offer,
        startRound: def.id == 'reversed' ? 3 : 1,
        charges: def.defaultCharges,
      ),
  },
);

List<ModifierInstance> offersFor(
  Standings s,
  String teamId, {
  int round = 1,
  String gameId = 'g',
  List<ModifierInstance> roundDraw = const [],
  Map<String, ModifierInstance> choices = const {},
  Set<String> blockImmuneTeamIds = const {},
}) =>
    pickThreeOffers(
        rules: rules,
        gameId: gameId,
        round: round,
        standings: s,
        teamId: teamId,
        roundDraw: roundDraw,
        choices: choices,
        blockImmuneTeamIds: blockImmuneTeamIds);

ModifierInstance forAll(String id) => ModifierInstance(
      catalogId: id,
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: modifierById(id)!.nature,
      round: 2,
    );

List<String> ids(List<ModifierInstance> mods) =>
    mods.map((m) => m.catalogId).toList();

void main() {
  test('force par écart, aux seuils', () {
    expect(strengthForGap(3), OfferStrength.light);
    expect(strengthForGap(4), OfferStrength.medium);
    expect(strengthForGap(7), OfferStrength.medium);
    expect(strengthForGap(8), OfferStrength.heavy);
  });

  test(
      '4 équipes : de la dernière à l\'avant-dernière, le leader exclu ; '
      'égalité générale : personne', () {
    const s = Standings({'rose': 20, 'bleue': 15, 'verte': 11, 'jaune': 13});
    expect(s.choosingOrder, ['verte', 'jaune', 'bleue']);
    expect(s.leaderId, 'rose');
    expect(s.gapOf('verte'), 9);
    expect(const Standings({'a': 5, 'b': 5}).choosingOrder, isEmpty);
    expect(const Standings({'a': 9, 'b': 9, 'c': 2}).leaderId, isNull,
        reason: 'co-leaders : pas de cible de malus');
  });

  test(
      'critère 1 : 14–8 → 3 offres « moyennes », bonus pour moi, malus '
      'contre la tête', () {
    const s = Standings({'rose': 14, 'bleue': 8});
    final offers = offersFor(s, 'bleue');
    expect(offers, hasLength(3));
    for (final o in offers) {
      expect(kOfferStrength[o.catalogId], OfferStrength.medium);
      expect(o.teamId, o.nature == ModifierNature.bonus ? 'bleue' : 'rose');
      expect(o.round, 2);
    }
    expect(offersFor(s, 'rose'), isEmpty, reason: 'le leader ne choisit pas');
    // Écart léger : `minus_10s` (tiré pour tous) et `reversed` (dès M3)
    // ne sont jamais proposés.
    expect(ids(offersFor(const Standings({'rose': 12, 'bleue': 10}), 'bleue')),
        ['free_pass']);
  });

  test(
      'exclusions : incompatible avec le tirage, plafond de 3 (Personnalisé), '
      'aucune offre → équipe sautée', () {
    const s = Standings({'rose': 14, 'bleue': 8});
    // `no_pass` tiré pour tous : `two_words` (incompatible) et `no_pass`
    // contre Rose (déjà subi, carte sans effet) disparaissent.
    expect(ids(offersFor(s, 'bleue', roundDraw: [forAll('no_pass')])),
        ['double_points']);

    // Rose a déjà 3 modificateurs (tirage + choix des équipes précédentes) :
    // plus de malus contre elle, les bonus pour Bleue restent.
    final roseChosen = ModifierInstance(
      catalogId: 'reversed',
      scope: ModifierScope.round,
      target: ModifierTarget.team,
      teamId: 'rose',
      charges: 0,
      nature: ModifierNature.malus,
      round: 2,
    );
    expect(
        ids(offersFor(s, 'bleue', roundDraw: [
          forAll('minus_10s')
        ], choices: {
          'verte': roseChosen,
          'jaune': ModifierInstance(
            catalogId: 'no_pass',
            scope: ModifierScope.round,
            target: ModifierTarget.team,
            teamId: 'rose',
            charges: 0,
            nature: ModifierNature.malus,
            round: 2,
          ),
        })),
        unorderedEquals(['double_points', 'two_words']));

    // Plafond atteint à tous les crans : aucune offre, l'équipe est sautée.
    expect(
        offersFor(s, 'bleue', roundDraw: [
          forAll('minus_10s'),
          forAll('reversed'),
          forAll('free_pass'),
        ]),
        isEmpty);
  });

  test('cran vide : on descend d\'un cran (forte → moyenne)', () {
    const s = Standings({'rose': 14, 'bleue': 5});
    expect(ids(offersFor(s, 'bleue')), ['block_guesser']);
    final stepped = offersFor(s, 'bleue', blockImmuneTeamIds: {'rose'});
    expect(stepped, hasLength(3));
    expect(stepped.map((o) => kOfferStrength[o.catalogId]),
        everyElement(OfferStrength.medium));

    // Cran vide APRÈS exclusions : Rose a déjà 3 modificateurs, donc
    // `block_guesser` (forte) est exclu et l'on descend quand même.
    ModifierInstance againstRose(String id) => ModifierInstance(
          catalogId: id,
          scope: ModifierScope.round,
          target: ModifierTarget.team,
          teamId: 'rose',
          charges: 0,
          nature: ModifierNature.malus,
          round: 2,
        );
    expect(
        ids(offersFor(s, 'bleue', choices: {
          'verte': againstRose('reversed'),
          'jaune': againstRose('no_pass'),
          'violette': againstRose('minus_10s'),
        })),
        unorderedEquals(['double_points', 'two_words']));
  });

  test(
      'graine figée (gameId, manche, équipe) : une app mise à jour '
      'retrouve les mêmes offres', () {
    expect(offerSeed('g', 1, 'bleue'), 1610297326);
    expect(ids(offersFor(const Standings({'rose': 14, 'bleue': 8}), 'bleue')),
        ['double_points', 'two_words', 'no_pass']);
  });

  test(
      'coup de pouce (Auto) : un bonus par menée, un malus pour la tête, '
      'jamais « Bloquer un devineur »', () {
    final auto = FiestaRules(mode: FiestaMode.auto);
    List<ModifierInstance> boost(Standings s, int round, String gameId) =>
        appBoost(
            rules: auto,
            gameId: gameId,
            round: round,
            standings: s,
            roundDraw: const []);

    final gifts = boost(const Standings({'rose': 14, 'bleue': 8}), 1, 'g');
    expect(gifts.map((g) => (g.teamId, g.nature)), [
      ('bleue', ModifierNature.bonus),
      ('rose', ModifierNature.malus),
    ]);
    expect(gifts.map((g) => kOfferStrength[g.catalogId]),
        everyElement(OfferStrength.medium));

    // Écart 10 après M1 : rien de « forte » possible en Auto avant M3, on
    // descend d'un cran au lieu de ne rien donner.
    final wide = boost(const Standings({'rose': 20, 'bleue': 10}), 1, 'g');
    expect(wide, hasLength(2));
    expect(ids(wide), isNot(contains('block_guesser')));

    for (var i = 0; i < 50; i++) {
      final g = boost(
          const Standings({'rose': 20, 'jaune': 18, 'bleue': 5}), 2, 'game-$i');
      expect(ids(g), isNot(contains('block_guesser')));
      expect(g.where((x) => x.nature == ModifierNature.bonus), hasLength(2));
    }
  });
}
