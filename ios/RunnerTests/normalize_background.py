#!/usr/bin/env python3
"""
Normalise les pixels proches de RGB(44, 55, 73) vers cette valeur exacte.
Tolérance: +/- 3 sur chaque composante.

Usage: python normalize_background.py <input_image> <output_image>
"""

import sys
from PIL import Image
import numpy as np


def normalize_background(input_path: str, output_path: str) -> None:
    target = np.array([44, 55, 73])
    tolerance = 3

    img = Image.open(input_path).convert('RGB')
    pixels = np.array(img)

    # Masque des pixels dans la tolérance
    mask = np.all(np.abs(pixels - target) <= tolerance, axis=2)

    # Remplacer par la valeur cible
    pixels[mask] = target

    result = Image.fromarray(pixels)
    result.save(output_path)
    print(f"Image sauvegardée: {output_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python normalize_background.py <input_image> <output_image>")
        sys.exit(1)

    normalize_background(sys.argv[1], sys.argv[2])
