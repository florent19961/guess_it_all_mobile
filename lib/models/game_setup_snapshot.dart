import 'package:flutter/foundation.dart';

import 'fiesta/fiesta_rules.dart';
import 'game_settings.dart';

/// La configuration d'une partie, archivée avec son résultat pour le
/// « Rejouer » de l'historique : les paramètres, plus les règles Fiesta si
/// c'en était une. Jamais les mots — ils sont toujours retirés ou ressaisis.
///
/// 🔴 Règle 7 : champ OPTIONNEL d'une entrée de `guessItAll_game_results`.
/// Absent des archives antérieures ; illisible → [tryFromJson] rend `null` et
/// le « Rejouer » retombe sur ce que l'archive connaît déjà.
@immutable
class GameSetupSnapshot {
  final GameSettings settings;

  /// `null` = partie Classique.
  final FiestaRules? fiesta;

  const GameSetupSnapshot({required this.settings, this.fiesta});

  Map<String, dynamic> toJson() => {
        'settings': settings.toJson(),
        if (fiesta != null) 'fiesta': fiesta!.toJson(),
      };

  /// Tolérant : `null` si la structure est inexploitable, jamais d'exception.
  /// Des règles Fiesta présentes mais illisibles invalident tout le snapshot,
  /// plutôt que de rejouer en Classique une partie qui était Fiesta.
  static GameSetupSnapshot? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final rawSettings = json['settings'];
    final rawFiesta = json['fiesta'];
    if (rawSettings is! Map) return null;

    final GameSettings settings;
    try {
      final parsed =
          GameSettings.fromJson(Map<String, dynamic>.from(rawSettings));
      // `fromJson` fait des `cast` PARESSEUX : on force la lecture ici pour
      // qu'un élément mal typé lève maintenant, pas au rendu d'un écran.
      settings = parsed.copyWith(
        selectedCategories: parsed.selectedCategories.toList(),
        selectedDifficultyLevels: parsed.selectedDifficultyLevels.toList(),
      );
    } catch (_) {
      return null;
    }

    FiestaRules? fiesta;
    if (rawFiesta != null) {
      if (rawFiesta is! Map) return null;
      fiesta = FiestaRules.tryFromJson(Map<String, dynamic>.from(rawFiesta));
      if (fiesta == null) return null;
    }
    return GameSetupSnapshot(settings: settings, fiesta: fiesta);
  }
}
