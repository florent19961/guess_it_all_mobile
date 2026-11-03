import 'package:flutter/foundation.dart';

/// Résultat du dépouillement d'un tour, une fois que l'équipe a coché les mots
/// réellement devinés sur l'écran de vérification.
///
/// 🔴 **Pourquoi c'est un type à part.** Tout ceci vivait au milieu des 167
/// lignes de `validateWords`, entremêlé avec le tracking analytics, la mutation
/// des équipes et l'avancement du tour. Conséquence : aucune règle de score
/// n'était atteignable sans instancier `SharedPreferences`, `AnalyticsService`
/// et `UserService` — donc rien n'était testable, donc rien n'était testé.
///
/// C'est aussi le pré-requis direct du mode Fiesta : « mot compte double »,
/// « sanction de passe divisée par deux », « une seule réponse autorisée » sont
/// tous des variantes de CE calcul. Les empiler dans `validateWords` sans point
/// d'entrée testable, c'est garantir des régressions de score qu'on ne
/// découvrirait qu'en soirée.
@immutable
class TurnResolution {
  /// Mots confirmés comme devinés par l'équipe.
  final List<String> validated;

  /// Mots cochés « deviné » pendant le tour mais refusés à la vérification.
  final List<String> invalidatedGuessed;

  /// Mots passés pendant le tour et refusés à la vérification.
  final List<String> invalidatedPassed;

  /// Mots passés pendant le tour mais finalement validés comme devinés.
  final List<String> validatedPassed;

  /// Le mot affiché à l'expiration du chrono a-t-il été validé / refusé ?
  final bool expiredValidated;
  final bool expiredInvalidated;

  /// Le mot affiché à l'expiration du chrono, s'il y en avait un.
  final String? expiredWord;

  /// Pool de mots restants après dépouillement.
  final List<String> remainingPool;

  /// Points marqués par l'équipe sur ce tour.
  final int pointsScored;

  const TurnResolution({
    required this.validated,
    required this.invalidatedGuessed,
    required this.invalidatedPassed,
    required this.validatedPassed,
    required this.expiredValidated,
    required this.expiredInvalidated,
    required this.expiredWord,
    required this.remainingPool,
    required this.pointsScored,
  });

  /// Tous les mots refusés, dans l'ordre où le jeu les traite.
  List<String> get allInvalidated => [
        ...invalidatedGuessed,
        ...invalidatedPassed,
        if (expiredInvalidated && expiredWord != null) expiredWord!,
      ];

  /// La manche est terminée : plus aucun mot à faire deviner.
  bool get isRoundOver => remainingPool.isEmpty;
}

/// Dépouille un tour. Fonction **pure** : mêmes entrées, même sortie, aucun
/// effet de bord, aucune dépendance à un service.
///
/// - [validatedWords] : ce que l'équipe a coché à la vérification.
/// - [guessedThisTurn] / [passedThisTurn] : ce qui s'est passé pendant le tour.
/// - [expiredWord] : le mot affiché quand le chrono est tombé, s'il y en a un.
/// - [currentPool] : les mots encore à faire deviner avant dépouillement.
/// - [pointsMultiplier] : ×2 pour « Mot compte double » (Fiesta 2-9). Vaut
///   pour les POINTS seulement : [TurnResolution.validated] reste la liste
///   des mots, et les stats « mots devinés » ne doublent pas.
TurnResolution resolveTurn({
  required List<String> validatedWords,
  required List<String> guessedThisTurn,
  required List<String> passedThisTurn,
  required String? expiredWord,
  required List<String> currentPool,
  int pointsMultiplier = 1,
}) {
  final validatedSet = validatedWords.toSet();

  final invalidatedGuessed =
      guessedThisTurn.where((w) => !validatedSet.contains(w)).toList();
  final invalidatedPassed =
      passedThisTurn.where((w) => !validatedSet.contains(w)).toList();
  final validatedPassed =
      passedThisTurn.where((w) => validatedSet.contains(w)).toList();

  final expiredValidated =
      expiredWord != null && validatedSet.contains(expiredWord);
  final expiredInvalidated =
      expiredWord != null && !validatedSet.contains(expiredWord);

  // Les mots refusés retournent au pool ; le Set garantit qu'un mot recyclé
  // pendant le tour n'y apparaît pas deux fois.
  final pool = <String>{
    ...currentPool,
    ...invalidatedGuessed,
    ...invalidatedPassed,
  }.toList();

  // Les mots finalement validés en sortent — y compris ceux qui avaient été
  // passés puis remis dans le pool pendant le tour.
  if (expiredValidated) pool.remove(expiredWord);
  for (final word in validatedPassed) {
    pool.remove(word);
  }

  return TurnResolution(
    validated: List<String>.from(validatedWords),
    invalidatedGuessed: invalidatedGuessed,
    invalidatedPassed: invalidatedPassed,
    validatedPassed: validatedPassed,
    expiredValidated: expiredValidated,
    expiredInvalidated: expiredInvalidated,
    expiredWord: expiredWord,
    remainingPool: pool,
    pointsScored: validatedWords.length * pointsMultiplier,
  );
}
