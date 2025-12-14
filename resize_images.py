#!/usr/bin/env python3
"""
Script pour redimensionner des images PNG en 2048x2732
Usage: python resize_images.py <dossier_source> <dossier_destination>
"""

import sys
import os
from PIL import Image

def resize_images(input_dir, output_dir):
    target_size = (1260, 2736)

    # Créer le dossier de sortie s'il n'existe pas
    os.makedirs(output_dir, exist_ok=True)

    # Parcourir les fichiers PNG
    png_files = [f for f in os.listdir(input_dir) if f.lower().endswith('.jpeg')]

    if not png_files:
        print(f"Aucun fichier PNG trouvé dans {input_dir}")
        return

    print(f"Traitement de {len(png_files)} image(s)...")

    for filename in png_files:
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, filename)

        try:
            with Image.open(input_path) as img:
                # Redimensionner avec LANCZOS pour une meilleure qualité
                resized = img.resize(target_size, Image.LANCZOS)
                resized.save(output_path, 'PNG')
                print(f"✓ {filename} -> {target_size[0]}x{target_size[1]}")
        except Exception as e:
            print(f"✗ Erreur pour {filename}: {e}")

    print(f"\nTerminé! Images sauvegardées dans {output_dir}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python resize_images.py <dossier_source> <dossier_destination>")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.isdir(input_dir):
        print(f"Erreur: {input_dir} n'est pas un dossier valide")
        sys.exit(1)

    resize_images(input_dir, output_dir)
