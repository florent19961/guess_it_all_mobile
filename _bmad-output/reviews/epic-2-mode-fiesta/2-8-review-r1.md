# Revue r1 — story 2-8 « Effets de tour » (tier risqué)

Reviewer : Opus (lecture seule). Patch : `2-8-patch-r1.diff` (base `4e548a2`). Worktree à `23017d4`.

## Verdict : READY

Aucun BLOCKER, aucun MAJOR. Trois MINOR, dont un (m1) à trancher **avant 2-10** : la correction
d'une ligne supprime aussi le drapeau `turnOver`.

Suite complète : 185 tests verts. `test/providers/fiesta_turn_effects_test.dart` : 4/4 verts.

## Vérifications (code lu avant la spec)

| Point | Résultat |
|---|---|
| `no_pass`, provider | `passWord` sort sur `!canPassWith(...)` (`game_provider.dart:737`) **avant** `onWordPassed` : aucun événement, état intact (test : `toJson` identique). |
| `no_pass`, bouton | `turn_screen.dart:263` lit la même garde `canPassWith`, avec le libellé « Passer (bloqué) ». Le seul écart possible (`timeRemaining` du ticker contre `displayedSecondsAt(now)`) existait déjà ; une passe gratuite ne l'élargit pas, puisqu'elle a une pénalité de 0. |
| `free_pass` ×N | La pénalité effective passe par `clock.applyPenalty(passPenalty)`, donc par TurnClock, sans aucun widget. Le compteur ne s'incrémente que si `usesFreePass`. Les charges de plusieurs instances s'additionnent (`freePassAllowance`). |
| Le compteur au fil du jeu | Il est persisté à chaque passe (`_saveGameState`) et relu après un kill (testé). Il est vidé dans les deux branches de `validateWords`. Un undo le restaure, car il vit dans le snapshot `GameState.toJson()` (testé). Une passe gratuite ne peut pas être rendue deux fois dans un même tour, ni une pénalité sautée. **Exception** : la continuation, voir m1. |
| Portée tour | L'instance est consommée en fin de tour réelle, pour l'équipe qui joue (`both` ou `teamId`). Elle est conservée en fin de manche, puis tombe à la fin de la continuation (testé). Un undo depuis la transition la restaure par le snapshot. `turnBonusTime` à 0 : la continuation de 0 s passe quand même par `validateWords` avec `turnOver: true`, donc l'instance est consommée et ne franchit aucune manche seule. |
| block_guesser | Il est sans effet à 2 joueurs ou moins, et ne vise jamais celui qui fait deviner : `setBlockedGuesser` refuse ce choix (testé). La rotation n'est pas touchée. Le sélecteur est un `showDialog`, donc la route du jeu n'est plus courante et la garde double tap de main s'applique. Fermer le sélecteur rend `null` : on reste sur l'avant-tour. Un retour système pendant l'annonce équivaut à « Compris », ce qui est acceptable. Le sélecteur défile (`Flexible` + `SingleChildScrollView` dans `AppModal`). |
| À l'envers | Seul l'`AutoSizeText` du tour change. `currentWord`, l'analytics, l'historique, la vérification et les résultats gardent le mot en clair. |
| Règle 7 | Les compteurs vivent sous la clé existante `fiesta.turn`. Lecture tolérante : `is int` et `is String`, et un id inconnu rouvre le sélecteur. En Classique, `copyWith(fiesta: null)` et `_fiestaAfterTurn` renvoient null : aucune clé `fiesta` n'est écrite. `kCurrentSchemaVersion` n'est pas touché (reste à 1). Un blob de la version store charge : `turn` absent donne `{}`. |
| Classique | Pénalité = réglage. `canPassWith` = la garde d'avant. Le libellé est identique, car `hasFreePass` vaut false. |
| Analytics | `no_pass` : aucun événement. Une passe gratuite enregistre `passed` avec les tags de 2-7 (`_lastModifiers` posé à `onWordShown`). |
| Diff `game_provider` | Ciblé : environ 100 lignes dans une section « EFFETS DE TOUR », et 3 branchements (`passWord`, et les deux branches de `validateWords`). |

## Mutation testing (12 mutants, tous tués)

| Mutant | Tué par |
|---|---|
| M1 `!passBlocked` retiré de `canPassWith` | test `no_pass` |
| M2 garde de `passWord` sans `no_pass` | test `no_pass` (`toJson` identique) |
| M3 compteur non incrémenté | test `free_pass` |
| M4 compteurs non vidés en fin de tour | test `free_pass` |
| M5 fin de manche = `turnOver: true` | test portée tour |
| M6 aucune consommation de portée tour | test portée tour |
| M7 pas de pénalité gratuite | test `free_pass` (AC3) |
| M8 `canBlockGuesser` à `> 1` | test `block_guesser` |
| M9 celui qui fait deviner non exclu | test `block_guesser` |
| M10 pénalité Classique à 0 (`<=`) | `turn_time_fiesta_test` (Classique) et test `free_pass` |
| M11 `setBlockedGuesser` sans validation | test `block_guesser` |
| M12 compteur effacé sur une passe payante | test `free_pass` |

