# Script de Réorganisation des Mots par Difficulté

Ce script Python réorganise automatiquement les mots dans le fichier `word_categories.dart` en les regroupant par niveau de difficulté au sein de chaque sous-catégorie.

## Fonctionnement

Le script :
1. ✅ Parse le fichier `word_categories.dart`
2. ✅ Identifie les mots mal placés (ex: `difficulty: 1` sous une section "Moyen")
3. ✅ Réorganise les mots par difficulté réelle
4. ✅ Trie alphabétiquement les mots dans chaque section
5. ✅ Préserve la structure des sous-catégories
6. ✅ Crée automatiquement un backup avant modification
7. ✅ Valide que tous les mots sont préservés

## Prérequis

- Python 3.7 ou supérieur
- Aucune dépendance externe (utilise uniquement la bibliothèque standard)

## Utilisation

### Mode normal : Réorganiser le fichier

```bash
python3 reorganize_words.py lib/utils/word_categories.dart
```

**Résultat :**
- Crée un backup avec timestamp : `word_categories.dart.backup_YYYYMMDD_HHMMSS`
- Réorganise les mots dans le fichier
- Affiche les statistiques de l'opération

### Mode statistiques : Voir la distribution actuelle

```bash
python3 reorganize_words.py lib/utils/word_categories.dart --stats
```

**Affiche :**
- Nombre total de catégories, sous-catégories et mots
- Distribution des mots par catégorie et difficulté

### Mode dry-run : Prévisualiser sans modifier

```bash
python3 reorganize_words.py lib/utils/word_categories.dart --dry-run
```

**Affiche :**
- Ce qui serait changé
- Sans modifier le fichier

## Exemple de Transformation

### Avant :
```dart
// ACTIONS PHYSIQUES - Facile
WordWithDifficulty('Lever', difficulty: 1),
WordWithDifficulty('Tomber', difficulty: 1),

// ACTIONS PHYSIQUES - Moyen
WordWithDifficulty('Soulever', difficulty: 2),
WordWithDifficulty('Siffler', difficulty: 1),  // ← MAL PLACÉ
WordWithDifficulty('Crier', difficulty: 2),
```

### Après :
```dart
// ACTIONS PHYSIQUES - Facile
WordWithDifficulty('Lever', difficulty: 1),
WordWithDifficulty('Siffler', difficulty: 1),  // ← DÉPLACÉ ET TRIÉ
WordWithDifficulty('Tomber', difficulty: 1),

// ACTIONS PHYSIQUES - Moyen
WordWithDifficulty('Crier', difficulty: 2),
WordWithDifficulty('Soulever', difficulty: 2),
```

## Workflow Recommandé

1. **Modifier les difficultés** dans `word_categories.dart` :
   ```dart
   WordWithDifficulty('Siffler', difficulty: 1),  // Changé de 2 à 1
   ```

2. **Vérifier les statistiques** (optionnel) :
   ```bash
   python3 reorganize_words.py lib/utils/word_categories.dart --stats
   ```

3. **Prévisualiser les changements** (optionnel) :
   ```bash
   python3 reorganize_words.py lib/utils/word_categories.dart --dry-run
   ```

4. **Réorganiser le fichier** :
   ```bash
   python3 reorganize_words.py lib/utils/word_categories.dart
   ```

5. **Vérifier le résultat** :
   - Un backup a été créé automatiquement
   - Les mots ont été réorganisés
   - Tous les mots sont préservés (vérification automatique)

## Sécurité

- ✅ **Backup automatique** avant toute modification
- ✅ **Validation** que tous les mots sont préservés
- ✅ **Préservation** du format et de l'indentation
- ✅ **Mode dry-run** pour prévisualiser

## Mapping des Difficultés

| Valeur | Label |
|--------|-------|
| 1 | Facile |
| 2 | Moyen |
| 3 | Difficile |
| 4 | Très Difficile |

## Gestion des Cas Particuliers

Le script gère automatiquement :
- ✅ Création de nouvelles sections si nécessaire (ex: "Très Difficile" pour difficulty: 4)
- ✅ Suppression des sections vides après réorganisation
- ✅ Préservation des caractères spéciaux (accents, apostrophes)
- ✅ Préservation de l'indentation exacte du fichier original
- ✅ Tri alphabétique insensible à la casse

## Restauration d'un Backup

Si vous souhaitez revenir en arrière :

```bash
# Lister les backups disponibles
ls -la lib/utils/word_categories.dart.backup_*

# Restaurer un backup spécifique
cp lib/utils/word_categories.dart.backup_20251208_183045 lib/utils/word_categories.dart
```

## Aide

Pour afficher l'aide du script :

```bash
python3 reorganize_words.py --help
```

## Notes

- Le script préserve la structure des sous-catégories (FILMS CLASSIQUES, SUPER-HÉROS, etc.)
- Les mots sont automatiquement triés par ordre alphabétique dans chaque section
- Les commentaires et la mise en forme sont préservés
- Le script est idempotent : l'exécuter plusieurs fois sur un fichier déjà organisé ne le modifiera pas

## Sortie Exemple

```
Creating backup... ✓
Backup: word_categories.dart.backup_20251208_183045

Parsing file... ✓
  Found 13 categories
  Found 147 sub-categories
  Found 2366 words

Reorganizing words... ✓
  Reorganized 2366 words

Generating output... ✓
  3289 lines written

Validation... ✓
  Word count: 2366 (unchanged)
  All words present
  Format valid

Success! ✓
Backup available at: word_categories.dart.backup_20251208_183045
```
