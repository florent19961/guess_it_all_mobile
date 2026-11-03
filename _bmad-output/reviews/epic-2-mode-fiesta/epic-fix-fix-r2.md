# Epic fix Fiesta — corrections r2

## MAJOR-1 — `minus_10s` annoncé sur une continuation en chaîne : **corrigé**

**Décision de l'orchestrateur.** Le contrat existant est gardé : une continuation joue son temps
reporté, sans aucun modificateur de temps (`composeTurnSeconds`).

**Correctif.** Sur une continuation, `malusToReveal` exclut les malus de temps (`kTimeModifierIds`,
dans `turn_time.dart`, aujourd'hui `{'minus_10s'}`). Les autres malus de la manche logique restent
révélés (blocage, `no_pass`…).

**Preuve.** Le test « Continuation en chaîne » (`fiesta_pick_three_test`) a un `minus_10s` fixé
sur M2. Sur la continuation M3, il vérifie :
- `minus_10s` est en jeu mais pas révélé ;
- la durée du tour = « Temps reporté » seul ;
- le blocage M2, lui, est révélé.

Au premier vrai tour M3 du leader, le `minus_10s` de M2 n'est plus actif : il n'est ni annoncé ni
appliqué (aucune ligne −10). Le mutant « pas d'exclusion des malus de temps » est tué par ce test.
Suite complète verte.
