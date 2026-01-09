# Guess It All - Systeme Analytics

## Vue d'ensemble

Le systeme analytics permet de tracker en temps reel tous les evenements d'une partie et de calculer des statistiques detaillees par mot, par joueur et par equipe. Ces donnees sont persistees localement et preparees pour une future integration cloud.

## Architecture

```
lib/
├── models/
│   ├── word_event.dart      # Evenements atomiques (shown, guessed, passed, etc.)
│   ├── word_stats.dart      # Statistiques agregees (WordMetadata, WordRoundStats, WordStats)
│   └── game_analytics.dart  # Conteneur principal (GameAnalytics, DeviceInfo)
├── services/
│   ├── analytics_service.dart  # Singleton de tracking et persistance
│   └── user_service.dart       # Gestion identite utilisateur et device
└── providers/
    └── game_provider.dart   # Integration du tracking dans le flux de jeu
```

## Modeles de donnees

### WordEvent

Evenement atomique sur un mot pendant le jeu.

```dart
class WordEvent {
  final String eventId;       // UUID v4 unique
  final String word;          // Le mot concerne
  final WordEventType eventType;  // shown | guessed | passed | expired | invalidated
  final int timestamp;        // Unix timestamp en millisecondes
  final int round;            // 1, 2 ou 3
  final int turn;             // Numero du tour
  final String teamId;        // Equipe qui jouait
  final String playerId;      // Joueur qui jouait
  final String gameId;        // ID de la partie
  final int? durationMs;      // Temps depuis affichage (null pour 'shown')
}
```

**Types d'evenements :**

| Type | Description |
|------|-------------|
| `shown` | Mot affiche a un joueur |
| `guessed` | Mot devine avec succes |
| `passed` | Mot passe (skip) |
| `expired` | Temps ecoule avec ce mot affiche |
| `invalidated` | Mot invalide lors de la verification |

### WordMetadata

Metadonnees d'un mot pour une partie.

```dart
class WordMetadata {
  final String word;
  final String? categoryId;    // ID categorie (null si mode personnalise)
  final int? difficulty;       // Niveau 1-3 (null si mode personnalise)
  final String? submittedBy;   // Player ID (mode personnalise uniquement)
  final String? language;      // 'french' | 'international'
}
```

### WordRoundStats

Statistiques d'un mot pour une manche specifique.

> **Regle importante** : A chaque manche, TOUS les mots doivent etre devines exactement 1 fois. Un mot peut etre passe plusieurs fois, mais sera forcement devine pour terminer la manche.

```dart
class WordRoundStats {
  final int round;                // 1, 2 ou 3
  final int timesPassed;          // Nombre de fois passe AVANT d'etre devine
  final int totalTimeMs;          // Temps cumulatif (tous les pass + devine)
  final int guessTimeMs;          // Temps pris par l'equipe qui a devine
  final String guessedByTeamId;
  final String guessedByPlayerId;
  final int guessedInTurn;
  final List<PassEvent> passEvents;  // Detail de chaque pass
}
```

**Calcul du temps total :**
```
totalTimeMs = sum(passEvents[].durationMs) + guessTimeMs
```

### WordStats

Statistiques agregees d'un mot sur une partie complete (3 manches).

```dart
class WordStats {
  final String word;
  final WordMetadata metadata;
  final List<WordRoundStats> roundStats;  // 3 elements (M1, M2, M3)

  // Getters agreges
  int get totalTimesPassed;      // Total pass sur 3 manches
  int get totalTimeMs;           // Temps cumule sur 3 manches
  double get avgTotalTimeMs;     // Moyenne par manche
  int get totalGuessTimeMs;      // Somme des temps de devine
  double get avgGuessTimeMs;     // Moyenne temps devine
  bool get isHighlyPassed;       // >= 5 pass total
}
```

### GameAnalytics

Conteneur principal pour les analytics d'une partie.

```dart
class GameAnalytics {
  // Identifiants
  final String gameId;            // UUID v4 de la partie
  final String userId;            // UUID v4 persistant de l'utilisateur

  // Metadonnees contextuelles
  final String appVersion;        // "1.2.3"
  final String platform;          // "android" | "ios" | "web" | ...
  final String locale;            // "fr_FR"
  final String? deviceModel;      // "Pixel 7" | "iPhone 14"

  // Timestamps
  final DateTime startedAt;
  final DateTime? endedAt;

  // Configuration de la partie
  final int numberOfPlayers;
  final int numberOfTeams;
  final int totalWords;
  final int turnDuration;
  final List<String> selectedCategories;
  final List<int> selectedDifficultyLevels;

  // Donnees brutes
  final List<WordEvent> events;
  final Map<String, WordMetadata> wordMetadata;

  // Stats agregees (calculees a la fin)
  final Map<String, WordStats> wordStats;
}
```

