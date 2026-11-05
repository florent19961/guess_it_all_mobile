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

  /// `null` si l'ensemble est illisible (dont un autre format que Fiesta v3) :
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
    return FiestaEnsemble(id: id, rules: rules);
  }
}

/// Réglage par défaut de [def] dans un nouvel ensemble : coupé, manches
/// possibles cochées, « Cartouche » (« Toujours » pour ce qui ne peut pas en
/// être une), 1 cartouche (2 pour la Passe gratuite).
ModifierSetting defaultSetting(ModifierDef def) => ModifierSetting(
      active: false,
      rounds: allowedRounds(def),
      mode: canBeCartridge(def) ? ModifierMode.cartridge : ModifierMode.always,
      charges: def.id == 'free_pass' ? 2 : 1,
    );

/// Règles d'un nouvel ensemble : Malus de 10 s, Mot à l'envers, Mime sans les
/// bras, Passe gratuite, Mot compte double en cartouche ; « Une seule réponse »
/// Toujours ; 1 tiré par manche, coup de pouce à 1 cartouche.
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
        def.id: defaultSetting(def).copyWith(active: on.contains(def.id)),
    },
    drawCount: 1,
    boostCount: 1,
  );
}

/// Clé des RÉGLAGES d'un ensemble, hors nom : deux ensembles de même clé
/// jouent pareil (doublon refusé). Seuls les modificateurs actifs comptent,
/// leurs manches seulement en Au tirage, leurs cartouches seulement en
/// Cartouche.
String settingsKey(FiestaRules rules) {
  final ids = rules.modifiers.keys
      .where((id) => rules.activeSetting(id) != null)
      .toList()
    ..sort();
  return jsonEncode({
    'drawCount': rules.drawCount,
    'boostCount': rules.boostCount,
    'modifiers': {
      for (final id in ids)
        id: {
          'mode': rules.modifiers[id]!.mode.name,
          if (rules.modifiers[id]!.mode == ModifierMode.draw)
            'rounds': rules.modifiers[id]!.rounds.toList()..sort()
          else if (rules.modifiers[id]!.mode == ModifierMode.cartridge)
            'charges': rules.modifiers[id]!.charges,
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
  required Map<String, ModifierMode> modes,
  int drawCount = 0,
  int charges = 0,
  int boostCount = 0,
}) =>
    FiestaEnsemble(
      id: '$kProvidedIdPrefix$key',
      rules: FiestaRules(
        mode: FiestaMode.custom,
        ensembleName: name,
        modifiers: {
          for (final def in kModifierCatalog)
            def.id: defaultSetting(def).copyWith(
              active: modes.containsKey(def.id),
              mode: modes[def.id],
              charges: charges,
            ),
        },
        drawCount: drawCount,
        boostCount: boostCount,
      ),
    );

/// Tout le catalogue en cartouche, hors « Une seule réponse ».
Map<String, ModifierMode> _allCartridges() => {
      for (final def in kModifierCatalog)
        if (canBeCartridge(def)) def.id: ModifierMode.cartridge,
    };

final List<FiestaEnsemble> kProvidedEnsembles = [
  // Tout au tirage (1 par manche) ; bonus, −10 s et « Bloquer un devineur »
  // seulement gagnés par le coup de pouce (cartouches à 0).
  _provided(
    'classic',
    'Fiesta classique',
    modes: {
      'no_pass': ModifierMode.draw,
      'reversed': ModifierMode.draw,
      'other_language': ModifierMode.draw,
      'draw': ModifierMode.draw,
      'one_answer': ModifierMode.draw,
      for (final def in kModifierCatalog)
        if (kCartridgeOnlyIds.contains(def.id)) def.id: ModifierMode.cartridge,
    },
    drawCount: 1,
    boostCount: 1,
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
    modes: _allCartridges(),
    charges: 3,
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
    modes: _allCartridges(),
    boostCount: 3,
  ),
];

FiestaEnsemble get classicEnsemble =>
    kProvidedEnsembles.firstWhere((e) => e.id == kClassicEnsembleId);
