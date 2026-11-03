# Revue 2-11 Deux mots à la fois — r1

Tier **risqué** ① (machine à états : pool, fin de manche, continuation) + ② (scoring ×2,
passe gratuite) + ⑤ (analytics : durée par mot) + ⑥ (expiration). Lire `2-11-patch-r1.diff`
(base = `6816b43`, sommet de 2-10 cœur, lui-même sur 2-9 : le patch ne contient que 2-11).
Briques déjà sur main : `FiestaWordCard`, `TwoWordsLayout` (verrou 0,3 s, `ValueKey(mot)`).

Sources : `_bmad-output/specs/fiesta/2-11-deux-mots-a-la-fois.md` (AC1-AC9, pièges),
`epic-fiesta.md` (Q8, table d'incompatibilités), maquette `two_cd` … `two_verif`.

## Interprétations prises (à challenger)

1. **Carte B dans `fiesta.turn`**, pas dans `GameState` (règle 7 : clés additives optionnelles
   du blob Fiesta seulement) : `twoWords` (`armed`/`spent`, mêmes valeurs que le ×2),
   `secondWord` (carte B), `secondExpiredWord` (B à l'expiration). Absentes = un seul mot. La
   carte A reste `currentWord`, `expiredWord` reste le mot A expiré.
2. **Pas d'indicateur sur `HistoryEntry`** (la story le demandait) : c'est la forme de
   `guessItAll_gameState` au premier niveau → hors règle 7 sans accord. Le tag `two_words` des
   événements porte l'information.
3. **Le mot visé est un argument** : `markWordAsGuessed([mot])`, `passWord([mot])`, mot A par
   défaut (Classique : appels sans argument, chemin inchangé). Un mot qui n'est plus à l'écran
   est ignoré (tap périmé).
4. **Remplaçant** (`drawOtherCard`, pur) : 1ᵉʳ mot du pool mélangé ≠ l'autre carte ; pool
   épuisé → les passés du tour (sauf l'autre carte) sont recyclés, comme pour un mot seul ;
   rien → l'autre carte reste seule, **en tête** (A ← B). Ensuite, la logique d'un mot seul
   reprend telle quelle (y compris « passer le dernier mot le fait revenir » et la vraie fin de
   manche avec temps reporté).
5. **Carte B tirée dans `startTurnTimer`** après la dépense de la charge, continuation de fin de
   manche comprise (`spent` survit à la fin de manche, même tour) ; déjà présente = gardée.
6. **`endTurn`** déplace B vers `secondExpiredWord` (ne touche rien si B absente : second
   `endTurn` idempotent) ; `validateWords` passe `[expiredWord, secondExpiredWord]` à
   `resolveTurn(expiredWords:)` ; la branche fin de manche retire `secondExpiredWord` (la
   branche normale vide `turn`).
7. **`effectiveRemainingWordsCount`** soustrait le nombre de cartes à l'écran. Le bouton Passer
   d'une carte est donc grisé quand il n'y a aucun autre mot (comme aujourd'hui pour un mot
   seul), même si la maquette `two_last` le montre actif.
8. **Q8** : `doublePointsCapped` compte « deux mots » allumé et `twoWordsCapped` compte le ×2
   allumé ; `turnModifiers` exclut `two_words` (charge non activée), badge et tag à part.
9. **Analytics** : `_lastShownWord/_lastShownTimestamp` → `Map<String,int> _shownAt`. Classique :
   un seul mot à la fois, donc même sortie. Après un kill, les cartes à l'écran perdent leur
   `shown` (événements suivants abandonnés), comme aujourd'hui pour le mot seul.
10. **UI** : annonce = carte sous l'interrupteur sur l'avant-tour (comme la maquette `two_cd`),
    pas une route plein écran. Pas d'écran intermédiaire « Temps écoulé » (`two_end`) : on va à
    la vérification comme aujourd'hui, avec une carte par mot expiré (toggle existant).
11. `two_words` reçoit `defaultCharges: 1` (sinon 0 charge en Auto et dans les ensembles neufs).
12. Tests : provider uniquement (consigne de lane), pas d'ajout dans `turn_resolution_test.dart`
    (AC4 ×2 couvert au niveau provider) ; adaptation mécanique des 3 asserts `expired*`.

## Questions précises

- Un chemin peut-il afficher deux fois le même mot, perdre un mot, ou laisser un mot trouvé
  dans le pool ? (recyclage avec l'autre carte déjà passée puis recyclée ; pass de la carte A
  quand le pool = {A, B} ; fin de manche dans `markWordAsGuessed` avec B encore là — censée
  impossible, à vérifier.)
- `secondWord` / `secondExpiredWord` périmés : `nextRound`, retour arrière depuis le tour
  suivant, app tuée sur le compte à rebours, double `endTurn`.
- Score : ×2 et passe gratuite consommée une seule fois par passe ; B validé compté une fois.
- Analytics : un événement peut-il partir sans `shown` ou avec la durée d'un autre mot ? La sortie
  Classique est-elle strictement identique (test figé `legacy` + `fiesta_analytics_test`) ?
- Mutation testing sur `test/providers/fiesta_two_words_test.dart` (4 tests). Mutants tués
  localement : garde « dernier `shown` » rétablie, `drawOtherCard` sans exclusion de l'autre
  carte, B non déplacée à l'expiration, `secondExpiredWord` non retiré en fin de manche.

Format attendu : findings BLOCKER / MAJOR / MINOR avec `fichier:ligne`, puis verdict READY / NOT
READY.
