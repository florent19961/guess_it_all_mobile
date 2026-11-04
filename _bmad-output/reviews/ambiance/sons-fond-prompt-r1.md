# Revue sons-fond r1 (tier standard)

Objectif : remplacer le son « mot trouvé » (ding.mp3 → ding.wav, cloche douce) et le son de fin de tour (klaxon.mp3 → end_of_turn.wav, gong), générés par `scripts/render_sounds.py` ; remplacer le fond animé `ShootingStars` (2 couches de traits diagonaux) par un « ciel étoilé calme » (étoiles qui scintillent sur 3 profondeurs + étoile filante toutes les 4-7 s). Choix validés par Florent. Le nom de classe `ShootingStars` et son API (`child`) restent inchangés (9 appelants).

Questions :
1. `ShootingStars` : Ticker + ValueNotifier + `CustomPainter(repaint:)` — fuite, dispose, comportement quand la route n'est pas visible (TickerMode), coût par frame (~126 cercles), `%` sur double négatif impossible ?
2. Le layout du Stack est-il équivalent à l'ancien (Container couleur expansé → SizedBox.expand) ?
3. Les WAV sont-ils un format sûr pour audioplayers 6 sur Android et iOS (PCM 16 bits mono 44,1 kHz) ? Reste-t-il une référence aux .mp3 supprimés (lib, test, docs) ?
4. `scripts/render_sounds.py` : enveloppes correctes, risque de clic (début/fin non nuls) ?
5. Grille thermo-nuclear limitée au diff.

Format : findings BLOCKER / MAJOR / MINOR avec fichier:ligne, puis verdict READY / NOT READY.
