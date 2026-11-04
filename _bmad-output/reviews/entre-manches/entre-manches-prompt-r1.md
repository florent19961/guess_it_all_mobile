# Revue — entre-manches r1 (tier standard)

Lis `_bmad-output/reviews/entre-manches/entre-manches-patch-r1.diff` (diff merge-base ; ne lance pas `git diff`). Lecture seule. Rapport dans `_bmad-output/reviews/entre-manches/entre-manches-review-r1.md`.

## Objectif (retour device Florent)
« Manche 1 terminée, manche 2, c'est ça la règle, et on clique sur suivant. » Affichage seul : aucune logique de jeu, aucun état persisté.

**Garder** : « Manche N terminée » ; carte sobre « Manche N+1 : <mode> » + règle (`roundModes`/`roundDescriptions`), sans emoji de fond ; « Commence : équipe · joueur fait deviner » ; temps reporté en une ligne avec la formulation d'avant la refonte #23 ; « Voir les N mots devinés » ; Fiesta : 1 parmi 3 (`PickThreeCard`, attente du choix) en carte pleine, tirage / rattrapage / coup de pouce chacun en une ligne sans perte d'info ; bouton « Manche N+1 » / « En attente du choix : X », Home, « ? », retour vérification.
**Retirer** : frise `_RoundTrack`, tuile « N mots reviennent dans le chapeau », astuce mémoire 🧠, emoji de fond.

## Décisions prises
- Formulation du report : avant #23 c'était exactement `Temps bonus conservé : ${turnBonusTime}s` (vérifiable : `git show 50b9191^:lib/screens/transition_screen.dart`, L213). Reprise telle quelle, placée juste sous « Commence : <équipe> » (c'est cette équipe qui reçoit le temps : `nextRound` ne change pas l'équipe courante).
- `CatchUpCard` / `AppBoostCard` remplacées par `CatchUpLine` / `AppBoostLine` ; `RoundDrawLine` ajoutée (`RoundDrawCard` reste pour l'avant-tour M1 de `game_screen`). Gabarit commun `FiestaInfoLine`. Les modificateurs restent des `ModifierBadge` (tap = explication).
- Animation d'entrée de la carte retirée (carte « sobre »).
- Aide : étape « La manche suivante » ne mentionne plus le nombre de mots du chapeau.

## Questions précises
1. Rien de perdu côté Fiesta ? Comparer chaque info des anciennes cartes (équipe, secondes ±, en tête/en retard, nature bonus/malus, force, nom du modificateur) aux nouvelles lignes. Ce qui a sauté volontairement : textes d'explication fixes (plafonds du rattrapage, « s'applique à toutes les équipes »). Acceptable ?
2. Wording du report : la ligne est-elle juste et non ambiguë ? Cas où `turnBonusTime > 0` mais l'équipe affichée n'est pas celle qui le reçoit ?
3. Cibles d'aide : `_catchUpKey` / `_appBoostKey` restent posées seulement quand la ligne est non vide ; `_nextRoundKey` sur la carte ; aucune clé orpheline ou cible disparue ? Texte d'aide cohérent avec l'écran ?
4. Mise en page : débordement possible (WidgetSpan badge dans Text.rich, titre long en Bangers 30) sur petit écran, Android et iOS ?
5. Code mort ou orphelins laissés par le diff ; docs (`lib/widgets/CLAUDE.md`, `lib/screens/CLAUDE.md`, `WIRING.md`) à jour ?

## Format attendu
Verdict READY / NOT READY, puis findings BLOCKER / MAJOR / MINOR avec `fichier:ligne` et preuve.
