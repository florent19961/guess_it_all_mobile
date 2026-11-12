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

### 🔴 Ce que `release` envoie

Décision Florent : le workflow `release` envoie l'IPA **vers TestFlight seulement**. La mise en
production se fait à la main dans App Store Connect. Google Play reste coupé : le bloc `google_play`
est commenté, l'AAB se télécharge depuis Codemagic. Pour l'activer (track `internal`) : le
décommenter, ajouter le groupe `gia-google-play` à l'environnement, sur go explicite de Florent.

### Secrets à créer dans Codemagic (une fois — jamais dans le dépôt, il est PUBLIC)

| Nom (exact) | Où dans Codemagic | Contenu |
|-------------|-------------------|---------|
| `gia-android-signing` | Team settings → Code signing identities → Android keystores (*reference name*) | Le keystore upload du Play Store + mot de passe, alias, mot de passe de clé (ceux du `key.properties` Windows) |
| `Guess It All (flow data)` | Team integrations → Developer Portal / App Store Connect (*nom de la clé API*) | Clé API App Store Connect (rôle App Manager) — sert à la signature automatique iOS |
| `gia-firebase` | Application → Environment variables (groupe) | `GOOGLE_SERVICES_JSON` = le contenu **brut** de `android/app/google-services.json` (ou sa version base64), marquée *Secure* |
| `gia-google-play` | idem (groupe) — **seulement à la 1re publication** | `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS` = JSON du compte de service Play, *Secure* |

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

Runbook : skill `guessitall-workflow` §Release. Côté Codemagic, le **push du tag**
`vX.Y.Z+N` devrait lancer `release`, mais en pratique ce n'est pas le cas : 🔴 **Florent lance le build
à la main dans Codemagic** (constat du 2026-11-12, le déclencheur sur tag ne part pas). Un agent ne
peut ni lancer ni suivre un build : aucun token d'API Codemagic n'est configuré, et Florent ne
souhaite pas en créer. Après un tag, l'agent dit donc « lance `release` dans Codemagic », jamais
« le tag lance le build ». Le build se contrôle ensuite à son arrivée chez Apple (`asc.py builds`).
Rappel : la garde du workflow exige un tag égal à la version de `pubspec.yaml` ; un tag qui ne correspond pas à `pubspec.yaml` échoue en première
étape, avant tout build. `flutter: 3.44.8` est épinglé dans `codemagic.yaml` : le bumper en même
temps que le SDK de dev.

Une entrée datée dans `docs/tracking_evolution.md` clôt toute release.

## App Store Connect depuis WSL (clé API d'équipe)

Codemagic **builde** l'IPA et l'**envoie** dans App Store Connect avec sa propre clé (intégration
`Guess It All (flow data)`, inchangée). Tout ce qui vient **après** le build se pilote depuis WSL
avec une clé d'équipe locale : état des builds, rattachement à la version, textes, soumission.