---

## Services

### UserService

Singleton gerant l'identite utilisateur.

```dart
class UserService {
  // Recupere ou cree l'userId persistant (UUID v4)
  Future<String> getUserId();

  // Recupere les infos device/app
  Future<DeviceInfo> getDeviceInfo();

  // Genere un nouveau gameId unique
  String generateGameId();
}
```

**Cles de stockage :**
- `guessItAll_userId` : UUID persistant de l'utilisateur

### AnalyticsService

Singleton gerant le tracking et la persistance.

```dart
class AnalyticsService {
  // Lifecycle
  Future<void> startGame({...});   // Demarre le tracking
  Future<void> endGame();          // Termine et sauvegarde

  // Tracking en temps reel
  void onWordShown(String word, int round, int turn, String teamId, String playerId);
  void onWordGuessed(String word);
  void onWordPassed(String word);
  void onWordExpired(String word);
  void onWordInvalidated(String word);

  // Persistance
  Future<void> saveCurrentGame();
  Future<List<GameAnalytics>> loadAllGames();
  Future<void> pruneOldGames(int keepCount);
}
```

**Cles de stockage :**
- `guessItAll_analytics_index` : Liste des gameIds
- `guessItAll_analytics_{gameId}` : JSON de GameAnalytics

**Retention :** 50 dernieres parties (configurable)

---

## Flux de tracking

### Sequence d'evenements

```
1. Debut de partie (startGame)
   └─> Creer GameAnalytics avec gameId unique
   └─> Initialiser wordMetadata pour tous les mots

2. Nouveau mot affiche (startTurnTimer, markWordAsGuessed, passWord)
   └─> WordEvent(type: 'shown', timestamp: now)
   └─> Memoriser shownTimestamp pour calcul duree

3. Mot devine (markWordAsGuessed)
   └─> WordEvent(type: 'guessed', duration: now - shownTimestamp)

4. Mot passe (passWord)
   └─> WordEvent(type: 'passed', duration: now - shownTimestamp)

5. Temps ecoule (endTurn)
   └─> WordEvent(type: 'expired', duration: turnDuration)

6. Validation (validateWords)
   └─> WordEvent(type: 'invalidated') pour chaque mot invalide

7. Fin de partie (endGameAndGoHome)
   └─> Calculer WordStats agrégées
   └─> Persister GameAnalytics complet
```

---

## Exemples concrets

### Exemple 1 : Mot passe 2 fois puis devine

**Scenario :** Le mot "Elephant" est passe par 2 equipes avant d'etre devine.

```
Tour 3 (Equipe A, Paul):
  - Elephant affiche
  - Passe apres 4.2s

Tour 4 (Equipe B, Marie):
  - Elephant affiche
  - Passe apres 6.1s

Tour 5 (Equipe A, Julie):
  - Elephant affiche
  - Devine apres 3.5s
```

**Evenements generes :**

```json
[
  {"eventType": "shown",   "word": "Elephant", "turn": 3, "teamId": "A", "playerId": "paul"},
  {"eventType": "passed",  "word": "Elephant", "turn": 3, "teamId": "A", "playerId": "paul", "durationMs": 4200},
  {"eventType": "shown",   "word": "Elephant", "turn": 4, "teamId": "B", "playerId": "marie"},
  {"eventType": "passed",  "word": "Elephant", "turn": 4, "teamId": "B", "playerId": "marie", "durationMs": 6100},
  {"eventType": "shown",   "word": "Elephant", "turn": 5, "teamId": "A", "playerId": "julie"},
  {"eventType": "guessed", "word": "Elephant", "turn": 5, "teamId": "A", "playerId": "julie", "durationMs": 3500}
]
```

**WordRoundStats resultant (pour manche 1) :**

```json
{
  "round": 1,
  "timesPassed": 2,
  "totalTimeMs": 13800,      // 4200 + 6100 + 3500
  "guessTimeMs": 3500,
  "guessedByTeamId": "A",
  "guessedByPlayerId": "julie",
  "guessedInTurn": 5,
  "passEvents": [
    {"turn": 3, "teamId": "A", "playerId": "paul", "durationMs": 4200},
    {"turn": 4, "teamId": "B", "playerId": "marie", "durationMs": 6100}
  ]
}
```

### Exemple 2 : Structure GameAnalytics complete

