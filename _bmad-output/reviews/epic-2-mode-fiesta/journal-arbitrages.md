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
