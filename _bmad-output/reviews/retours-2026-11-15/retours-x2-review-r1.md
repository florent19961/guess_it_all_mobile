# Revue r1 — L-X2 (D3, tier risqué : scoring)

Verdict : READY

## Findings

Aucun finding **BLOCKER**, **MAJOR** ou **MINOR** dans le diff.

## Conformité D3 et appelants

- Le seuil est une constante nommée à 10 et le filtre est strict :
  gap > kDoublePointsMinGap dans lib/models/fiesta/cartridge_gifts.dart:32-72.
  Ainsi 10 est exclu, 11 est inclus, et le leader / M1 (écart 0) ne peuvent
  pas recevoir le ×2.
- leaderGap utilise bien le maximum réel, y compris quand tous les scores sont
  négatifs (cartridge_gifts.dart:38-41). roundGifts le transmet au vivier de
  chaque équipe (:121-129), tandis que planChallenge le calcule sur la carte
  complète des scores, pour l'équipe qui reçoit le prix
  (challenge_plan.dart:82-99). Ce n'est donc ni l'écart entre les deux
  challengers, ni celui du leader.
- Le grep des symboles concernés ne trouve que les appelants attendus :
  giftPool dans son test, roundGifts et planChallenge; drawGift dans
  _giftsOf et planChallenge; leaderGap dans ces deux chemins de production.
  Aucun drawWeightedGift ni kGiftWeights ne subsiste dans les fichiers Dart.
  game_provider.dart n'est pas dans le patch.
- drawGift choisit un index unique dans le vivier
  (cartridge_gifts.dart:134-136) : les poids 3/1 ont réellement disparu.
  Les deux appels conservent un Random(giftSeed(...))
  (cartridge_gifts.dart:129, challenge_plan.dart:97). Deux exécutions
  identiques des cadeaux de manche et du prix de défi ont donné les mêmes
  sorties avec la graine, dans le harness de mutation.
- L'API future D4 est prête : giftPool exige explicitement gap et leaderGap est
  une fonction pure exportée. Un futur appelant ne peut pas oublier l'écart
  sans erreur de compilation. Les règles spécifiques de D4 restent
  naturellement hors du présent diff.
- Les commentaires, lib/models/CLAUDE.md:29-31 et
  docs/tracking_evolution.md:1459-1476 décrivent le nouveau contrat. Les
  autres références au poids 3/1 sont dans des entrées historiques ou des
  artefacts de revue, pas dans une aide, un tutoriel ou l'éditeur actif.

### Faut-il unifier les deux écarts ?

Non : conserver les deux calculs est le bon choix pour D3. Le top initialisé
à 0 de giftCount (cartridge_gifts.dart:111-120) détermine depuis avant ce diff
combien de cadeaux sont attribués; leaderGap détermine maintenant si le ×2 est
admissible depuis le leader réel. Les unifier modifierait hors périmètre le
volume de cadeaux pour des scores tous négatifs. Le journal l'explicite
(tracking_evolution.md:1473-1476). Cette séparation est volontaire,
documentée et ne compromet pas la règle D3.

## Mutation testing et valeur des tests

Les commandes Flutter habituelles ont été tentées via
scripts/with-test-slot.sh. Elles sont bloquées avant les tests par le sandbox :
SDK partagé non inscriptible (engine.stamp / lockfile), puis, avec une copie
temporaire identique du SDK 3.44.8 et --no-pub, interdiction de bind sur
127.0.0.1. Ce n'est pas un échec de test applicatif.

J'ai donc exécuté sous le même sémaphore un harness Dart temporaire qui importe
le code de ce worktree et reproduit exactement les nouvelles assertions. Il
est vert sans mutation; les mutations suivantes ont été tuées :

| Test ajouté | Mutations attrapées | Mutations non attrapées / limite |
|---|---|---|
| cartridge_gifts_test.dart:120 — vivier au seuil | > → >=, constante 10 → 9 (échec « gap 10 »), 10 → 11 (échec « gap 11 »), retrait du filtre (échec « gap 0 ») | Ne couvre pas le calcul de leaderGap, car il injecte délibérément gap. C'est son rôle d'unitaire du filtre. |
| cartridge_gifts_test.dart:139 — 11 oui, leader / 10 non | Leader non exclu, filtre retiré, roundGifts qui passe 0 ou l'écart d'une mauvaise équipe; le scénario contraint les trois équipes | Ne couvre pas le cas de tous scores négatifs; celui-ci est traité séparément. |
| cartridge_gifts_test.dart:143 — M1 | Retrait du filtre / passage d'un écart qui autoriserait le leader à M1 | Ne tue pas seul > → >= ni une constante 9/11 : l'écart M1 vaut 0. Il reste utile pour le chemin finishedRound: 0. |
| cartridge_gifts_test.dart:147 — scores négatifs | leaderGap = fold(0, max) (mutation exécutée : échec « negative scores use the real leader ») | Ne vérifie pas le seuil 10, déjà couvert par le test au seuil. |
| surprise_challenge_flow_test.dart:339 — prix de défi | gap: leaderGap(...) → gap: 0 dans planChallenge (mutation exécutée : échec « challenge recipient 11 behind sees both prizes »), ou l'écart de l'autre receveur | Ne mesure pas une distribution statistique exacte 1:1. C'est approprié : l'uniformité est garantie directement par le one-liner nextInt(pool.length), sans test probabiliste fragile. |

Les tests ajoutés ne sont donc pas redondants : ils séparent filtre pur,
intégration roundGifts, M1, scores négatifs et chemin des défis. Les tests
retirés sur les poids 3/1 et « trois fois moins » couvrent un contrat
expressément supprimé; leur retrait est légitime.

## Vérification de l'état

Chaque mutation de code a été restaurée. git checkout -- fichier a été tenté
conformément à la consigne, mais le fichier index.lock du worktree est monté en
lecture seule; la restauration byte-à-byte a donc été effectuée par patch
inverse. git status --short est propre hors ce rapport.

Verdict : READY

BLOCKER/MAJOR : aucun.
