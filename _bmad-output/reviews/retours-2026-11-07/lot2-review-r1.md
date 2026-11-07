# Revue lot 2 — retours-reveal, r1

## Verdict : READY

## Findings

### BLOCKER

Aucun.

### MAJOR

Aucun.

### MINOR

Aucun.

## Contrôles effectués

- D9 est respectée : aucune bulle ni effet sonore de cartouche ne subsiste, la musique et son gong restent sur leur chemin dédié, et `ScoreTimeline.events` a disparu sans retirer `chargesUsed`, son sérialiseur, le récapitulatif ou les badges de statistiques (`entryOfCharge` reste utilisé par `stats_screen.dart`). Aucun appelant des méthodes audio retirées ne reste.
- Le graphe réserve sa colonne à droite : les courbes se terminent avant elle et les étiquettes partent toujours de `headX + _labelOffset`. Les équipes à score nul et les égalités passent par le même empilement déterministe ; la partie sans historique continue d'aller directement aux résultats. Le chemin du piège ne modifie plus que la datation conservée pour les stats, pas la série des scores. Le retour système conserve le `PopScope` qui marque la révélation comme vue ; les animations réduites posent immédiatement la fin, sans démarrer la musique.
- `_stackLabels` ne peut plus chevaucher deux étiquettes lorsque la somme des hauteurs et des trois espaces tient dans `top..bottom` : sa passe avant impose chaque plancher, puis sa passe arrière chaque plafond. À `_minChartHeight = 100`, la zone utile vaut `100 - 26 - 8 = 66 px` ; quatre lignes minimales de `9 × 1,25 = 11,25 px` plus trois écarts de `7 px` occupent exactement ces 66 px.
- La moyenne sur sept échantillons d'une fenêtre de `min(0,045, 1-progress)` est pure et déterministe. Elle couvre environ 0,2 s de la durée de 4,5 s, puis se contracte jusqu'à zéro à la fin. Le croisement transitoire des étiquettes lors d'un échange d'ordre est donc bien celui explicitement accepté par D9 ; tenter de les ré-empiler après la moyenne introduirait un saut.
- Le cache `_fittedFor` ne devient pas périmé dans les chemins de l'écran : les libellés sont capturés à l'initialisation, et un changement de taille ou de `MediaQuery.textScaler` fournit un nouveau painter. Le repli grande police élargit d'abord la colonne, borne celle-ci à la moitié de l'écran, puis réduit/coupe les libellés sans dépasser la zone empilable.
- Le test ajouté exerce réellement les mutations annoncées : décalage horizontal, tri et bornes sont couverts par les placements à quatre équipes (y compris l'ordre final croisé), et le seuil est couvert des deux côtés avec cinq puis six joueurs. Les tests de flux restants couvrent animations réduites, grande police, égalité, absence d'historique et le piège. Aucun `CLAUDE.md` ni skill local ne décrit encore le comportement D9 antérieur.

Tests non exécutés, conformément à la consigne de revue en lecture seule.
