# Scripts de Conversion

## convert_words_to_json.dart

Script de conversion des catégories de mots de Dart vers JSON pour préparer l'internationalisation future.

### Utilisation

```bash
dart run tools/convert_words_to_json.dart
```

### Ce que fait le script

1. **Lecture** : Lit tous les fichiers `.dart` dans `lib/utils/word_categories/categories/`
2. **Parsing des en-têtes** : Extrait les métadonnées documentaires (description, sections, idées d'enrichissement, critères de difficulté)
3. **Extraction des mots** : Extrait tous les mots avec leur niveau de difficulté
4. **Génération** :
   - `assets/translations/categories.json` : Métadonnées de toutes les catégories
   - `assets/translations/words/fr/*.json` : 13 fichiers (un par catégorie)

### Format des fichiers générés

#### categories.json

```json
{
  "categories": [
    {
      "id": "nature",
      "icon": "🌿",
      "names": {"fr": "Nature et Gastronomie"},
      "availableLocales": ["fr"],
      "metadata": {
        "description": "Monde naturel et gastronomie...",
        "sections": ["Animaux sauvages", "Plantes", ...],
        "enrichmentIdeas": ["Races de chiens", ...],
        "difficultyCriteria": {
          "1": "Animaux/plats très connus",
          "2": "Moins courant mais reconnaissable",
          "3": "Spécialisé ou exotique"
        }
      }
    }
  ]
}
```

#### words/fr/nature.json

```json
{
  "categoryId": "nature",
  "words": [
    {"word": "Lion", "difficulty": 1},
    {"word": "Tigre", "difficulty": 1},
    {"word": "Bouillabaisse", "difficulty": 3}
  ]
}
```

### Output

Le script affiche le nombre de mots par catégorie et le total :

```
=== Conversion des catégories de mots Dart → JSON ===

✓ Répertoires de sortie créés

Fichiers trouvés: 13

Traitement de nature.dart...
  ✓ 883 mots extraits

...

✓ Fichier categories.json généré

=== Conversion terminée avec succès ===
Fichiers générés:
  - assets/translations/categories.json
  - assets/translations/words/fr/*.json (13 fichiers)

Statistiques:
  - Catégories: 13
  - Mots totaux: 5,400
```

### Validation

Total attendu : **5,400 mots** répartis sur 13 catégories

| Catégorie | Mots |
|-----------|------|
| Nature et Gastronomie | 883 |
| Dictionnaire | 870 |
| Noms communs | 728 |
| Marques | 427 |
| 7ème Art | 423 |
| Science et Médecine | 458 |
| Géographie | 377 |
| Célébrités | 328 |
| Métiers & Sports | 269 |
| Univers Arcade | 237 |
| Musique | 177 |
| Expressions | 118 |
| Métro Parisien | 105 |

### Historique

- **03/01/2026** : Création du script pour migration Dart → JSON
- **03/01/2026** : Conversion réussie de 5,400 mots
