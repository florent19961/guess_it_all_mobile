# Releases & stores

Ce que veut dire « mettre en prod » sur ce projet, et les gotchas de la mise à jour forcée.
Le runbook de release lui-même vit dans la skill **`guessitall-workflow` §Release**.

## Identifiants

| Plateforme | Identifiant |
|------------|-------------|
| Android | `com.guessitall.guess_it_all_mobile` |
| iOS | `6756429415` |

Version courante : voir `pubspec.yaml` (`version: X.Y.Z+N`).

## Le modèle de release

Il n'y a **pas de branche de prod**. `main` est le tronc ; ce qui est « en prod » est un **build
soumis au store**, matérialisé par un **tag `vX.Y.Z+N`** posé sur `main` au moment de la soumission.

Conséquences directes :

- Un closeout de story ne bump **jamais** `pubspec.yaml` et ne pousse **jamais** de tag.
- Le **build number `+N` doit STRICTEMENT augmenter** : les stores refusent un build déjà soumis.
  Un `+N` réutilisé se solde par un rejet à l'upload, après le build — donc tard.
- Une release ne se prépare que sur un `main` vert (`scripts/run-full-suite.sh`).

## Mise à jour forcée (`upgrader`)

Le package `upgrader` (^11.5.1) affiche un popup natif — Cupertino sur iOS, Material sur Android —
quand une version plus récente est disponible sur le store.

Configuration dans `lib/app.dart` :

```dart
static final _upgrader = Upgrader(
  storeController: UpgraderStoreController(
    onAndroid: () => UpgraderPlayStore(),
    oniOS: () => UpgraderAppStore(),
  ),
  languageCode: 'fr',
);

UpgradeAlert(
  upgrader: _upgrader,
  dialogStyle: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? UpgradeDialogStyle.cupertino
      : UpgradeDialogStyle.material,
  child: ...,
)
```

**Gotchas payés :**

- `dialogStyle` est un paramètre de **`UpgradeAlert`**, pas de `Upgrader`.
- Utiliser `kIsWeb` + `defaultTargetPlatform` (`package:flutter/foundation.dart`) — **pas**
  `Platform.isIOS` de `dart:io`, qui ne fonctionne pas sur web.
- Depuis upgrader 11.5.1, `UpgraderAppStore` détecte l'App ID automatiquement via le bundle
  identifier — inutile de le passer à la main.

## 🔴 Ce que la mise à jour forcée implique pour le code

`upgrader` pousse **tout le parc** vers la dernière version publiée. Une version qui part en store
devient donc, à court terme, la version que **tout le monde** a.

Corollaire dur : **un bug de persistance embarqué dans une release est irrattrapable** sur les
données déjà écrites sur les téléphones. C'est la raison pour laquelle le schéma
`SharedPreferences` (`guessItAll_*`) est classé au tier risqué dans `guessitall-workflow` — au même
titre que la money sur un projet e-commerce. Tout changement de **forme** d'une clé stockée exige
une migration explicite, pas un « ça repartira de zéro ».

## Build

Deux chemins :

- **Cloud (cible) — Codemagic**, cf. section suivante : un tag `v*` builde AAB + IPA sans Mac.
- **Local (secours)** — depuis Windows (Android) / un Mac (iOS), jamais depuis WSL :

```bash
flutter build appbundle    # Android → Play Console (exige android/key.properties)
flutter build ipa          # iOS → App Store Connect
```

Sans `android/key.properties`, Gradle ne plante plus : le build release sort **non signé** avec un
warning (inutilisable pour le Play Store), et le debug n'en a jamais eu besoin.

## Codemagic (builds cloud)

Config : `codemagic.yaml` à la racine. Machine `mac_mini_m2` (builde Android ET iOS).

| Workflow | Déclencheur | Fait |
|----------|-------------|------|
| `dry-run` | **manuel** (UI Codemagic) | pub get → analyze → test → AAB signé → IPA signée → artefacts |
| `release` | push d'un tag **`v*`** | garde « tag = `v` + version de `pubspec.yaml` », puis idem `dry-run` |

### 🔴 Publication désactivée — volontairement

Décision Florent : **une seule release, après le mode Fiesta**. Aucun workflow ne publie sur Play
ni sur App Store Connect aujourd'hui. Le bloc `publishing` (Play track `internal` + TestFlight) est
**présent mais commenté** dans `release` ; à la 1re release : le décommenter, ajouter le groupe
`gia_google_play` à l'environnement, et seulement sur go explicite de Florent. D'ici là, les
artefacts (AAB/IPA) se téléchargent depuis Codemagic et s'uploadent à la main si besoin.

### Secrets à créer dans Codemagic (une fois — jamais dans le dépôt, il est PUBLIC)

| Nom (exact) | Où dans Codemagic | Contenu |
|-------------|-------------------|---------|
| `gia_android_signing` | Team settings → Code signing identities → Android keystores (*reference name*) | Le keystore upload du Play Store + mot de passe, alias, mot de passe de clé (ceux du `key.properties` Windows) |
| `Guess It All (flow data)` | Team integrations → Developer Portal / App Store Connect (*nom de la clé API*) | Clé API App Store Connect (rôle App Manager) — sert à la signature automatique iOS |
| `gia_firebase` | Application → Environment variables (groupe) | `GOOGLE_SERVICES_JSON` = le contenu **brut** de `android/app/google-services.json` (ou sa version base64), marquée *Secure* |
| `gia_google_play` | idem (groupe) — **seulement à la 1re publication** | `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS` = JSON du compte de service Play, *Secure* |

iOS n'a pas besoin de `GoogleService-Info.plist` : Firebase s'initialise via
`lib/firebase_options.dart` (versionné). La signature iOS est **automatique** (`ios_signing`
`app_store` sur `com.guessitall.guessItAllMobile`) : Codemagic crée/récupère certificat et profil
via l'intégration `Guess It All (flow data)` — d'où l'absence de `DEVELOPMENT_TEAM` dans `project.pbxproj`, sans conséquence.

### Premier dry-run — à faire une fois

1. Créer les 3 premiers secrets ci-dessus, connecter le dépôt GitHub à Codemagic.
2. Lancer `dry-run` à la main sur `main`.
3. Récupérer l'artefact **`ios/Podfile.lock`** et le **commiter** (il n'est pas versionné et ne
   se génère pas depuis WSL) — les builds suivants seront reproductibles côté pods.
4. Lever les points marqués « à vérifier au 1er dry-run » dans `codemagic.yaml` : version
   `xcode: latest` compatible Flutter 3.44, chemin `/Users/builder/export_options.plist`.

### Couper une release (quand la publication sera ouverte)

Runbook : skill `guessitall-workflow` §Release. Côté Codemagic, c'est le **push du tag**
`vX.Y.Z+N` qui lance `release` ; un tag qui ne correspond pas à `pubspec.yaml` échoue en première
étape, avant tout build. `flutter: 3.44.8` est épinglé dans `codemagic.yaml` : le bumper en même
temps que le SDK de dev.

Une entrée datée dans `docs/tracking_evolution.md` clôt toute release.
