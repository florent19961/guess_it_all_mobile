# Correction r1 — L-PERSONNE

Revue : `retours-personne-review-r1.md` (Codex, NOT READY). Arbitrage des findings par l'orchestrateur.

## MAJOR — le grisé d'équipe par un malus 1.4.0 sans `playerId` n'est pas testé

**Décision : corrigé.** Le test de relecture 1.4.0 (`test/providers/fiesta_v4_test.dart:`) vérifie maintenant,
après la relecture du malus sans `playerId`, que `targetRefusal('reversed', id)` vaut « Déjà Mot à l'envers dans
son équipe » pour CHAQUE joueur de l'équipe visée. Pas de widget test, par décision de l'orchestrateur.

**Preuve.**
- Vert : `scripts/with-test-slot.sh flutter test test/providers/fiesta_v4_test.dart` → 25 tests, tous verts.
- Mutant : dans `_clashOn` (`lib/providers/game_provider.dart`), le cas `m.playerId == null ||` est retiré.
  Le test « relecture : un malus en attente écrit par la 1.4.0… » échoue (exit 1). Le code est ensuite restauré,
  et le diff du code est vide.

## MINOR — `inflictMalus` rend `null` en silence hors conflit

**Décision : résidu assumé.** C'est le contrat existant : un appel ignoré rend `null` (hors avant-tour, cartouche
épuisée ou grisée, cible invalide), comme avant cette lane. La feuille « Sur qui ? » grise d'avance par personne
(`targetRefusal`), et le refus détaillé reste réservé au conflit, le seul cas atteignable depuis l'UI.
Rien n'est changé.
