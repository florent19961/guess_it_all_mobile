import 'dart:convert';
import 'dart:math';

import 'fiesta_rules.dart';
import 'fiesta_state.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';

/// Règles de manche (`always` + tirage `draw`) et cartouches en stock d'une
/// manche (Fiesta v2).
///
/// 🔴 Tout est DÉTERMINISTE par `(gameId, manche)` : le retour arrière depuis
/// la transition rejoue la branche « fin de manche », et une app tuée relit la
/// partie. Les deux doivent retrouver le même tirage, sans rien stocker de plus.
/// D'où une graine calculée ici, et non `String.hashCode` (non garanti stable
/// d'une exécution à l'autre).
int drawSeed(String gameId, int round) {
  // FNV-1a 32 bits.
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode('$gameId#$round')) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// Un modificateur peut-il sortir en manche [round] ? (« manche 3
/// seulement » pour le mime, jamais en manche 3 pour la parole.)
bool isEligibleForRound(ModifierDef def, int round) =>
    round == 3 ? !def.notInRound3 : !def.round3Only;

/// Manches où [def] peut exister : {3} pour un mime, {1, 2} pour la parole,
/// sinon les trois. L'éditeur coche celles-ci par défaut.
Set<int> allowedRounds(ModifierDef def) => {
      for (var r = 1; r <= 3; r++)
        if (isEligibleForRound(def, r)) r
    };

/// Un modificateur qui vise un joueur (`block_guesser`, choisi par les
/// adversaires) n'a pas de sens « pour toutes les équipes ».
bool isForAllTeams(ModifierDef def) => def.defaultTarget == ModifierTarget.both;

/// [def] peut-il être une règle de manche (`always` / `draw`) ? Non pour les
/// exceptions « seulement en cartouche » ([kCartridgeOnlyIds]).
bool canBeRoundRule(ModifierDef def) =>
    isForAllTeams(def) && !kCartridgeOnlyIds.contains(def.id);

/// Auto : « Une seule réponse » vaut-elle pour la partie [gameId] ? Une
/// chance sur 4, DÉTERMINISTE par partie (graine de la « manche 0 »,
/// distincte de celles du tirage des manches 1 à 3).
bool drawsOneAnswer(String gameId) =>
    Random(drawSeed(gameId, 0)).nextInt(4) == 0;

/// Règles du mode Auto, exprimées dans le modèle des ensembles (spec §5) :
/// tout le catalogue pouvant être une règle de manche est « Au tirage » sur
/// ses manches possibles (1 ou 2 tirés par manche, [drawForRound]) ; « Une
/// seule réponse » est « Toujours » M1-M3 si [oneAnswer], hors tirage sinon.
/// Aucune cartouche, sauf le coup de pouce de l'app.
FiestaRules autoRules({required bool oneAnswer, bool autoCalibrate = true}) =>
    FiestaRules(
      mode: FiestaMode.auto,
      autoCalibrate: autoCalibrate,
      modifiers: {
        for (final def in kModifierCatalog)
          if (def.id == 'one_answer')
            def.id: ModifierSetting(
              active: oneAnswer,
              rounds: const {1, 2, 3},
              mode: ModifierMode.always,
            )
          else if (canBeRoundRule(def))
            def.id: ModifierSetting(
              active: true,
              rounds: allowedRounds(def),
              mode: ModifierMode.draw,
            ),
      },
    );

ModifierInstance _forAll(ModifierDef def, int round) => ModifierInstance(
      catalogId: def.id,
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: def.defaultCharges,
      nature: def.nature,
      round: round,
    );

/// Le réglage de [def] le fait-il jouer en manche [round] dans le [mode] ?
bool _plays(FiestaRules rules, ModifierDef def, ModifierMode mode, int round) {
  final setting = rules.activeSetting(def.id);
  return setting != null &&
      setting.mode == mode &&
      setting.rounds.contains(round) &&
      isEligibleForRound(def, round);
}

