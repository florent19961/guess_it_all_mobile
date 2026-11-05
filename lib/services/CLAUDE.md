# services/

8 services singletons initialises dans `main.dart`. Chacun gere un aspect technique.

## Fichiers

| Service | Classe | Role |
|---------|--------|------|
| `storage_service.dart` | `StorageService` | Wrapper SharedPreferences : persistance settings, gameSession, gameState |
| `analytics_service.dart` | `AnalyticsService` | Tracking temps reel WordEvents, calcul stats, persistance locale. Retention 50 parties. Recovery des parties orphelines (crash). Contexte de chaque event (`WordEventContext`) fourni par l'appelant depuis l'état persisté, jamais deviné ; durée par mot (`_shownAt`, mémoire seule : après un kill, event terminal sans durée), `docs/ANALYTICS.md` |
| `user_service.dart` | `UserService` | userId persistant (UUID v4) + DeviceInfo (appVersion, platform, locale, deviceModel) |
| `word_history_service.dart` | `WordHistoryService` | Historique mots joues (mot→seenCount). Priorise les mots jamais vus via `selectWordsByPriority()` |
| `word_loader_service.dart` | `WordLoaderService` | Charge categories depuis JSON (assets/translations/). Cache en memoire. Methodes : `loadCategory()`, `getCategoriesMetadata()` |
| `connectivity_service.dart` | `ConnectivityService` | Detection reseau (wifi/mobile/ethernet) via connectivity_plus |
| `firebase_sync_service.dart` | `FirebaseSyncService` | Sync offline-first vers Firestore. Queue de games en attente, sync auto quand online |
| `audio_service.dart` | `AudioService` | Sons : ding (mot devine), whoosh (mot passe), gong (fin de tour, `end_of_turn.wav`) via audioplayers. `ding.wav` et `end_of_turn.wav` sont générés par `scripts/render_sounds.py` |
| `fiesta_ensemble_service.dart` | `FiestaEnsembleService` | Ensembles Fiesta : `load` / `create` / `update` (sur place) / `duplicate(ensemble)` (« Nom (2) », premier numéro libre parmi fournis + miens ; copie d'un fourni en fin de liste) / `delete` / `markUsed` (l'id peut être celui d'un ensemble fourni). Les ensembles **fournis** (`kProvidedEnsembles`) ne sont jamais écrits. Forme v1 (avant Fiesta v2) = illisible, ignorée et réécrite telle quelle. **Borne 10 tenue par le service**, modifications serialisees (file interne), quarantaine du blob illisible ou venu du futur, ensemble illisible ignore seul a la lecture et **reecrit tel quel** a chaque modification (jamais detruit) ; ces entrees illisibles **ne comptent pas** dans la borne de 10 (le blob peut en porter 10 + k) |

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
| `guessItAll_fiestaEnsembles` | FiestaEnsemble | Enveloppe versionnee `{ensembles: [{id, rules}], lastUsedId}` (story 2-3) |
