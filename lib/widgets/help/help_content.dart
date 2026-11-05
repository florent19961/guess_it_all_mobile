import 'package:flutter/widgets.dart';
import '../../models/fiesta/fiesta_rules.dart';
import '../../services/game_history_service.dart';
import 'coach_marks.dart';

/// Textes des aides, écran par écran.
///
/// Une fonction par écran : elle reçoit les clés que l'écran a posées sur ses
/// contrôles et rend les étapes. Une clé non montée (bouton absent dans cet état
/// de l'écran) est simplement sautée par [CoachMarks.show].
///
/// 🔴 Règle : élément affiché = une étape l'explique ; élément absent = pas
/// d'étape, et aucun texte n'en parle. Un écran ne pose donc la clé d'un élément
/// conditionnel que s'il est affiché, et passe ici l'état dont dépend un texte.
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
  required String playLabel,
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
        title: playLabel,
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
        text: 'Les ${GameHistoryService.maxEntries} dernières parties jouées '
            'sur ce téléphone.',
      ),
    ];

// ========== PARAMÈTRES ==========

List<CoachStep> settingsHelp({
  required GlobalKey mode,
  required GlobalKey counts,
  required GlobalKey wordChoice,
  required GlobalKey categories,
  required GlobalKey longGame,
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
            'manches, pimentées de bonus et de malus : l\'ensemble de règles '
            'se choisit juste après cet écran.',
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
        target: longGame,
        title: 'Partie longue',
        text: 'Avec autant de mots, la partie va durer. Le nombre de mots se '
            'règle dans Avancés.',
      ),
      CoachStep(
        target: advanced,
        title: 'Avancés',
        text: 'Le nombre de mots, la durée d\'un tour et la pénalité quand on '
            'passe un mot. Avec tes réglages : '
            '${passPenaltySentence(passPenalty).toLowerCase()} Tout en bas : '
            'réinitialiser les paramètres.',
      ),
    ];

// ========== JOUEURS ==========

List<CoachStep> playersHelp({
  required GlobalKey firstPlayer,
  required GlobalKey words,
  required GlobalKey next,
  required bool randomWords,
}) =>
    [
      CoachStep(
        target: firstPlayer,
        title: 'Les joueurs',
        text: 'Écris le prénom de chaque joueur. Deux joueurs ne peuvent pas '
            'porter le même nom. Les prénoms sont gardés d\'une partie à '
            'l\'autre : efface-en un pour le retirer.',
      ),
      if (randomWords)
        CoachStep(
          target: words,
          title: 'Mots prêts',
          text: 'L\'app a tiré les mots de chaque joueur. Ils restent cachés '
              'jusqu\'au jeu.',
        )
      else
        CoachStep(
          target: words,
          title: 'Les mots du joueur',
          text:
              'Chaque joueur écrit ici ses mots, sans les montrer aux autres. '
              '« Saisir mots » devient « Voir mots » quand c\'est fait.',
        ),
      CoachStep(
        target: next,
        title: 'Suivant',
        text: randomWords
            ? 'Quand tout le monde est inscrit, passe à la composition des '
                'équipes.'
            : 'Quand tout le monde a son prénom et ses mots, passe à la '
                'composition des équipes.',
      ),
    ];

// ========== ÉQUIPES ==========

List<CoachStep> teamsHelp({
  required GlobalKey firstTeam,
  required GlobalKey shuffle,
  required GlobalKey incomplete,
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
        target: incomplete,
        title: 'Équipe incomplète',
        text: 'Glisse des joueurs pour que chaque équipe en ait au moins 2. '
            '« Commencer » reste grisé d\'ici là.',
      ),
      CoachStep(
        target: start,
        title: 'Commencer',
        text: 'Lance la partie. Il faut au moins 2 joueurs dans chaque équipe.',
      ),
    ];

// ========== ENSEMBLES FIESTA ==========

