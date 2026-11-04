import 'fiesta_ensemble.dart';
import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'symmetric_draw.dart';

/// Erreur sur le nom de [rules], `null` s'il est bon. [others] : les autres
/// ensembles (fournis et les miens, SANS celui qu'on modifie) ; un nom est
/// pris s'il est égal à l'un des leurs, sans compter la casse ni les espaces
/// autour.
String? ensembleNameError(
  FiestaRules rules, {
  Iterable<FiestaEnsemble> others = const [],
}) {
  final name = nameKey(rules.ensembleName ?? '');
  if (name.isEmpty) return 'Donne un nom à l\'ensemble.';
  if (others.any((e) => nameKey(e.name) == name)) {
    return 'Ce nom est déjà pris : choisis-en un autre.';
  }
  return null;
}

/// Pourquoi un ensemble ne peut pas être enregistré (messages affichés tels
/// quels au-dessus du bouton de l'éditeur). Vide = enregistrable.
///
/// Fonction PURE : l'éditeur l'appelle à chaque rendu, le test la couvre sans
/// écran. Seuls les modificateurs ACTIFS sont jugés : un réglage incohérent
/// sur un modificateur coupé ne gêne personne. [others] : voir
/// [ensembleNameError] ; sert aussi au refus d'un doublon de réglages.
List<String> validateEnsemble(
  FiestaRules rules, {
  Iterable<FiestaEnsemble> others = const [],
}) {
  final errors = <String>[
    if (ensembleNameError(rules, others: others) case final error?) error,
  ];

  final alwaysByRound = <int, List<ModifierDef>>{};
  for (final def in kModifierCatalog) {
    final setting = rules.activeSetting(def.id);
    if (setting == null) continue;
    final name = def.name;

    if (setting.rounds.isEmpty) {
      errors.add('$name : coche au moins une manche.');
      continue;
    }
    if (isRoundRuleMode(setting.mode) && !canBeRoundRule(def)) {
      errors.add('$name : seulement en cartouche.');
    }
    if (def.round3Only && !setting.rounds.every((r) => r == 3)) {
      errors.add('$name n\'existe qu\'en manche 3 (mime).');
    }
    if (def.notInRound3 && setting.rounds.contains(3)) {
      errors.add('$name n\'existe pas en manche 3 (mime) : manche 1 ou 2 '
          'seulement.');
    }
    if (setting.mode == ModifierMode.offer &&
        setting.rounds.every((r) => r == 1)) {
      errors.add('$name : en « 1 parmi 3 », la carte se gagne entre deux '
          'manches. Coche la manche 2 ou 3.');
    }
    if (setting.mode == ModifierMode.always) {
      for (final r in setting.rounds) {
        (alwaysByRound[r] ??= []).add(def);
      }
    }
  }

  // Deux « Toujours » incompatibles sur une même manche : l'un des deux ne
  // s'appliquerait pas.
  for (final MapEntry(key: round, value: defs) in alwaysByRound.entries) {
    for (var i = 0; i < defs.length; i++) {
      for (var j = i + 1; j < defs.length; j++) {
        if (!areCompatible(defs[i].id, defs[j].id)) {
          errors.add('${defs[i].name} et ${defs[j].name} sont incompatibles : '
              'pas « Toujours » tous les deux en manche $round.');
        }
      }
    }
  }

  final key = settingsKey(rules);
  final twin = others.where((e) => settingsKey(e.rules) == key).firstOrNull;
  if (twin != null) {
    errors.add('L\'ensemble ${twin.name} a déjà ces paramètres.');
  }
  return errors;
}
