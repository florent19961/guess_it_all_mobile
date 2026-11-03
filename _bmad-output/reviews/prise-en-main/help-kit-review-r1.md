# Revue — kit d'aide (prise en main), round 1 (Opus, à la place de Codex)

Worktree `feat/help-kit @ e80d377`. Patch lu : `help-kit-patch-r1.diff`. Tests ciblés lancés :
`help_flags_test`, `help_content_test`, `home_screen_new_game_test` → **4/4 verts**.

## Verdict : NOT READY

2 MAJOR, tous deux petits à corriger. Aucun BLOCKER : `CoachMarks` et `FirstGameHelp` ne sont
encore branchés nulle part en prod (seuls Accueil + Règles le sont) ; la règle 7 est respectée
(3 clés booléennes neuves, absentes = false, rien de renommé, aucune migration).

---

## MAJOR

### M1 — `CoachMarks` : la bulle peut sortir de l'écran, et deux sorties laissent un voile sans bulle → sur iOS, plus aucune issue

`lib/widgets/help/coach_marks.dart:118-133` et `:73`, `:75`

- **Bulle hors écran.** Pour poser la bulle au-dessus ou au-dessous, le code compare la place
  libre à un `minSpace = 180` fixe. Mais la `Positioned` n'a qu'un bord (`top` OU `bottom`), donc
  aucune hauteur maximale. Or la bulle dépasse déjà 180 px à taille de texte normale pour les
  textes longs : `preTurnHelp` étape 1 fait environ 200 px, `verificationHelp` environ 300 px. Et
  l'app ne plafonne pas `textScaler` (vérifié : rien dans `lib/`). Exemple : une cible au milieu
  bas de l'écran, avec 180 à 300 px libres en dessous, ou n'importe quelle cible avec le grand
  texte système. La rangée Passer / Suivant / Compris passe alors sous le bord de l'écran. Le
  voile avale tous les taps (`GestureDetector` opaque) et iOS n'a pas de retour système :
  **l'utilisateur est coincé**, il doit tuer l'app. En placement « au-dessus », la bulle grandit
  vers le haut sans borne, avec le même risque.
- **Voile sans bulle.** Aux lignes `:73` (`!targetContext.mounted`) et `:75`
  (`box == null || !box.hasSize`), la fonction fait un simple `return` après le `setState` de
  `_next` qui a mis `_hole = null`. Résultat : un voile plein, sans bulle ni bouton. Exemple : la
  cible est démontée pendant les 250 ms de `ensureVisible`. Ça arrive quand une liste paresseuse
  recycle l'élément, ou quand `app.dart` change de `currentScreen` sous l'overlay (fin de tour,
  changement d'état Fiesta). Même blocage sur iOS.
- **Correction (petite).**
  1. Bulle en dessous : `top: hole.bottom + 14` **et** `bottom: padding.bottom + 16`. Bulle
     au-dessus : `top: padding.top + 16` **et** `bottom: height - hole.top + 14`. Dans les deux
     cas, contenu dans un `Align` (vers la cible) avec un `SingleChildScrollView` autour du texte.
     Les boutons restent toujours visibles.
  2. Aux lignes `:73` et `:75`, remplacer `return` par `if (mounted) _next();`.

  Pas besoin de test widget : un check manuel avec le grand texte suffit au moment du
  branchement.

### M2 — La déduction au démarrage ne tourne pas « une seule fois » : une première partie abandonnée efface les aides auto au redémarrage suivant

`lib/services/storage_service.dart:159-166` · `lib/widgets/help/WIRING.md:81`

- Le commentaire (« historique des mots écrit en fin de partie seulement ») et `WIRING.md:81`
  sont **faux**. `GameProvider.startNewGame()` et `restartWithSamePlayers()` appellent
  `_analytics.endGame()` quand une partie est suivie (`game_provider.dart:1766-1791`). Or
  `endGame()` incrémente `WordHistoryService` avec **tous** les mots de la partie, posés dès
  `startGame`.
- **Scénario.** Installation neuve. Première partie lancée, puis Accueil → « Nouvelle partie » →
  confirmer (abandon). Ou « Rejouer » avant la fin. On redémarre l'app (ou l'OS la tue entre deux
  soirées). Au démarrage suivant, `firstGameDone` est absent et l'historique des mots n'est pas
  vide. Le flag passe donc à `true`. La vraie première partie, jouée ensuite, n'a plus aucune aide
  auto. C'est contraire à la règle 1 de Florent. Le check 1 l'interdit aussi : la déduction doit
  tourner une fois.
