/// Enveloppe de version pour tout ce qui est écrit dans `SharedPreferences`.
///
/// 🔴 Pourquoi ça existe : l'app est **publiée** et `upgrader` **force** la mise
/// à jour. Les données écrites par la version en store sont sur les téléphones
/// des joueurs, et une nouvelle version atteint tout le parc en quelques jours.
/// Sans numéro de schéma, faire évoluer la forme d'une clé `guessItAll_*` est un
/// pari : un champ ajouté sans défaut, et la partie en cours d'un joueur devient
/// illisible — définitivement, puisque rien ne nettoyait le blob fautif.
///
/// Trois règles portées par ce fichier :
/// 1. **Toute écriture est versionnée** (`{schemaVersion, data}`).
/// 2. **Une lecture illisible met le blob en QUARANTAINE** (l'appelant le
///    supprime) : un échec doit être transitoire, jamais permanent.
/// 3. **Le format d'AVANT le versionnage reste lisible** — c'est celui qui est
///    en production aujourd'hui, on le migre, on ne le jette pas.
library;

/// Version courante du schéma persisté.
///
/// À incrémenter **uniquement** quand la forme d'une donnée persistée change de
/// façon non rétro-compatible, et en écrivant la migration correspondante.
const int kCurrentSchemaVersion = 1;

/// Version implicite des données écrites avant l'introduction de l'enveloppe.
const int kLegacySchemaVersion = 0;

/// Ce qu'une lecture de blob persisté peut donner.
enum PersistedReadStatus {
  /// Rien n'était stocké.
  absent,

  /// Lu et exploitable.
  ok,

  /// Écrit par une version PLUS RÉCENTE de l'app : on ne sait pas l'interpréter.
  fromFuture,

  /// Structurellement illisible (JSON cassé, forme inattendue).
  corrupt,
}

/// Résultat d'une lecture, avec de quoi décider quoi faire.
class PersistedRead {
  final PersistedReadStatus status;
  final Map<String, dynamic>? data;
  final int version;

  const PersistedRead.absent()
      : status = PersistedReadStatus.absent,
        data = null,
        version = kCurrentSchemaVersion;

  const PersistedRead.corrupt()
      : status = PersistedReadStatus.corrupt,
        data = null,
        version = kCurrentSchemaVersion;

  const PersistedRead.fromFuture(int v)
      : status = PersistedReadStatus.fromFuture,
        data = null,
        version = v;

  const PersistedRead.ok(Map<String, dynamic> d, int v)
      : status = PersistedReadStatus.ok,
        data = d,
        version = v;

  bool get isUsable => status == PersistedReadStatus.ok;

  /// Vrai si le blob doit être SUPPRIMÉ du stockage.
  ///
  /// On met en quarantaine l'illisible ET le venu-du-futur : dans les deux cas
  /// on ne saura jamais le relire, et le garder condamnerait l'utilisateur à
  /// échouer à chaque démarrage. C'est la différence entre « je repars propre »
  /// et « l'app est cassée pour toujours ».
  bool get shouldQuarantine =>
      status == PersistedReadStatus.corrupt ||
      status == PersistedReadStatus.fromFuture;
}

/// Emballe [data] avec la version courante.
Map<String, dynamic> wrapWithSchema(Map<String, dynamic> data) => {
      'schemaVersion': kCurrentSchemaVersion,
      'data': data,
    };

/// Déballe un blob décodé.
///
/// [decoded] est le résultat d'un `jsonDecode`, ou `null` si la clé était
/// absente. Un décodage qui a levé doit être signalé par [decodeFailed].
PersistedRead unwrapSchema(Object? decoded, {bool decodeFailed = false}) {
  if (decodeFailed) return const PersistedRead.corrupt();
  if (decoded == null) return const PersistedRead.absent();

  if (decoded is! Map<String, dynamic>) return const PersistedRead.corrupt();

  final version = decoded['schemaVersion'];

  // Pas de numéro de version : c'est le format d'avant l'enveloppe, celui qui
  // est en production. Il est lu tel quel, et sera ré-écrit versionné à la
  // prochaine sauvegarde.
  if (version == null) {
    return PersistedRead.ok(decoded, kLegacySchemaVersion);
  }

  if (version is! int) return const PersistedRead.corrupt();
  if (version > kCurrentSchemaVersion) return PersistedRead.fromFuture(version);

  final data = decoded['data'];
  if (data is! Map<String, dynamic>) return const PersistedRead.corrupt();

  return PersistedRead.ok(data, version);
}
