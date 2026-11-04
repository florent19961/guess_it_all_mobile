import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'symmetric_draw.dart';

/// Pourquoi un ensemble ne peut pas être enregistré (messages affichés tels
/// quels sous le bouton de l'éditeur). Vide = enregistrable.
///
/// Fonction PURE : l'éditeur l'appelle à chaque frappe, le test la couvre
/// sans écran. Seuls les modificateurs ACTIFS sont jugés : un réglage
/// incohérent sur un modificateur coupé ne gêne personne.
///
/// Le tirage pour tous d'un ensemble a lieu si `symmetric` ET
/// `drawCount > 0` (l'interrupteur et le compteur de l'éditeur).
List<String> validateEnsemble(FiestaRules rules) {
  final errors = <String>[];
  if ((rules.ensembleName ?? '').trim().isEmpty) {
    errors.add('Donne un nom à l\'ensemble.');
  }

  final drawOn = rules.symmetric && rules.drawCount > 0;
  final fixedByRound = <int, List<String>>{};

  for (final entry in rules.modifiers.entries) {
    final setting = entry.value;
    final def = modifierById(entry.key);
    if (!setting.active || def == null) continue;
    final name = def.name;

    // Un modificateur à cible joueur n'est ni tiré ni fixé (`isForAllTeams`) :
    // il n'arriverait jamais.
    if (!isForAllTeams(def) && setting.arrival != ModifierArrival.offer) {
      errors.add('$name ne peut être que proposé à l\'équipe menée.');
    }

    switch (setting.arrival) {
      case ModifierArrival.draw:
        if (!drawOn) {
          errors.add('$name est tiré pour tous, mais le tirage symétrique '
              'est coupé ou à 0.');
        }
      case ModifierArrival.offer:
        if (!rules.oneOfThree) {
          errors.add('$name est proposé à l\'équipe menée, mais le choix '
              '1 parmi 3 est coupé.');
        }
        if (setting.startRound < 2) {
          errors.add('$name est proposé dès la manche 1 : le choix a lieu '
              'entre deux manches, M2 au plus tôt.');
        }
      case ModifierArrival.fixed:
        final round = setting.fixedRound;
        if (round == null) {
          // L'éditeur pose toujours une manche, mais un blob relu peut ne pas
          // en avoir : sans manche, le modificateur ne s'appliquerait jamais.
          errors.add('$name est fixé, mais sur aucune manche.');
        } else {
          (fixedByRound[round] ??= []).add(def.id);
        }
    }

    if (def.round3Only) {
      final tooEarly = setting.arrival == ModifierArrival.fixed
          ? setting.fixedRound != 3
          : setting.startRound < 3;
      if (tooEarly) errors.add('$name n\'existe qu\'en manche 3 (mime).');
    }
    if (def.notInRound3) {
      // Manche 1 ou 2 (offre : 2, déjà exigé plus haut) ; une manche fixée
      // absente a déjà son message.
      final round = setting.arrival == ModifierArrival.fixed
          ? setting.fixedRound
          : setting.startRound;
      if (round != null && (round < 1 || round > 2)) {
        errors.add('$name n\'existe pas en manche 3 (mime) : '
            'manche 1 ou 2 seulement.');
      }
    }
  }

  for (final MapEntry(key: round, value: ids) in fixedByRound.entries) {
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        if (!areCompatible(ids[i], ids[j])) {
          errors.add('${modifierById(ids[i])!.name} et '
              '${modifierById(ids[j])!.name} sont incompatibles : pas sur '
              'la même manche ($round).');
        }
      }
    }
  }
  return errors;
}
