Verdict : READY

# Revue statique — lot retours-2026-11-15

Revue en lecture seule du diff cumulé et des parcours exécutés par l'état
actuel. Aucun test ni commande Flutter n'a été lancé.

## Invariants transverses vérifiés

- Les malus envoyés se résolvent sur le prochain tour du joueur ciblé par
  `ModifierInstance.resolvesAt`; les blobs 1.4.0 sans `playerId` conservent le
  repli sur le prochain tour de l'équipe. `modifiersForTurn` est la source des
  malus effectifs et `_fiestaAfterTurn` consomme exactement ceux qui se
  résolvent sur le tour fini. Le masquage ne porte que sur la vue de
  l'avant-tour : `_drawDrop` lit bien cette source non masquée.
- Une cartouche tombée est persistée dans `FiestaTurnState.drop` avant le choix
  de l'écran; elle survit donc à une reprise sur `turnReveal`. Elle est
  conservée durant une continuation, où aucun nouveau tirage n'est fait. Les
  chemins `block_giver` (reçu ou tombé) repartent d'un état de tour neuf pour
  le remplaçant, dont la graine inclut le compteur de sauts.
- Le filtre commun `randomPool` applique le seuil strict de plus de 10 points
  pour `double_points`; les trois consommateurs (cartouches de manche, défi,
  chute) lui fournissent l'écart réel au leader. Les cartouches explicitement
  possédées ne sont pas concernées, conformément à la règle.
- `passBlocked` dépend de `no_pass` et de l'épuisement de la passe gratuite.
  La même garde est utilisée par le bouton et par `passWord` : une passe
  gratuite reste donc possible, puis le blocage s'applique.
- Les événements analytics lisent les modificateurs du tour persisté : malus
  reçus et malus tombé y sont présents une fois, tandis qu'un bonus tombé est
  ajouté une fois via `_charge`, sans créer de `ChargeUse` ni retirer du stock.
- La forme ajoutée est additive : `dropFrequency` absent vaut `never`, `drop`
  absent vaut `null`, les malus historiques sans `playerId` restent jouables et
  `screenTurnReveal` est routé par l'application. Les CLAUDE, le câblage de
  l'aide et le tutoriel décrivent les mêmes règles.

## Findings

### MINOR — état Fiesta de la dernière manche non nettoyé après une fin anticipée

- `lib/providers/game_provider.dart:1304`, `lib/providers/game_provider.dart:1864`, `lib/providers/game_provider.dart:1382`

  Scénario : un tour normal de M3 vide le pool avec du temps restant. Comme
  `noCarryOver` est forcément faux en M3, `validateWords` appelle
  `_fiestaAtRoundEnd`; hors continuation, celui-ci retourne l'état Fiesta sans
  vider `turn` ni retirer les malus résolus. `nextRound` passe alors directement
  aux résultats en gardant cet état et le persiste. Une `drop` et les malus
  résolus ne sont pas réaffichés ni rejoués (la partie est terminée), donc
  l'impact est limité à un état final orphelin, mais cela ne respecte pas
  strictement l'invariant de nettoyage à la vraie fin du tour.

Verdict : READY

BLOCKER/MAJOR : aucun.
