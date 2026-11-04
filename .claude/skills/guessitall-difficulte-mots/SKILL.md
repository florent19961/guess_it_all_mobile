---
name: guessitall-difficulte-mots
description: Use when Florent wants to look at real-game data on word difficulty in Guess It All — "reclasser les mots", "quels mots sont mal classés", "temps moyen par difficulté", "décrochage entre niveaux", "la gaussienne des temps", "refais l'analyse des mots", "mets à jour la page difficulté des mots". Pulls the Firestore `games` collection read-only, aggregates per word and per level × round, and publishes (or republishes) the « Difficulté des mots » artifact page. NOT for editing the word files themselves (that is a normal story via guessitall-workflow, once Florent has decided).
---

# Guess It All — analyse de la difficulté des mots

Une page à jour pour que Florent juge le niveau des mots à partir des vraies parties. Il décide,
la skill ne modifie aucun fichier de mots.

## Ce que la page montre

- **Le décrochage par niveau** : pour chaque manche, la gaussienne ajustée sur les temps « affiché
  → trouvé » de chaque niveau (1 Facile, 2 Moyen, 3 Difficile, 4 Expert), la médiane en pointillé,
  et un tableau moyenne / médiane / écart-type / % trouvés / % passés. La manche 1 (description
  libre) est celle qui mesure la difficulté ; en manches 2 et 3 les mots sont déjà connus.
- **Les mots joués** : tout mot trouvé ou passé au moins une fois (un seul passage suffit, choix
  Florent 2026-11-04), avec son niveau actuel (lu dans `assets/translations/words/fr/*.json`),
  et les signaux « Passé en M1 », « Lent » / « Rapide » (temps médian M1 au-dessus du 3ᵉ quartile /
  en dessous du 1ᵉʳ quartile des mots de son niveau).

Règles de calcul (`analyze.py`) : mots personnalisés exclus (pas de niveau) ; un mot trouvé puis
invalidé à la vérification ne compte pas ; une durée absente ou plus longue qu'un tour est écartée
(et comptée dans la note de la page).

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
écart entre niveaux (le temps sépare peu les niveaux, le taux de passe sépare davantage), et les
mots les plus signalés. Ne pas proposer de reclassement chiffré sans qu'il le demande.

## Faire évoluer

`template.html` porte toute la page (données injectées à la place de `__DATA__`).
`analyze.py` porte toutes les règles de calcul ; une nouvelle métrique s'y ajoute d'abord.
