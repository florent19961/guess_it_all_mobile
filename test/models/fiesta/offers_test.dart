import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/offers.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';

/// Personnalisé, tout le catalogue en « 1 parmi 3 », sauf `minus_10s` (au
/// tirage) et `reversed` (M3 seulement).
FiestaRules rulesWith({int pick3Choices = 1}) => FiestaRules(
      mode: FiestaMode.custom,
      pick3Choices: pick3Choices,
      modifiers: {
        for (final def in kModifierCatalog)
          def.id: ModifierSetting(
            active: true,
            rounds: def.id == 'reversed' ? {3} : {1, 2, 3},
            mode:
                def.id == 'minus_10s' ? ModifierMode.draw : ModifierMode.offer,
          ),
      },
    );

List<List<ModifierInstance>> rowsFor(
  Standings s,
  String teamId, {
  int pick3Choices = 1,
  List<ModifierInstance> roundDraw = const [],
  List<ModifierInstance> earlierChoices = const [],
  Set<String> blockImmuneTeamIds = const {},
}) =>
    pickThreeOffers(
        rules: rulesWith(pick3Choices: pick3Choices),
        gameId: 'g',
        round: 1,
        standings: s,
        teamId: teamId,
        roundDraw: roundDraw,
        earlierChoices: earlierChoices,
        blockImmuneTeamIds: blockImmuneTeamIds);

List<ModifierInstance> offersFor(Standings s, String teamId,
        {List<ModifierInstance> roundDraw = const [],
        List<ModifierInstance> earlierChoices = const [],
        Set<String> blockImmuneTeamIds = const {}}) =>
    rowsFor(s, teamId,
            roundDraw: roundDraw,
            earlierChoices: earlierChoices,
            blockImmuneTeamIds: blockImmuneTeamIds)
        .firstOrNull ??
    const [];

ModifierInstance forAll(String id) => ModifierInstance(
      catalogId: id,
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: modifierById(id)!.nature,
      round: 2,
    );

ModifierInstance against(String id, String teamId) => ModifierInstance(
      catalogId: id,
      scope: ModifierScope.round,
      target: ModifierTarget.team,
      teamId: teamId,
      charges: 0,
      nature: ModifierNature.malus,
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
      'contre la tête ; seuls les « 1 parmi 3 » cochés sur N+1', () {
    const s = Standings({'rose': 14, 'bleue': 8});
    final offers = offersFor(s, 'bleue');
    expect(offers, hasLength(3));
    for (final o in offers) {
      expect(kOfferStrength[o.catalogId], OfferStrength.medium);
      expect(o.teamId, o.nature == ModifierNature.bonus ? 'bleue' : 'rose');
      expect(o.round, 2);
    }
    expect(offersFor(s, 'rose'), isEmpty, reason: 'le leader ne choisit pas');
    // Écart léger : `minus_10s` (au tirage) et `reversed` (M3 seulement)
    // ne sont jamais proposés en M2.
    expect(ids(offersFor(const Standings({'rose': 12, 'bleue': 10}), 'bleue')),
        ['free_pass']);
  });

  test(
      'exclusions : incompatible avec les règles de N+1, déjà subi ; pas de '
      'plafond ; aucune offre → équipe sautée', () {
    const s = Standings({'rose': 14, 'bleue': 8});
    // `no_pass` pour tous : `two_words` (incompatible) et `no_pass` contre
    // Rose (déjà subi, carte sans effet) disparaissent.
    final withNoPass =
        ids(offersFor(s, 'bleue', roundDraw: [forAll('no_pass')]));
    expect(withNoPass, isNot(contains('two_words')));
    expect(withNoPass, isNot(contains('no_pass')));
    expect(withNoPass, hasLength(3));

    // Rose a déjà 3 malus (règles + choix précédents) : plus de plafond, les
    // malus restants contre elle sont encore proposés.
    final loaded = offersFor(s, 'bleue', roundDraw: [
      forAll('minus_10s')
    ], earlierChoices: [
      against('reversed', 'rose'),
      against('no_pass', 'rose')
    ]);
    expect(loaded.where((o) => o.nature == ModifierNature.malus), isNotEmpty);

    // Tout le cran léger déjà en jeu : aucune offre, l'équipe est sautée.
    expect(
        offersFor(const Standings({'rose': 12, 'bleue': 10}), 'bleue',
            roundDraw: [forAll('free_pass')]),
        isEmpty);
  });

  test('cran vide : on descend d\'un cran (forte → moyenne)', () {
    const s = Standings({'rose': 14, 'bleue': 5});
    final heavy = offersFor(s, 'bleue');
    expect(heavy.map((o) => kOfferStrength[o.catalogId]),
        everyElement(OfferStrength.heavy));
    // Rose immunisée contre « Bloquer un devineur » et mimes hors de M2 : le
    // cran fort est vide, on descend.
    final stepped = offersFor(s, 'bleue', blockImmuneTeamIds: {'rose'});
    expect(stepped, hasLength(3));
    expect(stepped.map((o) => kOfferStrength[o.catalogId]),
        everyElement(OfferStrength.medium));
  });

  test(
      'graine figée (gameId, manche, équipe) : une app mise à jour '
      'retrouve les mêmes offres', () {
    expect(offerSeed('g', 1, 'bleue'), 1610297326);
    expect(ids(offersFor(const Standings({'rose': 14, 'bleue': 8}), 'bleue')),
        ['double_points', 'one_answer', 'other_language']);
  });

  test(
      'plusieurs rangées : pick3Choices rangées de 3 au plus, sans id repris '
      'd\'une rangée à l\'autre, déterministes ; une rangée vide n\'est pas '
      'rendue', () {
    const s = Standings({'rose': 14, 'bleue': 8});
    for (final n in [1, 2, 3]) {
      final rows = rowsFor(s, 'bleue', pick3Choices: n);
      final all = [for (final r in rows) ...ids(r)];
      expect(rows.length, lessThanOrEqualTo(n));
      expect(rows.every((r) => r.isNotEmpty && r.length <= 3), isTrue);
      expect(all.toSet().length, all.length, reason: '$all');
      expect([for (final r in rowsFor(s, 'bleue', pick3Choices: n)) ...ids(r)],
          all);
      // La rangée 0 ne dépend pas du nombre de rangées.
      expect(
          ids(rows.first), ['double_points', 'one_answer', 'other_language']);
    }
    expect(rowsFor(s, 'bleue', pick3Choices: 2), hasLength(2));
    // Cran léger (écart 2) : une seule carte utile, la 2ᵉ rangée descend
    // d'un cran sans rien trouver → une seule rangée.
    expect(
        rowsFor(const Standings({'rose': 12, 'bleue': 10}), 'bleue',
            pick3Choices: 3),
        hasLength(1));
  });

  test(
      'coup de pouce (Auto) : un bonus par menée, un malus pour la tête, '
      'jamais « Bloquer un devineur »', () {
    final auto = autoRules(oneAnswer: false);
    List<ModifierInstance> boost(Standings s, int round, String gameId,
            [List<ModifierInstance> draw = const []]) =>
        appBoost(
            rules: auto,
            gameId: gameId,
            round: round,
            standings: s,
            roundDraw: draw);

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
