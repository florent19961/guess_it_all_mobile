#!/usr/bin/env python3
"""
Script pour dédoublonner les mots dans les fichiers Dart de catégories.
Conserve uniquement la première occurrence de chaque doublon.
"""

import re
import os
from pathlib import Path

def extract_words_with_positions(content: str) -> list:
    """Extrait tous les mots avec leur position dans le fichier."""
    pattern = r"WordWithDifficulty\('([^']+)',"
    matches = []
    for match in re.finditer(pattern, content):
        word = match.group(1)
        start = match.start()
        end = match.end()
        # Trouver la ligne complète
        line_start = content.rfind('\n', 0, start) + 1
        line_end = content.find('\n', end)
        if line_end == -1:
            line_end = len(content)
        full_line = content[line_start:line_end]
        matches.append({
            'word': word.lower(),  # Normalisation pour comparaison
            'original_word': word,
            'start': line_start,
            'end': line_end,
            'full_line': full_line
        })
    return matches

def deduplicate_file(filepath: str) -> tuple:
    """Dédoublonne un fichier et retourne le contenu modifié et les stats."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    matches = extract_words_with_positions(content)

    # Identifier les doublons (garder le premier, marquer les suivants)
    seen = {}
    duplicates = []

    for match in matches:
        word = match['word']
        if word in seen:
            duplicates.append(match)
        else:
            seen[word] = match

    if not duplicates:
        return content, 0, []

    # Supprimer les lignes des doublons (en ordre inverse pour préserver les positions)
    lines_to_remove = set()
    duplicate_words = []

    for dup in duplicates:
        lines_to_remove.add(dup['full_line'])
        duplicate_words.append(dup['original_word'])

    # Reconstruire le fichier sans les doublons
    lines = content.split('\n')
    new_lines = []
    removed_count = 0

    for line in lines:
        # Vérifier si cette ligne contient un doublon à supprimer
        is_duplicate = False
        for dup in duplicates:
            if dup['full_line'].strip() == line.strip() and dup['full_line'].strip() in [d['full_line'].strip() for d in duplicates]:
                # Vérifier si c'est exactement ce doublon
                pattern = r"WordWithDifficulty\('" + re.escape(dup['original_word']) + r"',"
                if re.search(pattern, line):
                    # C'est un doublon, on le retire de la liste pour ne pas le supprimer plusieurs fois
                    duplicates = [d for d in duplicates if d != dup]
                    is_duplicate = True
                    removed_count += 1
                    break

        if not is_duplicate:
            new_lines.append(line)

    return '\n'.join(new_lines), removed_count, duplicate_words

def process_files():
    """Traite tous les fichiers de catégories."""
    backup_dir = Path('/mnt/c/Users/flore/Documents/Python Scripts/guess_it_all_mobile/lib/utils/word_categories/backup')

    files_to_process = [
        'metiers_sports.dart',
        'univers_arcade.dart',
        'musique.dart',
        'marques.dart',
        'geographie.dart'
    ]

    total_removed = 0

    for filename in files_to_process:
        filepath = backup_dir / filename
        if not filepath.exists():
            print(f"Fichier non trouvé: {filename}")
            continue

        new_content, removed, duplicates = deduplicate_file(str(filepath))

        if removed > 0:
            # Sauvegarder le fichier dédoublonné
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"{filename}: {removed} doublons supprimés")
            print(f"  Doublons: {', '.join(duplicates[:10])}{'...' if len(duplicates) > 10 else ''}")
        else:
            print(f"{filename}: Aucun doublon trouvé")

        total_removed += removed

    print(f"\nTotal: {total_removed} doublons supprimés")

if __name__ == '__main__':
    process_files()
