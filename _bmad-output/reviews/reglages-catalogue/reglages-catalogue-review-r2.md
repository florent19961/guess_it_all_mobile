# Revue Codex reglages-catalogue r2

Verdict Codex : NOT READY, un seul MAJOR documentaire.

- MAJOR — `docs/tracking_evolution.md:778` affirmait que la règle de famille s'applique à l'exécution d'une partie gelée ; faux : un `FiestaState` hérité est relu sans normalisation (`fiesta_state.dart:80`) et `round_transition.dart:96` ne filtre que ses instances actives. → **corrigé** : la doc dit qu'une partie de dev déjà gelée avec deux mimes les garde et les applique, couvert par la rupture pré-release ; la règle ne vaut que pour les nouveaux tirages.
- Validé : résidu pré-release et règle d'après-publication exacts ; plus de prétention de conserver le mime tiré ; bornes « autre langue » 1–2 et offre dès 2 (mutant `== 3` tué) ; bouton Réinitialiser à 48 px.

Arbitrage orchestrateur (3ᵉ tour) : correction de documentation seule, pas de code exécuté changé → READY.
