# lib/

Point d'entree de l'application Flutter "Guess It All".

## Fichiers

| Fichier | Role |
|---------|------|
| `main.dart` | Initialise Firebase, services singletons (WordLoader, WordHistory, Connectivity, FirebaseSync, Analytics), wrappe l'app avec `GameProvider` |
| `app.dart` | Widget racine `GuessItAllApp` : MaterialApp + `UpgradeAlert` (mise a jour forcee) + routing par `GameProvider.game.currentScreen` |
| `firebase_options.dart` | Config Firebase auto-generee par FlutterFire CLI (ne pas modifier manuellement) |

## Architecture

```
Provider (GameProvider) → Screens → Widgets
     ↓
  Services (singletons) → SharedPreferences / Firebase
     ↓
  Models (immuables, copyWith)
```

## Navigation

Pas de Navigator classique. L'ecran affiche est determine par `GameState.currentScreen` (string) dans le `GameProvider`. Le routing est un `switch` dans `app.dart`.

## Conventions

- Code en anglais, UI en francais
- Tous les services sont des singletons initialises dans `main.dart`
- State management via Provider uniquement
