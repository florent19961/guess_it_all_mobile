# Revue r1 — L-X2 (`feat/retours-x2`) — tier RISQUÉ (scoring)

Lecture seule. Lis le patch `_bmad-output/reviews/retours-2026-11-15/retours-x2-patch-r1.diff` (pas `git diff`),
puis le code autour dans le worktree `/home/florent19961/guess-it-all-retours-x2`. Spec : section **D3** et
en-tête de `_bmad-output/specs/fiesta/retours-2026-11-15.md`. `CLAUDE.md` racine et `lib/models/CLAUDE.md` priment.

## Objectif (D3)
- Le poids réduit du ×2 (`kGiftWeights.overrides`) disparaît : il pèse comme les autres.
- `double_points` n'entre dans le vivier d'une équipe que si elle est menée par le leader de **plus de 10 points**
  (strict), constante nommée, fixe. Jamais pour le leader, donc jamais au lancement (M1).
- Vaut pour `roundGifts` (début de manche) et le prix des défis (`challenge_plan.dart`, écart de l'équipe qui
  reçoit). Plus tard pour les cartouches qui tombent (L-TOMBE réutilisera `giftPool(gap:)`, `leaderGap`,
  `kDoublePointsMinGap`). Pas les cartouches fixées d'un ensemble.

## Choix d'implémentation à juger
1. Poids uniformes : `kGiftWeights`/`_giftWeight` supprimés, `drawWeightedGift` → `drawGift`
   (`pool[random.nextInt(pool.length)]`). Change les tirages recalculés des parties en cours (rien de persisté).
2. `giftPool` prend `required int gap` ; filtre `def.id != 'double_points' || gap > kDoublePointsMinGap`.
3. `leaderGap(scores, teamId)` = vrai max (négatif compris) − score de l'équipe. Le nombre de cartouches
   (`giftCount`) garde son `top = fold(0, max)` existant : deux bases d'écart cohabitent dans `roundGifts`
   (volontaire, hors périmètre). Est-ce acceptable ou faut-il unifier ?

## Points précis à vérifier
- Seuil strict (10 exclu, 11 inclus), leader exclu, M1 exclu, sur les deux chemins (`roundGifts`, `planChallenge`).
- `planChallenge` : l'écart est bien celui de l'équipe qui reçoit, calculé sur TOUS les scores (pas seulement les
  deux équipes en retard).
- Aucun autre appelant de `giftPool` / `drawWeightedGift` oublié ; pas de `game_provider.dart` touché.
- Docs rendues fausses : commentaires de `cartridge_gifts.dart` et `challenge_plan.dart`, `lib/models/CLAUDE.md`,
  entrée `docs/tracking_evolution.md`, aide / tutoriel / éditeur (rien trouvé qui parle de la rareté du ×2).
- **Mutation testing obligatoire** sur les tests ajoutés (`test/models/fiesta/cartridge_gifts_test.dart` : vivier
  au seuil, groupe « Mot compte double au hasard (D3) » ; `test/providers/surprise_challenge_flow_test.dart` :
  « récompense : Mot compte double seulement à plus de 10 du leader »). Mutations suggérées : `>` → `>=`,
  constante 10 → 9/11, `gap: leaderGap(...)` → `gap: 0` / écart de base 0, filtre retiré, écart d'une autre équipe
  dans `planChallenge`.
- Valeur des tests : tests retirés (poids 3/1 épinglés, deux tests statistiques « 3 fois moins ») — couverture
  perdue légitime ? Tests redondants ou échafaudage ?

## Format attendu du rapport
Verdict **READY / NOT READY**, puis findings classés **BLOCKER / MAJOR / MINOR**, chacun avec `fichier:ligne`,
l'affirmation, la preuve et la correction proposée. Section dédiée aux résultats du mutation testing
(mutation → test qui la tue, ou survivante).
