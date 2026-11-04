# Correctifs r1 — lane aide-tuto

| Finding | Décision | Preuve |
|---|---|---|
| 1. MAJOR — sens de `guessItAll_tutorialSeen` | **Corrigé** : le code ne change pas, seule la doc dit « onboarding des règles de première partie traité (question posée OU tuto ouvert) ». Il n'y a ni clé nouvelle ni migration, et plus aucune ligne ne parle de « tuto vu » pour cette clé. | `lib/widgets/help/first_game_prompt.dart:5-10` (doc de la classe), `lib/services/storage_service.dart:131-133` (doc de `hasSeenTutorial`), `lib/widgets/help/WIRING.md:85`, `lib/screens/rules_tutorial_screen.dart:16-18`, `docs/tracking_evolution.md` (entrée 2026-11-04) |
| 2. MINOR — drapeau écrit avant le push | **Corrigé** : `markTutorialSeen()` est appelé juste après `Navigator.push`, une fois la route en pile. Il garde le `Future` de fermeture, qui est rendu ensuite. | `lib/screens/rules_tutorial_screen.dart:21-26` |

Aucun test n'est ajouté : le finding 1 ne touche que la doc, et le finding 2 est un ordre d'appel trivial, qu'un kill entre le push et le premier frame ne permet pas de tester utilement.
