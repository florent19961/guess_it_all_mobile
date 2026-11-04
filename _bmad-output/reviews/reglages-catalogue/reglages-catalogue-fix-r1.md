# Corrections r1 — reglages-catalogue

Arbitrage de l'orchestrateur : la Fiesta n'a jamais été publiée (le dernier tag store ne
contient aucun fichier Fiesta) → aucune partie Fiesta suspendue ni aucun ensemble chez un
joueur.

| # | Finding | Décision | Preuve |
|---|---|---|---|
| MAJOR-1 | Parties Auto suspendues recalculées après l'ajout au catalogue | **Résidu assumé** (rupture pré-release, pas de versionnage du catalogue). Doc corrigée et règle posée pour l'après-publication | `docs/tracking_evolution.md` (§ « Rupture pré-release assumée ») ; `lib/models/CLAUDE.md` ligne `modifier_catalog.dart` (« une fois la Fiesta publiée… persister les tirages ou versionner le catalogue ») |
| MAJOR-2 | `oneMimeAtMost` ne garde pas forcément le mime tiré auparavant | **Résidu assumé** ; la promesse « celui que le jeu appliquait » est retirée : normalisation déterministe, 1er fixé puis 1er actif dans l'ordre du catalogue. Réécriture à la prochaine écriture du store (`markUsed` compris) | `lib/models/fiesta/fiesta_ensemble.dart` (doc de `oneMimeAtMost`), `docs/tracking_evolution.md`, `lib/models/CLAUDE.md`, libellé du test `fiesta_ensemble_service_test.dart` |
| MINOR-1 | Validation « autre langue » limitée à `== 3` | **Corrigé** : manche fixée ou de départ hors 1–2 refusée (offre : 2, déjà exigé) | `lib/models/fiesta/ensemble_validation.dart` ; `test/models/fiesta/ensemble_validation_test.dart` (fixé 0/4, tiré dès 4, offre dès 3 refusés ; offre dès 2 acceptée). Mutation `== 3` → test rouge |
| MINOR-2 | « Réinitialiser les paramètres » < 44 px | **Corrigé** : `AppButtonSize.medium` (padding 12 + police 16 ≈ 48 px) | `lib/screens/settings_screen.dart`. Re-mesure (test jetable, vraies polices) : « Avancés » 413 px en Fiesta (306 en Classique) pour ≈ 541 / 490 disponibles ; Paramètres inchangé, 709 px pour 763 / 740 |
