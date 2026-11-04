---
name: guessitall-difficulte-mots
description: Use when Florent wants to look at real-game data on word difficulty in Guess It All — "reclasser les mots", "quels mots sont mal classés", "temps moyen par difficulté", "décrochage entre niveaux", "la gaussienne des temps", "refais l'analyse des mots", "mets à jour la page difficulté des mots". Pulls the Firestore `games` collection read-only, aggregates per word and per level × round, and publishes (or republishes) the « Difficulté des mots » artifact page. NOT for editing the word files themselves (that is a normal story via guessitall-workflow, once Florent has decided).
---

# Guess It All — analyse de la difficulté des mots

Une page à jour pour que Florent juge le niveau des mots à partir des vraies parties. Il décide,
la skill ne modifie aucun fichier de mots.

## Ce que la page montre

Unité de mesure : **un mot dans une manche d'une partie**. Son temps est le **cumul de tous ses
affichages dans la manche** (passé puis repris, fin de tour puis repris…) jusqu'à « trouvé »
(règle Florent 2026-11-04).

- **Le décrochage par niveau** : pour chaque manche, la gaussienne ajustée sur les temps cumulés
  des mots trouvés de chaque niveau (1 Facile, 2 Moyen, 3 Difficile, 4 Expert), **mise à
  l'échelle de la part de mots trouvés**, la médiane en pointillé, et à droite une barre
  **« Jamais trouvés »** par niveau (passés ou restés à l'écran sans jamais être trouvés dans la
  manche). C'est ainsi que les passes entrent dans le graphique : une passe suivie d'une réussite
  allonge le temps cumulé, une passe sans réussite nourrit la barre. Tableau : mots joués, % jamais
  trouvés, affichages par mot, passes par mot, moyenne / médiane / écart-type. La manche 1
  (description libre) est celle qui mesure la difficulté.
- **Les mots joués** : tout mot trouvé ou passé au moins une fois (un seul passage suffit, choix
  Florent 2026-11-04), avec son niveau actuel (lu dans `assets/translations/words/fr/*.json`),
  ses affichages, passes et « jamais trouvé » en M1, son temps cumulé médian M1, et les signaux
  « Passé en M1 », « Jamais trouvé », « Lent » / « Rapide » (temps médian M1 au-dessus du
  3ᵉ quartile / en dessous du 1ᵉʳ quartile des mots de son niveau).

Règles de calcul (`analyze.py`) :
- **un mot trouvé en moins d'1 s cumulée est écarté de tout** (tap accidentel, règle Florent
  2026-11-04, constante `MIN_S`) ;
- mots personnalisés exclus (pas de niveau) ;
- un mot trouvé puis invalidé à la vérification ne compte pas comme trouvé ;
- un affichage sans durée ou plus long qu'un tour (app fermée ou en pause) retire le mot des
  temps mais le garde dans les comptes ;
- « jamais trouvé » inclut les parties abandonnées en cours de manche.

## Lancer

Clé lecture seule : `~/.secrets/gia-viewer.json` (compte de service Cloud Datastore Viewer).
🔴 **Ne jamais afficher, copier ni committer la clé ni `games.json`** : le repo est public et
`games.json` contient des identifiants d'appareils et de joueurs. Tout se passe dans le scratchpad.

```bash
SK=/home/florent19961/guess_it_all_mobile/.claude/skills/guessitall-difficulte-mots
OUT=<scratchpad>/mots && mkdir -p $OUT
python3 $SK/fetch_games.py ~/.secrets/gia-viewer.json $OUT/games.json
python3 $SK/analyze.py $OUT/games.json /home/florent19961/guess_it_all_mobile/assets/translations/words/fr $OUT/data.json
python3 $SK/build_page.py $OUT/data.json $OUT/difficulte-mots.html
```

`python3` sans `-I` (numpy n'est pas requis, mais `PyJWT` est dans le site utilisateur).

Puis publier `difficulte-mots.html` avec l'outil Artifact. **Republier sur la page existante**
pour garder le même lien : https://claude.ai/artifact/4rrwvzNAjKH48aNvVRhvmj (passer `url`,
après une lecture `action: "read"` si la page n'a pas été publiée dans cette conversation).

## Lire le résultat

Répondre à Florent en quelques lignes : nombre de parties et de mots, médianes M1 par niveau,
écart entre niveaux, part de « jamais trouvés », et les mots les plus signalés. Ne pas proposer de reclassement chiffré sans qu'il le demande.

## Faire évoluer

`template.html` porte toute la page (données injectées à la place de `__DATA__`).
`analyze.py` porte toutes les règles de calcul ; une nouvelle métrique s'y ajoute d'abord.
