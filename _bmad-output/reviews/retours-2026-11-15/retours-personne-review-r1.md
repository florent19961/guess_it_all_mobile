Verdict : NOT READY

# Revue r1 — L-PERSONNE

## Findings

### MAJOR — La compatibilite 1.4.0 ne couvre pas le grisage d'equipe

`test/providers/fiesta_v4_test.dart:529-543`

La relecture retire bien `playerId`, puis ne verifie que l'effet du malus au
prochain tour de l'equipe. Elle n'appelle jamais `targetRefusal` pour chacun
des joueurs de cette equipe. Elle ne protege donc pas l'arbitrage D1 selon
lequel un malus 1.4.0 en attente sans `playerId` grise tous ses prenoms.

Preuve : le mutant de `_clashOn` qui retire le cas `m.playerId == null`
(`lib/providers/game_provider.dart:1819`) laisse encore passer le scenario de
relecture actuel : `resolvesAt` conserve bien le comportement equipe grace a
`playerId == null` (`lib/models/fiesta/modifier_instance.dart:56-60`), tandis
que le grisage par equipe disparait. C'est aussi le survivant connu indique
dans le prompt de revue.

Scenario : une partie suspendue 1.4.0 contient `reversed`, `from`, `teamId`,
mais pas `playerId`. Au prochain avant-tour adverse, chaque prenom de cette
equipe doit etre grise avec la raison « Deja Mot a l'envers dans son equipe ».
Une regression de ce cas laisserait un joueur recevoir un malus incompatible
avec le malus legacy de son equipe.

Correction proposee : completer le test de relecture par une assertion
`targetRefusal('reversed', id)` pour chaque joueur de l'equipe, et idealement
un widget test de la feuille attestant qu'ils sont tous inactifs.

### MINOR — Les garde-fous de `inflictMalus` ne fournissent pas le refus detaille demande

`lib/providers/game_provider.dart:1877-1887`

Les cas joueur inconnu, joueur de l'equipe courante, hors avant-tour,
cartouche indisponible et `block_guesser` sur une equipe de moins de trois
joueurs retournent tous `null`. Seul le conflit deja en attente retourne un
texte detaille (lignes 1889-1900). Cela contredit le point de controle du
prompt demandant un message de refus detaille pour ces garde-fous.

Scenario : un appelant non-UI ou une future feuille qui garde une cible
obsolète ne peut pas expliquer le refus, et ne peut pas le distinguer d'un
envoi reussi (les deux retournent `null`).

Correction proposee : retourner un message `Impossible : ...` specifique pour
chaque rejet exploitable, ou separer sans ambiguite le resultat de l'API
(succes/refus silencieux/refus explique).

## Conformite D1 et chemins d'etat examines

Le mecanisme central est coherent : `ModifierInstance.resolvesAt`
(`lib/models/fiesta/modifier_instance.dart:56-60`) est utilise par
`modifiersForTurn` (`lib/models/fiesta/round_transition.dart:97-105`) et par
le nettoyage de vraie fin de tour (`lib/providers/game_provider.dart:1709-1721`).
L'envoi persiste `playerId`, le `ChargeUse.target` reste l'equipe de la cible,
et l'annulation/reprise passent par les instances sauvegardees. La transition
garde les malus et ne rembourse plus ; le malus incompatible est filtre au
tour de la cible puis supprime a la fin de ce tour.

Les chemins `confirmGiverBlock`/`reuseReplacedChoices`, skips, continuation,
report nul, retour arriere serialise et relecture 1.4.0 ont ete relus. Les
deux blocages consecutifs conservent bien deux cibles et deux increments de
`skips`. La feuille affiche les equipes adverses et leurs prenoms seulement ;
les prenoms recus sont des `Tooltip` au tap. Aucun reste de `_pickTarget`,
`_TeamButton`, `_TeamPlayers`, `targetsFor` ou `RoundTransitionPlan.continuingTeamId`
n'est utilise par le code live.

Les tests ajoutes ont une bonne valeur pour la cible nominative a travers une
manche, le remplacement apres `block_giver`, les deux pieges consecutifs et
la perte sans remboursement. La lacune legacy ci-dessus reste importante dans
ce tier risque.

## Mutation testing obligatoire — resultat

Non execute : la sandbox interdit toute ecriture dans le worktree cible, donc
la mutation temporaire suivie de `git checkout -- <fichier>` demandee ne peut
pas etre realisee. Les tentatives de lancement ont aussi ete bloquees avant
l'execution des tests : le SDK Flutter installe ne peut pas ecrire son cache ;
avec une copie jetable du SDK et du worktree sous `/tmp`, `flutter test --no-pub`
echoue a la creation du socket local `127.0.0.1` (EPERM).

| Mutant prevu | Test cense le tuer | Resultat |
|---|---|---|
| resolution par equipe au lieu de `playerId == giverId` | `fiesta_v4_test.dart:481-499` | non execute (sandbox) |
| suppression de l'attente des autres malus du joueur saute | `fiesta_v4_test.dart:501-526` | non execute (sandbox) |
| fallback legacy sans `playerId` ignore | `fiesta_v4_test.dart:529-543` | non execute (sandbox) |
| grisage legacy par equipe retire | aucun test actuel | survivant connu / MAJOR ci-dessus |
| `block_giver` par equipe au lieu de par personne | `fiesta_v4_test.dart:283-307` | non execute (sandbox) |
| remboursement a la transition retabli | `zero_carryover_turn_test.dart:352-376`, `cartridge_gifts_test.dart:269-285` | non execute (sandbox) |

Le worktree controle etait propre avant les tentatives et l'est toujours ;
aucun changement de code ni commit n'a ete conserve.

## BLOCKER / MAJOR (liste courte)

- MAJOR — absence de test du grisage de toute l'equipe pour un malus 1.4.0 sans `playerId`.
