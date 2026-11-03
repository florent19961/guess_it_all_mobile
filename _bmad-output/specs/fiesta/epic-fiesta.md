---
epic: epic-2-mode-fiesta
title: "Mode Fiesta (Auto + Personnalisé) par-dessus le mode Classique"
status: ready-for-dev
created: 2026-11-03
framing: "grilling Florent 2026-08-02 + 2026-11-03 (story 2-1-fiesta-cadrage)"
mockup: https://claude.ai/artifact/N9w6ATfeJnXTkfq74AfAdj
stepsCompleted: [validate-prerequisites, design-epics, create-stories, final-validation]
---

# Epic 2 : Mode Fiesta

## Objectif

Ajouter à Guess It All une façon de jouer **Fiesta**, avec des bonus et des malus qui
pimentent les 3 manches et donnent une chance aux équipes menées. Le jeu d'aujourd'hui devient
le mode **Classique** et ne doit pas changer d'un octet de comportement. Une partie Classique
lancée avant la mise à jour, puis reprise après, doit se relire et se terminer normalement
(`CLAUDE.md` règle 7).

Valeur produit : renouveler l'intérêt des soirées (retour joueurs : la partie est jouée, puis
oubliée) sans toucher au cœur du jeu qui marche. Release : **un seul build store après
Fiesta** (pas de livraison partielle en store).

Référence UX : la maquette cliquable
<https://claude.ai/artifact/N9w6ATfeJnXTkfq74AfAdj>, écrans `gamemode`, `fiesta`, `auto`,
`perso`, `edit`, `recap`, `r1`, `cd`, `turn`, `rev`, `verif`, `malus`, `block`, `r2`, `pick3`,
`cd2`, `results`, `two_*`, `dropped`. Quand la maquette contredit une décision ci-dessous, la
décision gagne (voir les questions ouvertes Q1 et Q14).

## Cadrage figé (décisions de Florent, 2026-08-02 puis 2026-11-03)

On ne rouvre pas ces points pendant le dev. Un point qui bute va dans les questions ouvertes.

### Nommage

- Le jeu d'aujourd'hui s'appelle **Classique**.
- **Fiesta** a deux modes : **Auto** et **Personnalisé**.

### Mode Auto

Les joueurs ne choisissent rien. Deux interrupteurs cumulables, au moins un des deux allumé.

- **Symétrique** : au début de chaque manche, l'app tire 1 à 2 modificateurs compatibles qui
  s'appliquent à toutes les équipes. Le tirage est affiché sur la transition de manche. Pas de
  relance.
- **Auto-calibrage** :
  - les équipes menées reçoivent **+3 s × écart après M1** et **+5 s × écart après M2**,
    plafonné à **+30 s**, sur leur premier tour non-continuation de la manche. L'écart se
    mesure par rapport à l'équipe en tête ;
  - l'équipe en tête reçoit **−1 s × écart**, plafonné à **−15 s**, sur son premier tour de la
    manche ;
  - l'app peut aussi donner un bonus du catalogue aux équipes menées, ou un malus à l'équipe en
    tête, choisi selon l'écart. Les poids sont « au doigt mouillé », à recalibrer plus tard ;
  - le rattrapage se cumule avec le report de temps de fin de manche existant
    (`turnBonusTime` / `pendingBonusTurnId`) ;
  - en cas d'égalité : pas de rattrapage et pas de 1 parmi 3 pour cette manche. Le tirage
    symétrique s'applique quand même.

### Mode Personnalisé : les « ensembles »

- On crée un ensemble (le **nom est obligatoire**) ou on en réutilise un. **10 au maximum par
  téléphone.** Actions : Utiliser / Modifier (sur place) / Dupliquer / Supprimer (avec
  confirmation).
- Un ensemble contient **uniquement les règles Fiesta**. Les réglages de base (équipes, mots,
  durée, pénalité de passe) restent par téléphone, comme aujourd'hui.
