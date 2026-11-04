import 'dart:convert';

import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'symmetric_draw.dart';

/// Un ensemble du mode Personnalisé : des `FiestaRules` nommées. Les miens
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

  /// `null` si l'ensemble est illisible (dont la forme v1 d'avant Fiesta v2) :
  /// l'appelant l'ignore seul.
  static FiestaEnsemble? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rawRules = json['rules'];
    if (id is! String || id.startsWith(kProvidedIdPrefix) || rawRules is! Map) {
      return null;
    }
    final rules = FiestaRules.tryFromJson(Map<String, dynamic>.from(rawRules));
    // Un ensemble est toujours Personnalisé : des règles Auto ici ne
    // viennent pas de l'éditeur, on ne les propose pas au choix.
    if (rules == null || rules.mode != FiestaMode.custom) return null;
    return FiestaEnsemble(id: id, rules: oneMimeAtMost(rules));
  }
}

/// Famille « Mime » : un ensemble n'en garde qu'UN actif (choix exclusif de
/// l'éditeur). Normalisation déterministe d'un blob qui en aurait plusieurs :
/// le premier « Toujours » dans l'ordre du catalogue, sinon le premier actif ;
/// les autres sont désactivés, réglages conservés.
FiestaRules oneMimeAtMost(FiestaRules rules) {
  final active = [
    for (final def in kModifierCatalog)
      if (def.mimeFamily && rules.activeSetting(def.id) != null) def.id
  ];
  if (active.length < 2) return rules;
  final keep = active.firstWhere(
    (id) => rules.modifiers[id]!.mode == ModifierMode.always,
    orElse: () => active.first,
  );
  return rules.copyWith(modifiers: {
    for (final MapEntry(key: id, value: setting) in rules.modifiers.entries)
      id: active.contains(id) && id != keep
          ? setting.copyWith(active: false)
          : setting,
  });
}

/// Réglage par défaut de [def] dans un nouvel ensemble (maquette
/// `defaults()`) : coupé, manches possibles cochées, « En stock », 1
/// cartouche (2 pour la Passe gratuite), par manche.
ModifierSetting defaultSetting(ModifierDef def) => ModifierSetting(
      active: false,
      rounds: allowedRounds(def),
      mode: ModifierMode.stock,
      charges: def.id == 'free_pass' ? 2 : 1,
    );

/// Règles d'un nouvel ensemble (maquette `defaults()`) : Malus de 10 s, Mot
/// à l'envers, Mime sans les bras, Passe gratuite, Mot compte double en
/// stock ; « Une seule réponse » Toujours ; 1 tiré par manche, 1 choix
/// 1 parmi 3, rattrapage allumé.
FiestaRules defaultEnsembleRules(String name) {
  const on = {
    'minus_10s',
    'reversed',
    'mime_no_arms',
    'free_pass',
    'double_points',
    'one_answer',
  };
  return FiestaRules(
    mode: FiestaMode.custom,
    ensembleName: name,
    modifiers: {
      for (final def in kModifierCatalog)
        def.id: defaultSetting(def).copyWith(
          active: on.contains(def.id),
          mode: def.id == 'one_answer' ? ModifierMode.always : null,
        ),
    },
    drawCount: 1,
    pick3Choices: 1,
    catchUp: CatchUpRules.auto,
  );
}

/// Clé des RÉGLAGES d'un ensemble, hors nom : deux ensembles de même clé
/// jouent pareil (doublon refusé). Seuls les modificateurs actifs comptent,
/// et les cartouches seulement en « En stock ».
String settingsKey(FiestaRules rules) {
  final ids = rules.modifiers.keys
      .where((id) => rules.activeSetting(id) != null)
      .toList()
    ..sort();
  return jsonEncode({
    'drawCount': rules.drawCount,
    'pick3Choices': rules.pick3Choices,
    'catchUp': rules.catchUp.toJson(),
    'modifiers': {
      for (final id in ids)
        id: {
          'rounds': rules.modifiers[id]!.rounds.toList()..sort(),
          'mode': rules.modifiers[id]!.mode.name,
          if (rules.modifiers[id]!.mode == ModifierMode.stock) ...{
            'charges': rules.modifiers[id]!.charges,
            'perGame': rules.modifiers[id]!.perGame,
          },
        },
    },
  });
}

