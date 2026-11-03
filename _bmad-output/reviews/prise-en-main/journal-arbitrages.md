# Journal d'arbitrages — refonte « prise en main » (mode délégué, Florent 2026-11-04)

date · sujet · question · choix · raison · état

| 2026-11-03 | rejeu | Rejouer depuis l'historique avec une partie suspendue | Confirmation (AppConfirmDialog) ; sans partie en cours, direct | Action destructive | appliqué |
| 2026-11-03 | rejeu | Réglage archivé hors bornes ou inconnu | Snapshot ignoré → repli (noms, nb de mots, durée si dans les bornes) | Ne jamais planter les curseurs | appliqué |
| 2026-11-03 | noms d'équipes | Liste | 30 noms tout public ; « Mains Baladeuses » → « Mains Agiles », « Indices Foireux » → « Indices Farfelus » | Tout public | appliqué |
| 2026-11-03 | noms d'équipes | Changer le nombre d'équipes dans Paramètres | Retire les noms (recréation des équipes, comme avant) | Comportement existant | à valider |
| 2026-11-03 | aides | Joueurs existants (store) | Au démarrage : historique de mots ou de parties non vide → tuto et aide 1re partie marqués vus | Pas d'aide imposée aux anciens joueurs | appliqué |
| 2026-11-03 | aides | Aides Fiesta automatiques | Non, seulement « ? » ; tuto Fiesta 3 cartes automatique à la 1re partie Fiesta | Décision Florent (pas de voile auto) | appliqué |
| 2026-11-03 | aides | « ? » des écrans de réglage Fiesta | Rouvre le tuto Fiesta | Pas de contenu propre à ces écrans | appliqué |
| 2026-11-03 | aides | « ? » de l'Historique vide | Ne fait rien | Rien à montrer | à valider |
| 2026-11-03 | scores masqués | Carte 1 parmi 3 de la transition | Pas de force d'offre affichée (« Menée · offre X » seulement sur l'écran de choix) | La force réelle peut être un cran en dessous | appliqué |
| 2026-11-04 | transition | État « Qui a gagné ? » après M3 | Retiré : la fin de M3 va directement aux résultats, qui font la révélation | Pas de nouvel état dans la machine à états | appliqué |
| 2026-11-04 | transition | « Commence : équipe · joueur » | Équipe et joueur courants (nextRound ne les change pas) | Même valeur que l'avant-tour suivant | appliqué |
