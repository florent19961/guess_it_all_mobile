#!/usr/bin/env python3
"""
Script pour redimensionner des images PNG/JPEG et les sauvegarder en JPG
Usage: python resize_images.py <dossier_source> <dossier_destination>
"""

import sys
import os
from PIL import Image


def resize_images(input_dir, output_dir, target_size=(1284, 2778), quality=95):
    # Créer le dossier de sortie s'il n'existe pas
    os.makedirs(output_dir, exist_ok=True)

    # Parcourir les fichiers PNG et JPEG
    image_files = [
        f for f in os.listdir(input_dir)
        if f.lower().endswith(('.png', '.jpeg', '.jpg'))
    ]

    if not image_files:
        print(f"Aucun fichier PNG/JPEG trouvé dans {input_dir}")
        return

    print(f"Traitement de {len(image_files)} image(s)...")

    for filename in image_files:
        input_path = os.path.join(input_dir, filename)
        # Changer l'extension en .jpg
        base_name = os.path.splitext(filename)[0]
        output_filename = base_name + '.jpg'
        output_path = os.path.join(output_dir, output_filename)

        try:
            with Image.open(input_path) as img:
                # Convertir en RGB si nécessaire (JPEG ne supporte pas la transparence)
                if img.mode in ('RGBA', 'LA', 'P'):
                    background = Image.new('RGB', img.size, (255, 255, 255))
                    if img.mode == 'P':
                        img = img.convert('RGBA')
                    background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                    img = background
                elif img.mode != 'RGB':
                    img = img.convert('RGB')

                # Redimensionner avec LANCZOS pour une meilleure qualité
                resized = img.resize(target_size, Image.LANCZOS)
                resized.save(output_path, 'JPEG', quality=quality)
                print(f"✓ {filename} -> {output_filename} ({target_size[0]}x{target_size[1]})")
        except Exception as e:
            print(f"✗ Erreur pour {filename}: {e}")

    print(f"\nTerminé! Images sauvegardées dans {output_dir}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python resize_images.py <dossier_source> <dossier_destination> [largeur] [hauteur] [qualité]")
        print("  Défaut: 1284x2778, qualité 95")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]

    # Dimensions optionnelles
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 1284
    height = int(sys.argv[4]) if len(sys.argv) > 4 else 2778
    quality = int(sys.argv[5]) if len(sys.argv) > 5 else 95

    if not os.path.isdir(input_dir):
        print(f"Erreur: {input_dir} n'est pas un dossier valide")
        sys.exit(1)

    resize_images(input_dir, output_dir, (width, height), quality)
