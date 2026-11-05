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

/// Candidats au tirage de la manche [round] : interrupteurs actifs, non
/// verrouillés, qui existent dans cette manche.
Iterable<ModifierDef> drawCandidates(FiestaRules rules, int round) =>
    kModifierCatalog.where((def) =>
        canBeRoundRule(def) &&
        rules.drawsFrom(def.id) &&
        isEligibleForRound(def, round));

/// Manches où le tirage n'aurait rien à sortir (avertissement de l'éditeur,
/// pas une erreur). Vide sans tirage.
List<int> roundsWithoutDraw(FiestaRules rules) => [
      if (rules.drawCount > 0)
        for (var round = 1; round <= 3; round++)
          if (drawCandidates(rules, round).isEmpty) round,
    ];

/// Au moins un réglage joue réellement.
bool hasActiveSetting(FiestaRules rules) =>
    rules.balance ||
    rules.challenges ||
    rules.trailingCount > 0 ||
    rules.allCount > 0 ||
    kModifierCatalog.any((def) =>
        rules.isAlways(def.id) ||
        rules.chargesOf(def.id) > 0 ||
        (rules.drawCount > 0 && rules.drawsFrom(def.id)));

/// Pourquoi un ensemble ne peut pas être enregistré (messages affichés tels
/// quels au-dessus du bouton de l'éditeur). Vide = enregistrable.
///
/// Fonction PURE : l'éditeur l'appelle à chaque rendu, le test la couvre sans
/// écran. [others] : voir [ensembleNameError] ; sert aussi au refus d'un doublon
/// de réglages. Les combinaisons impossibles ne sont pas jugées : l'éditeur les
/// verrouille, et le moteur les écarte.
List<String> validateEnsemble(
  FiestaRules rules, {
  Iterable<FiestaEnsemble> others = const [],
}) {
  final errors = <String>[
    if (ensembleNameError(rules, others: others) case final error?) error,
    if (rules.drawCount > 0 &&
        !kModifierCatalog.any((def) => rules.drawsFrom(def.id)))
      'Combien par manche : aucun modificateur à tirer. Active-en un ou mets '
          '0.'
    else if (!hasActiveSetting(rules))
      'Active au moins un modificateur.',
  ];

  final key = settingsKey(rules);
  final twin = others.where((e) => settingsKey(e.rules) == key).firstOrNull;
  if (twin != null) {
    errors.add('L\'ensemble ${twin.name} a déjà ces paramètres.');
  }
  return errors;
}
