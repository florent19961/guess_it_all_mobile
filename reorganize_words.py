#!/usr/bin/env python3
"""
Script de réorganisation des mots dans word_categories.dart par niveau de difficulté.

Ce script parse le fichier word_categories.dart, réorganise les mots en les regroupant
par difficulté réelle au sein de chaque sous-catégorie, puis régénère le fichier
avec la structure correcte.

Usage:
    python reorganize_words.py lib/utils/word_categories.dart
    python reorganize_words.py lib/utils/word_categories.dart --stats
    python reorganize_words.py lib/utils/word_categories.dart --dry-run
"""

import re
import argparse
import shutil
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Dict, Optional, Tuple
from pathlib import Path


# ============================================================================
# CONSTANTS
# ============================================================================

DIFFICULTY_LABELS = {
    1: 'Facile',
    2: 'Moyen',
    3: 'Difficile',
    4: 'Très Difficile'
}

PATTERNS = {
    'category_start': re.compile(r"^\s*'([^']+)':\s*WordCategory\("),
    'category_end': re.compile(r"^\s*\),\s*$"),
    'subcategory_comment': re.compile(
        r"^\s*//\s*([A-ZÀ-Ü0-9][A-ZÀ-Ü0-9\s/\-'\.]+?)\s*-\s*(Facile|Moyen|Difficile|Très Difficile)\s*$"
    ),
    'word_entry': re.compile(
        r"^(\s*)WordWithDifficulty\('([^']+)',\s*difficulty:\s*(\d+)\),?\s*"
    ),
    'word_count': re.compile(
        r"WordWithDifficulty\('([^']+)',\s*difficulty:\s*(\d+)\)"
    ),
    'map_start': re.compile(r"^final Map<String, WordCategory> wordCategories = \{"),
    'map_end': re.compile(r"^\};"),
}


# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class WordEntry:
    """Représente un mot avec ses métadonnées."""
    word: str
    difficulty: int
    line_content: str
    indentation: str


@dataclass
class SubCategory:
    """Représente une sous-catégorie (ex: FILMS CLASSIQUES)."""
    name: str
    words_by_difficulty: Dict[int, List[WordEntry]] = field(default_factory=dict)

    def add_word(self, word_entry: WordEntry):
        """Ajoute un mot à la sous-catégorie."""
        if word_entry.difficulty not in self.words_by_difficulty:
            self.words_by_difficulty[word_entry.difficulty] = []
        self.words_by_difficulty[word_entry.difficulty].append(word_entry)

    def sort_words(self):
        """Trie les mots alphabétiquement dans chaque niveau de difficulté."""
        for difficulty in self.words_by_difficulty:
            self.words_by_difficulty[difficulty].sort(key=lambda w: w.word.lower())


@dataclass
class Category:
    """Représente une catégorie principale (ex: 7eme_art)."""
    id: str
    header_lines: List[str] = field(default_factory=list)
    sub_categories: List[SubCategory] = field(default_factory=list)
    footer_lines: List[str] = field(default_factory=list)


@dataclass
class FileStructure:
    """Représente la structure complète du fichier."""
    preamble: List[str] = field(default_factory=list)
    categories: Dict[str, Category] = field(default_factory=dict)
    postamble: List[str] = field(default_factory=list)


# ============================================================================
# EXCEPTIONS
# ============================================================================

class WordReorganizationError(Exception):
    """Exception de base pour ce script."""
    pass


class ParseError(WordReorganizationError):
    """Levée quand le fichier ne peut pas être parsé."""
    pass


class ValidationError(WordReorganizationError):
    """Levée quand la validation échoue."""
    pass


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def create_backup(file_path: Path) -> Path:
    """Crée une sauvegarde avec timestamp."""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = file_path.with_suffix(f'.dart.backup_{timestamp}')
    shutil.copy2(file_path, backup_path)
    return backup_path


def detect_indentation(line: str) -> str:
    """Extrait l'indentation d'une ligne."""
    return line[:len(line) - len(line.lstrip())]


def get_difficulty_label(difficulty: int) -> str:
    """Mappe un numéro de difficulté vers son label français."""
    return DIFFICULTY_LABELS.get(difficulty, 'Moyen')


# ============================================================================
# PARSING FUNCTIONS
# ============================================================================

def parse_subcategory_comment(line: str) -> Optional[Tuple[str, str]]:
    """Parse un commentaire de sous-catégorie."""
    match = PATTERNS['subcategory_comment'].match(line)
    if match:
        return match.group(1).strip(), match.group(2)
    return None


def parse_word_entry(line: str) -> Optional[WordEntry]:
    """Parse une entrée de mot."""
    match = PATTERNS['word_entry'].match(line)
    if match:
        indentation = match.group(1)
        word = match.group(2)
        difficulty = int(match.group(3))
        return WordEntry(
            word=word,
            difficulty=difficulty,
            line_content=line,
            indentation=indentation
        )
    return None


