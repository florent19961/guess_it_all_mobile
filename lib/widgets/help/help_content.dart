import 'package:flutter/widgets.dart';
import 'coach_marks.dart';

/// Textes des aides, écran par écran.
///
/// Une fonction par écran : elle reçoit les clés que l'écran a posées sur ses
/// contrôles et rend les étapes. Une clé non montée (bouton absent dans cet état
/// de l'écran) est simplement sautée par [CoachMarks.show].
///
/// 🔴 Les scores sont cachés pendant la partie : aucun texte ne parle d'un
/// score entre deux tours ou deux manches. Seuls les résultats finaux en
/// montrent.

/// Effet de la pénalité de passe, en une phrase. `GameSettings.passPenalty`.
String passPenaltySentence(int seconds) =>
    seconds <= 0 ? 'Passer ne coûte rien.' : 'Le chrono perd $seconds s.';

// ========== ACCUEIL ==========

List<CoachStep> homeHelp({
  required GlobalKey play,
  required GlobalKey resume,
  required GlobalKey replay,
  required GlobalKey rules,
  required GlobalKey history,
}) =>
    [
      CoachStep(
        target: resume,
        title: 'Reprendre',
        text: 'Une partie a été interrompue : reprends-la là où elle '
            's\'était arrêtée.',
      ),
      CoachStep(
        target: replay,
        title: 'Rejouer',
        text: 'Relance une partie avec les mêmes joueurs que la dernière '
            'fois.',
      ),
      CoachStep(
        target: play,
        title: 'Nouvelle partie',
        text: 'Lance une nouvelle partie : mode de jeu, réglages, joueurs, '
            'puis équipes.',
      ),
      CoachStep(
        target: rules,
        title: 'Règles',
        text: 'Les règles détaillées. Tu peux aussi y revoir le tuto et les '
            'aides.',
      ),
      CoachStep(
        target: history,
        title: 'Historique',
        text: 'Toutes les parties jouées sur ce téléphone.',
      ),
    ];

// ========== PARAMÈTRES ==========

List<CoachStep> settingsHelp({
  required GlobalKey mode,
  required GlobalKey counts,
  required GlobalKey wordChoice,
  required GlobalKey categories,
  required GlobalKey advanced,
  required int passPenalty,
}) =>
    [
      CoachStep(
        target: counts,
        title: 'Joueurs et équipes',
        text: 'Le nombre de joueurs, et d\'équipes. Il faut au moins '
            '2 joueurs par équipe.',
      ),
      CoachStep(
        target: mode,
        title: 'Classique ou Fiesta',
        text: 'Classique : les 3 manches habituelles. Fiesta : les mêmes '
            'manches, pimentées de bonus et de malus. En Fiesta, la roue '
            'crantée choisit Auto (l\'app décide de tout) ou Personnalisé '
            '(tes propres réglages, choisis juste après cet écran).',
      ),
      CoachStep(
        target: wordChoice,
        title: 'Choix des mots',
        text: 'Aléatoire : l\'app tire les mots au hasard. Personnalisé : '
            'chaque joueur écrit ses mots à la main, en cachette.',
      ),
      CoachStep(
        target: categories,
        title: 'Catégories & Difficultés',
        text: 'En aléatoire, choisis les thèmes et le niveau des mots tirés.',
      ),
      CoachStep(
        target: advanced,
        title: 'Avancés',
        text: 'Le nombre de mots, la durée d\'un tour et la pénalité quand on '
            'passe un mot. Avec tes réglages : '
            '${passPenaltySentence(passPenalty).toLowerCase()} En Fiesta, '
            'c\'est aussi là qu\'on passe d\'Auto à Personnalisé. Tout en '
            'bas : réinitialiser les paramètres.',
      ),
    ];

// ========== JOUEURS ==========

List<CoachStep> playersHelp({
  required GlobalKey firstPlayer,
  required GlobalKey words,
  required GlobalKey next,
}) =>
    [
      CoachStep(
        target: firstPlayer,
        title: 'Les joueurs',
        text: 'Écris le prénom de chaque joueur. Deux joueurs ne peuvent pas '
            'porter le même nom.',
      ),
      CoachStep(
        target: words,
        title: 'Les mots du joueur',
        text: 'En mode Personnalisé, chaque joueur écrit ici ses mots, sans '
            'les montrer aux autres. « Saisir mots » devient « Voir mots » '
            'quand c\'est fait. En mode Aléatoire, « N mots prêts » : l\'app '
            'a tiré les mots du joueur, ils restent cachés jusqu\'au jeu.',
      ),
      CoachStep(
        target: next,
        title: 'Suivant',
        text: 'Quand tout le monde est inscrit, passe à la composition des '
            'équipes.',
      ),
    ];

// ========== ÉQUIPES ==========