- **Correction (code judo, moins de cas).** Décider **une fois**, au premier démarrage de cette
  version : pour chaque flag absent, écrire `true` s'il existe un historique, **sinon `false`**.
  Le flag est alors présent, et plus aucun démarrage ne le recalcule. La règle « un `false` écrit
  prime » reste vraie. Une install neuve ne peut plus être basculée par un abandon. Mettre à jour
  le commentaire, `WIRING.md:81` et le test : ajouter le cas « prefs vides → flags écrits
  `false` ; puis historique ajouté → la déduction ne change rien ».

---

## MINOR

1. **Tuto Fiesta faux pour le mode Auto** (`lib/screens/fiesta_tutorial_screen.dart:40-43`).
   La carte 2 présente « Choix 1 parmi 3 : l'équipe menée choisit une carte » comme valable dans
   tous les modes. Or `isPickThreeOn` exige le mode Personnalisé avec `oneOfThree` allumé
   (`offers.dart:99`), et en Auto c'est le coup de pouce de l'app (`isAppBoostOn`). La carte 3 dit
   d'ailleurs « Auto : personne ne choisit » : les deux cartes se contredisent. Correction :
   remplacer la ligne 2 par « Choix 1 parmi 3 (Personnalisé) / Coup de pouce (Auto) ». De plus,
   avec 3 équipes ou plus, ce sont les équipes non en tête qui choisissent, au pluriel
   (`choosingOrder`).
2. **Tu et vous mélangés dans le même texte.** `help_content.dart:240` contient « Les mots que
   **vous** avez trouvés… **Touche** le mot… ». `rules_tutorial_screen.dart:52-56` contient
   « à **ton** équipe… **retenez** bien… ». Choisir une seule forme : tutoiement adressé à celui
   qui tient le téléphone, ou « vous » partout.
3. **`WIRING.md:36` : quelle pénalité passer à `turnHelp`.** Préciser
   `passPenalty: provider.currentPassPenalty`, et non `settings.passPenalty`. En Fiesta, la Passe
   gratuite met la pénalité à 0 (`game_provider.dart:1311`). Avec le malus « Interdit de
   passer », le bouton reste monté mais désactivé, et le texte « Passe-le » devient faux. Il faut
   alors ne pas poser la clé `pass`, ou adapter le texte.
4. **« Revoir les aides » promet une chose qui n'existe pas encore**
   (`lib/screens/rules_screen.dart:178`). La modale annonce « chaque joueur reverra les aides à
   son premier tour », mais l'avant-tour, la vérification et `finishFirstGame` ne sont pas
   branchés dans ce patch. Si une release part entre ce merge et le branchement, le bouton ne fait
   rien de visible. Correction : ne pas sortir de release avant le branchement, ou masquer le
   bouton d'ici là.
5. **`FirstGameHelp` après un kill en pleine partie** (`first_game_help.dart:15`). Après une
   reprise, `_shown` est vide. Les joueurs qui ont déjà eu l'aide la revoient une fois à leur
   prochain tour. C'est documenté et sans gravité ; accepté tel quel. `isFirstGameDone` est relu
   à chaque `claim`. Une partie reprise reste donc bien une « première partie », et la déduction
   ne se déclenche pas sur un kill : `finalizeOrphanedGames` n'incrémente pas l'historique des
   mots.
6. **Tuto : les points de pagination restent roses en Fiesta** (`tutorial_pager.dart:107`).
   Utiliser `widget.accent`, comme pour le symbole.
