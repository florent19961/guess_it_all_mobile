# Revue r1 — lane aide-tuto (Codex, arbitrée par l'orchestrateur)

Verdict : **NOT READY**.

## Findings

1. **MAJOR (règle 7)** — `lib/widgets/help/first_game_prompt.dart:14`, `lib/screens/rules_tutorial_screen.dart:19` : le sens de `guessItAll_tutorialSeen` glisse de « question posée » à « tuto vu ».
   **Arbitrage** : on garde le sens de la clé. Elle veut dire « onboarding des règles de première partie traité » : question posée **ou** tuto ouvert. Un ancien `true` reste valable (qui a répondu « Je connais déjà » ne revoit rien, c'est voulu). Un ancien `false` sur un téléphone sans partie ouvre le tuto (voulu aussi). Pas de clé nouvelle, pas de migration. La doc et les commentaires sont à corriger pour le dire exactement ; plus aucune ligne ne doit parler de « tuto vu ».
2. **MINOR** — `lib/screens/rules_tutorial_screen.dart:19` : le drapeau est écrit avant `Navigator.push`.
   **Arbitrage** : l'écrire une fois la route poussée, pour qu'un kill avant l'affichage ne saute pas le tuto pour toujours.

## Validé

- Voile en `PathFillType.evenOdd` : correct sur CanvasKit, HTML et mobile.
- Garde statique de `FiestaTutorialScreen.show()` et son test : validés (mutation OK).
