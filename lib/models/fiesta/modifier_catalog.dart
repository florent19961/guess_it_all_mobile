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

  /// Mini-phrase de la pastille du tour. `block_guesser` : à faire précéder du
  /// prénom du joueur bloqué. Nul : pas de pastille (`block_giver`, le joueur
  /// saute son tour).
  final String? turnLabel;
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
    required this.turnLabel,
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
    turnLabel: 'Mime sans les bras',
    description: 'Les bras restent le long du corps pendant tout le tour.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'mime_no_fists',
    name: 'Mime sans les mains',
    turnLabel: 'Mime sans les mains',
    description: 'On mime sans se servir de ses mains.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'mime_eyes_closed',
    name: 'Mime les yeux fermés',
    turnLabel: 'Mime les yeux fermés',
    description: 'On mime les yeux fermés pendant tout le tour.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'draw',
    name: 'Dessiner',
    turnLabel: 'Dessine au lieu de mimer',
    description: 'On dessine au lieu de mimer.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'no_pass',
    name: 'Interdit de passer',
    turnLabel: 'Interdit de passer',
    description: 'Le bouton Passer est désactivé pendant le tour.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'free_pass',
    name: 'Passe gratuite',
    turnLabel: '1 passe gratuite',
    description: 'Tu peux passer gratuitement une fois.',
    nature: ModifierNature.bonus,
    defaultCharges: 1,
  ),
  ModifierDef(
    id: 'minus_10s',
    name: 'Malus de 10 s',
    turnLabel: '−10 secondes',
    description: 'Le tour démarre avec 10 secondes de moins.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'double_points',
    name: 'Mot compte double',
    turnLabel: 'Chaque mot vaut 2 points',
    description: 'Chaque mot trouvé pendant ton tour rapporte 2 points.',
    nature: ModifierNature.bonus,
    defaultCharges: 1,
  ),
  ModifierDef(
    id: 'reversed',
    name: 'Mot à l\'envers',
    turnLabel: 'Mot écrit à l\'envers',
    description: 'Le mot s\'affiche à l\'envers : STAR WARS devient SRAW RATS.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'block_guesser',
    name: 'Bloquer un devineur',
    turnLabel: 'ne répond pas',
    description: 'Le joueur choisi n\'a pas le droit de répondre pendant un '
        'tour.',
    nature: ModifierNature.malus,
    defaultScope: ModifierScope.turn,
    defaultTarget: ModifierTarget.player,
  ),
  // Ajouts du 2026-11-04 : EN FIN de liste (les ids et l'ordre des anciens
  // ne bougent pas).
  ModifierDef(
    id: 'mime_under_sheet',
    name: 'Mimer sous un drap',
    turnLabel: 'Mime sous un drap',
    description: 'On mime caché sous un drap (ou une couverture).',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'mime_back_turned',
    name: 'Mime de dos',
    turnLabel: 'Mime dos à ton équipe',
    description: 'On mime en tournant le dos à son équipe.',
    nature: ModifierNature.malus,
    round3Only: true,
    mimeFamily: true,
  ),
  ModifierDef(
    id: 'other_language',
    name: 'Faire deviner dans une autre langue',
    turnLabel: 'Parle une autre langue',
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
    turnLabel: 'Une seule réponse par mot',
    description: 'Une seule réponse par mot pour toute l\'équipe.',
    nature: ModifierNature.malus,
  ),
  ModifierDef(
    id: 'sounds_only',
    name: 'Bruitages seulement',
    turnLabel: 'Bruitages, ni mots ni gestes',
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
    turnLabel: '+10 secondes',
    description: 'Ton tour démarre avec 10 secondes de plus.',
    nature: ModifierNature.bonus,
  ),
  // Fiesta v4 (2026-11-05) : le joueur nommé saute son prochain tour. EN FIN de
  // liste.
  ModifierDef(
    id: 'block_giver',
    name: 'Interdit de faire deviner',
    turnLabel: null,
    description: 'Le joueur choisi saute son prochain tour : il ne fait pas '
        'deviner.',
    nature: ModifierNature.malus,
    defaultScope: ModifierScope.turn,
    defaultTarget: ModifierTarget.player,
  ),
];

/// Modificateurs retirés du jeu, en LECTURE SEULE : des données déjà écrites
/// (historique, cartouches gagnées ou dépensées, règles gelées, ensembles
/// enregistrés) portent encore leur id (règle 7). [modifierById] les connaît
/// pour les nommer ; hors de [kModifierCatalog], ils ne sont ni proposés, ni
/// tirés, ni joués.
const List<ModifierDef> _kRetiredModifiers = [
  ModifierDef(
    id: 'two_words',
    name: 'Deux mots à la fois',
    turnLabel: null,
    description: 'Deux mots sont affichés en même temps.',
    nature: ModifierNature.bonus,
    defaultCharges: 1,
  ),
];

/// Seulement en cartouche : jamais « Toujours » ni en aléatoire. Un bonus et
/// les malus de temps ou de joueur sont forcément one shot : un « ×2 » pour tout
/// le monde n'en est pas un, un −10 s se joue contre une équipe, et personne ne
/// désignerait le joueur à bloquer.
const Set<String> kCartridgeOnlyIds = {
  'block_guesser',
  'block_giver',
  'double_points',
  'free_pass',
  'plus_10s',
  'minus_10s',
};

/// Paires incompatibles (Q14 de l'epic). Chaque paire est écrite une fois :
/// [areCompatible] est symétrique par construction. La famille « Mime » n'y
/// figure pas : c'est une règle de groupe (`mimeFamily`).
const List<(String, String)> kModifierIncompatibilities = [
  ('no_pass', 'free_pass'),
];

/// Seule paire de mimes compatible, dans toutes les combinaisons.
bool _isSoundsSheetPair(String a, String b) =>
    (a == 'sounds_only' && b == 'mime_under_sheet') ||
    (a == 'mime_under_sheet' && b == 'sounds_only');

/// Texte de [id] quand les modificateurs [active] jouent avec lui : la paire
/// Bruitages / drap change le sens de chacun (Bruitages seul interdit les
/// gestes).
String modifierDescription(String id, Iterable<String> active) {
  if (active.any((other) => _isSoundsSheetPair(id, other))) {
    return 'Gestes et bruits sous le drap, sans parler.';
  }
  return modifierById(id)?.description ?? '';
}

/// Cherche aussi parmi les modificateurs retirés ([_kRetiredModifiers]).
ModifierDef? modifierById(String id) {
  for (final def in kModifierCatalog.followedBy(_kRetiredModifiers)) {
    if (def.id == id) return def;
  }
  return null;
}

/// Deux membres de la famille « Mime » (`mimeFamily`, « Dessiner » compris)
/// s'excluent (retours device 2026-11-04), sauf la paire Bruitages / drap : un
/// membre ajouté au catalogue l'est d'office.
bool areCompatible(String a, String b) {
  bool family(String id) => modifierById(id)?.mimeFamily ?? false;
  if (family(a) && family(b)) return _isSoundsSheetPair(a, b);
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