7. **Couches : `StorageService` dépend maintenant de `GameHistoryService` et de
   `WordHistoryService`** (`storage_service.dart:5,7`), et `_hasPlayedBefore` relit le JSON de
   l'historique des mots à la main. Comme les tâches locales tournent dans l'ordre,
   `WordHistoryService` est déjà initialisé à ce moment. Une petite propriété
   `WordHistoryService().hasHistory` (cache non vide) supprime ce second parseur. Mieux encore :
   sortir la déduction de `StorageService` et la placer dans `FirstGameHelp` (le service bas
   niveau n'a pas à connaître les services métier). Dans ce cas, `storageKey` n'a plus besoin
   d'être public. L'alias `_historyKey = storageKey` (`word_history_service.dart:19`) est en
   double : n'en garder qu'un.
8. **Mesure de la cible prise une seule fois** (`coach_marks.dart`). Aucune nouvelle mesure en
   cas de changement de taille (écran partagé, pliable, clavier). L'orientation est bloquée en
   portrait (`main.dart`) ; portrait inversé, la géométrie ne change pas. Acceptable : à noter
   dans `WIRING.md`.

## NIT

- `FirstGameHelp.preTurn` / `verification` sont des chaînes : un `enum` est plus sûr.
  `HelpButton` utilise `right == null` pour dire « inline », un sentinel nullable ; acceptable.
- Rattrapage et 1 parmi 3 disent « équipe menée » / « en tête ». Ce n'est pas un score (règle 4
  respectée à la lettre), mais ça révèle le classement. La mécanique Fiesta le révèle déjà ; à
  confirmer avec Florent si la règle 4 se lit au sens large.

---

## Les 6 contrôles demandés

1. **Flags.** Additifs ; absent = false ; un `false` explicite prime (testé). La déduction se
   lance avant `runApp` (tâches locales séquentielles, après l'init de `WordHistoryService`) et
   ne se trompe pas sur une installation neuve. Elle ne se trompe pas non plus pendant la première
   partie : ni un kill ni `finalizeOrphanedGames` n'écrivent l'historique des mots. **Mais elle
   n'est pas « une fois »** : voir M2. « Revoir les aides » remet `firstGameDone` à `false` et
   vide `_shown` : OK.
2. **CoachMarks.** Les clés non montées sont bien sautées, au départ (`show`) comme en cours de
   route (`_focusCurrent` → `_next`), et la boucle se termine toujours. Pas de fuite : la route
   est poppée, et un double tap pendant l'animation de sortie est ignoré par le `ModalRoute`. Le
   retour Android ferme l'overlay et les tutos (route du dessus). Sur iOS, Passer est toujours
   présent dans les tutos. **Problèmes : grand texte, petit écran, cible démontée → M1.**
3. **FirstGameHelp.** Une fois par joueur et par écran, en mémoire. Après un kill, l'aide est
   revue une fois (MINOR 5, accepté).
4. **Contenu.** Pénalité : 0 s → « Passer ne coûte rien. », 3 s et 5 s → « Le chrono perd N s. ».
   C'est juste : la pénalité retire du temps au chrono (`clock.applyPenalty`). Aucun score en cours
   de partie : la carte 4 du tuto dit qu'on découvre les scores à la fin. La vérification est très
   explicite (vert, rouge, toucher, défiler) et conforme à `verification_screen` : mots devinés en
   vert, mot expiré en rouge, toucher bascule. Autres textes vérifiés et justes : décompte de 3 s,
   info de la manche, tap sur l'équipe, « Tour précédent », Mélanger, crayon, glisser-déposer,
   « Ce nom existe déjà », 2 joueurs minimum. Le tuto Fiesta est faux pour Auto (MINOR 1).
5. **Test d'accueil ajusté.** Légitime : seul test qui monte `HomeScreen`. Il sème
   `tutorialSeen = true` pour garder son objet, « Jouer » → choix du mode sans réinitialiser les
   réglages. Aucun autre test ne passe par « Jouer ».
6. **Qualité.** Taille raisonnable : aucun fichier ne dépasse 1 000 lignes, `help_content` fait
   375 lignes de données pures. Pas de sur-ingénierie notable : `CoachMarks` tient en une route,
   `TutorialPager` est partagé par les deux tutos. Les textes des écrans non branchés sont du code
   mort jusqu'au branchement : choix de lane assumé. Points de couches et de doublon : MINOR 7.
