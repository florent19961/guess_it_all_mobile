# Correctifs r1 — PR A (revue Codex, rapport rendu en réponse : le sandbox interdisait l'écriture du fichier)

Verdict r1 : NOT READY, 3 MINOR (un premier passage annonçait 1 MAJOR + 2 MINOR, sans détail récupérable).

| Finding | Décision | Preuve |
|---|---|---|
| MINOR 1 — fenêtre des blocages : le nom de l'équipe refusée reste en couleur pleine | corrigé : nom à 35 %, raison lisible | `lib/widgets/fiesta/turn_cartridges.dart` (`_TeamPlayers`) |
| MINOR 2 — le test ne vérifie pas que grisé = refusé | corrigé : envoi vers la cible grisée refusé, rien consommé | `test/providers/fiesta_cartridges_test.dart` (dernier test) |
| MINOR 3 — « un seul blocage de chaque type » n'exerce que `block_giver` | résidu assumé : titre préexistant, seule l'assertion a changé ; une matrice irait contre la règle des tests minimaux | `test/providers/fiesta_v4_test.dart:286` |
