/// Catalogue des modificateurs Fiesta (epic-2, V1).
///
/// 🔴 Le catalogue est du CODE, pas de la donnée persistée : seules les
/// instances (`ModifierInstance`) et les réglages (`FiestaRules`) stockent des
/// ids. Renommer un id casserait la relecture des parties en cours et des
/// ensembles enregistrés : les ids ci-dessous sont FIGÉS.
library;

enum ModifierNature { bonus, malus }

/// Portée d'une instance : toute la manche, ou un seul tour.
enum ModifierScope { round, turn }

/// Cible d'une instance : toutes les équipes, une équipe, un joueur.
enum ModifierTarget { both, team, player }

class ModifierDef {
  final String id;
  final String name;
  final String description;
  final ModifierNature nature;
  final ModifierScope defaultScope;
  final ModifierTarget defaultTarget;
  final int defaultCharges;

  /// Contrainte de la manche 3 (mime / dessin) : jamais avant.
  final bool round3Only;

  /// Contrainte de la parole : jamais en manche 3 (on y mime).
  final bool notInRound3;

  /// Famille « Mime » : au plus UN de ses membres à la fois (voir
  /// [areCompatible]).
  final bool mimeFamily;

  const ModifierDef({
    required this.id,
    required this.name,
    required this.description,
    required this.nature,
    this.defaultScope = ModifierScope.round,
    this.defaultTarget = ModifierTarget.both,
    this.defaultCharges = 0,
    this.round3Only = false,
    this.notInRound3 = false,
    this.mimeFamily = false,
  });
}

const List<ModifierDef> kModifierCatalog = [
  ModifierDef(
    id: 'mime_no_arms',
    name: 'Mime sans les bras',
    description: 'Les bras restent le long du corps pendant tout le tour.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'mime_no_fists',
    name: 'Mime sans les poings',
    description: 'Mains ouvertes, jamais de poing fermé.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'mime_eyes_closed',
    name: 'Mime les yeux fermés',
    description: 'On mime les yeux fermés pendant tout le tour.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'draw',
    name: 'Dessiner',
    description: 'On dessine au lieu de mimer.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'no_pass',
    name: 'Interdit de passer',
    description: 'Le bouton Passer est désactivé.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'free_pass',
    name: 'Passe gratuite',
    description: 'Les premières passes du tour sont sans pénalité.',
    nature: ModifierNature.bonus,
    defaultCharges: 2,
  ),
  ModifierDef(
    id: 'minus_10s',
    name: 'Malus de 10 s',
    description: 'Le tour démarre avec 10 secondes de moins.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'double_points',
    name: 'Mot compte double',
    description: 'Les points du tour comptent double.',
    nature: ModifierNature.bonus,
    defaultCharges: 1,
  ),
  ModifierDef(
    id: 'two_words',
    name: 'Deux mots à la fois',
    description: 'Deux mots sont affichés en même temps.',
    nature: ModifierNature.bonus,
    defaultCharges: 1,
  ),
  ModifierDef(
    id: 'reversed',
    name: 'Mot à l\'envers',
    description: 'Le mot est affiché à l\'envers.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'block_guesser',
    name: 'Bloquer un devineur',
    description: 'Les adversaires bloquent un devineur pour un tour.',
    nature: ModifierNature.malus,
    defaultScope: ModifierScope.turn,
    defaultTarget: ModifierTarget.player,
  ),
  // Ajouts du 2026-11-04 : EN FIN de liste (les ids et l'ordre des anciens
  // ne bougent pas).
  ModifierDef(
    id: 'mime_under_sheet',
    name: 'Mimer sous un drap',
    description: 'On mime caché sous un drap (ou une couverture).',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'mime_back_turned',
    name: 'Mime de dos',
    description: 'On mime en tournant le dos à son équipe.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'other_language',
    name: 'Faire deviner dans une autre langue',
    description: 'On fait deviner en parlant une autre langue que le '
        'français.',
    nature: ModifierNature.malus,
    notInRound3: true,
  ),
  // Fiesta v2 (2026-11-04) : « Une seule réponse » devient un malus normal du
  // catalogue (avant : un réglage de toute la partie, hors liste), puis
  // « Bruitages seulement ». EN FIN de liste.
  ModifierDef(
    id: 'one_answer',
    name: 'Une seule réponse',
    description: 'Une seule réponse par mot.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'sounds_only',
    name: 'Bruitages seulement',
    description: 'On fait deviner uniquement avec des bruitages : ni mots, '
        'ni gestes.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  // Fiesta v3 (2026-11-05) : symétrique de « Malus de 10 s ». EN FIN de liste.
  ModifierDef(
    id: 'plus_10s',
    name: 'Bonus de 10 s',
    description: 'Le tour démarre avec 10 secondes de plus.',
    nature: ModifierNature.bonus,
  ),
];

/// Seulement en cartouche (Fiesta v3) : jamais « Toujours » ni « Au tirage ».
/// Un bonus et les malus de temps ou de joueur sont forcément one shot : un
/// « ×2 » pour tout le monde n'en est pas un, un −10 s se joue contre une
/// équipe, et personne ne désignerait le devineur à bloquer.
const Set<String> kCartridgeOnlyIds = {
  'block_guesser',
  'double_points',
  'free_pass',
  'two_words',
  'plus_10s',
  'minus_10s',
};

/// Seulement règle de manche (Fiesta v3) : jamais en cartouche.
const Set<String> kRoundRuleOnlyIds = {'one_answer'};

/// Paires incompatibles (Q14 de l'epic). Chaque paire est écrite une fois :
/// [areCompatible] est symétrique par construction. La famille « Mime » n'y
/// figure pas : c'est une règle de groupe (`mimeFamily`).
const List<(String, String)> kModifierIncompatibilities = [
  ('no_pass', 'two_words'),
  ('no_pass', 'free_pass'),
];

ModifierDef? modifierById(String id) {
  for (final def in kModifierCatalog) {
    if (def.id == id) return def;
  }
  return null;
}

/// Deux membres de la famille « Mime » (`mimeFamily`, « Dessiner » compris)
/// s'excluent toujours (retours device 2026-11-04) : un membre ajouté au
/// catalogue l'est d'office.
bool areCompatible(String a, String b) {
  bool family(String id) => modifierById(id)?.mimeFamily ?? false;
  if (family(a) && family(b)) return false;
  for (final (x, y) in kModifierIncompatibilities) {
    if ((x == a && y == b) || (x == b && y == a)) return false;
  }
  return true;
}

/// Retrouve une valeur d'enum par son `name` sérialisé, `null` si inconnue.
///
/// Même règle que `WordEvent.tryFromJson` : jamais de valeur par défaut
/// inventée sur une donnée persistée illisible.
T? enumFromJson<T extends Enum>(List<T> values, Object? raw) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return null;
}
