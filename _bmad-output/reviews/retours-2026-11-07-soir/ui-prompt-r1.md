# Revue r1 — PR A « retours UI du 07/11 au soir » (tier standard)

Patch : `ui-patch-r1.diff` (même dossier), calculé sur la merge-base `origin/main`.

## Objectif (décisions Florent, cadrage du 2026-11-09)
1. Message d'erreur en bas de l'avant-tour Fiesta (`_showSnack`, turn_cartridges.dart) : 3 s au lieu de 5, fermeture par glissement vers le bas.
2. Griser à l'avance ce qui n'est pas utilisable : un malus que AUCUNE équipe adverse ne peut recevoir (trop petite pour block_guesser, ou déjà visée par le même malus ou par un malus incompatible) est grisé dans la réserve, avec la raison. Dans « Contre quelle équipe ? » et la fenêtre des blocages, une équipe refusée est grisée, inactive, avec sa raison. Toucher une cartouche grisée garde un message court.
3. Bottom sheets (explication d'un badge / cartouche, choix d'équipe, blocages) : liseré coloré sur le seul bord supérieur (`SheetTopBorder`).
4. Mode aléatoire : retirer le badge « N mots prêts » de l'écran Joueurs et l'étape d'aide qui pointait dessus.
5. Écran de formation des équipes : nom d'équipe sur 2 lignes (18 caractères max inchangé).

## Questions précises
- `targetRefusal` / `_clashOn` / `_malusBlock` (game_provider.dart) : la règle de grisage est-elle EXACTEMENT celle du refus d'`inflictMalus` (pas de cas grisé qui serait accepté, ni l'inverse) ? Chemins : 2 vs 3+ équipes, malus envoyé par moi ce tour (annulable via la puce), malus envoyé par une autre équipe, block_giver / block_guesser, continuation de tour, passage de manche.
- `fiesta.active` peut-il contenir des malus déjà consommés ou d'un tour passé qui grisent à tort ?
- `_showSnack` : fuite ou double `remove()` d'OverlayEntry (timer + dismiss + dispose + nouveau message) ?
- `SheetTopBorder` (sous-classe de RoundedRectangleBorder qui redéfinit `paint`) : risque avec copyWith/lerp/scale côté Material ?
- TextField multi-ligne dans `IntrinsicWidth` (teams_screen) : Entrée valide-t-elle bien (textInputAction.done) sur Android ET iOS ?
- Tests : le test ajouté dans fiesta_cartridges_test et la modification de fiesta_v4_test exercent-ils la garantie qu'ils nomment ?

## Format attendu
Fichier `ui-review-r1.md` : verdict (READY / NOT READY), puis findings BLOCKER / MAJOR / MINOR avec `fichier:ligne` et scénario concret.
