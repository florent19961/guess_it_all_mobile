# Fix r1 — story 2-6

Verdict r1 : READY (0 BLOCKER, 0 MAJOR). Condition de merge m4 et MINORs traités ci-dessous.

| Finding | Décision | Preuve |
|---|---|---|
| m1 — justification « mots refusés » inatteignable | **Corrigé** : l'entrée de `docs/tracking_evolution.md` (2-6) donne la vraie raison (prescrit par la story, retrait explicite, embarqué par le snapshot et la persistance, principe de `turnBonusTime`) et note que `turnBonusTime` et `pendingBonusTurnId` coïncident en fin de manche. | `docs/tracking_evolution.md`, entrée 2-6, « Pourquoi ces choix » |
| m2 — `MalusReveal` de `minus_10s` avant une continuation | **Corrigé** : `malusToReveal` révèle `minus_10s` au premier tour **non-continuation** de l'équipe (`turnBonusTime` nul et aucune entrée non-continuation dans la manche) ; les autres malus restent révélés au premier tour. Le test 2-5 « révélation dès M2 aussi » (venu de `main`) asserte précisément l'ancien comportement avec `minus_10s` : il est étendu, à intention égale (rien avant la continuation, révélation au premier tour complet de chaque équipe, y compris celle qui a joué M1). | `lib/providers/game_provider.dart`, `malusToReveal` ; `test/providers/fiesta_round_draw_test.dart` |
| m3a — mutant « compte tous les modificateurs » | **Corrigé** : `no_pass` fixé en M2 en plus de `minus_10s` dans le test provider ; le total 26 ne tient que si seul `minus_10s` compte. | `test/providers/turn_time_fiesta_test.dart`, règles du `startGame` |
| m3b — filtre de types de `tryFromJson` non testé | **Corrigé** : `catchUpDue: {'a': 'x', 'b': 3}` → `{'b': 3}` et `[1]` → `{}` dans le test de relecture tolérante existant. | `test/models/game_state_test.dart`, « une instance inconnue ou mal formée est ignorée » |
| m3c — fallback `?? turnDuration` non exercé | **Résidu assumé** : une ligne triviale, un test provider qui forge un blob en plein tour coûterait plus que ce qu'il garde. | `game_provider.dart`, `validateWords` |
| m4 — garde de `nextRound` absent de la base | **Corrigé** : lane rebasée sur `origin/main` (2-5 mergée en `934de6c`, garde incluse) ; `_fiestaForRound` est appelé dans la branche gardée, sans conflit. | `lib/providers/game_provider.dart`, `nextRound` |
| (trouvé au restack) `toJson` écrivait `turnAllottedSeconds: null` | **Corrigé** : clé omise quand nulle, comme `fiesta`. `main` a figé le blob Classique en littéral (`test/models/game_state_test.dart`, « un blob Classique reste Classique ») : un blob de la version en store doit se relire et se réécrire octet pour octet (règle 7). Avant le restack, ce test régénérait le blob depuis le code et ne pouvait pas le voir. | `lib/models/game_state.dart`, `toJson` |
| n1 — dû signé découpé en deux paramètres | Faux positif / non retenu : les deux paramètres portent deux libellés et deux couleurs sur la carte ; le mutant équivalent est sans effet observable. | — |
| n2, n3 | Non retenus (NIT) : pas de changement pour éviter de bouger du code que la revue a validé. | — |