/// Modificateurs « Toujours » de la manche [round] : toutes les équipes,
/// toute la manche. Ils passent avant le tirage, qui doit leur être
/// compatible. Un réglage impossible (exception cartouche, manche interdite,
/// incompatible avec un précédent) est ignoré : l'éditeur l'interdit.
List<ModifierInstance> alwaysForRound(FiestaRules rules, int round) {
  final always = <ModifierInstance>[];
  for (final def in kModifierCatalog) {
    if (!canBeRoundRule(def) ||
        !_plays(rules, def, ModifierMode.always, round)) {
      continue;
    }
    final instance = _forAll(def, round);
    if (canAdd(always, instance)) always.add(instance);
  }
  return always;
}

/// Tirage de la manche [round] parmi les modificateurs « Au tirage » cochés
/// sur cette manche, compatible avec [already] et avec lui-même : les
/// incompatibles sont sautés ; moins de candidats que demandé, on en tire
/// moins. Pas de plafond (seules les incompatibilités limitent).
///
/// Personnalisé : `drawCount` (0 = aucun tirage) ; Auto : 1 ou 2 (50/50).
List<ModifierInstance> drawForRound({
  required FiestaRules rules,
  required int round,
  required List<ModifierInstance> already,
  required Random random,
}) {
  final count = rules.mode == FiestaMode.auto
      ? (random.nextBool() ? 2 : 1)
      : rules.drawCount;
  if (count <= 0) return const [];

  // Ordre du catalogue, jamais celui d'une Map relue : le mélange doit partir
  // de la même liste pour donner le même tirage.
  final candidates = [
    for (final def in kModifierCatalog)
      if (canBeRoundRule(def) && _plays(rules, def, ModifierMode.draw, round))
        _forAll(def, round),
  ]..shuffle(random);

  final drawn = <ModifierInstance>[];
  for (final candidate in candidates) {
    if (drawn.length >= count) break;
    if (canAdd([...already, ...drawn], candidate)) drawn.add(candidate);
  }
  return drawn;
}

/// Règles de la manche [round] pour toutes les équipes : les « Toujours »,
/// puis le tirage. Point d'entrée unique du provider et du récap.
List<ModifierInstance> roundModifiers(
  FiestaRules rules, {
  required String gameId,
  required int round,
}) {
  final always = alwaysForRound(rules, round);
  return [
    ...always,
    ...drawForRound(
      rules: rules,
      round: round,
      already: always,
      random: Random(drawSeed(gameId, round)),
    ),
  ];
}

/// Cartouches « En stock » reçues par chaque équipe de [teamIds] au début de
/// la manche [round] : une instance par équipe et par modificateur, `charges`
/// = N (« par manche ») ou N moins ce que l'équipe a déjà dépensé dans les
/// manches d'avant (« pour la partie », [chargesUsed]).
///
/// 🔴 Lane 1 : les BONUS jouent par le mécanisme de charges existant (×2 et
/// Deux mots s'allument avant le tour ; Passe gratuite = N passes gratuites
/// par tour toute la manche, toujours « par manche » : ses passes ne
/// laissent pas de `ChargeUse`). Les MALUS sont posés en réserve
/// ([ModifierInstance.reserve]) : persistés, sans effet jusqu'à l'écran
/// « Ce tour / Réserve » (lane 2).
List<ModifierInstance> stockForRound(
  FiestaRules rules, {
  required int round,
  required Iterable<String> teamIds,
  List<ChargeUse> chargesUsed = const [],
}) {
  final stock = <ModifierInstance>[];
  for (final def in kModifierCatalog) {
    if (!_plays(rules, def, ModifierMode.stock, round)) continue;
    final setting = rules.activeSetting(def.id)!;
    final perGame = setting.perGame && def.id != 'free_pass';
    for (final teamId in teamIds) {
      final spent = perGame
          ? chargesUsed
              .where((u) =>
                  u.catalogId == def.id &&
                  u.teamId == teamId &&
                  u.round < round)
              .length
          : 0;
      final charges = setting.charges - spent;
      if (charges <= 0) continue;
      stock.add(ModifierInstance(
        catalogId: def.id,
        scope: ModifierScope.round,
        target: ModifierTarget.team,
        teamId: teamId,
        charges: charges,
        nature: def.nature,
        round: round,
        reserve: def.nature == ModifierNature.malus,
      ));
    }
  }
  return stock;
}
