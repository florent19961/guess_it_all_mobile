# Journal d'arbitrages — epic-2 mode Fiesta (mode délégué)

Délégation explicite de Florent le 2026-11-03 : « avance tout droit jusqu'à la fin de l'epic, go pour clôturer les PR, pas de teach-back ». Une ligne par décision prise sans lui.

| Date | Story | Question | Choix | Raison | État |
|---|---|---|---|---|---|
| 2026-11-03 | 2-2 | Teach-back avant merge ? | Sauté | Consigne explicite de Florent | appliqué |
| 2026-11-03 | 2-3 / 2-4 | Lanes empilées sur la branche de 2-2 avant son merge | Oui, restack au merge | Paralléliser (demande Florent) ; types publics figés tôt | appliqué |
| 2026-11-03 | 2-4 | Merger 2-4 avant 2-3 (avec le bouchon d'écran d'ensembles) | Oui | 2-4 READY plus tôt ; 2-3 remplace le bouchon à son merge | appliqué |
| 2026-11-03 | 2-3 | Rattrapage on/off sans champ dans le modèle | Interrupteur UI : off = 5 valeurs à 0, on = valeurs Auto | Décision Florent « on/off + curseurs » sans toucher au format persisté | appliqué |
| 2026-11-03 | 2-3 | Modificateur d'id inconnu dans un ensemble lisible, perdu à la réécriture | Résidu assumé | Ids figés, pas de downgrade possible : seul un blob corrompu le déclenche | à valider |
| 2026-11-03 | 2-4 | Config Fiesta perdue si l'app est tuée avant un « Rejouer » depuis l'accueil | Reporté (notes_pour_plus_tard) | Cas rare, config en mémoire par décision Q10 | à valider |
| 2026-11-03 | UI kit | Briques visuelles de 2-8/2-11 préparées hors cœur, en parallèle | Lane dédiée, PR #11 | Paralléliser (demande Florent) sans toucher game_provider | appliqué |
| 2026-11-03 | UI kit | 2ᵉ round de revue pour un correctif d'une ligne (ValueKey par carte) | Mergé sans r2 | Correctif trivial, prouvé par le reviewer r1 | appliqué |
| 2026-11-03 | 2-5 | Tirage stocké ou recalculé ? | Recalculé depuis (gameId, manche), FNV-1a | Identique après undo/kill sans toucher les types 2-2 | appliqué |
| 2026-11-03 | 2-5 | Bug store : double tap « Manche suivante » saute M2 | Corrigé dans 2-5 (garde écran de transition) + test | Bug de machine à états visible en Classique | appliqué |
| 2026-11-03 | 2-5 | Mise à jour de l'app entre la transition et « Manche suivante » peut changer le tirage | Résidu assumé | Fenêtre de quelques secondes, upgrader ne s'affiche pas en pleine partie | à valider |
| 2026-11-03 | 2-6 / 2-7 | Lanes empilées sur des branches encore en revue | Oui, restack au merge | Paralléliser (demande Florent) | appliqué |
| 2026-11-03 | 2-6 | Nouveau champ `turnAllottedSeconds` dans GameState, écrit aussi en Classique | Accepté si optionnel en lecture (vérifié en revue) | Corrige le bug store du temps par mot ; ajout additif couvert par la décision d'epic « stocker la vraie durée » | à valider |
| 2026-11-03 | 2-6 | Résidu m3c (mutant non tué) | Résidu assumé | Coût de test disproportionné | appliqué |
