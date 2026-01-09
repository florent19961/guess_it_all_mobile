# Guide Firebase - Guess It All

Ce guide détaille la configuration et les tests de l'intégration Firebase pour la synchronisation des analytics de parties.

## Table des matières

1. [Prérequis](#prérequis)
2. [Étape 1 : Créer un projet Firebase](#étape-1--créer-un-projet-firebase)
3. [Étape 2 : Installer FlutterFire CLI](#étape-2--installer-flutterfire-cli)
4. [Étape 3 : Configurer Firebase dans le projet](#étape-3--configurer-firebase-dans-le-projet)
5. [Étape 4 : Créer la base Firestore](#étape-4--créer-la-base-firestore)
6. [Étape 5 : Configurer les règles de sécurité](#étape-5--configurer-les-règles-de-sécurité)
7. [Étape 6 : Configuration Android](#étape-6--configuration-android)
8. [Étape 7 : Configuration iOS](#étape-7--configuration-ios)
9. [Tests de validation](#tests-de-validation)
10. [Lecture des logs](#lecture-des-logs)
11. [Vérification dans Firebase Console](#vérification-dans-firebase-console)
12. [Dépannage](#dépannage)

---

## Prérequis

- Compte Google
- Flutter installé et fonctionnel
- Node.js installé (pour Firebase CLI)
- Un terminal/console

---

## Étape 1 : Créer un projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)

2. Cliquer sur **"Ajouter un projet"** (ou "Create a project")

3. **Nom du projet** : `guess-it-all` (ou un nom de votre choix)
   - Note : Firebase ajoutera un suffixe unique automatiquement

4. **Google Analytics** : Vous pouvez le désactiver (non nécessaire pour ce projet)
   - Cliquer sur "Continuer" sans activer Analytics

5. Cliquer sur **"Créer le projet"** et attendre la création (~30 secondes)

6. Une fois créé, cliquer sur **"Continuer"** pour accéder à la console du projet

**Résultat attendu** : Vous êtes sur la page d'accueil de votre projet Firebase.

---

## Étape 2 : Installer FlutterFire CLI

FlutterFire CLI automatise la configuration de Firebase pour Flutter.

### 2.1 Installer Firebase CLI (si pas déjà fait)

```bash
# Via npm (recommandé)
npm install -g firebase-tools

# OU via curl (Linux/macOS)
curl -sL https://firebase.tools | bash
```

### 2.2 Se connecter à Firebase

```bash
firebase login
```

Cette commande ouvre un navigateur pour vous authentifier avec votre compte Google.

**Vérification** :
```bash
firebase projects:list
```
Vous devriez voir votre projet `guess-it-all` dans la liste.

### 2.3 Installer FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

**Vérification** :
```bash
flutterfire --version
```
Devrait afficher quelque chose comme `0.3.0` ou plus récent.

---

## Étape 3 : Configurer Firebase dans le projet

C'est l'étape la plus importante. Elle génère automatiquement tous les fichiers de configuration.

### 3.1 Aller dans le dossier du projet

```bash
cd "/mnt/c/Users/flore/Documents/Python Scripts/guess_it_all_mobile"
```

### 3.2 Exécuter FlutterFire Configure

```bash
flutterfire configure
```

### 3.3 Répondre aux questions interactives

1. **Select a Firebase project** : Choisir `guess-it-all` (votre projet créé à l'étape 1)

2. **Which platforms should your configuration support?** :
   - [x] android
   - [x] ios
   - [ ] macos (décocher si pas nécessaire)
   - [ ] web (décocher si pas nécessaire)

   Utiliser Espace pour sélectionner/déselectionner, Entrée pour valider.

3. **Android package name** : Garder la valeur par défaut ou utiliser `com.example.guess_it_all`

4. **iOS bundle identifier** : Garder la valeur par défaut ou utiliser `com.example.guessItAll`

### 3.4 Fichiers générés

La commande crée/modifie automatiquement :

| Fichier | Description |
|---------|-------------|
| `lib/firebase_options.dart` | Configuration Dart (remplace le placeholder) |
| `android/app/google-services.json` | Configuration Android |
| `ios/Runner/GoogleService-Info.plist` | Configuration iOS |
| `ios/firebase_app_id_file.json` | ID de l'app iOS |

**Vérification** :
```bash
cat lib/firebase_options.dart | head -20
```
Vous devriez voir des vraies valeurs (pas "PLACEHOLDER").

---

## Étape 4 : Créer la base Firestore

Firestore est la base de données NoSQL où seront stockées les parties.

1. Dans [Firebase Console](https://console.firebase.google.com/), sélectionner votre projet

2. Dans le menu de gauche, cliquer sur **"Build"** > **"Firestore Database"**

3. Cliquer sur **"Créer une base de données"**

4. **Mode de démarrage** :
   - Choisir **"Mode production"** (plus sécurisé)
   - Cliquer sur "Suivant"

5. **Emplacement** :
   - Choisir **`europe-west1` (Belgium)** pour la France
   - Ou `europe-west3` (Frankfurt) comme alternative
   - ⚠️ L'emplacement ne peut pas être changé après création !

6. Cliquer sur **"Activer"** et attendre (~1 minute)

**Résultat attendu** : Vous voyez l'interface Firestore avec "Aucune collection" affiché.

---

## Étape 5 : Configurer les règles de sécurité

Les règles définissent qui peut lire/écrire dans la base.

1. Dans Firestore, cliquer sur l'onglet **"Règles"**

2. Remplacer le contenu par :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /games/{gameId} {
      // Permettre l'écriture uniquement (pas de lecture côté client)
      allow create: if request.resource.data.userId != null
                    && request.resource.data.gameId != null;
      allow update: if false;  // Pas de modification
      allow delete: if false;  // Pas de suppression
      allow read: if false;    // Pas de lecture côté client
    }
  }
}
```

3. Cliquer sur **"Publier"**

**Explication des règles** :
- `create: if ...` : Autorise la création si userId et gameId sont présents
- `update/delete/read: if false` : Bloque toute modification, suppression ou lecture
- Les données sont en écriture seule (analytics) et consultables uniquement via la Console Firebase

---

## Étape 6 : Configuration Android

### 6.1 Vérifier google-services.json

```bash
ls -la android/app/google-services.json
```

Ce fichier doit exister et contenir votre `project_id`.

### 6.2 Vérifier build.gradle (racine)

Ouvrir `android/build.gradle` et vérifier que le plugin Google Services est présent :

```groovy
buildscript {
    // ...
    dependencies {
        // Ajouter cette ligne si absente :
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

### 6.3 Vérifier build.gradle (app)

Ouvrir `android/app/build.gradle` et vérifier :

```groovy
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'dev.flutter.flutter-gradle-plugin'
    id 'com.google.gms.google-services'  // Ajouter si absent
}

android {
    defaultConfig {
        minSdkVersion 21  // Minimum pour Firebase
        // ...
    }
}
```

---

## Étape 7 : Configuration iOS

### 7.1 Vérifier GoogleService-Info.plist

```bash
ls -la ios/Runner/GoogleService-Info.plist
```

Ce fichier doit exister.

### 7.2 Vérifier le Podfile

Ouvrir `ios/Podfile` et vérifier :

```ruby
platform :ios, '13.0'  # Minimum pour Firebase
```

### 7.3 Installer les pods

```bash
cd ios
pod install
cd ..
```

**Note** : Si vous avez des erreurs de pods, essayez :
```bash
cd ios
pod deintegrate
pod install
cd ..
```

---

## Tests de validation

### Test 1 : Lancer l'app et vérifier les logs

```bash
flutter run
```

**Logs attendus au démarrage (Firebase configuré)** :
```
╔════════════════════════════════════════════════════════════╗
║           GUESS IT ALL - APPLICATION STARTUP               ║
╚════════════════════════════════════════════════════════════╝

[Main] Step 1/4: Initializing Firebase...
[Main] Firebase initialized successfully
[Main] Firebase project: guess-it-all-xxxxx
[Main] Step 2/4: Initializing ConnectivityService...
[Connectivity] Initializing service...
[Connectivity] Initial check: [ConnectivityResult.wifi]
[Connectivity] Service initialized - isConnected: true
[Main] ConnectivityService ready
[Main] Step 3/4: Initializing FirebaseSyncService...
[Firebase] ══════════════════════════════════════════
[Firebase] Initializing FirebaseSyncService...
[Firebase] Firebase available: true
[Firebase] Firebase apps: [[DEFAULT]]
[Firebase] Pending games in queue: 0
[Firebase] No pending games to sync
[Firebase] Service initialized successfully
[Firebase] ══════════════════════════════════════════
[Main] FirebaseSyncService ready
[Main] Step 4/4: Initializing WordLoaderService...
[Main] WordLoaderService ready
[Main] Checking for orphaned games...
[Main] No orphaned games found

[Main] ════════════════════════════════════════════════════════
[Main] Startup complete - Launching app...
[Main] Firebase enabled: true
[Main] ════════════════════════════════════════════════════════
```

**Logs si Firebase NON configuré** :
```
[Main] Step 1/4: Initializing Firebase...
[Main] Firebase initialization FAILED: ...
[Main] App will run in OFFLINE-ONLY mode
[Main] To enable sync, run: flutterfire configure
[Main] Step 2/4: SKIPPED (Firebase not available)
[Main] Step 3/4: SKIPPED (Firebase not available)
```

### Test 2 : Jouer une partie complète

1. Lancer une partie avec 2 joueurs, 2 équipes, 10 mots
2. Jouer jusqu'à la fin (ou quitter volontairement)
3. Observer les logs lors de `endGame()` :

```
[Firebase] ──────────────────────────────────────────
[Firebase] markForSync called for gameId: abc123-def456-...
[Firebase] Game added to sync queue (1 total pending)
[Firebase] Checking sync conditions:
[Firebase]   - Firebase available: true
[Firebase]   - Network connected: true
[Firebase] Conditions met, attempting immediate sync...
[Firebase] syncGame: abc123-def456-...
[Firebase] Loading game data from local storage...
[Firebase] Game loaded:
[Firebase]   - Events: 42
[Firebase]   - Words: 10
[Firebase]   - Started: 2026-01-09 14:30:00.000
[Firebase] Uploading to Firestore collection: games
[Firebase] Document ID: abc123-def456-...
[Firebase] SUCCESS: Game synced to Firestore!
[Firebase] Removed from pending queue: abc123-def456-...
[Firebase] ──────────────────────────────────────────
```

### Test 3 : Mode offline puis online

1. Activer le mode avion sur le device/émulateur
2. Jouer une partie complète
3. Observer les logs :

```
[Firebase] markForSync called for gameId: xyz789-...
[Firebase] Game added to sync queue (1 total pending)
[Firebase] Checking sync conditions:
[Firebase]   - Firebase available: true
[Firebase]   - Network connected: false
[Firebase] Offline - game queued for sync when connected
```

4. Désactiver le mode avion
5. Observer les logs de synchronisation automatique :

```
[Connectivity] Network change detected: [ConnectivityResult.wifi]
[Connectivity] Status changed: OFFLINE -> ONLINE
[Firebase] Connectivity changed -> isConnected: true
[Firebase] Network restored, triggering sync...
[Firebase] ══════════════════════════════════════════
[Firebase] Starting batch sync of 1 games...
[Firebase] [1/1] Syncing: xyz789-...
[Firebase] SUCCESS: Game synced to Firestore!
[Firebase] [1/1] OK
[Firebase] Batch sync completed:
[Firebase]   - Synced: 1
[Firebase]   - Failed: 0
[Firebase]   - Remaining: 0
[Firebase] ══════════════════════════════════════════
```

---

## Lecture des logs

### Filtrer les logs Firebase uniquement

```bash
flutter run 2>&1 | grep -E "\[Firebase\]|\[Connectivity\]|\[Main\]"
```

### Tags de logs utilisés

| Tag | Source | Description |
|-----|--------|-------------|
| `[Main]` | `main.dart` | Démarrage de l'app |
| `[Connectivity]` | `connectivity_service.dart` | État du réseau |
| `[Firebase]` | `firebase_sync_service.dart` | Synchronisation Firestore |

### Symboles visuels

| Symbole | Signification |
|---------|---------------|
| `══════` | Début/fin d'une section importante |
| `──────` | Délimiteur d'opération |
| `SUCCESS` | Opération réussie |
| `ERROR` | Erreur rencontrée |
| `SKIP` | Opération ignorée |
| `FAILED` | Échec de l'opération |

---

## Vérification dans Firebase Console

### Voir les données synchronisées

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet
3. Menu gauche : **Build** > **Firestore Database**
4. Onglet **Données**

Vous devriez voir :
```
games/
├── abc123-def456-...
│   ├── gameId: "abc123-def456-..."
│   ├── userId: "user-uuid-..."
│   ├── startedAt: January 9, 2026 at 2:30:00 PM
│   ├── endedAt: January 9, 2026 at 2:45:00 PM
│   ├── numberOfPlayers: 4
│   ├── numberOfTeams: 2
│   ├── totalWords: 40
│   ├── events: [...]
│   ├── wordStats: {...}
│   └── syncedAt: January 9, 2026 at 2:45:05 PM
└── xyz789-...
    └── ...
```

### Exporter les données

1. Dans Firestore, cliquer sur les 3 points ⋮ à côté de "games"
2. **Exporter la collection** pour télécharger en JSON

---

## Dépannage

### Problème : "Firebase n'est pas configuré"

**Symptôme** :
```
[Main] Firebase initialization FAILED: UnsupportedError: Firebase n'est pas configuré...
```

**Solution** :
```bash
flutterfire configure
```

---

### Problème : "No Firebase App '[DEFAULT]' has been created"

**Symptôme** : Crash au démarrage avec erreur Firebase.

**Solution** :
1. Vérifier que `Firebase.initializeApp()` est appelé en premier dans `main()`
2. Vérifier que `firebase_options.dart` contient de vraies valeurs

---

### Problème : Sync toujours en échec

**Symptôme** :
```
[Firebase] ERROR syncing game: ...
```

**Vérifications** :
1. Vérifier les règles Firestore (Étape 5)
2. Vérifier la connexion internet
3. Regarder le stack trace complet dans les logs

---

### Problème : "MissingPluginException"

**Symptôme** : Erreur sur connectivity_plus ou cloud_firestore.

**Solution** :
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

### Problème : Pods iOS qui ne s'installent pas

**Solution** :
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

---

### Commandes utiles de debug

```bash
# Vérifier l'état Firebase CLI
firebase projects:list

# Réinitialiser la config Flutter Firebase
flutterfire configure --force

# Nettoyer le projet
flutter clean && flutter pub get

# Logs détaillés Flutter
flutter run --verbose
```

---

## Structure des données Firestore

Chaque document dans `games/{gameId}` contient :

```json
{
  "gameId": "uuid-v4",
  "userId": "uuid-v4",
  "appVersion": "1.0.0",
  "platform": "android",
  "locale": "fr_FR",
  "deviceModel": "Pixel 6",
  "startedAt": "2026-01-09T14:30:00.000Z",
  "endedAt": "2026-01-09T14:45:00.000Z",
  "numberOfPlayers": 4,
  "numberOfTeams": 2,
  "totalWords": 40,
  "turnDuration": 60,
  "selectedCategories": ["nature", "celebrites", "musique"],
  "selectedDifficultyLevels": [1, 2, 3],
  "events": [
    {
      "word": "Lion",
      "eventType": "guessed",
      "timestamp": 1736430612345,
      "round": 1,
      "turn": 1,
      "teamId": "team-1",
      "playerId": "player-1",
      "durationMs": 4500
    }
  ],
  "wordMetadata": {
    "Lion": {
      "categoryId": "nature",
      "difficulty": 1
    }
  },
  "wordStats": {
    "Lion": {
      "totalTimesPassed": 0,
      "totalTimeMs": 4500,
      "rounds": {...}
    }
  },
  "syncedAt": "2026-01-09T14:45:05.000Z"
}
```

---

## Résumé des commandes

| Action | Commande |
|--------|----------|
| Se connecter à Firebase | `firebase login` |
| Configurer Firebase | `flutterfire configure` |
| Lancer l'app | `flutter run` |
| Filtrer les logs | `flutter run 2>&1 \| grep "\[Firebase\]"` |
| Nettoyer le projet | `flutter clean && flutter pub get` |
| Réinstaller pods iOS | `cd ios && pod install && cd ..` |

---

## Support

Si vous rencontrez des problèmes :

1. Vérifier les logs avec les tags `[Main]`, `[Firebase]`, `[Connectivity]`
2. Consulter la section Dépannage ci-dessus
3. Vérifier la Firebase Console pour les erreurs côté serveur