- L'éditeur règle :
  - pour chaque modificateur : actif ou non ; comment il arrive (tiré pour tous / proposé à
    l'équipe menée en « 1 parmi 3 » / fixé sur la manche N) ; à partir de quelle manche ;
    charges ;
  - le **1 parmi 3** : à chaque transition de manche, chaque équipe non en tête choisit 1 offre
    parmi 3 (bonus ou malus). La force de l'offre suit l'écart. On commence par la dernière
    équipe ;
  - les curseurs du rattrapage ;
  - le nombre de modificateurs tirés pour tous, de 0 à 2 ;
  - les règles communes.
- L'éditeur **bloque l'enregistrement** d'une configuration impossible, avec une explication
  (exemple : un modificateur réglé sur « tiré pour tous » alors que le tirage est à 0).
- Les ensembles sont une **nouvelle clé `guessItAll_*`**, versionnée via `persisted_schema`
  dès le premier jour. C'est le **seul** ajout de format persisté en dehors de `GameState`.

### Règles communes (Auto et Personnalisé)

- **Une seule réponse** (fil rouge) : une proposition par mot. Une mauvaise réponse oblige à
  passer, et la pénalité de passe s'applique. **Simple annonce** : l'app ne vérifie rien.
  Activée par défaut, désactivable.
- Le report de temps de fin de manche est conservé.
- Les **3 manches restent codées en dur**. Pas de manche 4 : le dessin est une contrainte de la
  manche 3.

### Modèle de modificateur

- `{id catalogue, portée manche|tour, cible les deux|équipe|joueur, charges, nature}`.
- Le **catalogue est codé en dur**. Seules les instances actives sont persistées, dans
  `GameState`, en **champs optionnels** (absent = Classique), **sans incrémenter
  `kCurrentSchemaVersion`**. Une partie commencée avant la mise à jour se relit en Classique.
- Le mode Fiesta et sa configuration sont **gelés dans `GameState` au lancement** de la partie.
- **2 modificateurs actifs au maximum par équipe et par tour.**
- Table d'incompatibilités : « deux mots » ✗ « interdit de passer » ; « dessiner » ✗ les
  contraintes de mime ; … (complément de la maquette : voir Q14).
- Le retour arrière (`savePreValidationState` capture déjà `GameState.toJson`) doit restaurer
  l'état Fiesta et **rendre une charge dépensée sur un tour annulé**.
- Les scores restent dans `Team`.

### Catalogue V1

| Id proposé | Nom | Nature | Notes |
|---|---|---|---|
| `mime_no_arms` | Mime sans les bras | malus | contrainte annoncée, manche 3 |
| `mime_eyes_closed` | Mime les yeux fermés | malus | contrainte annoncée, manche 3 |
| `draw` | Dessiner | malus | manche 3 seulement |
| `no_pass` | Interdit de passer | malus | bouton Passer désactivé |
| `free_pass` | Passe gratuite ×N | bonus | les N premières passes du tour sans pénalité |
| `minus_10s` | Malus de 10 s | malus | le tour démarre avec 10 s de moins |
| `double_points` | Mot compte double | bonus | 1 charge par équipe et par manche, activée avant son propre tour, ×2 sur les points du tour via une variante **pure** de `resolveTurn` |
| `two_words` | Deux mots à la fois | bonus | voir story 2-11 ; **tier risqué** car il casse le modèle « un mot courant / un mot expiré » de `turn_resolution.dart` |
| `reversed` | Mot à l'envers | malus | MAJUSCULES inversées (« CINATIT »), chaîne entière pour les entrées à plusieurs mots ; les deux cartes avec « deux mots » ; vérification et résultats en clair |
| `block_guesser` | Bloquer un devineur | malus | les adversaires choisissent un joueur qui DEVINE, bloqué un tour ; simple annonce, rotation inchangée ; impossible si l'équipe a ≤ 2 joueurs |

Les ids sont des propositions : la story 2-2 les fige.

### Écartés

Lettre par lettre ; bloquer celui qui fait deviner ; émotion ; zozoter ; 4 mots interdits ;
validation libre ; mot hors partie / mutation ; mots les plus durs en priorité ; relancer le
tirage ; économie de budget / points ; « auto-équilibrée » comme politique à part ; « Pass
fêtard » payant (monétisation en pause).

### Analytics

- Chaque événement de mot enregistre le ou les modificateurs actifs au moment où il a été joué
  (champs **additifs, nullables**).
- Rien n'est exclu des stats, et la difficulté initiale du mot est conservée.
- Mode et modificateurs ajoutés à `GameAnalytics` et `GameResult`, en champs optionnels
  additifs.

### Risque connu dans le code

`timeSpent = _settings.turnDuration - _game.timeRemaining`
(`lib/providers/game_provider.dart:869`) est **déjà faux** pour les continuations : un tour de
7 s reportés terminé à 2 s compte 28 s. Le rattrapage et le malus aggravent l'erreur. Il nourrit
`averageTimePerWordRanking` (`lib/models/stats_aggregation.dart:67-75`). Il faut stocker la durée
réelle du tour (story 2-6).

### Hors périmètre

- **i18n reportée** : les textes Fiesta s'écrivent en français, comme aujourd'hui (epic-4).
- Règle des **tests minimaux** (`guessitall-orchestration`) : un test seulement pour un
  invariant du tier risqué ou un bug reproduit.

## Stories

Tier : **R** = tier risqué, numéroté comme dans `CLAUDE.md` (① machine à états, ② scoring,
③ schéma `SharedPreferences`, ④ sync, ⑤ analytics, ⑥ timer et cycle de vie). **L** = léger
(UI seule).

Collisions : **GP** = `lib/providers/game_provider.dart`, **GS** = `lib/models/game_state.dart`,
**ST** = `lib/services/storage_service.dart` + clés `guessItAll_*` + `persisted_schema.dart`,
**AN** = `lib/services/analytics_service.dart` (contrat d'événements).

| Id | Story | Tier | Collisions | Dépend de |
|---|---|---|---|---|
| [2-2](2-2-fondation-modele-fiesta.md) | Fondation : catalogue, modèle, champs optionnels de `GameState`, gel au lancement | R ① ③ | GS, GP | — |
| [2-3](2-3-ensembles-stockage-editeur.md) | Ensembles : clé versionnée, validation, liste et éditeur | R ③ (+ L écrans) | ST (nouvelle clé) | 2-2 |
| [2-4](2-4-selection-mode-auto-recap.md) | Choix du mode, écran Auto, récap, lancement et « Rejouer » | L (+ GP) | GP | 2-2, 2-3 |
| [2-5](2-5-tirage-symetrique-transition.md) | Tirage symétrique, transition de manche et annonces avant le tour | R ① | GP, GS | 2-2 |
| [2-6](2-6-temps-rattrapage-duree-reelle.md) | Temps du tour : rattrapage, malus de temps, durée réelle | R ⑥ ① | GP, GS | 2-5 |
| [2-7](2-7-analytics-archive-recap.md) | Analytics, archive et récap des résultats | R ⑤ | AN, GP, GS | 2-5, 2-6 |
| [2-8](2-8-effets-de-tour-catalogue.md) | Effets de tour : interdit de passer, passe gratuite, bloquer un devineur, contraintes annoncées, mot à l'envers | R ⑥ ② | GP, GS | 2-5, 2-7 |
| [2-9](2-9-mot-compte-double.md) | Mot compte double : charges, activation, score ×2, retour arrière | R ② ① | GP, GS | 2-8 |
| [2-10](2-10-un-parmi-trois-coup-de-pouce.md) | 1 parmi 3 (Personnalisé) et coup de pouce du catalogue (Auto) | R ① | GP, GS | 2-6, 2-9 |
| [2-11](2-11-deux-mots-a-la-fois.md) | Deux mots à la fois | R ① ② ⑤ ⑥ | GP, GS, AN | 2-7, 2-9 |

Dix stories, toutes ancrées sur le code de `origin/main` au 2026-11-03 (commit `de3c8af`).

## Lanes et ordre proposés

Presque tout passe par `game_provider.dart` et `game_state.dart` : c'est **une seule lane
séquentielle** (lane A). Seule la story des ensembles (2-3) ne touche ni l'un ni l'autre, et
peut courir en parallèle (lane B).

```
Lane A (GP/GS, séquentielle) : 2-2 ──► 2-5 ──► 2-6 ──► 2-7 ──► 2-8 ──► 2-9 ──► 2-10 ──► 2-11
                                 │
Lane B (ST + écrans)          :  └──► 2-3 ──► 2-4 (entre dans la lane A dès que 2-5 est mergée)
```

1. **2-2** seule. Elle pose les types dont tout le reste dépend.
2. Dès que 2-2 est mergée : **2-5** (lane A) **en parallèle de 2-3** (lane B). 2-3 crée sa propre
   clé et ses propres écrans, et ne touche ni `GP` ni `GS`.
3. **2-4** touche `GP` (lancement de partie, « Rejouer ») : elle entre dans la lane A entre 2-5 et
   2-6, ou juste après 2-6, selon ce qui finit en premier. Avant 2-4, une partie Fiesta ne se
   lance que dans les tests (en construisant un `GameState`) : les recettes device commencent
   après 2-4.
4. Ensuite 2-6 → 2-7 → 2-8 → 2-9 → 2-10 → 2-11, un merge à la fois.

Pourquoi les analytics (2-7) passent avant les effets de tour : 2-8 à 2-11 doivent chacun
taguer leurs événements, et 2-11 réécrit le suivi « un mot affiché à la fois »
(`analytics_service.dart:32-38`, `:238`). Poser le champ « modificateurs actifs » d'abord évite de
repasser trois fois sur le contrat d'événements.

Modèle par lane (`guessitall-workflow` §Parallélisme) : **Fable** pour 2-2, 2-6, 2-9, 2-11 (état,
temps, score, modèle de mot) ; **Opus** pour les autres.

**Gate ③** (`guessitall-orchestration` §7) : **dû**, puisque plus de deux stories sont
sérialisées sur `GP`/`GS`. Point clé de la revue cumulée : la garantie de retour arrière de 2-2
tient-elle encore après les chemins ajoutés par 2-8, 2-9, 2-10 et 2-11 ?

**Recettes device** (Android + iOS, depuis Windows) : chaque story liste les siennes. Florent
peut les grouper en une soirée de test après 2-11, mais 2-4 et 2-6 méritent une passe au fil de
l'eau : elles changent le parcours d'entrée et le chrono.

## Questions ouvertes

À trancher par Florent. Chacune porte une recommandation ; la story concernée l'applique **par
défaut** et le signale dans sa PR. Un arbitrage différent coûte une retouche localisée.

| # | Question | Story | Recommandation |
|---|---|---|---|
| Q1 | La maquette `cd2` additionne « durée de base 30 s + temps reporté 7 s + rattrapage » sur **un même tour**. Le code fait autrement : le report est un **tour de continuation** qui ne dure que les secondes reportées (`startTurnTimer`, `game_provider.dart:524`). Quel modèle ? | 2-6 | Garder le code : la continuation reste un tour court, le rattrapage tombe sur le tour suivant. On corrige la maquette. |
| Q2 | Le malus du leader (−1 s × écart) se mesure par rapport à quelle équipe ? Et « son premier tour de la manche » compte-t-il une continuation ? | 2-6 | L'écart avec la 2ᵉ équipe. On l'applique au premier tour **non-continuation**, comme le bonus. |
| Q3 | Que veut dire « égalité » à 3 ou 4 équipes ? | 2-6, 2-10 | Égalité = **toutes** les équipes au même score. Avec des co-leaders, ils sont tous « en tête » (pas de rattrapage, malus mesuré par rapport à la meilleure équipe non leader) ; les autres sont menées. |
| Q4 | Plancher de durée d'un tour ? Le minimum réglable est de 20 s (`AppConstants.minTurnDuration`, `constants.dart:16`) ; avec −10 s (tirage) et −15 s (leader), on arrive à 0. | 2-6 | Plancher de **10 s** après tous les malus. |
| Q5 | Les modificateurs de temps (malus de 10 s, rattrapage, malus du leader) s'appliquent-ils aux tours de continuation ? | 2-6 | Non : la continuation garde exactement les secondes reportées. Les modificateurs d'affichage et de règle (interdit de passer, à l'envers…) s'appliquent, eux. |
| Q6 | « Une seule réponse » + « Interdit de passer » : après une mauvaise réponse, l'équipe ne peut ni répondre ni passer. | 2-8 | C'est voulu (malus dur) : l'annonce le dit (« mot grillé jusqu'à la fin du tour »). Aucun code, seulement le texte. |
| Q7 | Une carte « 1 parmi 3 » choisie : quelle durée d'effet et quelle cible ? Comment se mesure la « force » d'un modificateur ? | 2-10 | Effet sur **toute la manche suivante**. Un bonus cible l'équipe qui choisit, un malus cible l'équipe en tête. Un bonus à charges donne +charges pour la manche. La force vient d'une table constante par modificateur (légère / moyenne / forte), avec les seuils de la maquette : écart ≤ 3 → légère, ≤ 7 → moyenne, > 7 → forte. Table « à recalibrer ». |
| Q8 | Plafond de 2 modificateurs par équipe et par tour : qui gagne quand on le dépasse ? | 2-5, 2-9, 2-10 | Le tirage symétrique d'abord. Les offres 1 parmi 3 et les cadeaux Auto excluent ce qui dépasserait. L'activation d'une charge est refusée, avec une explication, si 2 modificateurs sont déjà actifs. Les règles communes et le temps de rattrapage ne comptent pas. |
| Q9 | Mode Auto : « 1 à 2 » modificateurs tirés, au hasard ? | 2-5 | Oui : 1 ou 2 au hasard (50/50), tiré une fois par manche. |
| Q10 | Le choix du mode avant le lancement est-il persisté ? Seuls `GameState` et la clé des ensembles ont le droit de changer de format. | 2-4 | Non : il vit en mémoire jusqu'à `startGame`. Si l'app est tuée avant, on repart en Classique. Le « dernier ensemble utilisé » de la maquette va **dans** la clé des ensembles. |
| Q11 | Où se place l'écran Paramètres actuel dans le parcours ? Le bouton « Lancer : Joueurs → Équipes → Mots » de la maquette `recap` le saute, mais les réglages de base restent éditables. | 2-4 | Accueil → Mode de jeu → (Fiesta → Auto ou Personnalisé → Récap) → **Paramètres actuels** → Joueurs (et leurs mots) → Équipes → `startGame` (`teams_screen.dart:79`). Classique va directement aux Paramètres. |
| Q12 | « Rejouer » garde-t-il la configuration Fiesta ? | 2-4 | Oui : on relit la config gelée de la partie finie, puis on passe par le Récap (la maquette `results` → `recap`). |
| Q13 | Les noms d'ensembles doivent-ils être uniques ? Comment nommer un doublon ? | 2-3 | Pas d'unicité imposée. Doublon = « <nom> (copie) », tronqué à 30 caractères (`maxlength` de la maquette). |
| Q14 | Table d'incompatibilités : la décision s'arrête à « … ». La maquette ajoute « interdit de passer » ✗ « passe gratuite » et « sans les bras » ✗ « yeux fermés ». | 2-2 | Adopter la table de la maquette : `no_pass`✗`two_words`, `no_pass`✗`free_pass`, `mime_no_arms`✗`mime_eyes_closed`, `mime_no_arms`✗`draw`, `mime_eyes_closed`✗`draw`. |
| Q15 | « Bloquer un devineur » tiré pour tous : qui choisit pour chaque équipe à 3 ou 4 équipes ? | 2-8 | L'app affiche « Les adversaires choisissent » et la liste des devineurs. Personne n'est désigné : c'est une annonce. |
| Q16 | « Fixé sur la manche N » (Personnalisé) : quelle cible ? | 2-5 | Toutes les équipes, pendant toute la manche N, en plus du tirage (lecture de la maquette `edit`). |

## Pièges transverses (valables pour toutes les stories)

- **Tout l'état Fiesta vit dans `GameState`**, jamais dans des champs du provider : c'est ce qui
  le fait survivre à un kill de l'app (`_saveGameState`, `game_provider.dart:124`) et ce qui le
  fait restaurer par le retour arrière (`savePreValidationState` / `restorePreValidationState`,
  `game_provider.dart:1334-1392`). Un compteur posé ailleurs n'est ni persisté ni restauré.
- **Une partie Classique ne change pas.** Toute nouvelle branche est gardée par « `fiesta` est
  absent ». Les tests existants (`test/models/turn_resolution_test.dart`,
  `test/providers/turn_time_test.dart`, `test/models/game_state_test.dart`) doivent rester
  verts **sans modification**.
- **`TurnClock` reste la seule autorité sur le temps** (`lib/models/turn_clock.dart`). On ne
  calcule pas de temps dans un widget.
- **Pas de `Platform.*`** (`CLAUDE.md` règle 8). Les nouveaux dialogues passent par `AppModal`.
- `GameSettings` (`lib/models/game_settings.dart`) **ne change pas** : un ensemble n'en contient
  aucun champ.
