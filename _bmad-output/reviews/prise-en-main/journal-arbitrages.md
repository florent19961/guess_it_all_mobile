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
| 2026-11-04 | revues | Codex hors quota (jusqu'à 3 h) | Revues r1 du kit d'aide et du branchement faites par Opus | Consigne Florent : Opus en repli quand Codex est hors quota | appliqué |
| 2026-11-04 | aides | Aide 1re partie si la 1re partie est abandonnée ou tuée | Liée au gameId de la 1re partie, état persisté ; une autre partie clôt la 1re partie | Aide automatique seulement pendant la vraie 1re partie, une fois par joueur | appliqué |
| 2026-11-04 | aides | Détection « a déjà joué » | Décidée une seule fois au 1er lancement de cette version, puis figée | Une partie abandonnée écrit aussi l'historique de mots | appliqué |
| 2026-11-04 | scores masqués | Le classement Fiesta reste déductible (ordre du 1 parmi 3, secondes de rattrapage) | Accepté | Inhérent au mécanisme de rattrapage | à valider |
| 2026-11-04 | revues | Codex toujours hors quota | Revue thermo-nucléaire finale faite par Opus | Consigne Florent (repli Opus) | appliqué |
| 2026-11-04 | noms d'équipes | Phrases incorrectes avec « Les … » (« choix de Les Mimes Fous ») | On garde les noms ; phrases au deux-points (« En attente du choix : X », « Passe le téléphone : X ») ; « menée » → « en retard » | Accord impossible avec un pluriel, noms voulus par Florent | à valider |
| 2026-11-04 | revue finale | 10 MINOR (code dupliqué, provider à 2 110 lignes, widgets à usage unique…) | Différés après la release | Aucun n'affecte le joueur | appliqué |
