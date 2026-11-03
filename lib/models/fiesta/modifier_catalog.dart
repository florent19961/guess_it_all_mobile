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

  const ModifierDef({
    required this.id,
    required this.name,
    required this.description,
    required this.nature,
    this.defaultScope = ModifierScope.round,
    this.defaultTarget = ModifierTarget.both,
    this.defaultCharges = 0,
    this.round3Only = false,
  });
}

const List<ModifierDef> kModifierCatalog = [
  ModifierDef(
    id: 'mime_no_arms',
    name: 'Mime sans les bras',
    description: 'Les bras restent le long du corps pendant tout le tour.',
    nature: ModifierNature.malus,
    round3Only: true,
  ),
  ModifierDef(
    id: 'mime_no_fists',
    name: 'Mime sans les poings',
    description: 'Mains ouvertes, jamais de poing fermé.',
    nature: ModifierNature.malus,
    round3Only: true,
  ),
  ModifierDef(
    id: 'mime_eyes_closed',
    name: 'Mime les yeux fermés',
    description: 'On mime les yeux fermés pendant tout le tour.',
    nature: ModifierNature.malus,
    round3Only: true,
  ),
  ModifierDef(
    id: 'draw',
    name: 'Dessiner',
    description: 'On dessine au lieu de mimer.',
    nature: ModifierNature.malus,
    round3Only: true,
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
    description: 'Une fois par manche, les points du tour comptent double.',
    nature: ModifierNature.bonus,
    defaultCharges: 1,
  ),
  ModifierDef(
    id: 'two_words',
    name: 'Deux mots à la fois',
    description: 'Deux mots sont affichés en même temps.',
    nature: ModifierNature.bonus,
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
];

/// Paires incompatibles (Q14 de l'epic). Chaque paire est écrite une fois :
/// [areCompatible] est symétrique par construction.
const List<(String, String)> kModifierIncompatibilities = [
  ('no_pass', 'two_words'),
  ('no_pass', 'free_pass'),
  ('mime_no_arms', 'mime_eyes_closed'),
  ('mime_no_arms', 'draw'),
  ('mime_eyes_closed', 'draw'),
  ('mime_no_fists', 'mime_no_arms'),
  ('mime_no_fists', 'draw'),
];

ModifierDef? modifierById(String id) {
  for (final def in kModifierCatalog) {
    if (def.id == id) return def;
  }
  return null;
}

bool areCompatible(String a, String b) {
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
