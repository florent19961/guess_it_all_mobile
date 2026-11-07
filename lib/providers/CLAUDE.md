# providers/

Gestion d'etat centralisee via Provider.

## Fichier unique : `game_provider.dart`

`GameProvider` (ChangeNotifier, ~2020 lignes) : cerveau de l'application.

**Frontière** : le provider orchestre (mutations, navigation, persistance, analytics) ; les
règles Fiesta sont des fonctions pures de `lib/models/fiesta/` (passage de manche
`planRoundTransition`, effets du tour `modifiersForTurn`, état du tour typé `FiestaTurnState`).
Les ~400 lignes de getters Fiesta (modèle de lecture) restent ici pour l'instant : extraction
`FiestaView` reportée (`docs/notes_pour_plus_tard.md`).

### Responsabilites

- **Settings** : modification des parametres (equipes, joueurs, mots, duree, categories)
- **Joueurs/Equipes** : ajout, suppression, formation des equipes (manuelle/aleatoire)
- **Generation de mots** : mode aleatoire (avec cache metadata `_wordMetadataCache`) ou personnalise
- **Flux de jeu** : startGame, startTurn, markWordAsGuessed, passWord, validateWords, nextRound
- **Fiesta** : `startGame({FiestaRules? fiesta})` gele la config dans `GameState.fiesta` ; `startGame()` sans argument l'EFFACE (`clearFiesta`, le `copyWith` part de `_game`). Getter `isFiesta`. Tout l'etat Fiesta vit dans `GameState`, jamais dans des champs du provider (persistance + retour arriere)
- **Navigation** : changement d'ecran via `GameState.currentScreen`
- **Analytics** : tracking des evenements via `AnalyticsService`
- **Persistance** : sauvegarde/restauration etat via `StorageService`

### Points d'attention

