import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/offers.dart';

/// Personnalisé, 1 parmi 3 allumé, TOUT le catalogue « proposé » dès M1.
final rules = FiestaRules(
  mode: FiestaMode.custom,
  oneOfThree: true,
  modifiers: {
    for (final def in kModifierCatalog)
      def.id: ModifierSetting(
        active: true,
        arrival: ModifierArrival.offer,
        startRound: 1,
        charges: def.defaultCharges,
      ),
  },
);

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
  });

  test(
      'critère 1 : 14–8 → 3 offres « moyennes », bonus pour moi, malus '
      'contre la tête', () {
    const s = Standings({'rose': 14, 'bleue': 8});
    final offers = pickThreeOffers(
        rules: rules,
        gameId: 'g',
        round: 1,
        standings: s,
        teamId: 'bleue',
        taken: const []);
    expect(offers, hasLength(3));
    for (final o in offers) {
      expect(kOfferStrength[o.catalogId], OfferStrength.medium);
      expect(o.teamId, o.nature == ModifierNature.bonus ? 'bleue' : 'rose');
      expect(o.round, 2);
    }
    expect(
        pickThreeOffers(
            rules: rules,
            gameId: 'g',
            round: 1,
            standings: s,
            teamId: 'rose',
            taken: const []),
        isEmpty,
        reason: 'le leader ne choisit pas');
  });

  test(
      'exclusions : incompatible avec le tirage, plafond de 2, aucune offre '
      '→ équipe sautée', () {
    const s = Standings({'rose': 14, 'bleue': 8});
    List<ModifierInstance> offers(List<ModifierInstance> taken) =>
        pickThreeOffers(
            rules: rules,
            gameId: 'g',
            round: 1,
            standings: s,
            teamId: 'bleue',
            taken: taken);

    // `no_pass` tiré pour tous : `two_words` (incompatible) disparaît.
    expect(ids(offers([forAll('no_pass')])),
        unorderedEquals(['double_points', 'no_pass']));

    // Rose a déjà 2 modificateurs (tirage + choix d'une équipe précédente) :
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
    expect(ids(offers([forAll('minus_10s'), roseChosen])),
        unorderedEquals(['double_points', 'two_words']));

    // Plafond atteint pour tout le monde : aucune offre, l'équipe est sautée.
    expect(offers([forAll('minus_10s'), forAll('reversed')]), isEmpty);
  });

  test('déterminisme : même graine → mêmes offres', () {
    const s = Standings({'rose': 30, 'bleue': 10, 'verte': 25});
    for (var i = 0; i < 50; i++) {
      List<ModifierInstance> run() => pickThreeOffers(
          rules: rules,
          gameId: 'game-$i',
          round: 2,
          standings: s,
          teamId: 'bleue',
          taken: const []);
      expect(ids(run()), ids(run()));
    }
  });
}
