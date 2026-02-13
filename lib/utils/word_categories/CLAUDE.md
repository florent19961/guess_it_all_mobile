# utils/word_categories/

Chargement, generation et lookup de mots depuis les fichiers JSON de categories.

## Fichiers

| Fichier | Role |
|---------|------|
| `models.dart` | `WordWithDifficulty` (word, difficulty 1-4, language), `WordCategory` (id, name, icon, words) |
| `utils.dart` | Fonctions async de generation de mots via `WordLoaderService` |
| `word_categories.dart` | Barrel export (reexporte models + utils) |

## Fonctions cles (`utils.dart`)

| Fonction | Role |
|----------|------|
| `lookupWordsMetadata(words)` | Lookup direct dans toutes les categories pour retrouver categoryId/difficulty/language. Fallback quand le cache memoire est absent |
| `generateWordsFromCategoriesAsync(categories, count, difficultyLevels?)` | Genere une liste de mots en priorisant les jamais vus (via WordHistoryService) |
| `generateWordsWithMetadataAsync(categories, count, difficultyLevels?)` | Idem mais retourne `Map<String, WordMetadata>` avec metadonnees completes |
| `getCategoryListAsync()` | Retourne les metadonnees des categories (sans charger les mots) |
| `getTotalWordsCountAsync(categories, difficultyLevels?)` | Compte les mots disponibles pour les categories/difficultes donnees |

## Donnees

Les mots sont stockes dans `assets/translations/` en JSON. 13 categories, ~5711 mots au total.

## Note

Le sous-repertoire `backup/` contient d'anciennes definitions Dart en dur (avant migration JSON). Ne pas utiliser.
