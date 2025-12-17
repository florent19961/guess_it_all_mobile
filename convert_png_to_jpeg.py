#!/usr/bin/env python3
"""
Convertit tous les fichiers PNG en JPEG dans un dossier donné.
Les fichiers originaux PNG sont supprimés après conversion.
"""

import os
import sys
from PIL import Image


def convert_png_to_jpeg(folder_path: str, quality: int = 95) -> None:
    """
    Convertit tous les fichiers PNG d'un dossier en JPEG.

    Args:
        folder_path: Chemin du dossier contenant les PNG
        quality: Qualité JPEG (1-100, défaut: 95)
    """
    if not os.path.isdir(folder_path):
        print(f"Erreur: '{folder_path}' n'est pas un dossier valide.")
        sys.exit(1)

    png_files = [f for f in os.listdir(folder_path) if f.lower().endswith('.png')]

    if not png_files:
        print(f"Aucun fichier PNG trouvé dans '{folder_path}'.")
        return

    print(f"Conversion de {len(png_files)} fichier(s) PNG en JPEG...")

    for filename in png_files:
        png_path = os.path.join(folder_path, filename)
        jpeg_filename = os.path.splitext(filename)[0] + '.jpg'
        jpeg_path = os.path.join(folder_path, jpeg_filename)

        try:
            with Image.open(png_path) as img:
                # Convertir en RGB si nécessaire (JPEG ne supporte pas la transparence)
                if img.mode in ('RGBA', 'LA', 'P'):
                    # Créer un fond blanc pour remplacer la transparence
                    background = Image.new('RGB', img.size, (255, 255, 255))
                    if img.mode == 'P':
                        img = img.convert('RGBA')
                    background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                    img = background
                elif img.mode != 'RGB':
                    img = img.convert('RGB')

                img.save(jpeg_path, 'JPEG', quality=quality)

            # Supprimer le fichier PNG original
            os.remove(png_path)
            print(f"  ✓ {filename} → {jpeg_filename}")

        except Exception as e:
            print(f"  ✗ Erreur pour {filename}: {e}")

    print("Conversion terminée.")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python convert_png_to_jpeg.py <dossier> [qualité]")
        print("  dossier: Chemin du dossier contenant les PNG")
        print("  qualité: Qualité JPEG 1-100 (optionnel, défaut: 95)")
        sys.exit(1)

    folder = sys.argv[1]
    quality = int(sys.argv[2]) if len(sys.argv) > 2 else 95

    convert_png_to_jpeg(folder, quality)
