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
            '${passPenaltySentence(passPenalty).toLowerCase()}',
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
            'quand c\'est fait.',
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
        title: 'Tour précédent',
        text: 'Les mots trouvés au tour d\'avant. Retiens-les : les mêmes '
            'mots reviennent à chaque manche.',
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

List<CoachStep> transitionHelp({
  required GlobalKey previousTurn,
  required GlobalKey next,
  required GlobalKey back,
  required GlobalKey home,
}) =>
    [
      CoachStep(
        target: previousTurn,
        title: 'Mots du dernier tour',
        text: 'Revois les mots trouvés pendant le dernier tour.',
      ),
      CoachStep(
        target: next,
        title: 'Manche suivante',
        text: 'Lance la manche suivante : tous les mots retournent dans le '
            'chapeau, avec une nouvelle règle. Après la dernière manche, ce '
            'bouton devient « Voir les résultats ».',
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
  required GlobalKey badges,
  required GlobalKey doublePoints,
  required GlobalKey turnTime,
}) =>
    [
      CoachStep(
        target: badges,
        title: 'Actif ce tour',
        text: 'Les bonus et malus qui s\'appliquent à ton équipe pendant ce '
            'tour. Chaque badge s\'explique d\'un tap.',
      ),
      CoachStep(
        target: doublePoints,
        title: 'Mot compte double',
        text: 'Une charge par manche : active-la avant le tour, les points '
            'de ce tour comptent double.',
      ),
      CoachStep(
        target: turnTime,
        title: 'Temps du tour',
        text: 'Le détail du chrono : base, temps reporté, rattrapage et '
            'malus. Le total est le temps que tu auras.',
      ),
    ];

// ========== FIESTA : FIN DE MANCHE ==========

List<CoachStep> fiestaTransitionHelp({
  required GlobalKey catchUp,
  required GlobalKey pickThree,
  required GlobalKey appBoost,
}) =>
    [
      CoachStep(
        target: catchUp,
        title: 'Rattrapage',
        text: 'L\'équipe menée gagne du temps à la manche suivante, l\'équipe '
            'en tête en perd un peu.',
      ),
      CoachStep(
        target: pickThree,
        title: 'Choix 1 parmi 3',
        text: 'L\'équipe menée prend le téléphone et choisit une carte : un '
            'bonus pour elle ou un malus pour l\'équipe en tête.',
      ),
      CoachStep(
        target: appBoost,
        title: 'Coup de pouce',
        text: 'En mode Auto, personne ne choisit : l\'app donne elle-même un '
            'coup de pouce à l\'équipe menée.',
      ),
    ];