/// Nom comparé pour l'unicité : insensible à la casse et aux espaces autour.
String nameKey(String name) => name.trim().toLowerCase();

// ---------------------------------------------------------------------------
// Ensembles fournis par l'app (spec Fiesta v2 §4).
// ---------------------------------------------------------------------------

const String kProvidedIdPrefix = 'provided_';

/// Id de « Fiesta classique », présélectionné par défaut.
const String kClassicEnsembleId = '${kProvidedIdPrefix}classic';

FiestaEnsemble _provided(
  String key,
  String name, {
  required Map<String, ModifierMode> modes,
  Map<String, Set<int>> rounds = const {},
  int drawCount = 0,
  int charges = 1,
  bool catchUp = false,
}) =>
    FiestaEnsemble(
      id: '$kProvidedIdPrefix$key',
      rules: FiestaRules(
        mode: FiestaMode.custom,
        ensembleName: name,
        modifiers: {
          for (final def in kModifierCatalog)
            def.id: ModifierSetting(
              active: modes.containsKey(def.id),
              rounds: rounds[def.id] ?? allowedRounds(def),
              mode: modes[def.id] ?? ModifierMode.stock,
              charges: charges,
            ),
        },
        drawCount: drawCount,
        pick3Choices: 1,
        catchUp: catchUp ? CatchUpRules.auto : kCatchUpOff,
      ),
    );

/// Tous les malus et bonus du catalogue dans [mode], un seul mime (« Mime
/// sans les bras », règle « un seul mime à la fois »), en respectant les
/// exceptions « seulement en cartouche » (toujours vrai ici : [mode] est une
/// cartouche).
Map<String, ModifierMode> _everything(ModifierMode mode) => {
      for (final def in kModifierCatalog)
        if (!def.mimeFamily || def.id == 'mime_no_arms') def.id: mode,
    };

final List<FiestaEnsemble> kProvidedEnsembles = [
  // L'ancien défaut, dans le nouveau modèle : malus au tirage (1 par
  // manche), « Dessiner » toute la manche 3, bonus et « Bloquer un devineur »
  // en 1 parmi 3 dès M2, « Une seule réponse » toute la partie, sans
  // rattrapage.
  _provided(
    'classic',
    'Fiesta classique',
    modes: {
      'no_pass': ModifierMode.draw,
      'minus_10s': ModifierMode.draw,
      'reversed': ModifierMode.draw,
      'other_language': ModifierMode.draw,
      'draw': ModifierMode.always,
      'one_answer': ModifierMode.always,
      'block_guesser': ModifierMode.offer,
      'free_pass': ModifierMode.offer,
      'double_points': ModifierMode.offer,
      'two_words': ModifierMode.offer,
    },
    rounds: {
      'block_guesser': {2, 3},
      'free_pass': {2, 3},
      'double_points': {2, 3},
      'two_words': {2, 3},
    },
    drawCount: 1,
  ),
  _provided(
    'pro',
    'Pro Player',
    modes: {
      'no_pass': ModifierMode.draw,
      'reversed': ModifierMode.draw,
      'one_answer': ModifierMode.always,
    },
    drawCount: 1,
  ),
  _provided(
    'straight',
    'Droit au but',
    modes: {'one_answer': ModifierMode.always},
  ),
  _provided(
    'explosive',
    'Explosif',
    modes: _everything(ModifierMode.stock),
    charges: 2,
  ),
  _provided(
    'pictionary',
    'Pictionnary',
    modes: {'draw': ModifierMode.always},
  ),
  _provided(
    'bilingual',
    'Bilingue',
    modes: {'other_language': ModifierMode.always},
  ),
  _provided(
    'injustice',
    'L\'injustice',
    modes: _everything(ModifierMode.offer),
    // Une carte se gagne entre deux manches : jamais en M1.
    rounds: {
      for (final def in kModifierCatalog)
        def.id: allowedRounds(def).difference({1}),
    },
    catchUp: true,
  ),
];

FiestaEnsemble get classicEnsemble =>
    kProvidedEnsembles.firstWhere((e) => e.id == kClassicEnsembleId);
