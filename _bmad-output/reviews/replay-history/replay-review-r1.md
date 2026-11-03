# Revue statique — replay-history r1

**Verdict : NOT READY**

Revue **statique uniquement** du patch fourni `replay-patch-r1.diff`. Aucun
exécutable Flutter/Dart ni aucun test n'a été lancé.

## Findings

### BLOCKER — Un `setup` corrompu mais bien typé est accepté et peut faire crasher l'écran Paramètres

**Emplacements :** `lib/models/game_setup_snapshot.dart:36-56`,
`lib/screens/settings_screen.dart:450-481`, `lib/widgets/common/app_slider.dart:49-54`.

**Scénario :** une entrée de `guessItAll_game_results` contient par exemple
`setup.settings.totalWords: 101` (ou `turnDuration: 0`, `passPenalty: -1`).
`GameSettings.fromJson` et `GameSetupSnapshot.tryFromJson` l'acceptent car les
types sont corrects. Rejouer restaure ensuite cette valeur ; ouvrir « Avancés »
passe une valeur hors de `[min, max]` à `Slider`, qui lève en debug et n'offre
aucune garantie de rendu sûr en release. Un `wordChoice` inconnu est également
accepté : aucun choix n'est alors sélectionné dans le toggle.

Cela viole directement le contrat demandé : un `setup` corrompu doit être
abandonné, puis le replay doit employer le fallback, sans crash.

**Correctif :** valider sémantiquement le snapshot au même boundary que son
parsing : mode de mots connu, bornes de `totalWords`, `turnDuration` et
`passPenalty`, difficultés autorisées, et stratégie explicite pour les
catégories disparues (filtrage documenté ou snapshot abandonné). Au moindre
échec, retourner `null`. Ajouter des tests avec des valeurs bien typées mais
hors bornes/enum inconnu, et vérifier le fallback de `replayFromHistory`.

### MAJOR — Les tests ne verrouillent pas les deux chemins destructifs demandés

**Emplacements :** `test/providers/replay_from_history_test.dart:119-170`,
`test/screens/history_screen_test.dart:47-90`,
`test/screens/players_screen_test.dart` (absent).

**Scénario :** le test Fiesta appelle directement `replayFromHistory`; il ne
couvre donc ni « Annuler » (la partie suspendue doit rester intacte), ni
« Valider » depuis la carte, ni l'effet analytics/word-history de l'abandon.
Il ne peut pas détecter une régression qui omet `endGame`, le double-appelle,
ou incrémente deux fois les mots. Aucune régression ne protège non plus le
contrat métier « en Aléatoire, les mots ne sont jamais montrables ».

**Correctif :** ajouter un test ciblé du dialogue Historique avec une partie
suspendue (Annuler immuable, Valider remplace), en vérifiant l'analytics
persistée et le compteur de mots exactement une fois ; ajouter un test de route
pour confirmer qu'un mode aléatoire ne monte jamais `WordsScreen` (y compris
avec un `currentEditingPlayerId` présent). Ce ne sont pas des widget tests
cosmétiques : ils protègent une confirmation destructive et le secret des mots.

### MINOR — Un nom aléatoire n'est pas clairement tout public

**Emplacement :** `lib/utils/team_names.dart:21`.

**Scénario :** « Les Mains Baladeuses » est une expression couramment associée
aux attouchements ; elle ne respecte pas sûrement l'exigence de noms familiaux
pour un jeu mobile.

**Correctif :** remplacer ce libellé par une alternative sans connotation (par
exemple « Les Mains Agiles »). Les 30 noms restent alors distincts et la forme
persistée ne change pas.

### MINOR — La confirmation est recopiée au lieu d'utiliser le contrat commun

**Emplacements :** `lib/screens/history_screen.dart:110-157`,
`lib/widgets/common/app_confirm_dialog.dart:42-64`.

**Scénario :** la nouvelle carte ajoute à nouveau une modale Annuler/Valider
faite à la main, alors que le projet possède `AppConfirmDialog`, précisément
pour centraliser la sémantique « fermeture = refus ». Cette duplication ajoute
un second chemin à maintenir pour une action destructive.

**Correctif :** appeler `await AppConfirmDialog.show(...)` puis lancer le
replay seulement si le résultat est `true`, ou extraire un unique helper de
confirmation conservant exactement le style `AppModal` requis par l'écran
d'accueil.

## Vérifications demandées

| Point | Conclusion statique |
|---|---|
| Archive store sans `setup` | OK : `GameResult.tryFromJson` laisse `setup` à `null`; `replayFromHistory` reprend noms/composition, `totalWords` et `turnDuration`, et reste Classique. |
| `setup` optionnel/tolérant | Partiel : les erreurs de structure/type sont absorbées, mais le finding BLOCKER couvre les valeurs sémantiquement invalides. |
| Schéma et autres clés locales | OK : `kCurrentSchemaVersion` reste 1; seul `setup`, champ additif de `GameResult`, est écrit dans `guessItAll_game_results`. Les noms d'équipe ne changent que des valeurs existantes. |
| Firestore | OK : `FirebaseSyncService` sérialise uniquement `GameAnalytics`; le patch ne modifie ni ce modèle ni son payload. |
| Replay, Fiesta, mots et état suspendu | OK à la lecture : joueurs/équipes sont recréés, mots vidés, Fiesta va dans `_pendingFiesta`, puis `restartWithSamePlayers` ferme une analytics en cours une seule fois avant d'effacer le `gameState`. Le reset préalable évite que la Fiesta suspendue écrase celle de l'archive. |
| Mots aléatoires cachés | Le seul appel applicatif vers `screenWords` est conditionné par `!isRandom`; l'ID d'édition n'est pas persisté. Le badge est non cliquable et sans chevron. La garantie mérite néanmoins le test MAJOR ci-dessus. |
| Noms d'équipe | OK hors finding MINOR : `createTeams` est bien appelé au changement de nombre d'équipes, tire des noms distincts; le replay reconstruit directement les noms archivés et conserve donc leur composition. |
| Rubric thermo-nucléaire / focus provider | Le nouveau modèle et le tirage de noms sont dans les bons modules; l'orchestration de replay relève du provider. `game_provider.dart` était déjà au-delà de 1 000 lignes (le patch ne franchit pas ce seuil). La duplication de confirmation est le seul écart structurel clair dans le diff. |

## Valeur des tests ajoutés

Les tests de snapshot typé, du fallback d'archive ancienne, de la restauration
des équipes/réglages et du passage Fiesta en attente sont ciblés et non
redondants avec `test/services/game_history_test.dart`, qui vérifie surtout la
rétention et la robustesse du service d'historique. Leur lacune significative
est celle signalée ci-dessus : ni valeurs sémantiquement corrompues, ni
confirmation/analytics, ni invariant de masquage des mots ne sont épinglés.