List<CoachStep> teamsHelp({
  required GlobalKey firstTeam,
  required GlobalKey shuffle,
  required GlobalKey start,
}) =>
    [
      CoachStep(
        target: firstTeam,
        title: 'Les équipes',
        text: 'Fais glisser un joueur d\'une équipe à l\'autre pour changer '
            'les équipes. Le crayon permet de renommer l\'équipe.',
      ),
      CoachStep(
        target: shuffle,
        title: 'Mélanger',
        text: 'Refait des équipes au hasard.',
      ),
      CoachStep(
        target: start,
        title: 'Commencer',
        text: 'Lance la partie. Il faut au moins 2 joueurs dans chaque équipe.',
      ),
    ];

// ========== FIESTA PERSONNALISÉE ==========

List<CoachStep> fiestaEnsemblesHelp({
  required GlobalKey ready,
  required GlobalKey create,
  required GlobalKey next,
}) =>
    [
      CoachStep(
        target: ready,
        title: 'Prêts à jouer',
        text: 'Les ensembles fournis par l\'app, puis les tiens. Touche-en un '
            'pour le choisir. Ceux de l\'app se dupliquent pour les modifier.',
      ),
      CoachStep(
        target: create,
        title: 'Créer un ensemble',
        text: 'Ouvre l\'éditeur : un nom, les règles de la partie, les malus '
            'et bonus, puis « Enregistrer ».',
      ),
      CoachStep(
        target: next,
        title: 'Suivant',
        text: 'Passe aux joueurs avec l\'ensemble choisi.',
      ),
    ];

List<CoachStep> fiestaEditorHelp({
  required GlobalKey rules,
  required GlobalKey modifiers,
  required GlobalKey save,
}) =>
    [
      CoachStep(
        target: rules,
        title: 'Règles de la partie',
        text: 'Combien de modificateurs sont tirés à chaque manche, et le coup '
            'de pouce : après les manches 1 et 2, chaque équipe menée reçoit '
            'une cartouche au hasard.',
      ),
      CoachStep(
        target: modifiers,
        title: 'Malus et bonus',
        text: 'Allume un modificateur, puis règle-le. « Toujours » et « Au '
            'tirage » valent pour toutes les équipes toute la manche ; une '
            'cartouche se joue au tour de son choix, et le compteur vaut pour '
            'toute la partie. Les bonus (dont le +10 s) ne sont que des '
            'cartouches.',
      ),
      CoachStep(
        target: save,
        title: 'Enregistrer',
        text: 'S\'il manque quelque chose, le message dit quoi.',
      ),
    ];

// ========== HISTORIQUE ==========

List<CoachStep> historyHelp({
  required GlobalKey trends,
  required GlobalKey firstGame,
  required GlobalKey replay,
}) =>
    [
      CoachStep(
        target: trends,
        title: 'Tendances',
        text: 'Quelques chiffres sur toutes les parties jouées sur ce '
            'téléphone.',
      ),
      CoachStep(
        target: firstGame,
        title: 'Une partie',
        text: 'Touche une partie pour voir le détail : les équipes, leurs '
            'joueurs et les points.',
      ),
      CoachStep(
        target: replay,
        title: 'Rejouer',
        text: 'Relance cette partie avec les mêmes joueurs, les mêmes équipes '
            'et les mêmes réglages. Les mots, eux, sont nouveaux.',
      ),
    ];

// ========== AVANT LE TOUR (game_screen) ==========

/// Aussi affichée automatiquement au premier tour de chaque joueur pendant la
/// première partie sur ce téléphone.
List<CoachStep> preTurnHelp({
  required GlobalKey team,
  required GlobalKey roundRules,
  required GlobalKey previousTurn,
  required GlobalKey start,
  required String playerName,
}) =>
    [
      CoachStep(
        target: team,
        title: 'C\'est ton tour, $playerName',
        text: 'Tu fais deviner les mots à ton équipe. Pendant le tour, toi '
            'seul regardes l\'écran. Touche le nom de l\'équipe pour voir ses '
            'joueurs.',
      ),
      CoachStep(
        target: roundRules,
        title: 'La règle de la manche',
        text: 'Manche 1 : décrire. Manche 2 : un seul mot. Manche 3 : mimer. '
            'Touche ici pour relire la règle de cette manche.',
      ),
      CoachStep(
        target: previousTurn,
        title: 'Mots du tour précédent',
        text: 'Touche ici pour voir les mots trouvés au tour précédent. '
            'Retiens-les : ils reviennent aux manches suivantes.',
      ),
      CoachStep(
        target: start,
        title: 'Commencer le tour',
        text: 'Le chrono démarre après un décompte de 3 secondes. Prends le '
            'téléphone, cache l\'écran, et c\'est parti.',
      ),
    ];

// ========== TOUR ==========