List<CoachStep> fiestaEnsemblesHelp({
  required GlobalKey ready,
  required GlobalKey firstMine,
  required GlobalKey create,
  required GlobalKey next,
  required bool hasMine,
  required bool full,
  required bool hasDraft,
}) =>
    [
      CoachStep(
        target: ready,
        title: 'Prêts à jouer',
        text:
            'Les ensembles fournis par l\'app${hasMine ? ', puis les tiens' : ''}. '
            'Touche-en un pour le choisir. L\'œil montre ce qu\'il fait, '
            'l\'icône de copie le duplique : c\'est ainsi qu\'on modifie un '
            'ensemble de l\'app.'
            '${full ? ' Ta liste est pleine : la copie reste grisée tant que tu '
                'n\'en supprimes pas un.' : ''}',
      ),
      CoachStep(
        target: firstMine,
        title: 'Tes ensembles',
        text: 'Le badge « Perso » les distingue. Le crayon en modifie un, la '
            'corbeille le supprime.',
      ),
      if (hasDraft)
        CoachStep(
          target: create,
          title: 'Reprendre le brouillon',
          text: 'Rouvre l\'ensemble que tu n\'as pas fini, là où tu l\'as '
              'laissé.',
        )
      else if (full)
        CoachStep(
          target: create,
          title: 'Limite atteinte',
          text: 'Supprime un de tes ensembles pour en créer un nouveau.',
        )
      else
        CoachStep(
          target: create,
          title: 'Créer un ensemble',
          text: 'Ouvre l\'éditeur : un nom, les 3 menus de réglages, puis '
              '« Enregistrer ».',
        ),
      CoachStep(
        target: next,
        title: 'Suivant',
        text: 'Passe aux joueurs avec l\'ensemble choisi.',
      ),
    ];

/// [tab] : le menu ouvert. Seul son contenu est expliqué.
List<CoachStep> fiestaEditorHelp({
  required GlobalKey tabs,
  required GlobalKey menu,
  required GlobalKey noDraw,
  required GlobalKey locked,
  required GlobalKey challenges,
  required GlobalKey save,
  required EnsembleMenu tab,
  required bool hasCounts,
}) =>
    [
      CoachStep(
        target: tabs,
        title: 'Les 3 menus',
        text: 'Toujours : toute la partie, dans les manches où il existe, pour '
            'toutes les équipes. '
            'Aléatoire par manche : tiré au sort à chaque manche. Cartouches : '
            'à usage unique, jouées au tour de son choix.'
            '${hasCounts ? ' Le chiffre sur un menu : ce qu\'il active.' : ''}',
      ),
      switch (tab) {
        EnsembleMenu.always => CoachStep(
            target: menu,
            title: 'Toujours',
            text: 'Allume ce qui reste actif toute la partie, dans les manches '
                'où il existe. Les bonus, Malus '
                'de 10 s et les deux blocages n\'y sont pas : ils ne sont que '
                'des cartouches.',
          ),
        EnsembleMenu.draw => CoachStep(
            target: menu,
            title: 'Aléatoire par manche',
            text:
                '« Combien par manche » : le nombre de tirages. Allume ce qui '
                'peut sortir. Les bonus, Malus de 10 s et les deux blocages n\'y '
                'sont pas : ils ne sont que des cartouches.',
          ),
        EnsembleMenu.cartridge => CoachStep(
            target: menu,
            title: 'Cartouches',
            text:
                'Au hasard : l\'app choisit. Pour tout le monde : chaque équipe '
                'reçoit exactement ça. « Si tu veux vraiment pousser plus loin » '
                'ouvre les défis surprises.',
          ),
      },
      CoachStep(
        target: noDraw,
        title: 'Rien à tirer',
        text: 'Ce que tu as allumé n\'existe pas dans ces manches : aucun '
            'tirage n\'y aura lieu.',
      ),
      CoachStep(
        target: locked,
        title: 'Verrouillé',
        text: 'Ce réglage est bloqué par un modificateur en Toujours, la ligne '
            'dit lequel. Il est gardé et revient si tu décoches ce modificateur.',
      ),
      CoachStep(
        target: challenges,
        title: 'Défis surprises',
        text:
            '1 ou 2 fois dans la partie, deux joueurs des équipes les plus en '
            'retard s\'affrontent : une cartouche à gagner.',
      ),
      CoachStep(
        target: save,
        title: 'Enregistrer',
        text: 'S\'il manque quelque chose, le message dit quoi.',
      ),
    ];

// ========== HISTORIQUE ==========

