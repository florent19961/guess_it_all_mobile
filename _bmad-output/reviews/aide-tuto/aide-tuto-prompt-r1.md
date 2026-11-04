# Revue r1 — lane « aide-tuto » (tier standard)

Lis **uniquement** `_bmad-output/reviews/aide-tuto/aide-tuto-patch-r1.diff` (diff sur la merge-base avec `origin/main`) et le code qu'il touche. Ne lance pas `git diff`. Revue en lecture seule : n'écris que ton rapport, dans `_bmad-output/reviews/aide-tuto/aide-tuto-review-r1.md`.

## Objectif

Corriger l'aide intégrée à partir des retours de Florent sur device (2026-11-04).

## Décisions de Florent (appliquées telles quelles)

1. **Bulle des coach marks** (`coach_marks.dart`) : carte bleu nuit (`AppColors.backgroundMain`, contour `gray600`). Titre en `AppTextStyles.title(fontSize: 24)` (Bangers blanc, ombre rose décalée), jamais un titre rose. Corps en Poppins blanc. Compteur et « Passer » en `gray400`, bouton « Suivant / Compris » en `AppButton` primaire. Plus aucun brun ni crème.
2. **Cadre de la cible** : un liseré blanc à 50 % de 1,5 px remplace le trait jaune de 3 px. **Bug** : sur Chrome (web), la cible restait voilée. Correctif : le voile est un seul `Path` en `PathFillType.evenOdd` (écran + rrect) au lieu de `Path.combine(PathOperation.difference, …)`.
3. **Bouton « ? »** : le « ? » seul en `gray400`, sans rond ni bordure. La zone tactile reste de 48×48 (`color: Colors.transparent` sur le `Container`) et la position ne change pas.
4. **Premier lancement** (arbitré par l'orchestrateur, option a) : sur un téléphone neuf (`guessItAll_tutorialSeen` à false, posé par `FirstGameHelp.initAtStartup`), le premier « Jouer » ouvre directement le tuto des règles, sans la question « Première partie ? ». Les bulles de la première partie restent automatiques, comme avant. Aucune clé n'est créée. Un téléphone qui a un historique ne voit rien.
5. Pendant les bulles, tous les boutons restent bloqués (`GestureDetector` opaque plein écran) : à vérifier qu'il n'y a pas de régression.
6. **Tuto Fiesta ouvert deux fois** : une garde statique `_isOpen` dans `FiestaTutorialScreen.show()`, sans toucher aux appelants.

Hors périmètre (autres lanes) : `transition_screen.dart`, les écrans de configuration et `app_theme.dart`.

## Questions précises

1. **Découpe, web contre mobile** : est-ce que `PathFillType.evenOdd` avec `addRect` puis `addRRect` donne bien un trou net sur CanvasKit/skwasm (web) et sur Impeller/Skia (Android, iOS) ? Est-ce que l'hypothèse « `Path.combine` mal rendu sur web » tient, ou bien la cause vient-elle d'ailleurs (rect mesuré décalé avec `localToGlobal` sous web, ordre de peinture, `FadeTransition`) ? Si c'est le cas, le correctif ne suffit pas : dis-le.
2. **Règle 7** : est-ce qu'une clé `guessItAll_*` change de forme ou de sens ? `tutorialSeen` voulait dire « prompt posé » et veut maintenant dire « tuto vu ». Les téléphones en store ont `true` (historique) ou `false` (install neuve qui n'a jamais joué). Y a-t-il un parc pour lequel ce glissement de sens pose problème ?
3. **Premier lancement** : est-ce que le tuto peut s'ouvrir alors qu'il ne devrait pas (téléphone avec historique, « Nouvelle partie », « Rejouer ») ? Ou est-ce qu'il peut ne jamais s'ouvrir sur une install neuve (context démonté, `RulesTutorialScreen.show` qui marque avant le push) ?
4. **Garde du tuto Fiesta** : y a-t-il une fuite de `_isOpen = true` (exception, route jamais complétée, hot restart) ? Est-ce que « Continuer » (`game_mode_screen`), qui revient aussitôt quand le tuto est déjà ouvert par « ? », navigue sous le tuto d'une façon gênante ?
5. **Test ajouté** (`test/screens/fiesta_tutorial_screen_test.dart`) : il reproduit le bug, et le mutant « garde retirée » a été tué localement. A-t-il de la valeur, ou est-il redondant ?

## Format attendu

Une liste de findings classés BLOCKER, MAJOR ou MINOR. Pour chacun : `fichier:ligne`, le constat, la preuve et un correctif proposé. Termine par un verdict READY ou NOT READY.
