# Journal d'arbitrages — retours de recette Florent du 2026-11-15

date · sujet · question · choix · raison · état

| 2026-11-15 | lot | Suivi sur le board (`sprint-status.yaml`) ? | Non : spec + journal, comme les lots de retours du 07/11 | Même pratique que les deux lots de retours précédents | appliqué |
| 2026-11-15 | ordre | Ordre du track `game_provider.dart` | L-PERSONNE → L-CACHE → L-TOMBE ; L-X2 et L-LOGO en parallèle | L-CACHE affiche des malus résolus par personne ; L-TOMBE réutilise l'écran de L-CACHE et le vivier de L-X2 | appliqué |
| 2026-11-15 | L-PERSONNE | Malus en attente écrit par la 1.4.0 sans `playerId` | Garde l'ancien comportement (prochain tour de l'équipe) | Règle 7 : la 1.4.0 est la première release Fiesta publique, des parties suspendues existeront | à valider |
| 2026-11-15 | L-CACHE | « Ce qui t'attend » quand rien de nouveau n'est à révéler | Pas d'écran, décompte direct comme aujourd'hui | L'avant-tour montre déjà tout le reste ; l'écran ne doit jamais être inutile (Florent) | à valider |
| 2026-11-15 | L-CACHE | App tuée sur « Ce qui t'attend » | L'écran est persisté et y revient (nouvelle valeur d'écran, ajout additif) | Revenir à l'avant-tour permettrait de réarmer en connaissant les malus | à valider |
| 2026-11-15 | L-TOMBE | Nouveau champ persisté de `FiestaRules` (fréquence) | Optionnel, omis à Jamais, `format` inchangé | Réglage validé par Florent dans la maquette ; même régime que les ajouts optionnels de l'epic 2 | à valider |
| 2026-11-15 | L-TOMBE | Joueur qui saute son tour après une cartouche tombée | Le remplaçant a son propre tirage | Un tirage par tour joué, sans relance pour le même joueur | à valider |
| 2026-11-15 | L-TOMBE | Ensemble fourni « Chaos » évoqué en V1 | Non créé | Absent des versions validées de la maquette | appliqué |