/// [trends] : seules les lignes affichées sont expliquées. [hasPlayers] et
/// [hasSetup] : ce que la première partie, cible des étapes, a archivé.
List<CoachStep> historyHelp({
  required GlobalKey trends,
  required GlobalKey firstGame,
  required GlobalKey replay,
  required HistoryTrends stats,
  required bool hasPlayers,
  required bool hasSetup,
}) =>
    [
      CoachStep(
        target: trends,
        title: 'Tendances',
        text: 'Sur les ${GameHistoryService.maxEntries} dernières parties au '
            'plus. Points par partie : la moyenne, toutes équipes réunies.'
            '${stats.bestScoreTeam != null ? ' Meilleur score : le plus haut '
                'd\'une équipe.' : ''}'
            '${stats.winsByTeam.isNotEmpty ? ' Victoires : par nom d\'équipe.' : ''}'
            '${stats.playerAppearances.isNotEmpty ? ' Le plus assidu : le joueur '
                'présent dans le plus de parties.' : ''}',
      ),
      CoachStep(
        target: firstGame,
        title: 'Une partie',
        text: 'Touche une partie pour voir le détail : les équipes, '
            '${hasPlayers ? 'leurs joueurs, ' : ''}les points par manche et ses '
            'réglages.',
      ),
      CoachStep(
        target: replay,
        title: 'Rejouer',
        text: hasSetup
            ? 'Relance cette partie avec les mêmes joueurs, les mêmes équipes '
                'et les mêmes réglages. Les mots, eux, sont nouveaux.'
            : 'Relance cette partie avec les mêmes joueurs et les mêmes '
                'équipes, en Classique. Ancienne partie : seuls le nombre de '
                'mots et la durée du tour sont repris. Les mots sont nouveaux.',
      ),
    ];

// ========== AVANT LE TOUR (game_screen) ==========