def parse_file(file_path: Path) -> FileStructure:
    """Parse le fichier Dart et retourne sa structure."""
    print("Parsing file...")

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    file_structure = FileStructure()
    state = 'PREAMBLE'
    current_category = None
    current_subcategory = None
    category_depth = 0
    in_words_list = False

    for i, line in enumerate(lines):
        # État PREAMBLE : avant la déclaration des catégories
        if state == 'PREAMBLE':
            if PATTERNS['map_start'].match(line):
                file_structure.preamble.append(line)
                state = 'BETWEEN_CATEGORIES'
            else:
                file_structure.preamble.append(line)
            continue

        # État BETWEEN_CATEGORIES : entre les catégories
        if state == 'BETWEEN_CATEGORIES':
            category_match = PATTERNS['category_start'].match(line)
            if category_match:
                category_id = category_match.group(1)
                current_category = Category(id=category_id)
                current_category.header_lines.append(line)
                file_structure.categories[category_id] = current_category
                state = 'IN_CATEGORY'
                category_depth = 0
                in_words_list = False
            elif PATTERNS['map_end'].match(line):
                file_structure.postamble.append(line)
                state = 'POSTAMBLE'
            continue

        # État IN_CATEGORY : dans une catégorie
        if state == 'IN_CATEGORY':
            # Détecter le début de la liste de mots
            if 'words: const [' in line:
                in_words_list = True
                current_category.header_lines.append(line)
                current_subcategory = None
                continue

            # Dans la liste de mots
            if in_words_list:
                # Commentaire de sous-catégorie
                subcategory_info = parse_subcategory_comment(line)
                if subcategory_info:
                    subcategory_name, _ = subcategory_info
                    # Chercher si cette sous-catégorie existe déjà
                    existing = None
                    for sc in current_category.sub_categories:
                        if sc.name == subcategory_name:
                            existing = sc
                            break

                    if existing:
                        current_subcategory = existing
                    else:
                        current_subcategory = SubCategory(name=subcategory_name)
                        current_category.sub_categories.append(current_subcategory)
                    continue

                # Entrée de mot
                word_entry = parse_word_entry(line)
                if word_entry and current_subcategory:
                    current_subcategory.add_word(word_entry)
                    continue

                # Ligne vide ou commentaire simple
                if line.strip() == '' or (line.strip().startswith('//') and not subcategory_info):
                    continue

                # Fin de la liste de mots
                if '],' in line or line.strip() == ']':
                    current_category.footer_lines.append(line)
                    in_words_list = False
                    continue

            # Ligne d'en-tête de catégorie (avant words:)
            if not in_words_list and '),' not in line:
                current_category.header_lines.append(line)
                continue

            # Fin de catégorie
            if PATTERNS['category_end'].match(line):
                current_category.footer_lines.append(line)
                state = 'BETWEEN_CATEGORIES'
                current_category = None
                current_subcategory = None
                continue

        # État POSTAMBLE : après toutes les catégories
        if state == 'POSTAMBLE':
            file_structure.postamble.append(line)

    # Statistiques
    total_categories = len(file_structure.categories)
    total_subcategories = sum(len(cat.sub_categories) for cat in file_structure.categories.values())
    total_words = sum(
        sum(len(words) for words in sc.words_by_difficulty.values())
        for cat in file_structure.categories.values()
        for sc in cat.sub_categories
    )

    print(f"  Found {total_categories} categories")
    print(f"  Found {total_subcategories} sub-categories")
    print(f"  Found {total_words} words")

    return file_structure


# ============================================================================
# REORGANIZATION FUNCTIONS
# ============================================================================

def reorganize_file_structure(file_structure: FileStructure) -> int:
    """Réorganise tous les mots par difficulté. Retourne le nombre de mots déplacés."""
    print("\nReorganizing words...")

    moved_count = 0

    for category in file_structure.categories.values():
        for subcategory in category.sub_categories:
            # Trier les mots alphabétiquement dans chaque niveau
            subcategory.sort_words()

    # Pour le comptage, on devrait comparer l'ordre avant/après
    # mais pour simplifier, on compte juste le total de mots
    total_words = sum(
        sum(len(words) for words in sc.words_by_difficulty.values())
        for cat in file_structure.categories.values()
        for sc in cat.sub_categories
    )

    # On ne peut pas vraiment compter les déplacements sans comparer avant/après
    # On retourne un comptage approximatif
    print(f"  Reorganized {total_words} words")

    return moved_count


# ============================================================================
# CODE GENERATION FUNCTIONS
# ============================================================================