List<CoachStep> turnHelp({
  required GlobalKey timer,
  required GlobalKey word,
  required GlobalKey guessed,
  required GlobalKey pass,
  required GlobalKey pause,
  required int passPenalty,
}) =>
    [
      CoachStep(
        target: timer,
        title: 'Le chrono',
        text: 'Quand il arrive à zéro, le tour s\'arrête.',
      ),
      CoachStep(
        target: word,
        title: 'Le mot',
        text: 'Fais-le deviner en suivant la règle de la manche, sans le '
            'montrer.',
      ),
      CoachStep(
        target: guessed,
        title: 'Trouvé',
        text: 'Ton équipe a trouvé le mot : touche ici, le suivant arrive.',
      ),
      CoachStep(
        target: pass,
        title: 'Passer',
        text: 'Mot trop dur ? Passe-le, il reviendra plus tard dans la '
            'manche. ${passPenaltySentence(passPenalty)}',
      ),
      CoachStep(
        target: pause,
        title: 'Pause',
        text: 'Un imprévu ? Mets le chrono en pause.',
      ),
    ];

// ========== VÉRIFICATION ==========

/// Écran souvent mal compris : le texte doit être très explicite.
List<CoachStep> verificationHelp({
  required GlobalKey wordList,
  required GlobalKey validate,
}) =>
    [
      CoachStep(
        target: wordList,
        title: 'Vérifie les mots',
        text: 'Les mots que ton équipe a trouvés doivent être en VERT. Ceux '
            'qu\'elle n\'a pas trouvés doivent être en ROUGE. Une erreur ? '
            'Touche le mot pour le corriger : il passe du vert au rouge, ou '
            'du rouge au vert. S\'il y a beaucoup de mots, fais défiler la '
            'liste pour tous les vérifier.',
      ),
      CoachStep(
        target: validate,
        title: 'Valider',
        text: 'Quand toutes les couleurs sont justes, valide. Le téléphone '
            'passe ensuite à l\'équipe suivante.',
      ),
    ];

// ========== ENTRE DEUX MANCHES (transition_screen) ==========

/// [fiesta] (`fiestaTransitionHelp`) se place à l'ordre de l'écran : sous le
/// héros et les mots du dernier tour, avant les boutons.
List<CoachStep> transitionHelp({
  required GlobalKey nextRound,
  required GlobalKey previousTurn,
  required GlobalKey next,
  required GlobalKey back,
  required GlobalKey home,
}) =>
    [
      CoachStep(
        target: nextRound,
        title: 'La manche suivante',
        text: 'Sa nouvelle règle, puis qui commence. Ce sont exactement les '
            'mêmes mots qu\'à la manche d\'avant.',
      ),
      CoachStep(
        target: previousTurn,
        title: 'Mots du dernier tour',
        text: 'Revois les mots trouvés pendant le dernier tour.',
      ),
      CoachStep(
        target: next,
        title: 'Lancer la manche',
        text: 'Lance la manche suivante.',
      ),
      CoachStep(
        target: back,
        title: 'Retour',
        text: 'Reviens à la vérification du dernier tour pour corriger un mot.',
      ),
      CoachStep(
        target: home,
        title: 'Accueil',
        text: 'Met la partie en pause et revient à l\'accueil. Tu pourras la '
            'reprendre avec « Reprendre ».',
      ),
    ];

// ========== RÉSULTATS ==========

List<CoachStep> resultsHelp({
  required GlobalKey podium,
  required GlobalKey details,
  required GlobalKey replay,
  required GlobalKey stats,
}) =>
    [
      CoachStep(
        target: podium,
        title: 'Le podium',
        text: 'Touche une marche pour voir les joueurs de cette équipe. '
            'Pratique si tu as oublié le nom de ton équipe.',
      ),
      CoachStep(
        target: details,
        title: 'Détails par manche',
        text: 'Les points de chaque équipe, manche par manche.',
      ),
      CoachStep(
        target: replay,
        title: 'Rejouer',
        text: 'Relance une partie avec les mêmes joueurs.',
      ),
      CoachStep(
        target: stats,
        title: 'Statistiques',
        text: 'L\'évolution des scores, les meilleurs joueurs et le temps '
            'moyen par mot.',
      ),
    ];

// ========== FIESTA : AVANT LE TOUR ==========

List<CoachStep> fiestaPreTurnHelp({
  required GlobalKey thisTurn,
  required GlobalKey reserve,
}) =>
    [
      CoachStep(
        target: thisTurn,
        title: 'Ce tour',
        text: 'Tout ce qui s\'applique à ton tour : les règles de la manche, '
            'les malus reçus d\'une autre équipe et les bonus que tu as '
            'activés. Appui long sur un cercle pour l\'explication.',
      ),
      CoachStep(
        target: reserve,
        title: 'Réserve',
        text:
            'Tes cartouches pour toute la partie, un tour chacune. Touche un bonus pour '
            'l\'activer ce tour ; touche un malus pour l\'infliger à une '
            'autre équipe, pour son prochain tour (annulable tant que ton '
            'tour n\'a pas commencé).',
      ),
    ];