/// Aussi affichée automatiquement au premier tour de chaque joueur pendant la
/// première partie sur ce téléphone.
List<CoachStep> preTurnHelp({
  required GlobalKey team,
  required GlobalKey roundRules,
  required GlobalKey previousTurn,
  required GlobalKey bonusTime,
  required GlobalKey back,
  required GlobalKey start,
  required String playerName,
  required bool firstTurnOfGame,
  List<CoachStep> fiesta = const [],
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
      ...fiesta,
      CoachStep(
        target: bonusTime,
        title: 'Temps bonus',
        text: 'La manche d\'avant s\'est finie pendant ton tour : le temps '
            'qu\'il te restait est reporté sur ce tour.',
      ),
      CoachStep(
        target: back,
        title: firstTurnOfGame ? 'Retour aux équipes' : 'Retour',
        text: firstTurnOfGame
            ? 'Reviens à la composition des équipes, tant que le premier tour '
                'n\'a pas commencé.'
            : 'Reviens à la vérification du tour précédent pour corriger un mot.',
      ),
      CoachStep(
        target: start,
        title: 'Commencer le tour',
        text: 'Le chrono démarre après un court décompte. Prends le '
            'téléphone, cache l\'écran, et c\'est parti.',
      ),
    ];

// ========== TOUR ==========

/// Pourquoi « Passer » marche ou non à cet instant.
enum PassState { available, blocked, lastWord, notEnoughTime }

String _passSentence(PassState state, int passPenalty) => switch (state) {
      PassState.available => 'Mot trop dur ? Passe-le, il reviendra plus tard '
          'dans la manche. ${passPenaltySentence(passPenalty)}',
      PassState.blocked => 'Un malus interdit de passer pendant ce tour.',
      PassState.lastWord => 'Plus aucun autre mot à faire deviner : impossible '
          'de passer celui-ci.',
      PassState.notEnoughTime => 'Il reste moins de temps que la pénalité : '
          'impossible de passer.',
    };

/// Deux mots : les boutons vivent sous chaque carte, sans clé `guessed` ni
/// `pass` : l'étape du mot les explique ([buttonsUnderWord], [secondWordShown]).
List<CoachStep> turnHelp({
  required GlobalKey timer,
  required GlobalKey modifiers,
  required GlobalKey blockedGuesser,
  required GlobalKey freePasses,
  required GlobalKey word,
  required GlobalKey guessed,
  required GlobalKey pass,
  required GlobalKey pause,
  required GlobalKey endTurn,
  required int passPenalty,
  required PassState passState,
  required bool reversed,
  required bool buttonsUnderWord,
  required bool secondWordShown,
}) {
  final reversedNote =
      reversed ? ' À l\'écran, il est à l\'envers : à toi de le remettre.' : '';
  return [
    CoachStep(
      target: timer,
      title: 'Le chrono',
      text: 'Quand il arrive à zéro, le tour s\'arrête.',
    ),
    CoachStep(
      target: modifiers,
      title: 'Actif pendant ce tour',
      text: 'Ce qui s\'applique à ce tour : règles de la manche, malus reçus, '
          'bonus activés. Touche un badge pour son explication.',
    ),
    CoachStep(
      target: blockedGuesser,
      title: 'Joueur bloqué',
      text: 'Une autre équipe l\'a bloqué : il ne doit pas répondre pendant ce '
          'tour.',
    ),
    CoachStep(
      target: freePasses,
      title: 'Passes gratuites',
      text: 'Passer ne coûte rien tant qu\'il en reste. Ensuite, la pénalité '
          'habituelle revient.',
    ),
    if (buttonsUnderWord)
      CoachStep(
        target: word,
        title: secondWordShown ? 'Les deux mots' : 'Le mot',
        text: secondWordShown
            ? 'Deux mots à faire deviner en même temps, sans les montrer. '
                'Chacun a ses boutons : Trouvé, et Passer.$reversedNote '
                '${_passSentence(passState, passPenalty)}'
            : 'Fais-le deviner sans le montrer, puis touche Trouvé ou Passer, '
                'juste dessous.$reversedNote '
                '${_passSentence(passState, passPenalty)}',
      )
    else
      CoachStep(
        target: word,
        title: 'Le mot',
        text: 'Fais-le deviner en suivant la règle de la manche, sans le '
            'montrer.$reversedNote',
      ),
    CoachStep(
      target: guessed,
      title: 'Trouvé',
      text: 'Ton équipe a trouvé le mot : touche ici, le suivant arrive.',
    ),
    CoachStep(
      target: pass,
      title: passState == PassState.blocked ? 'Passer (bloqué)' : 'Passer',
      text: _passSentence(passState, passPenalty),
    ),
    CoachStep(
      target: pause,
      title: 'Pause',
      text: 'Un imprévu ? Mets le chrono en pause.',
    ),
    CoachStep(
      target: endTurn,
      title: 'Terminer le tour',
      text:
          'Arrête le tour tout de suite. Les secondes restantes sont perdues.',
    ),
  ];
}

// ========== VÉRIFICATION ==========

/// Écran souvent mal compris : le texte doit être très explicite.
List<CoachStep> verificationHelp({
  required GlobalKey doubled,
  required GlobalKey wordList,
  required GlobalKey expired,
  required GlobalKey passed,
  required GlobalKey validate,
}) =>
    [
      CoachStep(
        target: doubled,
        title: 'Mot compte double',
        text: 'Ce bonus jouait à ce tour : chaque mot validé compte 2 points.',
      ),
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
        target: expired,
        title: 'Temps écoulé',
        text: 'Ce qui était à l\'écran quand le chrono est tombé. Trouvé à '
            'temps ? Touche-le pour le valider.',
      ),
      CoachStep(
        target: passed,
        title: 'Mots passés',
        text: 'Les mots passés pendant ce tour. Ils reviennent plus tard dans '
            'la manche, sauf si tu en valides un.',
      ),
      CoachStep(
        target: validate,
        title: 'Valider',
        text: 'Quand toutes les couleurs sont justes, valide. Le téléphone '
            'passe ensuite à l\'équipe suivante.',
      ),
    ];

// ========== ENTRE DEUX MANCHES (transition_screen) ==========

/// Après la manche 3 : le seul écran fixe entre deux manches, les autres sont
/// une animation.
List<CoachStep> transitionHelp({
  required GlobalKey previousTurn,
  required GlobalKey next,
  required GlobalKey back,
}) =>
    [
      CoachStep(
        target: previousTurn,
        title: 'Mots du dernier tour',
        text: 'Revois les mots trouvés pendant le dernier tour.',
      ),
      CoachStep(
        target: back,
        title: 'Retour',
        text: 'Reviens à la vérification du dernier tour pour corriger un mot.',
      ),
      CoachStep(
        target: next,
        title: 'Voir les résultats',
        text: 'Termine la partie et lance la révélation des scores.',
      ),
    ];

