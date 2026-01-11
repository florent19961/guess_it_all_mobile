#!/usr/bin/env python3
"""
Script pour dédoublonner les mots à travers TOUS les fichiers JSON de catégories.
Conserve uniquement la première occurrence de chaque mot (arbitrairement).
"""

import json
import os
from pathlib import Path
from collections import defaultdict

def normalize_word(word: str) -> str:
    """Normalise un mot pour la comparaison (minuscules, sans accents problématiques)."""
    return word.lower().strip()

def load_all_words(json_dir: Path) -> dict:
    """Charge tous les mots de tous les fichiers JSON."""
    all_files = {}

    for json_file in sorted(json_dir.glob('*.json')):
        # Ignorer les fichiers annotés
        if '_annotated' in json_file.name:
            continue

        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            all_files[json_file.name] = {
                'path': json_file,
                'data': data,
                'words': data.get('words', [])
            }

    return all_files

def find_duplicates(all_files: dict) -> dict:
    """Trouve tous les doublons à travers les fichiers."""
    word_locations = defaultdict(list)

    for filename, file_info in all_files.items():
        for idx, word_entry in enumerate(file_info['words']):
            word = word_entry['word']
            normalized = normalize_word(word)
            word_locations[normalized].append({
                'file': filename,
                'index': idx,
                'original': word,
                'difficulty': word_entry.get('difficulty', 1)
            })

    # Filtrer pour ne garder que les doublons
    duplicates = {word: locs for word, locs in word_locations.items() if len(locs) > 1}
    return duplicates

def deduplicate_files(all_files: dict, duplicates: dict) -> tuple:
    """Supprime les doublons, garde la première occurrence."""
    indices_to_remove = defaultdict(set)
    removed_details = []

    for normalized_word, locations in duplicates.items():
        # Garder le premier, supprimer les autres
        kept = locations[0]
        for loc in locations[1:]:
            indices_to_remove[loc['file']].add(loc['index'])
            removed_details.append({
                'word': loc['original'],
                'removed_from': loc['file'],
                'kept_in': kept['file']
            })

    # Reconstruire les fichiers sans les doublons
    modified_files = {}
    total_removed = 0

    for filename, file_info in all_files.items():
        if filename in indices_to_remove:
            indices = indices_to_remove[filename]
            new_words = [w for i, w in enumerate(file_info['words']) if i not in indices]
            modified_files[filename] = {
                'path': file_info['path'],
                'data': {
                    'categoryId': file_info['data'].get('categoryId'),
                    'words': new_words
                },
                'removed_count': len(indices)
            }
            total_removed += len(indices)
        else:
            modified_files[filename] = {
                'path': file_info['path'],
                'data': file_info['data'],
                'removed_count': 0
            }

    return modified_files, total_removed, removed_details

def save_files(modified_files: dict):
    """Sauvegarde les fichiers modifiés."""
    for filename, file_info in modified_files.items():
        if file_info['removed_count'] > 0:
            with open(file_info['path'], 'w', encoding='utf-8') as f:
                json.dump(file_info['data'], f, ensure_ascii=False, indent=2)

def main():
    print("=== Déduplication globale des mots JSON ===\n")

    json_dir = Path('/mnt/c/Users/flore/Documents/Python Scripts/guess_it_all_mobile/assets/translations/words/fr')

    # Charger tous les fichiers
    print("Chargement des fichiers...")
    all_files = load_all_words(json_dir)

    total_words_before = sum(len(f['words']) for f in all_files.values())
    print(f"  {len(all_files)} fichiers chargés")
    print(f"  {total_words_before} mots au total\n")

    # Trouver les doublons
    print("Recherche des doublons...")
    duplicates = find_duplicates(all_files)
    print(f"  {len(duplicates)} mots en double trouvés\n")

    if not duplicates:
        print("Aucun doublon trouvé !")
        return

    # Afficher quelques exemples
    print("Exemples de doublons:")
    for word, locs in list(duplicates.items())[:10]:
        files = [f"{loc['file'].replace('.json', '')}" for loc in locs]
        print(f"  '{locs[0]['original']}' → {', '.join(files)}")
    if len(duplicates) > 10:
        print(f"  ... et {len(duplicates) - 10} autres\n")

    # Dédupliquer
    print("\nDéduplication en cours...")
    modified_files, total_removed, removed_details = deduplicate_files(all_files, duplicates)

    # Afficher les stats par fichier
    print("\nRésultats par fichier:")
    for filename in sorted(modified_files.keys()):
        info = modified_files[filename]
        if info['removed_count'] > 0:
            new_count = len(info['data']['words'])
            print(f"  {filename}: -{info['removed_count']} doublons ({new_count} mots restants)")

    # Sauvegarder
    print("\nSauvegarde des fichiers...")
    save_files(modified_files)

    total_words_after = sum(len(f['data']['words']) for f in modified_files.values())

    print("\n=== Résumé ===")
    print(f"  Mots avant: {total_words_before}")
    print(f"  Mots après: {total_words_after}")
    print(f"  Doublons supprimés: {total_removed}")

    # Sauvegarder le rapport des doublons
    report_path = json_dir.parent.parent / 'duplicates_report.json'
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump({
            'total_removed': total_removed,
            'duplicates': removed_details
        }, f, ensure_ascii=False, indent=2)
    print(f"\n  Rapport sauvegardé: {report_path}")

if __name__ == '__main__':
    main()
