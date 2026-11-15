# Revue d'ensemble — lot retours-2026-11-15 (diff cumulé)

Lot mergé sur main depuis 1b7c02e (spec) : PR #62 logo, #63 ×2, #64 malus par personne, #65 malus cachés + « Ce qui t'attend »
+ passe gratuite, #66 cartouches qui tombent (modèle/éditeur), #67 outillage suite, #68 cartouches qui tombent (branchement).
Spec : _bmad-output/specs/fiesta/retours-2026-11-15.md. Journal : _bmad-output/reviews/retours-2026-11-15/journal-arbitrages.md.
Chaque story a déjà eu sa revue. Ne re-relis PAS chaque story isolément : cherche les INVARIANTS TRANSVERSES, c.-à-d.
« la garantie posée par A tient-elle encore après le chemin ajouté par B ? ». Questions précises :
1. Résolution par personne (`resolvesAt`, #64) × masquage (`currentTeamModifiers`/`_receivedHidden`, #65) × cartouche tombée
   (`turn.drop`, `droppedMalus`, #68) : un malus reçu ou tombé peut-il fuir dans l'avant-tour, être compté deux fois, ou
   être perdu à tort (continuation, piège block_giver, remplaçant, retour arrière, app tuée sur screenTurnReveal) ?
2. Le tirage de la cartouche qui tombe lit-il les malus reçus EFFECTIFS du tour (résolus par personne) et non la vue masquée ?
3. Passe gratuite sous Interdit de passer (#65) × passe gratuite TOMBÉE (#68) × no_pass tombé : une passe, puis bloqué ?
4. ×2 (#63) : seuil appliqué sur tous les chemins (cartouches au hasard, défis, tombées), jamais le leader.
5. Fin de tour : `turn` (dont `drop`) et malus résolus/perdus nettoyés une seule fois, continuation comprise.
6. Partie suspendue écrite par la 1.4.0 (règle 7) : se relit et se joue (malus sans playerId, pas de `drop`, pas de
   `dropFrequency`, écran persisté connu).
7. Analytics : `WordEvent.modifiers` cohérent pour reçus, tombés, règles ; rien de doublé.
8. Docs (`lib/*/CLAUDE.md`, WIRING, aide) cohérentes entre elles après les 5 PR.
Format : rapport avec « Verdict : READY » ou « Verdict : NOT READY », findings BLOCKER/MAJOR/MINOR avec fichier:ligne et
preuve (scénario concret). Revue STATIQUE : ne lance ni test ni flutter.
