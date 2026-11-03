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
- **Effets de tour Fiesta (2-8)** : `canPassWith(secondesAffichées)` est la **seule** garde de la passe (`passWord` ET le bouton de `turn_screen`), sur la pénalité **effective** (`currentPassPenalty`, 0 si `hasFreePass`) ; sous `no_pass`, `passWord` sort avant `onWordPassed`. **Un seul tour** : fin de manche + continuation en N+1. 🔴 **Règle de la continuation** (epic fix) : `isContinuation` (dérivé de l'historique, pas de `turnBonusTime`) ; elle joue avec les effets de N (`currentTeamModifiers` = `modifiersForTurn` sur la manche logique N), jamais ceux de N+1 (tirage, choix, cadeaux, charges), qui commencent au premier vrai tour de chaque équipe ; aucune charge ne s'y allume. `validateWords` vide `fiesta.turn` et consomme les instances de portée **tour** qui ont pesé sur le tour, à la vraie fin seulement (pas dans la branche fin de manche) ; à la fin d'une continuation, les instances de N partent. `malusToReveal` = premier VRAI tour (jamais la continuation).
- **Mot compte double (2-9)** : Bonus à charge (×2, deux mots) : une table `kChargeBonusKeys`, une implémentation (`_charge`, `_chargesLeft`, `_capped`, `_setCharge`). `setDoublePoints` n'écrit que `armed` dans `fiesta.turn.charges` ; la charge se dépense dans `startTurnTimer` (`spent` + `chargesUsed`). `validateWords` passe `pointsMultiplier` à `resolveTurn` (pur). La continuation de fin de manche garde `spent` (même tour), sans charge de N+1. `turnModifiers` = badges / tags analytics sans la charge non activée.
- **1 parmi 3 / coup de pouce (2-10)** : offres (`offersFor`) et cadeaux (`appBoostPreview`) recalculés sur la transition, jamais stockés ; seuls les choix vont dans `fiesta.offerChoices` (`chooseOffer`, refusé hors tour). 🔴 `nextRound` refuse tant que `nextChooserId` n'est pas nul. 🔴 Un seul plan pur `planRoundTransition` (tirage + cadeaux + choix + rattrapage + ce qui survit) : aperçu (`nextRoundModifiers`, `appBoostPreview`, `catchUpPreview`) et application de `nextRound` (`plan.apply`) lisent le même.
- **Deux mots à la fois (2-11)** : même interrupteur que le ×2 (`setTwoWords`, `_setCharge`, dépense dans `startTurnTimer`). Carte A = `game.currentWord`, carte B = `fiesta.turn.secondWord` (tirée au départ, continuation comprise) ; 🔴 les deux restent dans `remainingWords`. `markWordAsGuessed(mot)` / `passWord(mot)` visent une carte (mot plus à l'écran = ignoré) ; seule elle est remplacée, par `drawOtherCard` (≠ l'autre carte, recyclage des passés hors l'autre carte) ; plus aucun autre mot → l'autre carte reste seule en tête, et la logique d'un mot seul reprend. `endTurn` déplace B dans `fiesta.turn.secondExpiredWord`, que `resolveTurn(expiredWords:)` dépouille ; la branche fin de manche le retire (`afterRoundEnd`). Q8 : chaque interrupteur compte l'autre bonus allumé.
- **Rattrapage Fiesta** : `catchUpPreview` (transition, calculé sur les scores) → `nextRound` le pose dans `fiesta.catchUpDue` → `startTurnTimer` le consomme au premier tour non-continuation de l'équipe.

### Dependances

Utilise `StorageService`, `AnalyticsService`, `UserService` (singletons).
