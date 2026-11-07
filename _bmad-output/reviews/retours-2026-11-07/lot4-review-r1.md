# Revue lot 4 — round 1

Portée : lecture statique du patch par rapport à `origin/feat/retours-regles`, et du code appelant. Aucun test ni build n'a été lancé ; aucun fichier de production n'a été modifié.

## BLOCKER

Aucun.

## MAJOR

### MAJOR — Le tutoriel Fiesta peut s'ouvrir et être définitivement consommé après un retour immédiat en Classique

**Emplacement :** `lib/screens/settings_screen.dart:90-95`

**Scénario concret :** sur une première ouverture (tutoriel Fiesta non vu), toucher « Fiesta » lance `chooseFiestaMode()` et attend la lecture des ensembles. Avant son retour, toucher « Classique ». `setPendingFiesta(null)` laisse bien le mode Classique, et le garde d'identité empêche la règle tardive de revenir. Mais `_setMode` reprend ensuite à la ligne 91 sans revérifier le mode : il ouvre `FiestaTutorialScreen`. Cette ouverture appelle immédiatement `markFiestaTutorialSeen()` (`fiesta_tutorial_screen.dart:20`). Le joueur voit donc le tutoriel alors qu'il est en Classique, puis ne le verra plus lors de sa vraie première partie Fiesta.

**Correction proposée :** après chaque `await` de ce flux — au minimum après `hasSeenFiestaTutorial()` — ne montrer le tutoriel que si le widget est toujours monté **et** si `provider.pendingFiesta != null`. Ajouter un test widget qui déclenche ce changement Fiesta → Classique pendant l'attente et vérifie à la fois l'absence de modal et de flag écrit.

### MAJOR — Le garde par identité ne protège pas une nouvelle sélection de Fiesta classique

**Emplacement :** `lib/providers/game_provider.dart:112-135`

**Scénario concret :** le dernier ensemble utilisé est « Pro Player ». Une activation Fiesta pose l'objet singleton `classicEnsemble.rules` et commence sa relecture asynchrone. Pendant cette attente, le joueur ouvre Avancés, choisit explicitement « Fiesta classique » et valide : `onValidate` repose exactement le même objet singleton. La lecture initiale, qui a déjà lu « Pro Player », voit alors `identical(_pendingFiesta, expected)` à vrai et remplace la validation explicite par « Pro Player ». Le mode finalement lancé ne correspond plus au bouton « Valider » du joueur.

**Correction proposée :** protéger la relecture par un jeton de génération/incrémenté à chaque `setPendingFiesta`, plutôt que par l'identité de `FiestaRules`. La relecture ne doit appliquer son résultat que si le jeton capturé est encore courant. Couvrir le cas d'une validation explicite de Fiesta classique pendant une lecture retardée.

## MINOR

### MINOR — Le suffixe joueur « (ancienne version) » dépasse D8

**Emplacement :** `lib/screens/settings_screen.dart:105-115`

**Scénario concret :** une partie rejouée dont les règles gelées portent encore le nom « Fiesta classique » mais diffèrent de l'ensemble actuel affichera `Ensemble : Fiesta classique (ancienne version)`. D8 demande seulement `Ensemble : <nom>` hors Fiesta classique et ne prévoit ni comparaison JSON ni texte additionnel. Le joueur reçoit donc un libellé inédit, non spécifié, et la logique/test associée ajoute une surface de maintenance sans nécessité pour le parcours demandé.

**Correction proposée :** retirer `_isCurrentClassic` / le suffixe et afficher strictement le nom décidé par D8 ; si ce signal historique est souhaité par Florent, l'ajouter explicitement à D8 avant de le conserver.

## Points contrôlés sans finding

- Les chemins rejouer (résultats et accueil), `replayFromHistory`, reprise après kill et retour aux équipes préservent les règles gelées quand `replayFiesta` ou `allWords` l'indique. Les règles historiques (`draw` en Toujours, `two_words`, compteurs) ne font pas échouer `startGame` : `two_words` reste lisible mais n'est plus dans le catalogue actif, donc il n'est ni tiré ni joué.
- `forgetLastUsed()` ne modifie pas la forme persistée : il réécrit le même blob et omet simplement une clé déjà facultative, en conservant les entrées illisibles. `markUsed` est attendu avant `onValidate` ; ce chemin ne lit donc pas une écriture inachevée.
- Pour le clavier, `MediaQuery.padding` est bien `max(0, viewPadding - viewInsets)` : avec le clavier qui recouvre la zone sûre, le `SafeArea` n'ajoute pas une seconde fois le bas. L'aide ignore proprement `_nextKey` lorsqu'il est démonté (`CoachMarks.show` filtre les cibles sans contexte). Les 2 000 px couvrent les 20 lignes maximales ; conserver `cacheExtent` est justifié tant que les recettes Windows restent en Flutter 3.38, qui ne connaît pas `scrollCacheExtent` (l'avertissement de dépréciation 3.44 est non fatal dans le CI).
- Les trois widget tests de la ligne « Ensemble » ne sont pas redondants : ils couvrent les trois branches d'état (absence, ensemble non classique, règles gelées). Ils verrouillent une condition métier/compatibilité, pas seulement la mise en forme.

## Verdict

**NOT READY** — corriger les deux courses MAJOR avant validation ; trancher explicitement le surplus de texte MINOR.
