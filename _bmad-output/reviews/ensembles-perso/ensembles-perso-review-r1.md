# Revue Codex r1 — ensembles-perso

> Copie des findings tels que relayés par la session principale (2026-11-04) ; le rapport
> brut du reviewer n'a pas été transmis à la lane.

**Verdict : NOT READY.** Les 4 choix tranchés seuls par la lane sont jugés sains.

1. **MAJOR** — retour système Android sans `PopScope` sur `players_screen.dart:487`,
   `teams_screen.dart:106`, `words_screen.dart:436` (préexistant, rendu visible par le nouveau
   parcours : Joueurs doit revenir aux ensembles en Personnalisé).
2. **MAJOR** — l'éditeur en ligne perd silencieusement les modifications non enregistrées
   (`fiesta_ensembles_screen.dart:120`, `:195`, `app.dart:100`) : « Modifier » sur B ou retour
   pendant l'édition de A ; sélectionner B laisse l'éditeur sur A alors que « Suivant » lancera B.
3. **MAJOR** — le test de non-régression contourne Paramètres : aucun test de la route
   Paramètres → ensembles (ni du « Continuer » de l'avertissement de mots).
4. **MINOR** — `lib/models/fiesta/fiesta_ensemble.dart:28` documente encore `onUse` ; la spec
   `_bmad-output/specs/fiesta/2-3-ensembles-stockage-editeur.md:126` garde l'ancien contrat.
