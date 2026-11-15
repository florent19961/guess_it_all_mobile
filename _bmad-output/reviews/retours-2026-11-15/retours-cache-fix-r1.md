# Corrections r1 — L-CACHE

Revue Codex r1 statique : **READY**, aucun BLOCKER ni MAJOR.

| Finding | Décision | Preuve |
|---|---|---|
| MINOR — cercle des règles de manche blanc, la maquette dit jaune (`lib/screens/turn_reveal_screen.dart:21`) | **Résidu assumé** (orchestrateur) : on garde le blanc, cohérent avec la zone « Actif » réelle de l'avant-tour (`_Circle`, `_Kind.rule` en blanc, `lib/widgets/fiesta/turn_cartridges.dart`). Consigné au journal, « à valider » par Florent | `turn_reveal_screen.dart:21`, `turn_cartridges.dart` (`rule ? Colors.white`) |

Mutation testing de la lane : `retours-cache-mutations-r1.md` (8/9 tués, 1 survivant assumé).
