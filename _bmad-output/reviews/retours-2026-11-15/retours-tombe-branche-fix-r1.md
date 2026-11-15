# Corrections r1 — L-TOMBE-BRANCHEMENT

Revue Codex r1 (statique) : READY, un MINOR.

| Finding | Décision | Preuve |
|---|---|---|
| MINOR — tableau de mutations : M18 dit survivant alors que le test modèle de `droppedMalus` le tue | Corrigé (avant réception du rapport) | 7632bba ajoute le test pur `droppedMalus` (`test/models/fiesta/cartridge_drop_test.dart`) ; M18, M18b, M18c rejoués contre lui : tués ; tableau mis à jour en 0413afe (`retours-tombe-branche-mutations-r1.md`, section « Survivants » : aucun) |
