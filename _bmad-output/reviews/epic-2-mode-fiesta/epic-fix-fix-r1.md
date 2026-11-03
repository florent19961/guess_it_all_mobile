# Epic fix Fiesta — corrections r1

## MAJOR-1 — continuation en chaîne : **corrigé**

**Re-tracé dans le code.** La continuation M1→M2 vide à elle seule le pool de M2. La branche fin
de manche de `validateWords` (`game_provider.dart`, ex-l.1130) gardait alors toujours l'état du
tour via `afterRoundEnd()`. La continuation M3 était bien reconnue (manche logique M2), mais
portait encore le ×2 dépensé en M1. Le test l'a confirmé en rouge : `isDoublePointsOn` valait
vrai sur la continuation M3.

**Correctif.** Nouvelle fonction `_fiestaAtRoundEnd()`.
- **Le tour qui finit la manche est une continuation :** son tour logique N se termine ici,
  comme à une vraie fin de tour. Elle appelle `_fiestaAfterTurn()`, qui vide l'état et consomme
  les instances de tour appliquées. Les instances de N partent aussi.
- **Sinon :** `afterRoundEnd()`, comme avant.
- **Résultat :** `plan.apply` vers N+2 ne garde que N+1. La continuation suivante ne porte que
  le contexte de N+1.

**Conséquence assumée, sans décision produit nouvelle.** La règle validée dit « continuation =
contexte de sa manche logique ». Pour la continuation en chaîne, ce contexte est N+1, que
l'équipe subit pour la première fois. `malusToReveal` raisonne donc désormais sur la manche
logique : il révèle les malus de N+1 (dont le blocage M2, avec le sélecteur et `blockingTeam`).
Une continuation ordinaire ne révèle toujours rien.

**Preuve.**
- Test `fiesta_pick_three_test` « Continuation en chaîne » : M1→M2→M3, ×2 de M1, blocage de M2,
  kill avant la continuation M3, retour arrière et revalidation. Il était rouge avant le
  correctif.
- Mutant « `afterRoundEnd()` inconditionnel » : tué par ce test.
- Suite complète : 214/214.

**Double tap.** Déjà couvert par la garde d'écran de `validateWords` (A1). Le test ne le rejoue
pas.
