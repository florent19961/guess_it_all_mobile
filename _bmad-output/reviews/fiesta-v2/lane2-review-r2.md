# Revue Codex — lane 2 r2 (2026-11-04)

# NOT READY

## BLOCKER

Aucun. Le blocker r1 est réellement fermé :

- `round_transition.dart:113` résout les malus reçus une seule fois, au tour de la cible et selon sa manche logique ; l’ordre est celui de `active`, préservé par persistance et retour arrière.
- Les effets, révélation, durée, analytics et continuation lisent `currentTeamModifiers`; `_fiestaAfterTurn` retire aussi les malus écartés (`game_provider.dart:1564`).
- Le récap reste cohérent : il décrit les cartouches consommées, y compris un envoi finalement sans effet.
- `turn_screen.dart:395` évite bien le doublon « Deux mots » et affiche le badge Passe gratuite de cartouche.
- `free_pass.perGame` a de nouveau un effet dans `stockForRound`; son retour dans `settingsKey` est donc juste.

## MAJOR

- [turn_cartridges.dart:498](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/widgets/fiesta/turn_cartridges.dart:498), [turn_cartridges.dart:561](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/widgets/fiesta/turn_cartridges.dart:561), [game_screen.dart:170](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/screens/game_screen.dart:170) — le `ClipRect` peut masquer des puces d’envoi, qui sont l’unique action d’annulation. `_fit` suppose trois puces par ligne, mais à 360 px l’espace utile est 312 px et une puce peut faire 143 px (`20 + 110 + 13`) : deux seulement tiennent réellement.

  Scénario : Explosif M1, quatre équipes aux noms longs, sept malus envoyés avant le tour (possible avec les cinq malus en stock et deux charges). Le `Wrap` réel fait quatre lignes, `_fit` n’en réserve que trois ; une fois les planchers 36/32 atteints, la dernière ligne est coupée. L’annulation de ces envois devient inaccessible, sur Android comme sur iOS.

  Correction : calculer les lignes selon la largeur réelle des puces (au pire deux à 360 px), réserver cette hauteur avant d’appliquer le clip, et ajouter un rendu 360×640 avec 7+ envois vérifiant que chaque puce est visible/tappable. Aucun scroll ne doit être réintroduit.

## MINOR

- [fiesta_cartridges_test.dart:232](/home/florent19961/guess-it-all-fiesta-v2-tour/test/providers/fiesta_cartridges_test.dart:232), [round_transition.dart:136](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/models/fiesta/round_transition.dart:136) — le nouveau test du blocker tue bien le mutant qui ignore l’incompatibilité `no_pass`/`free_pass` et celui qui ne retire pas le malus, mais pas le garde-fou de doublon. Un mutant supprimant `weighing.any((w) => w.catalogId == m.catalogId)` survit.

  Scénario : `minus_10s` envoyé en M1, puis `minus_10s` règle Toujours en M2 chez la cible. Le malus reçu doit être écarté ; sinon le temps est amputé deux fois. Ajouter ce cas, idéalement aussi deux malus reçus incompatibles dans l’ordre d’envoi.

- [fiesta_cartridges_test.dart:298](/home/florent19961/guess-it-all-fiesta-v2-tour/test/providers/fiesta_cartridges_test.dart:298), [game_provider.dart:854](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/providers/game_provider.dart:854) — le test Auto ne prouve pas que les deux passes sont réellement gratuites. Le mutant `freePassesUsed + 2` à chaque passe survit : après deux appels, la pénalité vaut bien 5 comme attendu, bien que la seconde passe ait coûté 5 s.

  Correction : après la première passe, vérifier `freePassesUsed == 1` et `currentPassPenalty == 0`; après la seconde, vérifier `freePassesUsed == 2` puis la pénalité à 5.

- [fiesta_ensemble.dart:123](/home/florent19961/guess-it-all-fiesta-v2-tour/lib/models/fiesta/fiesta_ensemble.dart:123) — le correctif `perGame` est fonctionnel, mais aucune régression ne protège directement la clé de doublon. Un retour au comportement lane 1 (`&& id != 'free_pass'`) ne semble pas détecté.

  Scénario : deux ensembles ne différant que par « Passe gratuite : par manche / pour la partie » doivent être distincts et enregistrables. Ajouter l’assertion sur `settingsKey` ou `validateEnsemble`.

La réécriture du `gameId` persisté dans le test Auto est légitime : elle fige la graine via le même chemin de rechargement que l’app. Elle est un peu couplée au stockage, mais ne constitue pas une régression métier.

Classique conserve sa grande carte et son `Spacer`; les clés/taps équipe et tour précédent restent présents. Aucune branche spécifique Android/iOS n’est introduite ; le problème de clip affecte donc les deux plateformes. Aucun test ou mutant n’a été exécuté/injecté afin de respecter strictement la lecture seule.