| Élément | Valeur |
|---|---|
| Fichier de la clé | `/mnt/c/Users/flore/.stores/AuthKey_3HXC7Q7999.p8` (Windows : `C:\Users\flore\.stores\`) |
| Key ID | `3HXC7Q7999` |
| Issuer ID | `87c6e544-ee5c-4964-93ac-4d4fef23acb7` |
| Rôle | Gestionnaire d'app (App Manager) ; clé d'équipe, valable pour toutes les apps du compte |
| Apple ID de l'app | `6756429415` (bundle `com.guessitall.guessItAllMobile`) |

Key ID et Issuer ID ne sont pas secrets (décision Florent). 🔴 Le `.p8` l'est : ne jamais afficher son
contenu, ni le copier dans le dépôt (PUBLIC) ou dans un dossier synchronisé. Si un outil exige une
copie : fichier temporaire en `chmod 600`, supprimé après usage. Clé compromise : la révoquer dans
App Store Connect → Utilisateurs et accès → Intégrations.

Authentification : JWT ES256, en-tête `kid` = Key ID, claims `iss` = Issuer ID,
`aud` = `appstoreconnect-v1`, `exp` ≤ 20 min. Le script `scripts/asc.py` (PyJWT) le fait :

```bash
python3 -I scripts/asc.py builds     # le build du tag est-il arrivé ? processingState VALID ?
python3 -I scripts/asc.py versions   # versions App Store, état, build rattaché
python3 -I scripts/asc.py get /v1/apps/6756429415   # vérification de la clé : doit sortir les infos de l'app
```

**Lien build ↔ version** : c'est le numéro de `pubspec.yaml`. Le workflow `release`, lancé à la main
par Florent sur le tag `vX.Y.Z+N`, fait sortir le build `X.Y.Z (N)`. Il apparaît dans `asc.py builds`
une fois traité par Apple (`VALID`, compter 10 à 30 min après la fin du workflow). S'il est absent, le
workflow tourne encore, n'a pas été lancé ou a échoué : seul Florent le voit dans Codemagic.

**Soumettre une version — procédure exercée le 2026-11-12 (1.4.0+13)**, chaque écriture sur go
explicite de Florent. JWT identique à la lecture, requêtes JSON:API sur `https://api.appstoreconnect.apple.com` :

1. **Build prêt** : `asc.py builds` → `X.Y.Z+N` en `VALID`.
2. **Chiffrement** : un build arrive avec `usesNonExemptEncryption: null` (la clé `ITSAppUsesNonExemptEncryption`
   manque dans `ios/Runner/Info.plist`). Tous les builds ont été déclarés `false` (HTTPS standard seulement) :
   `PATCH /v1/builds/{id}` `{"usesNonExemptEncryption": false}`.
3. **Rattacher** : `PATCH /v1/appStoreVersions/{version}/relationships/build` `{"data": {"type": "builds", "id": …}}` (204).
4. **Textes** : `PATCH /v1/appStoreVersionLocalizations/{loc}` `{"whatsNew": …, "promotionalText": …}` (fiche
   `fr-FR` seulement). Localisations : `GET /v1/appStoreVersions/{version}/appStoreVersionLocalizations`.
5. **Sortie** : `PATCH /v1/appStoreVersions/{version}` `{"releaseType": "AFTER_APPROVAL" | "MANUAL"}`. Décision Florent
   du 2026-11-12 : **publier dès l'acceptation** (`AFTER_APPROVAL`).
6. **Captures** (si besoin) : séries par appareil via
   `GET /v1/appStoreVersionLocalizations/{loc}/appScreenshotSets?include=appScreenshots`. iPhone = `APP_IPHONE_65`,
   **1284 × 2778**, JPEG RGB (redimensionner à 1284 de large sans déformer, rogner le reste) ; iPad =
   `APP_IPAD_PRO_3GEN_129`, 2048 × 2732. Envoi : `POST /v1/appScreenshots` (`fileName`, `fileSize`, relation
   `appScreenshotSet`) → exécuter chaque `uploadOperations` tel que renvoyé (méthode, URL, en-têtes, morceau) →
   `PATCH /v1/appScreenshots/{id}` `{"uploaded": true, "sourceFileChecksum": <md5>}` → attendre
   `assetDeliveryState.state = COMPLETE`. Ordre : `PATCH /v1/appScreenshotSets/{set}/relationships/appScreenshots`
   avec la liste ordonnée. Retrait : `DELETE /v1/appScreenshots/{id}`. Sauvegarder l'ancienne d'abord (`imageAsset.templateUrl`).
7. **Soumettre** (API *Review Submissions*) : `POST /v1/reviewSubmissions` (`platform: IOS`, relation `app`) →
   `POST /v1/reviewSubmissionItems` (relations `reviewSubmission` + `appStoreVersion`) →
   `PATCH /v1/reviewSubmissions/{id}` `{"submitted": true}` → la version passe `WAITING_FOR_REVIEW`.

Piège rencontré : un 409 `STATE_ERROR.ENTITY_STATE_INVALID` à l'étape 7 liste dans `meta.associatedErrors` ce qui
manque. Le 2026-11-12, c'était une nouvelle question de la classification par âge (`socialMedia`), à laquelle on a
répondu `false` : `PATCH /v1/ageRatingDeclarations/{id}` (l'id est celui de l'`appInfo` en `PREPARE_FOR_SUBMISSION`,
via `GET /v1/apps/{app}/appInfos?include=ageRatingDeclaration`). Apple ajoute des questions de temps en temps : relire
l'erreur et y répondre comme les précédentes (tout à « non »/« aucun » pour ce jeu), en le signalant à Florent.

`asc.py` reste en lecture ; les écritures se font avec un petit script ponctuel qui réutilise la même signature JWT.

## Google Play depuis WSL (compte de service)

Le compte de service `firebase-adminsdk-fbsvc@wasreal.iam.gserviceaccount.com` (projet Google Cloud de
WasReal) est invité dans la Play Console du compte perso de Florent, avec les droits de publication.
Sa clé est `/mnt/c/Users/flore/.stores/wasreal-42d9f844ce8f.json`. 🔴 Secret : ne jamais afficher la
`private_key`. ⚠️ Le fichier `google-services (1).json` du même dossier est la **config Firebase** de l'app,
pas une clé : il ne sert pas à publier.

| Élément | Valeur |
|---|---|
| Package | `com.guessitall.guess_it_all_mobile` (≠ bundle iOS) |
| API | Google Play Android Developer API v3, scope `https://www.googleapis.com/auth/androidpublisher` |
| Authentification | JWT RS256 signé avec la clé du compte de service → jeton OAuth (`token_uri` du JSON) |

Vérifié le 2026-11-12 : un brouillon d'édition ouvert, ses pistes lues, puis supprimé (rien de publié).
Pistes à cette date : production `1.1.3` (versionCode 8), alpha `1.1.2` (7), internal `1.0.0` (2). Le
prochain AAB doit avoir un versionCode > 8 (le `+N` de `pubspec.yaml`, actuellement 13).

Pas encore exercé : l'envoi d'un AAB et la mise à jour des notes de version. L'AAB vient de Codemagic
(artefact téléchargé par Florent, le bloc `google_play` de `codemagic.yaml` restant coupé). Toute écriture
se fait sur go explicite de Florent.

