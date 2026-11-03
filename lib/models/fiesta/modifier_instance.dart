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

  const ModifierInstance({
    required this.catalogId,
    required this.scope,
    required this.target,
    this.teamId,
    this.playerId,
    required this.charges,
    required this.nature,
    required this.round,
  });

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
        'teamId': teamId,
        'playerId': playerId,
        'charges': charges,
        'nature': nature.name,
        'round': round,
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
    if (scope == null ||
        target == null ||
        nature == null ||
        charges is! int ||
        round is! int ||
        teamId is! String? ||
        playerId is! String?) {
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
    );
  }
}

/// Peut-on poser [candidate] à côté des instances [active] (celles du tour en
/// cours) ? Non si l'équipe concernée atteindrait [maxPerTurn] modificateurs,
/// ou si une instance active de la même équipe lui est incompatible.
bool canAdd(
  List<ModifierInstance> active,
  ModifierInstance candidate, {
  int maxPerTurn = 2,
}) {
  final sameTeam = active.where(candidate.concernsSameTeamAs);
  if (sameTeam.length >= maxPerTurn) return false;
  return sameTeam.every((a) => areCompatible(a.catalogId, candidate.catalogId));
}
