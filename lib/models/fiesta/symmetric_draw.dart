import 'dart:convert';
import 'dart:math';

import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';

/// Tirage symétrique et modificateurs fixés d'une manche (story 2-5).
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

/// Un modificateur peut-il sortir en manche [round] ?
bool isEligibleForRound(ModifierDef def, int round) =>
    !def.round3Only || round == 3;

/// Le tirage pour toutes les équipes est-il allumé ? (définition partagée
/// avec 2-3 / le Récap : les DEUX drapeaux comptent).
bool isSymmetricDrawOn(FiestaRules rules) =>
    rules.symmetric && rules.drawCount > 0;

ModifierInstance _forAll(ModifierDef def, int round, int charges) =>
    ModifierInstance(
      catalogId: def.id,
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: charges,
      nature: def.nature,
      round: round,
    );

/// Modificateurs « fixés sur la manche N » (Personnalisé, Q16) : toutes les
/// équipes, toute la manche. Ils passent avant le tirage, qui doit leur être
/// compatible ; le plafond de 2 s'applique à eux aussi.
List<ModifierInstance> fixedForRound(FiestaRules rules, int round) {
  final fixed = <ModifierInstance>[];
  if (rules.mode != FiestaMode.custom) return fixed;
  for (final def in kModifierCatalog) {
    final setting = rules.modifiers[def.id];
    if (setting == null ||
        !setting.active ||
        setting.arrival != ModifierArrival.fixed ||
        setting.fixedRound != round ||
        !isEligibleForRound(def, round)) {
      continue;
    }
    final instance = _forAll(def, round, setting.charges);
    if (canAdd(fixed, instance)) fixed.add(instance);
  }
  return fixed;
}

/// Tirage symétrique de la manche [round], compatible avec [alreadyFixed] et
/// avec lui-même, plafond de 2 compris (Q8). Moins de candidats que demandé :
/// on en tire moins, sans erreur.
///
/// - Auto : 1 ou 2 (50/50, Q9) dans tout le catalogue ;
/// - Personnalisé : `drawCount` parmi les modificateurs actifs réglés sur
///   « tiré pour tous » et dont la manche de départ est atteinte.
///
/// Un modificateur qui vise un joueur (`block_guesser`) n'est jamais tiré pour
/// tous : sa cible n'a pas de sens « toutes les équipes ».
List<ModifierInstance> drawSymmetric({
  required FiestaRules rules,
  required int round,
  required List<ModifierInstance> alreadyFixed,
  required Random random,
}) {
  if (!isSymmetricDrawOn(rules)) return const [];

  final auto = rules.mode == FiestaMode.auto;
  final count =
      auto ? (random.nextBool() ? 2 : 1) : rules.drawCount.clamp(0, 2);

  // Ordre du catalogue, jamais celui d'une Map relue : le mélange doit partir
  // de la même liste pour donner le même tirage.
  final candidates = <ModifierInstance>[];
  for (final def in kModifierCatalog) {
    if (def.defaultTarget != ModifierTarget.both ||
        !isEligibleForRound(def, round)) {
      continue;
    }
    if (auto) {
      candidates.add(_forAll(def, round, def.defaultCharges));
      continue;
    }
    final setting = rules.modifiers[def.id];
    if (setting == null ||
        !setting.active ||
        setting.arrival != ModifierArrival.draw ||
        setting.startRound > round) {
      continue;
    }
    candidates.add(_forAll(def, round, setting.charges));
  }
  candidates.shuffle(random);

  final drawn = <ModifierInstance>[];
  for (final candidate in candidates) {
    if (drawn.length >= count) break;
    if (canAdd([...alreadyFixed, ...drawn], candidate)) drawn.add(candidate);
  }
  return drawn;
}

/// Tout ce qui s'applique à toutes les équipes pendant la manche [round] :
/// les fixés, puis le tirage. Point d'entrée unique du provider.
List<ModifierInstance> roundModifiers(
  FiestaRules rules, {
  required String gameId,
  required int round,
}) {
  final fixed = fixedForRound(rules, round);
  return [
    ...fixed,
    ...drawSymmetric(
      rules: rules,
      round: round,
      alreadyFixed: fixed,
      random: Random(drawSeed(gameId, round)),
    ),
  ];
}
