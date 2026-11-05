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

    if (setting.mode == ModifierMode.cartridge) {
      if (!canBeCartridge(def)) errors.add('$name : jamais en cartouche.');
      if (setting.charges == 0 && rules.boostCount == 0) {
        errors.add('$name : 0 cartouche sans coup de pouce, elle ne servirait '
            'jamais. Mets-en au moins 1, ou allume le coup de pouce.');
      }
      continue;
    }

    if (setting.rounds.isEmpty) {
      errors.add('$name : coche au moins une manche.');
      continue;
    }
    if (!canBeRoundRule(def)) {
      errors.add('$name : seulement en cartouche.');
    }
    if (def.round3Only && !setting.rounds.every((r) => r == 3)) {
      errors.add('$name n\'existe qu\'en manche 3 (mime).');
    }
    if (def.notInRound3 && setting.rounds.contains(3)) {
      errors.add('$name n\'existe pas en manche 3 (mime) : manche 1 ou 2 '
          'seulement.');
    }
    if (setting.mode == ModifierMode.always) {
      for (final r in setting.rounds) {
        (alwaysByRound[r] ??= []).add(def);
      }
    }
  }

  if (rules.boostCount > 0 &&
      !rules.modifiers.values
          .any((s) => s.active && s.mode == ModifierMode.cartridge)) {
    errors.add('Le coup de pouce a besoin d\'au moins un modificateur en '
        'Cartouche.');
  }

  // Un mime « Toujours » exclut tout autre mime actif, quel que soit son mode
  // (en partie, deux mimes ne jouent jamais ensemble : `areCompatible`).
  final mimes = [
    for (final def in kModifierCatalog)
      if (def.mimeFamily && rules.activeSetting(def.id) != null) def,
  ];
  bool always(ModifierDef def) =>
      rules.activeSetting(def.id)!.mode == ModifierMode.always;
  for (var i = 0; i < mimes.length; i++) {
    for (var j = i + 1; j < mimes.length; j++) {
      final (first, second) = (mimes[i], mimes[j]);
      if (always(first)) {
        errors.add('${first.name} est « Toujours » : retire ${second.name} ou '
            'change son mode.');
      } else if (always(second)) {
        errors.add('${second.name} est « Toujours » : retire ${first.name} ou '
            'change son mode.');
      }
    }
  }

  // Deux « Toujours » incompatibles sur une même manche : l'un des deux ne
  // s'appliquerait pas. Les mimes ont leur message ci-dessus.
  for (final MapEntry(key: round, value: defs) in alwaysByRound.entries) {
    for (var i = 0; i < defs.length; i++) {
      for (var j = i + 1; j < defs.length; j++) {
        if (!areCompatible(defs[i].id, defs[j].id) &&
            !(defs[i].mimeFamily && defs[j].mimeFamily)) {
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
