import 'dart:convert';

import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'symmetric_draw.dart';

/// Un ensemble Fiesta : des `FiestaRules` nommées. Les miens
/// sont enregistrés sur le téléphone (`FiestaEnsembleService`) ; ceux fournis
/// par l'app ([kProvidedEnsembles]) sont du code, jamais écrits.
///
/// Le nom vit dans `rules.ensembleName` (une seule source) : l'ensemble choisi
/// peut ainsi être gelé tel quel dans la partie par `startGame`.
class FiestaEnsemble {
  /// Identifiant stable : il survit à « Modifier » (remplacement sur place).
  final String id;
  final FiestaRules rules;

  const FiestaEnsemble({required this.id, required this.rules});

  String get name => rules.ensembleName ?? '';

  /// Fourni par l'app : ni modifiable, ni supprimable, seulement duplicable.
  bool get isProvided => id.startsWith(kProvidedIdPrefix);

  Map<String, dynamic> toJson() => {'id': id, 'rules': rules.toJson()};

  /// `null` si l'ensemble est illisible (dont un autre format que Fiesta v4) :
  /// l'appelant l'ignore seul.
  static FiestaEnsemble? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rawRules = json['rules'];
    if (id is! String || id.startsWith(kProvidedIdPrefix) || rawRules is! Map) {
      return null;
    }
    final rules = FiestaRules.tryFromJson(Map<String, dynamic>.from(rawRules));
    if (rules == null) return null;
    return FiestaEnsemble(id: id, rules: rules);
  }
}

/// Clé des RÉGLAGES d'un ensemble, hors nom : deux ensembles de même clé
/// jouent pareil (doublon refusé). Seul ce qui joue compte : pas les réglages
/// verrouillés, ni l'aléatoire sans tirage, ni le nombre fixe sous « Équilibrer
/// la partie ».
String settingsKey(FiestaRules rules) {
  final draws = rules.drawCount > 0;
  return jsonEncode({
    'drawCount': rules.drawCount,
    'allCount': rules.allCount,
    'trailingCount': rules.balance ? 0 : rules.trailingCount,
    'balance': rules.balance,
    'modifiers': {
      for (final def in kModifierCatalog)
        if (rules.isAlways(def.id) ||
            (draws && rules.drawsFrom(def.id)) ||
            rules.chargesOf(def.id) > 0)
          def.id: {
            if (rules.isAlways(def.id)) 'always': true,
            if (draws && rules.drawsFrom(def.id)) 'draw': true,
            if (rules.chargesOf(def.id) > 0) 'charges': rules.chargesOf(def.id),
          },
    },
  });
}

/// Nom comparé pour l'unicité : insensible à la casse et aux espaces autour.
String nameKey(String name) => name.trim().toLowerCase();

// ---------------------------------------------------------------------------
// Ensembles fournis par l'app (spec Fiesta v3).
// ---------------------------------------------------------------------------

const String kProvidedIdPrefix = 'provided_';

/// Id de « Fiesta classique », présélectionné par défaut.
const String kClassicEnsembleId = '${kProvidedIdPrefix}classic';

FiestaEnsemble _provided(
  String key,
  String name, {
  Set<String> always = const {},
  Set<String> draw = const {},
  int drawCount = 0,
  int allCount = 0,
  int trailingCount = 0,
  bool balance = false,
}) =>
    FiestaEnsemble(
      id: '$kProvidedIdPrefix$key',
      rules: FiestaRules(
        ensembleName: name,
        modifiers: {
          for (final id in {...always, ...draw})
            id: ModifierSetting(
              always: always.contains(id),
              draw: draw.contains(id),
            ),
        },
        drawCount: drawCount,
        allCount: allCount,
        trailingCount: trailingCount,
        balance: balance,
      ),
    );

final List<FiestaEnsemble> kProvidedEnsembles = [
  _provided(
    'classic',
    'Fiesta classique',
    draw: {
      for (final def in kModifierCatalog)
        if (canBeRoundRule(def)) def.id,
    },
    drawCount: 1,
    balance: true,
  ),
  _provided('last', 'Les derniers seront les premiers', trailingCount: 4),
  _provided('pro', 'Pro Player', always: {'no_pass', 'reversed', 'one_answer'}),
  _provided('straight', 'Droit au but', always: {'one_answer'}),
  _provided('pictionary', 'Pictionnary', always: {'draw'}),
  _provided('bilingual', 'Bilingue', always: {'other_language'}),
  _provided('explosive', 'Explosif', allCount: 5),
  _provided(
    'expert',
    'Mimeur expert',
    always: {'sounds_only', 'mime_under_sheet'},
  ),
];

FiestaEnsemble get classicEnsemble =>
    kProvidedEnsembles.firstWhere((e) => e.id == kClassicEnsembleId);