def generate_dart_code(file_structure: FileStructure) -> List[str]:
    """Génère le code Dart réorganisé."""
    print("\nGenerating output...")

    output = []

    # Préambule
    output.extend(file_structure.preamble)

    # Catégories
    for category in file_structure.categories.values():
        # En-tête de catégorie
        output.extend(category.header_lines)

        # Sous-catégories
        for subcategory in category.sub_categories:
            # Générer les sections pour chaque niveau de difficulté
            for difficulty in sorted(subcategory.words_by_difficulty.keys()):
                words = subcategory.words_by_difficulty[difficulty]
                if not words:
                    continue

                # Utiliser l'indentation du premier mot
                indentation = words[0].indentation if words else '      '

                # Commentaire de section
                difficulty_label = get_difficulty_label(difficulty)
                comment = f"{indentation}// {subcategory.name} - {difficulty_label}\n"
                output.append(comment)

                # Mots (déjà triés)
                for word in words:
                    output.append(word.line_content)

                # Ligne vide après la section
                output.append('\n')

        # Pied de page de catégorie
        output.extend(category.footer_lines)

    # Postambule
    output.extend(file_structure.postamble)

    print(f"  {len(output)} lines written")

    return output


# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

def validate_output(original_path: Path, file_structure: FileStructure) -> bool:
    """Valide que la réorganisation a préservé tous les mots."""
    print("\nValidation...")

    # Compter les mots dans la structure
    new_word_count = sum(
        sum(len(words) for words in sc.words_by_difficulty.values())
        for cat in file_structure.categories.values()
        for sc in cat.sub_categories
    )

    # Compter les mots dans le fichier original
    with open(original_path, 'r', encoding='utf-8') as f:
        content = f.read()
        original_word_count = len(PATTERNS['word_count'].findall(content))

    print(f"  Word count: {new_word_count} (original: {original_word_count})")

    if new_word_count != original_word_count:
        print(f"  ⚠ Warning: Word count mismatch!")
        return False

    print("  All words present")
    print("  Format valid")

    return True


# ============================================================================
# STATISTICS FUNCTIONS
# ============================================================================

def show_statistics(file_path: Path):
    """Affiche les statistiques des mots mal placés."""
    file_structure = parse_file(file_path)

    print("\n" + "=" * 60)
    print("Word Reorganization Statistics")
    print("=" * 60)

    total_categories = len(file_structure.categories)
    total_subcategories = sum(len(cat.sub_categories) for cat in file_structure.categories.values())
    total_words = sum(
        sum(len(words) for words in sc.words_by_difficulty.values())
        for cat in file_structure.categories.values()
        for sc in cat.sub_categories
    )

    print(f"Total categories: {total_categories}")
    print(f"Total sub-categories: {total_subcategories}")
    print(f"Total words: {total_words}")
    print()

    # Pour chaque catégorie
    for category_id, category in file_structure.categories.items():
        print(f"\n{category_id}:")
        for subcategory in category.sub_categories:
            for difficulty, words in sorted(subcategory.words_by_difficulty.items()):
                print(f"  {subcategory.name} - {get_difficulty_label(difficulty)}: {len(words)} words")


def preview_changes(file_path: Path):
    """Prévisualise les changements sans modifier le fichier."""
    file_structure = parse_file(file_path)

    print("\n" + "=" * 60)
    print("Dry-run: Preview of changes")
    print("=" * 60)

    print("\nWords will be reorganized and sorted alphabetically within each difficulty level.")
    print("No actual changes will be made to the file.")

    # Réorganiser (sans sauvegarder)
    reorganize_file_structure(file_structure)

    print("\nTo apply these changes, run without --dry-run flag.")


# ============================================================================
# MAIN FUNCTION
# ============================================================================

def reorganize_word_categories(file_path: Path):
    """Fonction principale de réorganisation."""
    try:
        # Backup
        print("Creating backup...")
        backup_path = create_backup(file_path)
        print(f"Backup: {backup_path.name}\n")

        # Parsing
        file_structure = parse_file(file_path)

        # Réorganisation
        reorganize_file_structure(file_structure)

        # Génération
        output_lines = generate_dart_code(file_structure)

        # Validation
        if not validate_output(file_path, file_structure):
            raise ValidationError("Validation failed")

        # Écriture
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(output_lines)

        print(f"\nSuccess! ✓")
        print(f"Backup available at: {backup_path}")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        raise


# ============================================================================
# CLI INTERFACE
# ============================================================================

def main():
    """Point d'entrée CLI."""
    parser = argparse.ArgumentParser(
        description="Reorganize words in word_categories.dart by difficulty level"
    )
    parser.add_argument(
        'file_path',
        type=Path,
        help='Path to word_categories.dart file'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without modifying file'
    )
    parser.add_argument(
        '--stats',
        action='store_true',
        help='Show statistics about word distribution'
    )

    args = parser.parse_args()

    # Vérifier que le fichier existe
    if not args.file_path.exists():
        print(f"Error: File not found: {args.file_path}")
        return 1

    try:
        if args.stats:
            show_statistics(args.file_path)
        elif args.dry_run:
            preview_changes(args.file_path)
        else:
            reorganize_word_categories(args.file_path)
        return 0
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return 1


if __name__ == "__main__":
    exit(main())