// ========== RÉSULTATS ==========

List<CoachStep> resultsHelp({
  required GlobalKey podium,
  required GlobalKey details,
  required GlobalKey back,
  required GlobalKey replay,
  required GlobalKey stats,
  required bool hasPlayedCartridges,
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
        target: back,
        title: 'Retour',
        text: 'Reviens à la vérification du dernier tour pour corriger un mot.',
      ),
      CoachStep(
        target: replay,
        title: 'Rejouer',
        text: 'Relance une partie avec les mêmes joueurs.',
      ),
      CoachStep(
        target: stats,
        title: 'Statistiques',
        text: 'Les meilleurs joueurs et l\'évolution des scores'
            '${hasPlayedCartridges ? ', avec un filtre pour les bonus et malus joués' : ''}. Le '
            'temps moyen par mot et le détail par manche sont sous « Cherry on '
            'the cake ».',
      ),
    ];

// ========== FIESTA : AVANT LE TOUR ==========

/// Une clé par type d'élément de l'avant-tour Fiesta. `FiestaTurnZone` ne la
/// pose que si l'élément est là : sans lui, l'étape n'existe pas.
class FiestaPreTurnKeys {
  final thisTurn = GlobalKey();
  final firstRule = GlobalKey();
  final firstReceived = GlobalKey();
  final firstArmed = GlobalKey();
  final blockedGuesser = GlobalKey();
  final reserveBonus = GlobalKey();
  final reserveMalus = GlobalKey();
  final firstUnusable = GlobalKey();
  final sent = GlobalKey();
  final reuseChoices = GlobalKey();
}

List<CoachStep> fiestaPreTurnHelp(FiestaPreTurnKeys keys) => [
      CoachStep(
        target: keys.reuseChoices,
        title: 'Reprendre les choix',
        text: 'Le joueur bloqué avait préparé son tour : touche ici pour '
            'reprendre ses choix.',
      ),
      CoachStep(
        target: keys.thisTurn,
        title: 'Actif pendant votre prochain tour',
        text: 'Tout ce qui s\'applique à ton tour. Appui long sur un cercle '
            'pour l\'explication.',
      ),
      CoachStep(
        target: keys.firstRule,
        title: 'Règles de la manche',
        text: 'Étiquette « manche » : cette règle vaut toute la manche, pour '
            'toutes les équipes.',
      ),
      CoachStep(
        target: keys.firstReceived,
        title: 'Malus reçu',
        text: 'Flèche vers le bas : une autre équipe te l\'a infligé, pour ce '
            'tour.',
      ),
      CoachStep(
        target: keys.firstArmed,
        title: 'Bonus activé',
        text: 'Coche : ce bonus jouera pendant ton tour. Touche-le pour le '
            'remettre dans ta réserve.',
      ),
      CoachStep(
        target: keys.blockedGuesser,
        title: 'Joueur bloqué',
        text: 'Une autre équipe l\'a bloqué : il ne devra pas répondre pendant '
            'ton tour.',
      ),
      CoachStep(
        target: keys.reserveBonus,
        title: 'Réserve : tes bonus',
        text: 'Tes cartouches pour toute la partie, un tour chacune. Touche un '
            'bonus pour l\'activer ce tour.',
      ),
      CoachStep(
        target: keys.reserveMalus,
        title: 'Réserve : tes malus',
        text: 'Tes cartouches pour toute la partie, un tour chacune. Touche un '
            'malus pour l\'infliger à une autre équipe, pour son prochain tour.',
      ),
      CoachStep(
        target: keys.firstUnusable,
        title: 'Cartouche indisponible',
        text: 'Grisée : plus aucune en réserve, ou bloquée par une règle. '
            'Appui long pour savoir pourquoi.',
      ),
      CoachStep(
        target: keys.sent,
        title: 'Malus envoyés',
        text: 'Touche une puce pour annuler l\'envoi, tant que ton tour n\'a '
            'pas commencé.',
      ),
    ];
