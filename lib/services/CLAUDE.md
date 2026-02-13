# services/

8 services singletons initialises dans `main.dart`. Chacun gere un aspect technique.

## Fichiers

| Service | Classe | Role |
|---------|--------|------|
| `storage_service.dart` | `StorageService` | Wrapper SharedPreferences : persistance settings, gameSession, gameState |
| `analytics_service.dart` | `AnalyticsService` | Tracking temps reel WordEvents, calcul stats, persistance locale. Retention 50 parties. Recovery des parties orphelines (crash) |
| `user_service.dart` | `UserService` | userId persistant (UUID v4) + DeviceInfo (appVersion, platform, locale, deviceModel) |
| `word_history_service.dart` | `WordHistoryService` | Historique mots joues (mot→seenCount). Priorise les mots jamais vus via `selectWordsByPriority()` |
| `word_loader_service.dart` | `WordLoaderService` | Charge categories depuis JSON (assets/translations/). Cache en memoire. Methodes : `loadCategory()`, `getCategoriesMetadata()` |
| `connectivity_service.dart` | `ConnectivityService` | Detection reseau (wifi/mobile/ethernet) via connectivity_plus |
| `firebase_sync_service.dart` | `FirebaseSyncService` | Sync offline-first vers Firestore. Queue de games en attente, sync auto quand online |
| `audio_service.dart` | `AudioService` | Sons : ding (mot devine), whoosh (mot passe), klaxon (fin de tour) via audioplayers |

## Cles SharedPreferences

| Cle | Service | Contenu |
|-----|---------|---------|
| `guessItAll_settings` | Storage | JSON GameSettings |
| `guessItAll_session` | Storage | JSON session (joueurs, equipes) |
| `guessItAll_gameState` | Storage | JSON GameState complet |
| `guessItAll_userId` | User | UUID v4 |
| `guessItAll_analytics_index` | Analytics | Liste gameIds |
| `guessItAll_analytics_{gameId}` | Analytics | JSON GameAnalytics |
| `guessItAll_pending_sync` | FirebaseSync | Liste gameIds en attente |
| `guessItAll_word_history` | WordHistory | Map mot→seenCount |
