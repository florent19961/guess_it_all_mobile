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
| 2026-11-03 | 2-7 | Revue r2 après un fix test+doc seul ? | Clôture vérifiée par l'orchestrateur, pas de 2ᵉ reviewer | Aucun code de prod changé, mutants M10/M11 tués | appliqué |
| 2026-11-03 | 2-7 | HistoryEntry.modifiers (listé dans la story) | Non ajouté | Aucun AC ne l'exige ; changerait la forme de la partie en cours | à valider |
| 2026-11-03 | 2-7 | Récap : rattrapage accordé même si non consommé | Accepté | Jugé acceptable en revue | à valider |
| 2026-11-03 | 2-8 | block_guesser « tiré pour tous » (Q15) alors que 2-5 l'exclut du tirage symétrique | Reste offre seule (via 2-10 : 1 parmi 3 / coup de pouce), jamais tiré ni fixé pour tous ; Q15 sans objet | Un blocage de joueur n'a pas de sens symétrique ; aucun code à changer | à valider |
| 2026-11-03 | 2-10 kit | Moins de 3 offres de la bonne force (avant M3, « forte » = block_guesser seul) | Force stricte, on propose ce qui existe ; 0 offre → l'équipe est sautée | Fidèle à la spec ; compléter avec la force voisine serait un ajout | à valider |
| 2026-11-03 | 2-10 kit | Co-leaders | Aucun malus proposé, les co-leaders ne choisissent pas | Pas de « tête » unique à viser | à valider |
| 2026-11-03 | 2-10 kit | Coup de pouce Auto et block_guesser | Jamais donné par l'app | Personne n'a choisi, donc personne pour désigner le joueur bloqué | appliqué |
| 2026-11-03 | 2-8 | Un « tour » = tour de fin de manche + sa continuation ? | Oui, une seule définition : compteurs et instances « tour » vivent jusqu'à la vraie fin de la continuation | Sinon block_guesser rouvre le choix et une passe gratuite serait rendue en plein tour | appliqué |
| 2026-11-03 | 2-8 | Effet de bord : une passe gratuite « manche » de N+1 hérite du compteur de N pendant la continuation | Résidu assumé | Cas rare (passe gratuite + fin de manche en plein tour) | à valider |
| 2026-11-03 | 2-10 kit | Table de force des modificateurs (légère / moyenne / forte) | Calée sur l'exemple de la maquette (moyenne = mot compte double, deux mots, interdit de passer, dessiner), marquée « à recalibrer » | Réglage d'équilibrage, à ajuster après une vraie partie | à valider |
| 2026-11-03 | 2-10 kit | Force exacte vide (aucun bonus « fort » : une équipe très menée n'aurait rien, ou seulement block_guesser) | Révisé : on descend d'un cran (forte → moyenne → légère) avant de sauter l'équipe | Sinon l'équipe la plus menée est celle qui reçoit le moins d'aide | à valider |
| 2026-11-03 | 2-10 kit | Offre ou cadeau identique à un modificateur déjà sur la cible | Exclu (même catalogId déjà sur la cible) | Carte sans effet | appliqué |