- `_wordMetadataCache` est en memoire (non persiste). Si l'app est tuee, il est `null` au redemarrage. Un fallback `lookupWordsMetadata()` reconstitue les metadonnees depuis les categories.
- La navigation arriere est complexe : depend de l'ecran courant, du tour, et de l'existence de snapshots de validation.
- `_ensureWordsForPlayer()` conserve les mots existants d'un joueur si le compte est suffisant (meme apres changement de categories).
- **Durée du tour** : `turnTime` (composée par `composeTurnSeconds`) est lue par `startTurn` ET `startTurnTimer`. Ne jamais recalculer la durée ailleurs : l'avant-tour et le chrono divergeraient. `timeSpent` se mesure sur `turnAllottedSeconds`, pas sur le réglage.
- **Effets de tour Fiesta (2-8)** : `canPassWith(secondesAffichées)` est la **seule** garde de la passe (`passWord` ET le bouton de `turn_screen`), sur la pénalité **effective** (`currentPassPenalty`, 0 si `hasFreePass`) ; sous `no_pass`, `passWord` sort avant `onWordPassed`. **Un seul tour** : fin de manche + continuation en N+1. 🔴 **Règle de la continuation** (Fiesta v3) : `isContinuation` (dérivé de l'historique, pas de `turnBonusTime`) ; les règles de manche de N+1 s'y appliquent DIRECTEMENT (`currentTeamModifiers` = `modifiersForTurn` sur la manche courante), le temps reporté reste exact (+ 10 s seulement si `plus_10s` y est allumé ; un `minus_10s` déjà appliqué ne se réapplique pas), les effets one shot déjà dépensés (×2, passe gratuite, malus reçu) vivent jusqu'à la vraie fin du tour. 🔴 Fiesta v3.1 : la réserve y est complète, cartouches gagnées à l'instant comprises (`nextRound` écrit `earned` avant cet avant-tour) : bonus allumables et malus à infliger, annulables avant le départ, comme un tour normal. Une charge dépensée sur la partie précédente reste comptée une fois et ne se rallume pas (`déjà en cours ce tour`) ; un malus envoyé avant cette partie n'est plus annulable (`sentThisTurn` : manche d'envoi = manche courante). `validateWords` vide `fiesta.turn` et consomme les malus infligés à l'équipe, à la vraie fin seulement (pas dans la branche fin de manche). Continuation qui vide à elle seule le pool : `_fiestaAtRoundEnd` clôt son tour, la continuation suivante repart à vide. 🔴 **Report nul** (`timeRemaining <= 0` à la fin de M1 ou M2) : pas de continuation, `validateWords` traite une vraie fin de tour (`_fiestaAfterTurn`, rotation, pas de `turnBonusTime` ni de `pendingBonusTurnId`) et la manche suivante s'ouvre sur l'équipe suivante. `isContinuation` exige donc qu'aucune entrée n'existe dans la manche ; `continuingTeamId` est nul sans `pendingBonusTurnId`. M3 inchangée : la partie se termine.
- **Bonus à charge (2-9, Fiesta v3)** : ×2, passe gratuite, +10 s : une table `kChargeBonusKeys`, une implémentation (`_charge`, `_chargesLeft`, `_conflict`, `_setCharge`). Plus de plafond, allumer est refusé seulement si le bonus est incompatible avec un modificateur en jeu ou l'autre bonus allumé. Le stock vient de `FiestaState.cartridgesLeft` (ensemble + gagnées − dépensées, toutes manches), jamais d'une instance. `setDoublePoints` n'écrit que `armed` dans `fiesta.turn.charges` ; la charge se dépense dans `startTurnTimer` (`spent` + `chargesUsed`). `validateWords` passe `pointsMultiplier` à `resolveTurn` (pur). La continuation de fin de manche garde `spent` (même tour). `spentBonuses` = badges du tour ; `turnTime` compte le +10 s allumé ou dépensé (aperçu et chrono d'accord) ; sur un temps reporté, allumé seulement. `isBonusArmed` : encore annulable.
- **Cartouches au hasard (Fiesta v4)** : `startGame` écrit celles de M1 ; `_transitionPlan` (`planRoundTransition`) est recalculé sur l'état de fin de manche ; 🔴 seul `nextRound` écrit ensuite (`plan.apply` : règles de N+1, `fiesta.earned`, malus devenus impossibles rendus à l'envoyeur). Rien de persisté sur la transition : app tuée, retour arrière et correction de vérification ne peuvent ni doubler ni perdre une cartouche.
- **Fin de manche** : `validateWords` va toujours à `screenTransition`, M3 compris ; `nextRound` après M3 archive et va aux résultats.
- **Défis surprises (Fiesta v4)** : `nextRound` va à `screenChallenge` si `_challengeAfter` rend un plan ; `currentChallenge` relit le plan, `finishChallenge(winnerTeamId:)` écrit l'issue (`null` = passé) et va à `screenGame`. 🔴 Un défi terminé survit au retour arrière (`keepingChallengesOf` dans `restorePreValidationState`) : ni rejeu, ni doublon, ni perte de cartouche.
- **Blocages nommés (Fiesta v4)** : `inflictMalus(id, équipe, playerId:)`, le joueur se nomme à l'envoi. `block_guesser` : `blockedGuesser` au tour concerné, attend si son joueur fait deviner. 🔴 `block_giver` : `startTurnTimer` redirige vers `screenGiverBlocked` sans démarrer le chrono ni rien dépenser (`_pendingGiverBlock`, jamais sur une continuation) ; `confirmGiverBlock` (« Suivant ») est le seul à consommer : annule ce que le joueur avait allumé ou envoyé, le garde dans `fiesta.turn.replaced`, retire le blocage, décale la rotation (`fiesta.skips`, lu par `playerIndexAtTurn`). `reuseReplacedChoices` remet ce qui reste possible.
- **Deux mots à la fois** : retiré du jeu (2026-11-07). 🔴 Une partie relue avec ce bonus allumé ou dépensé continue à un mot : la cartouche ne joue plus, la carte B reste dans `remainingWords` et sort quand elle est trouvée ; `chargesUsed` et `earned` gardent leur `two_words` pour le récap (`test/providers/fiesta_two_words_legacy_test.dart`).
- **Ce tour / Réserve** : une cartouche = UN tour d'UNE équipe, stock pour toute la partie. `reserve` (`Cartridge` : restantes, raison du grisé) = les modificateurs où l'équipe a du stock, possibles dans la manche (un mime reste caché avant M3), continuation comprise ; `roundRulesThisTurn` / `receivedThisTurn` / `bonusesThisTurn` = la zone « Ce tour ». Bonus : `toggleBonus` → `armed`, dépensé dans `startTurnTimer`. Malus : `inflictMalus(id, cible)` pose une instance `fromTeamId` (portée tour) + un `ChargeUse` avec `target`, tout de suite ; 🔴 même malus déjà infligé à la cible (ou un malus qui ne s'y cumule pas : un seul mime) → message de refus, **rien consommé**. `sentThisTurn` / `cancelSent` : annulable seulement dans l'avant-tour de l'envoyeuse où il a été envoyé. `_fiestaAfterTurn` retire les malus infligés à l'équipe à la vraie fin de son tour, sauf les blocages qui attendent.

- **Dernier choix (Fiesta v3.1)** : `setPendingFiesta` et `restartWithSamePlayers` écrivent le choix dans `GameSettings` (`fiestaEnabled`, `_rememberFiestaChoice`). `_rememberedFiesta` le relit au démarrage et dans `startNewGame` : Classique = nul, une partie rejouée pas encore lancée (`replayFiesta`, écrit par `restartWithSamePlayers`, effacé par `startGame` et par tout `setPendingFiesta`), ou le dernier ensemble (`lastUsedId` ; supprimé ou illisible → Fiesta classique). Partie reprise : `pendingFiesta` = `fiesta?.rules`, sans toucher au dernier choix. Le tuto Fiesta n'est ouvert que par `_setMode`, donc jamais par une restauration.

### Dependances

Utilise `StorageService`, `AnalyticsService`, `UserService` (singletons).
- **Noms des joueurs** : `_savedNames` (`guessItAll_savedPlayerNames`) survit à `startNewGame`, `clearLocalStorage` et au retrait d'un joueur par le réglage. Seul `updatePlayer` avec un nom effacé ou corrigé en retire un. `nextSavedName` remplit les joueurs ajoutés par l'écran Joueurs.
