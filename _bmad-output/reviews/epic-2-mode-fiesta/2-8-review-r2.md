# Revue r2 — story 2-8 « Effets de tour »

Reviewer : Opus, en lecture seule. Tip : `ab60d0d`. Patch : `2-8-patch-r2.diff`. Fix : `2-8-fix-r1.md`.

## Verdict : READY

Aucun BLOCKER, aucun MAJOR, aucun nouveau MINOR.

- Suite complète : 185 tests verts.
- `flutter analyze` : 0 erreur. Les seules infos relevées dans les fichiers touchés sont
  `withOpacity` et l'import `foundation` de `game_provider`, toutes antérieures à 2-8.

## m1 — un seul tour : corrigé

La branche fin de manche de `validateWords` (`game_provider.dart:1016-1021`) ne touche plus à
`fiesta`. `_fiestaAfterTurn()` n'est plus appelé qu'à la vraie fin de tour (`:1052`), et il n'a
plus de paramètre booléen.

| Point | Résultat |
|---|---|
| Continuation | Compteurs, devineur bloqué et instance de portée tour franchissent `nextRound`, puisque `_fiestaForRound` ne retire que la portée **manche** de N. Ils tombent à la fin de la continuation. Testé avec `freePassesUsed == 1`, `blockedGuesser` conservé et `needsBlockedGuesser` faux. |
| block_guesser | Le sélecteur ne se rouvre pas en continuation (assertion `needsBlockedGuesser` faux). |
| Fin de tour normale | Remet tout à zéro (test `free_pass` : le compteur revient à 0). |
| Undo | Le snapshot porte `fiesta` en entier : le retour depuis la transition ou depuis N+1 rend l'état d'avant validation (test : le compteur vaut 2). |
| Kill | Le compteur est persisté à chaque passe et relu au redémarrage (testé). |
| Contrepartie acceptée | Une `free_pass` de **manche** N+1 hérite en continuation du compteur de N. C'est conforme à la décision du lead, et documenté dans `_fiestaAfterTurn` et dans `providers/CLAUDE.md`. |
| Cas limites | Une continuation qui finit elle aussi N+1 reste le même tour jusqu'en N+2. C'est cohérent avec « un seul tour ». En fin de M3, les compteurs restent posés, ce qui est sans effet puisque la partie est terminée (même comportement qu'en r1 pour les instances). |

## m2 — corrigé

`BlockedGuesser.pick` rend le `Player`. `setBlockedGuesser` n'est appelé qu'après `announce`,
derrière la garde `mounted` / `currentScreen` (`game_screen.dart:300-318`).

- Un kill pendant l'annonce redemande le choix.
- Fermer le sélecteur (`null`) fait rester sur l'avant-tour.
- La garde double tap est inchangée.

## m3 — corrigé

- `hasFreePass` est désormais la seule source, lue par `currentPassPenalty`, `passWord`
  (`usesFreePass`) et le bouton.
- `_has(id)` sert à `passBlocked`, `isWordReversed` et `blockableGuessers`.
- `effectivePassPenalty` et `isPassBlocked` sont supprimés. `turn_effects.dart` ne garde que
  les clés, `freePassAllowance` et `canBlockGuesser`.
- Le diff du provider est plus court qu'en r1.

## Le reste du diff : pas de régression

Les parties suivantes n'ont pas changé depuis r1 :

- les garde `no_pass` (sortie avant `onWordPassed`) ;
- le Classique, où `hasFreePass` vaut faux et `_fiestaAfterTurn` renvoie null : aucune clé
  `fiesta` n'est écrite ;
- l'affichage à l'envers ;
- les contraintes annoncées ;
- la relecture tolérante de `fiesta.turn` ;
- `kCurrentSchemaVersion`, toujours à 1.

## Mutation testing r2 (7 mutants, tous tués, tous annulés)

| Mutant | Tué par |
|---|---|
| R1 compteurs vidés en fin de manche | test « un seul tour » |
| R2 `_fiestaAfterTurn()` remis en fin de manche | test « un seul tour » |
| R3 compteurs conservés en fin normale | tests `free_pass` et « un seul tour » |
| R4 portée tour non consommée | test « un seul tour » |
| R5 `hasFreePass` ignoré dans la pénalité | test `free_pass` |
| R6 `passBlocked` toujours faux | test `no_pass` |
| R7 aucune remise à zéro en fin normale | tests `free_pass` et « un seul tour » |

m2 (l'ordre d'appel dans le widget) n'est pas couvert par un test, faute de widget test (règle
de la story). Je l'ai vérifié à la lecture.
