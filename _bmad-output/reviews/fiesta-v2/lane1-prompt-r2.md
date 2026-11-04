# Revue Fiesta v2 — lane 1 — round 2

**Tier : RISQUÉ.** Lecture seule. Même périmètre et même format que
`lane1-prompt-r1.md` (à relire pour l'objectif et les décisions). Rapport dans
`_bmad-output/reviews/fiesta-v2/lane1-review-r2.md`.

À lire :
- `lane1-patch-r2.diff` : le diff complet sur la merge-base avec `origin/main`, sans
  `_bmad-output`.
- `lane1-delta-r1-r2.diff` : seulement les corrections depuis r1.
- `lane1-review-r1.md` (tes findings) et `lane1-fix-r1.md` (décision et preuve par finding).

## Ce qu'il faut vérifier

1. **Fermeture des findings r1.** Chaque MAJOR est-il fermé par la correction indiquée, sans
   régression ? En particulier :
   - **M1** : la règle « cible `both` = règle de manche, cible `team`/`player` = cartouche » tient
     sur tous les chemins. Les chemins à couvrir sont le tirage, « Toujours », le stock, le
     1 parmi 3, le coup de pouce Auto, la continuation de fin de manche, le retour arrière et l'app
     tuée. Une instance `both` peut-elle encore porter une charge allumable, ou une cartouche
     s'appliquer sans activation ?
   - **M2** : les malus en réserve (`reserve: true`). Un lecteur de `fiesta.active` autre que
     `modifiersForTurn` les applique-t-il, les compte-t-il ou les affiche-t-il par erreur ? À
     vérifier : badges, analytics, récap, offres (`isUsefulOffer`), `_fiestaAfterTurn`,
     `plan.apply`.
   - **M4** : `hasUnreadableFiesta` est-il appliqué partout où une `GameState` relue pourrait
     redevenir Classique ?
2. **Résidus assumés** : M3 (Passe gratuite seulement « par manche ») et M5 (un seul
   brouillon). Sont-ils acceptables pour la lane 1, ou cachent-ils une perte de données ?
3. **Valeur des tests ajoutés et mutation** : test de règle de manche « Deux mots », test
   d'intégration `pick3Choices: 2`, snapshot v1 refusé, malus en réserve, ids des ensembles
   fournis.

Conclure par READY / NOT READY. Sévérités BLOCKER / MAJOR / MINOR / NIT, avec `fichier:ligne`.
