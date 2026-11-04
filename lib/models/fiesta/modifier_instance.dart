import 'modifier_catalog.dart';

/// Un modificateur ACTIF dans une partie. Persisté dans `GameState.fiesta`.
class ModifierInstance {
  final String catalogId;
  final ModifierScope scope;
  final ModifierTarget target;
  final String? teamId;
  final String? playerId;
  final int charges;
  final ModifierNature nature;

  /// Manche dans laquelle l'instance a été posée.
  final int round;

  /// Cartouche de malus « En stock » détenue par l'équipe [teamId], en
  /// RÉSERVE : sans aucun effet tant qu'elle n'est pas jouée contre une
  /// équipe (écran « Ce tour / Réserve », lane 2). `modifiersForTurn` l'ignore.
  /// Clé JSON omise si faux.
  final bool reserve;

  /// Malus INFLIGÉ par l'équipe [fromTeamId] à l'équipe [teamId] avec une
  /// cartouche de sa réserve (écran « Ce tour / Réserve ») : il pèse sur le
  /// PROCHAIN tour de [teamId], quelle que soit la manche ([round] = manche
  /// d'envoi, pour mémoire), puis part à la vraie fin de ce tour. Clé JSON
  /// `from`, omise si nul.
  final String? fromTeamId;

  /// Contrat : une cible `team` ou `player` porte toujours son [teamId] (le
  /// joueur est repéré par son équipe pour le plafond par équipe).
  const ModifierInstance({
    required this.catalogId,
    required this.scope,
    required this.target,
    this.teamId,
    this.playerId,
    required this.charges,
    required this.nature,
    required this.round,
    this.reserve = false,
    this.fromTeamId,
  }) : assert(target == ModifierTarget.both || teamId != null,
            'une cible team/player exige un teamId');

  /// Vrai si les deux instances pèsent sur la même équipe : une cible `both`
  /// touche toutes les équipes, sinon c'est le même `teamId`.
  bool concernsSameTeamAs(ModifierInstance other) {
    if (target == ModifierTarget.both || other.target == ModifierTarget.both) {
      return true;
    }
    return teamId == other.teamId;
  }

  Map<String, dynamic> toJson() => {
        'catalogId': catalogId,
        'scope': scope.name,
        'target': target.name,
        if (teamId != null) 'teamId': teamId,
        if (playerId != null) 'playerId': playerId,
        'charges': charges,
        'nature': nature.name,
        'round': round,
        if (reserve) 'reserve': true,
        if (fromTeamId != null) 'from': fromTeamId,
      };

  /// Variante tolérante : rend `null` au lieu de lever.
  ///
  /// 🔴 Un `catalogId` inconnu (écrit par une version plus récente, ou corrompu)
  /// ou un champ illisible ABANDONNE l'instance : jamais de valeur par défaut
  /// inventée (même règle que `WordEvent.tryFromJson`). L'appelant l'ignore et
  /// relit le reste de la partie.
  static ModifierInstance? tryFromJson(Map<String, dynamic> json) {
    final catalogId = json['catalogId'];
    if (catalogId is! String || modifierById(catalogId) == null) return null;
    final scope = enumFromJson(ModifierScope.values, json['scope']);
    final target = enumFromJson(ModifierTarget.values, json['target']);
    final nature = enumFromJson(ModifierNature.values, json['nature']);
    final charges = json['charges'];
    final round = json['round'];
    final teamId = json['teamId'];
    final playerId = json['playerId'];
    final reserve = json['reserve'] ?? false;
    final from = json['from'];
    if (reserve is! bool ||
        from is! String? ||
        scope == null ||
        target == null ||
        nature == null ||
        charges is! int ||
        round is! int ||
        teamId is! String? ||
        playerId is! String? ||
        (target != ModifierTarget.both && teamId == null)) {
      return null;
    }
    return ModifierInstance(
      catalogId: catalogId,
      scope: scope,
      target: target,
      teamId: teamId,
      playerId: playerId,
      charges: charges,
      nature: nature,
      round: round,
      reserve: reserve,
      fromTeamId: from,
    );
  }
}

/// Peut-on poser [candidate] à côté des instances [active] ? Non si une
/// instance active d'une équipe qu'elle touche lui est incompatible. Pas de
/// plafond (Fiesta v2 : seules les incompatibilités limitent).
bool canAdd(List<ModifierInstance> active, ModifierInstance candidate) => active
    .where(candidate.concernsSameTeamAs)
    .every((a) => areCompatible(a.catalogId, candidate.catalogId));
