/// Métadonnées d'une catégorie de mots
///
/// Contient les informations multilingues et la documentation
/// pour une catégorie de mots du jeu.
class CategoryMetadata {
  final String id;
  final String icon;
  final Map<String, String> names; // locale -> nom localisé
  final List<String> availableLocales;
  final Map<String, dynamic>? metadata; // Description, sections, critères

  const CategoryMetadata({
    required this.id,
    required this.icon,
    required this.names,
    required this.availableLocales,
    this.metadata,
  });

  /// Factory constructor depuis JSON
  factory CategoryMetadata.fromJson(Map<String, dynamic> json) {
    return CategoryMetadata(
      id: json['id'] as String,
      icon: json['icon'] as String,
      names: Map<String, String>.from(json['names'] as Map),
      availableLocales: (json['availableLocales'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'names': names,
    'availableLocales': availableLocales,
    if (metadata != null) 'metadata': metadata,
  };

  /// Obtenir le nom localisé pour une langue donnée
  ///
  /// Retourne le nom dans la locale demandée, sinon en français,
  /// sinon l'ID de la catégorie.
  String getLocalizedName(String locale) {
    return names[locale] ?? names['fr'] ?? id;
  }

  /// Vérifier si la catégorie est disponible dans une locale
  bool isAvailableInLocale(String locale) {
    return availableLocales.contains(locale);
  }
}