Les 4 tests mordent tous, et aucune assertion n'est décorative. AC7 (Classique) n'a pas de test
dédié, mais M10 montre que `turn_time_fiesta_test` couvre la pénalité Classique. Les mutants ont
tous été annulés (`git status` propre).

## Findings

### m1 — MINOR (latent, à trancher avant 2-10) : deux définitions du « tour » à la continuation

`lib/providers/game_provider.dart:1021`, avec `_fiestaAfterTurn` en `:1260`.

**Scénario.** En fin de manche, `_fiestaAfterTurn(turnOver: false)` vide `fiesta.turn` mais garde
les instances de portée tour, au motif que « le tour n'est pas fini ». La même équipe poursuit en
N+1 avec la même instance et un compteur remis à 0.

- `block_guesser` (portée tour, posé par 2-10) : l'équipe visée finit la manche pendant ce
  tour-là. En continuation, le sélecteur se **rouvre** et les adversaires choisissent une seconde
  fois, éventuellement un autre joueur, avec une seconde annonce.
- Une `free_pass` de portée tour ×2 donnerait 2 + 2 passes gratuites pour un seul tour. Une passe
  gratuite est alors « rendue » une fois.

Aucun écrivain de portée tour n'existe aujourd'hui : il n'y a donc pas de bug visible en r1.

**Correction (code judo).** Retenir une seule définition : la continuation **est** le même tour.
Il suffit de retirer `fiesta: _fiestaAfterTurn(turnOver: false)` de la branche fin de manche (la
ligne `:1021`). `_fiestaAfterTurn` perd alors son paramètre booléen et ne sert plus qu'à la vraie
fin de tour.

Contrepartie, à faire acter par le lead : une `free_pass` de **manche** N+1 hérite en continuation
du compteur de N. Cela reste cohérent avec « les N premières passes du tour », Q5 étant respecté.
Le test de portée tour reste valable ; ajouter un `expect(freePassesUsed, …)` après `nextRound`.

### m2 — MINOR : un kill entre le choix et l'annonce perd l'annonce

`lib/screens/game_screen.dart:302-307`.

**Scénario.** Le choix est persisté par `setBlockedGuesser` **avant** `announce`. Si l'app est
tuée pendant l'annonce, au retour `needsBlockedGuesser` vaut false : le tour démarre sans
qu'aucune annonce « X ne répond pas » ne soit jamais montrée à l'équipe.

**Correction.** Afficher `announce` avec le `Player` choisi, et n'appeler `setBlockedGuesser`
qu'**après** son retour. Un kill pendant l'annonce redemande alors le choix, ce qui est sans
conséquence puisque rien n'a démarré. Aucun nouveau drapeau n'est nécessaire.

### m3 — MINOR (qualité, grille thermo-nucléaire) : prédicats dupliqués et enveloppes minces

**Prédicat « il reste une passe gratuite ».** Le même calcul existe en 3 endroits :

- `effectivePassPenalty` (`turn_effects.dart:22`) ;
- `usesFreePass` (`game_provider.dart:740`) ;
- `hasFreePass` (`turn_screen.dart:261`).

Correction : un getter provider `bool get hasFreePass => freePassesUsed < freePasses;`, avec
`currentPassPenalty => hasFreePass ? 0 : _settings.passPenalty`. Cela supprime
`effectivePassPenalty`, une fonction à 3 paramètres pour un ternaire.

**Recherche d'un modificateur.** Elle est écrite de trois façons :

- `isPassBlocked` dans `turn_effects.dart` ;
- `isWordReversed` en ligne (`:1211`) ;
- `block_guesser` en ligne (`:1220`).

Correction : un seul `bool _has(String id) => currentTeamModifiers.any((m) => m.catalogId == id);`.
`turn_effects.dart` se réduit alors aux clés et à `freePassAllowance`, et `canBlockGuesser`
(`> 2`) peut rester comme règle nommée.

### NIT

- `game_provider.dart` passe à 1704 lignes. Il dépassait déjà 1k : ce n'est pas causé par 2-8,
  mais la section « EFFETS DE TOUR » serait une bonne candidate à l'extraction.
- Fermer le sélecteur puis retaper « Commencer le tour » rejoue `MalusReveal`. C'est acceptable.
- Sous `no_pass` combiné à `free_pass`, interdit par Q14 mais possible via des offres de 2-10 si
  les exclusions ne couvrent pas les portées mixtes : le libellé « gratuit » s'affiche sous
  « Passer (bloqué) ».

## Mécanisme sur-construit dont la racine est un choix de spec

Le drapeau `turnOver` et l'exception « fin de manche » de `_fiestaAfterTurn` existent pour un
écrivain qui n'est pas encore là (2-10). Ils viennent de l'interprétation (2) : « continuation =
même tour pour les instances, nouveau tour pour les compteurs ». Une définition unique (m1)
supprime à la fois le drapeau et l'incohérence.
