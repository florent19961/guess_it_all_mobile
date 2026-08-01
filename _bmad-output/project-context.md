# Project Context for AI Agents — digest transverse (Guess It All)

Chargé par les workflows BMad. C'est un **digest de règles d'implémentation**, pas une doc
d'architecture : le détail vit dans `CLAUDE.md`, les `lib/*/CLAUDE.md` et `docs/`.

## ⚠️ NON-NÉGOCIABLES (violation = bug chez les joueurs)

1. **Rétro-compat des données joueur.** L'app est **publiée** et `upgrader` **force** la mise à
   jour → une release atteint tout le parc. Tout changement de **forme** d'une clé
   `guessItAll_*` (`SharedPreferences`) exige une migration explicite. Jamais de « ça repartira de
   zéro » : les données sont sur les téléphones, pas dans une base resettable.
2. **Une partie en cours doit survivre à l'imprévu** — app backgroundée, écran verrouillé, appel
   entrant, process tué. Soit l'état se recharge, soit il est invalidé proprement ; jamais un crash
   ni un état à moitié écrit.
3. **Le scoring est la sortie observable du produit.** Un point faux ruine une soirée et n'est pas
   rattrapable après coup. Toute modification du calcul se couvre par un test qui **dérive** la
   propriété, pas qui énumère des cas.
4. **Parité Android ↔ iOS.** Pas de `Platform.isIOS` (`dart:io`) — utiliser `defaultTargetPlatform`
   + `kIsWeb` (`package:flutter/foundation.dart`).

## Points de collision structurels (parallélisme)

Un seul track en vol à la fois sur chacun :

| Fichier | Pourquoi |
|---|---|
| `lib/providers/game_provider.dart` | Provider unique : porte la logique de partie ET le tracking |
| `lib/models/game_state.dart`, `game_settings.dart` | Forme de l'état ; un champ ajouté casse le `copyWith` de l'autre lane |
| `lib/services/storage_service.dart` + clés `guessItAll_*` | Schéma persisté |
| `lib/services/analytics_service.dart`, `firebase_sync_service.dart` | Contrat d'events |

Les écrans (`lib/screens/*`) sont en général parallélisables entre eux.

⚠️ **Couplage non évident** : la priorisation des mots (`WordHistoryService`) est incrémentée par
`AnalyticsService.endGame()`. Toucher au chemin analytics touche donc *aussi* la sélection des
mots.

## Conventions d'implémentation

- Modèles **immuables** + `copyWith()`. Persistance automatique après chaque mutation d'état.
- Services = **singletons**. État global = **Provider** (un seul : `GameProvider`).
- Code en **anglais**, messages UI en **français**.
- Offline-first : écrire en local d'abord, synchroniser ensuite (queue `guessItAll_pending_sync`).

## Tests

- `scripts/run-full-suite.sh` = plancher de gate (`dart format` + `flutter analyze` + `flutter test`).
- 🔴 **Tout run de tests passe par `scripts/with-test-slot.sh`** (sémaphore RAM machine-global,
  partagé avec WasReal).
- ⚠️ **État actuel : aucun test ne tourne** (`test/widget_test.dart` = scaffold Flutter cassé). Le
  TDD du pipeline est bloqué tant que ce n'est pas soldé — cf. `docs/notes_pour_plus_tard.md`.

## Process

- Tronc = `main` ; PR de story → base `main` ; release = **tag** `vX.Y.Z+N`, jamais une branche.
- Gate ② = **1 reviewer adversarial spec-aveugle + Codex cross-LLM + consolidation**. Gate ① sauté
  par défaut (le pare-feu est le `grill-me` amont).
- Merge **uniquement sur go explicite de Florent**.