```json
{
  "gameId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "123e4567-e89b-12d3-a456-426614174000",
  "appVersion": "1.2.3",
  "platform": "android",
  "locale": "fr_FR",
  "deviceModel": "Samsung Galaxy S23",
  "startedAt": "2024-01-15T14:30:00.000Z",
  "endedAt": "2024-01-15T15:15:00.000Z",
  "numberOfPlayers": 6,
  "numberOfTeams": 2,
  "totalWords": 40,
  "turnDuration": 60,
  "selectedCategories": ["7eme_art", "geographie", "celebrites"],
  "selectedDifficultyLevels": [1, 2, 3],
  "events": [...],
  "wordMetadata": {
    "Paris": {"word": "Paris", "categoryId": "geographie", "difficulty": 1, "language": "french"},
    "Titanic": {"word": "Titanic", "categoryId": "7eme_art", "difficulty": 2, "language": "international"}
  },
  "wordStats": {
    "Paris": {
      "word": "Paris",
      "metadata": {...},
      "roundStats": [
        {"round": 1, "timesPassed": 0, "totalTimeMs": 2100, "guessTimeMs": 2100, ...},
        {"round": 2, "timesPassed": 1, "totalTimeMs": 5400, "guessTimeMs": 2200, ...},
        {"round": 3, "timesPassed": 0, "totalTimeMs": 1800, "guessTimeMs": 1800, ...}
      ]
    }
  }
}
```

---

## Statistiques disponibles

### Par mot (WordStats)

| Metrique | Description |
|----------|-------------|
| `totalTimesPassed` | Nombre total de pass sur 3 manches |
| `totalTimeMs` | Temps cumule total (pass + devine) |
| `avgTotalTimeMs` | Moyenne par manche |
| `totalGuessTimeMs` | Somme des temps de devine uniquement |
| `avgGuessTimeMs` | Moyenne temps de devine |
| `isHighlyPassed` | Indicateur de difficulte (>= 5 pass) |

### Par partie (GameAnalytics)

| Metrique | Description |
|----------|-------------|
| `durationSeconds` | Duree totale de la partie |
| `totalEvents` | Nombre d'evenements enregistres |
| `totalPasses` | Nombre total de pass |
| `totalGuessed` | Nombre total de mots devines |
| `hardestWord` | Mot avec le plus de temps total |
| `mostPassedWord` | Mot le plus passe |
| `fastestWord` | Mot devine le plus rapidement |

### Agregations disponibles

```dart
// Mots les plus difficiles
List<WordStats> getHardestWords({int limit = 10});

// Mots les plus passes
List<WordStats> getMostPassedWords({int limit = 10});

// Mots les plus rapides
List<WordStats> getFastestWords({int limit = 10});

// Stats par categorie
Map<String, int> getStatsByCategory();

// Stats par difficulte
Map<int, int> getStatsByDifficulty();
```

---

## Preparation cloud

Le systeme est concu pour faciliter une future integration cloud :

### Identifiants uniques

- **userId** : UUID v4 persistant cree au premier lancement
- **gameId** : UUID v4 unique pour chaque partie
- **eventId** : UUID v4 unique pour chaque evenement

### Metadonnees contextuelles

- Version de l'application
- Plateforme (Android, iOS, Web, Windows, macOS, Linux)
- Locale de l'utilisateur
- Modele du device

### Format d'export

Toutes les donnees sont serialisables en JSON via `toJson()` et peuvent etre envoyees a une API REST ou stockees dans une base NoSQL.

---

## Guide d'implementation

### Integration dans un nouvel ecran

```dart
// Recuperer le service
final analytics = AnalyticsService();

// Verifier si une partie est en cours
if (analytics.isTracking) {
  // Acceder aux donnees courantes
  final currentGame = analytics.currentGame;
  final wordStats = analytics.computeWordStats();
}

// Charger l'historique des parties
final allGames = await analytics.loadAllGames();
```

### Ajout d'un nouveau type d'evenement

1. Ajouter le type dans `WordEventType` enum
2. Creer la methode de tracking dans `AnalyticsService`
3. Appeler la methode au bon endroit dans `GameProvider`

### Modification de la retention

```dart
// Dans AnalyticsService
static const int defaultRetentionCount = 50;  // Modifier ici

// Ou appeler manuellement
await analytics.pruneOldGames(100);  // Garder 100 parties
```

---

## Dependances

```yaml
dependencies:
  uuid: ^4.5.1              # Generation UUID v4
  device_info_plus: ^11.2.0 # Info device (model, OS)
  package_info_plus: ^8.1.2 # Info app (version)
```
